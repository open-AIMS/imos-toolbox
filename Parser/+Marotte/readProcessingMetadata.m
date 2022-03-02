function deviceInfo = readProcessingMetadata( filename )
%READECODEVICE parses a processing metadata file created from
% MarotteHSConfig
%
% Inputs:
%   filename    - name of the input file to be parsed
%
% Outputs:
%   deviceInfo  - struct containing fields 'smoothing_window', 'decimate',
%               'magnetic_offset_compensation',
%               'zero_point_drift_compensation',
%               'serial', 'first_sample_time', 'last_sample_time'
%               'zero_point', 'acc_cal', 'mag_cal'
%

%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%
% Code based on readECODevice.m
%

%
% An example processing metadata file looks like
%
% *** Overview ***
% Date of processing,2019-03-08 16:38:09
% Number of instruments,1
%
% *** Options ***
% Smoothing window (seconds),60
% Decimate,yes
% Magnetic offset compensation,no
% Zero point drift compensation,no
% Processing Start,2018-09-13 20:26:54
% Processing End,2019-02-25 20:06:14
%
% *** Instrument B1351 ***
% Name,Marotte HS
% First Sample,2018-09-13 20:26:54
% Last Sample,2019-02-25 20:06:14
% Samples,14254758
% --- Calibration ---
% Zero Point,-16.0,-4098.0,-116.0
% Acc Cal,4031.0,4089.0,4067.0,-23.0,20.0,-36.0
% Mag Cal,413.0,436.0,409.0,-158.0,-133.0,1092.0
%

%
% Copyright (C) 2021, Australian Ocean Data Network (AODN) and Integrated
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

% ensure that there is exactly one argument
narginchk(1, 1);
if ~ischar(filename), error('filename must contain a string'); end

deviceInfo = struct;

% open file, get everything from it as lines
fid     = -1;
lines = {};
try
    fid = fopen(filename, 'rt');
    if fid == -1, error(['couldn''t open ' filename 'for reading']); end
    
    % read in the data
    lines = textscan(fid, '%s', 'Whitespace', '\r\n');
    lines = lines{1};
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end

%%
pat = '*** Overview ***';
ind = find(contains(lines, pat));
if isempty(ind)
    error('Processing metadata does not contain overview section.');
end

pat = 'Number of instruments,(\d+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
num_instruments = str2num(tkns{ind}{1}{1});

if  num_instruments ~= 1
    error('More than one instrument listed in processing metadata file.')
end

%%
pat = '*** Options ***';
ind = find(contains(lines, pat));
if isempty(ind)
    error('Processing metadata does not contain options section.');
end

pat = 'Smoothing window \(seconds\),(\d+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    deviceInfo.smoothing_window = str2num(tkns{ind}{1}{1});
end

pat = 'Decimate,(\w+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    deviceInfo.decimate = strtrim(tkns{ind}{1}{1});
end

pat = 'Magnetic offset compensation,(\w+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    deviceInfo.magnetic_offset_compensation = strtrim(tkns{ind}{1}{1});
end

pat = 'Zero point drift compensation,(\w+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    deviceInfo.zero_point_drift_compensation = strtrim(tkns{ind}{1}{1});
end

%%
pat = '*** Instrument (\w+) ***';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if isempty(ind)
    error('Processing metadata does not contain instrument section.');
end
deviceInfo.instrument_serial_number = strtrim(tkns{ind}{1}{1});
deviceInfo.instrument_make = 'JCU';
deviceInfo.instrument_model = 'Marotte';

pat = 'Name,(.+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
deviceInfo.name = strtrim(tkns{ind}{1}{1});

% First Sample,2018-09-13 20:26:54
pat = 'First Sample,([\w\-\:\s]+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
deviceInfo.first_sample = datenum(tkns{ind}{1}{1}, 'yyyy-mm-dd HH:MM:SS');

pat = 'Last Sample,([\w\-\:\s]+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
deviceInfo.last_sample = datenum(tkns{ind}{1}{1}, 'yyyy-mm-dd HH:MM:SS');

% this is the number of samples in the raw .TXT file
%Samples,14254758
pat = 'Samples,(\d+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    deviceInfo.number_raw_samples = str2num(tkns{ind}{1}{1});
end

%%
pat = '--- Calibration ---';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if isempty(ind)
    error('Processing metadata does not contain calibration section.');
end

%Zero Point,-16.0,-4098.0,-116.0
pat = 'Zero Point,(.+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    deviceInfo.zero_point = strtrim(tkns{ind}{1}{1});
end

%Acc Cal,4031.0,4089.0,4067.0,-23.0,20.0,-36.0
pat = 'Acc Cal,(.+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    deviceInfo.acc_cal = strtrim(tkns{ind}{1}{1});
end

%Mag Cal,413.0,436.0,409.0,-158.0,-133.0,1092.0
pat = 'Mag Cal,(.+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    deviceInfo.mag_cal = strtrim(tkns{ind}{1}{1});
end

end