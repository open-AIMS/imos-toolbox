function sample_data = SBE26hexParse( filename, mode )
%SBE26HEXPARSE Parses the header of .hex file from SBE26plus and if 
% available SeasoftWaves processed .tid and .was, .wts
%
% This function is able to read in a .tid data file retrieved
% from a Seabird SBE26/SBE26plus Temperature and Pressure Logger. It is 
% assumed the file consists in the following columns:
%
%   - measurement number
%   - date and time (mm/dd/yyyy HH:MM:SS) of beginning of measurement
%   - pressure in psia
%   - temperature in degrees Celsius
%
% Inputs:
%   filename    - cell array of files to import (only one supported).
%   mode        - Toolbox data type mode.
%
% Outputs:
%   sample_data - Struct containing sample data.
%
% Author:       Guillaume Galibert <guillaume.galibert@utas.edu.au>
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

% You should have received a copy of the GNU General Public License
% along with this program.
% If not, see <https://www.gnu.org/licenses/gpl-3.0.en.html>.
%
narginchk(1,2);

if ~iscellstr(filename)
    error('filename must be a cell array of strings');
end

% only one file supported currently
hex_filename = filename{1};

is_hex_file = endsWith(filename, '.hex');
if ~is_hex_file
   error('SBE26hexParse requires hex filename.');
end

if exist(hex_filename, 'file')
    header = SBE.parse_sbe26_hex_header(hex_filename);
else
    error('SBE26hexParse : hex filename does not exist.');
end

% tide guage data file
tid_filename = regexprep(hex_filename, '\.hex$', '.tid', 'ignorecase');
has_tid_file = exist(tid_filename, 'file');

% wts file has the most useful statistics so handle that first. Don't know
% if other contains any usefull info that an end user would want?
wts_filename = regexprep(hex_filename, '\.hex$', '.wts', 'ignorecase');
has_wts_file = exist(wts_filename, 'file');

% if wave data was collected, set of related files
% was_filename = regexprep(filename, '\.hex$', '.was', 'ignorecase');
% has_was_file = exist(was_filename, 'file');

% rpt_filename = regexprep(filename, '\.hex$', '.rpt', 'ignorecase');
% has_rpt_file = exist(rpt_filename, 'file');

[data, xattrs] = SBE.read_tid_file( header, tid_filename );
header.tid_filename = tid_filename;

sample_data = SBE.construct_sample_data_tid( header, data, xattrs, mode );

% TODO handle wts
% test both existence of wts file and that the hex file stated that waves 
% where collected (maybe overkill)
if has_wts_file && header.has_waves
    if isstruct(sample_data)
        tmp = sample_data;
        sample_data = {};
        sample_data{end+1} = tmp;
        clear('tmp');
    end
    [data, xattrs] = SBE.read_wts_file( header, wts_filename );
    header.wts_filename = wts_filename;
    sample_data{end+1} = SBE.construct_sample_data_wts( header, data, xattrs, mode );
end


end