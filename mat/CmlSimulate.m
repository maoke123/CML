function [sim_param, sim_state] = CmlSimulate( varargin )
% CmlSimulate runs a set of simulations.
%
% The calling syntax is:
%     [sim_param, sim_state] = CmlSimulate( scenario_filename, cases )
%
%     Outputs:
%     sim_param = A structure containing simulation parameters.
%     sim_state = A structure containing the simulation state.
%     Note: See readme.txt for a description of the structure formats.
%
%     Required inputs:
%	  scenario_filename = the name of the file containing an array of sim_param structures.
%     cases = a list of the array indices to simulate.
%
%     Note: Multiple scenario files can be specified.  In this case, the argument list
%     should contain each scenario file to be used followed by the list of array indices
%     to read from that file.
%
%     Example:
%     [sim_param, sim_state] = CmlSimulate( 'Scenario1', [1 2 5], 'Scenario2', [1 4 6] );
%
%     Copyright (C) 2005-2007, Matthew C. Valenti
%
%     Last updated on Oct. 12, 2007


% determine if in testing mode.  Terry 2/2016
if strcmp(varargin{end},'testing') 
    testing=1;
    varargin = varargin(1:end-1); % remove testing parameter from input
else
    testing=0;
end

% setup structures and retrieve data
[sim_param, sim_state] = ReadScenario( varargin{:} );
number_cases = length( sim_param );

% if testing mode is requested, set required parameters
%  Terry 2/2016
if testing == 1,
   [sim_param, sim_state]=SetTestingParameters(sim_param, sim_state);
end

% determine location of CmlHome
load( 'CmlHome.mat' );

for ( case_number=1:number_cases )
    fprintf( '\n\nRecord %d\n', case_number );
    [sim_param(case_number), code_param] = InitializeCodeParam( sim_param(case_number), cml_home );
    
    sim_param(case_number).SimLocation = 'local';    % using CmlSimulate so assume running locally
    
    if ( ( strcmp( sim_param(case_number).sim_type, 'throughput' ) ) )
        % calculate the throughput
        [sim_param(case_number), sim_state(case_number)] = CalculateThroughput( sim_param(case_number), sim_state(case_number), code_param );
    elseif ( ( strcmp( sim_param(case_number).sim_type, 'bwcapacity' ) ) )
        % calculate the bandwidth constrained capacity of CPFSK
        [sim_param(case_number), sim_state(case_number)] = CalculateMinSNR( sim_param(case_number), sim_state(case_number), code_param );
    elseif ( ( strcmp( sim_param(case_number).sim_type, 'minSNRvsB' ) ) )
        % calculate the throughput
        fprintf( '\n minSNRvsB\n\n' );
        [sim_param(case_number), sim_state(case_number)] = CalculateMinSNRvsB( sim_param(case_number), sim_state(case_number), code_param );
    else
        % Call SingleSimulate for this case
        
        % determine if mat or exe is called
        if ( sim_param(case_number).compiled_mode == 0 )
            % run the matlab version
            sim_state(case_number) = SingleSimulate( sim_param(case_number), sim_state(case_number), code_param );
        else
            % run the compiled exe in stand-alone mode
            save('SimSetup.mat','code_param');
            save_param = sim_param(case_number);
            save_state = sim_state(case_number);
            
            save('SimState.mat','save_param','save_state');
            !SingleSimulate &
        end
    end
end
end

% set simulation parameters to execute scenario tests
%  max_trials = 1
%  snr = [ 0 ]
%  save_state.trials = 0
%  sim_param.testing = 1
function [sim_param, sim_state] = SetTestingParameters(sim_param, sim_state)
[sim_param.max_trials] = deal(1);
[sim_param.SNR] = deal(0);
gmi = max([ sim_param.max_iterations ]); % global max iterations
[sim_state.trials] = deal(zeros(gmi,1));
[sim_param.testing] = deal(1);
end


%     Function CmlSimulate is part of the Iterative Solutions Coded Modulation
%     Library (ISCML).
%
%     The Iterative Solutions Coded Modulation Library is free software;
%     you can redistribute it and/or modify it under the terms of
%     the GNU Lesser General Public License as published by the
%     Free Software Foundation; either version 2.1 of the License,
%     or (at your option) any later version.
%
%     This library is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%     Lesser General Public License for more details.
%
%     You should have received a copy of the GNU Lesser General Public
%     License along with this library; if not, write to the Free Software
%     Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
