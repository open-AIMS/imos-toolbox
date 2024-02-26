function deviceInfo = readMetadata( cal_filename, inf_filename )
%readMetadata parses a processing metadata file created for
% Aanderaa
%
% Inputs:
%   cal_filename    - calibration file to be parsed
%   inf_filename    - info file to be parsed
%   instrument_model - user set instrument model or ''
%
% Outputs:
%   deviceInfo  - struct containing fields
%       'serial_number'
%       'instrument_model' : text string, eg WLR7
%       'start_time': time of first sample in
%       	'yyyy/mm/ddTHH:MM' or 'yyyymmddTHHMM' format
%       'sample_interval': in seconds
%       'coeff' : coefficients, matrix
%       'is_new_style_cal_file': is calibration file new type
%       'cal_serial_number': calibration file serial number
%       'cal_start_date': start date of calibration
%       'cal_end_date': end date of calibration, old style
%       'jflag': should be 2 for WLR with a TEMP sensor?, old style
%       'nzero': ?, oldstyle
%

%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%

%
% Copyright (C) 2024, Australian Ocean Data Network (AODN) and Integrated
% Marine Observing System (IMOS).
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation version 3 of the License.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.
% If not, see <https://www.gnu.org/licenses/gpl-3.0.en.html>.
%

% ensure that there is at least two arguments
narginchk(2, 3);
if ~ischar(cal_filename), error('Calibration filename must be a string'); end
if ~ischar(inf_filename), error('Information filename must be a string'); end

deviceInfo = struct;

deviceInfo = Aanderaa.parse_inf_file( deviceInfo, inf_filename );

deviceInfo = Aanderaa.parse_cal_file( deviceInfo, cal_filename );

end