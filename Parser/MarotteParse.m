function sample_data = MarotteParse( filename, mode )
%MarotteParse Parses a .csv data file created from MarotteHSConfig export
%of instrument file. Requires "verbose output" and rename
%processing_metadata.txt to same radical of the input csv filename, with a 
%.dev extension and to contain only one instruments worth of metadata.
%
% This function is able to read in a .csv data file produced by conversion
% of raw .TXT file.
%
%   - processed header  - header information generated by MarotteHSConfig software.
%                         Typically first ? lines. Limited information.
%   - data              - Rows of comma seperated data.
%
% This function reads in the header sections, and delegates to the two file
% specific sub functions to process the data.
%
% Inputs:
%   filename    - cell array of files to import (only one supported).
%   mode        - Toolbox data type mode.
%
% Outputs:
%   sample_data - Struct containing sample data.
%
% Code based on ECOTripletParse.m
%
% Each data record starts with a header line. As far as I can tell the
% column names seem to be stable over time.
% datetime : YYYY-MM-DD hh:mm:ss.fff
%
% datetime,speed (m/s),heading (degrees CW from North),speed upper (m/s),speed lower (m/s),tilt (radians),direction (radians CCW from East),batt (volts),temp (Celsius)
% 2021-01-25 13:20:00.000,1.1977,114.5,1.2577,1.1377,1.7419,-0.4284,3.151,27.29
% 2021-01-25 13:30:00.000,1.1977,117.8,1.2577,1.1377,1.7747,-0.4853,3.158,27.47
% 2021-01-25 13:40:00.000,1.1977,130.0,1.2577,1.1377,1.8106,-0.6978,3.161,27.84
% 2021-01-25 13:50:00.000,1.1977,178.4,1.2577,1.1377,1.5059,-1.5434,3.151,28.02
%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%

%
% Copyright (c) 2017, Australian Ocean Data Network (AODN) and Integrated
% Marine Observing System (IMOS).
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
%     * Redistributions of source code must retain the above copyright notice,
%       this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in the
%       documentation and/or other materials provided with the distribution.
%     * Neither the name of the AODN/IMOS nor the names of its contributors
%       may be used to endorse or promote products derived from this software
%       without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
%
narginchk(1,2);

if ~iscellstr(filename)
    error('filename must be a cell array of strings');
end

% only one file supported currently
filename = filename{1};
metadata_filename = strrep(filename, '.csv', '.dev');

sample_data = [];

if ~exist(metadata_filename, 'file'), error('processing metadata file must have the same name as the data file with .csv'); end

% this would be much easier if MarotteHSConfig conversion added instrument
% data as header to csv file
deviceInfo = Marotte.readProcessingMetadata(metadata_filename);

[header, data, xattrs] = Marotte.readCSV(filename, deviceInfo);
  
deviceInfo.toolbox_input_file = filename;

% create sample data struct,
% and copy all the data in
sample_data = struct;
sample_data.toolbox_input_file  = filename;

%%
meta = struct;
meta.featureType    = mode;
meta.procHeader     = deviceInfo;

meta.instrument_make = 'JCU';
if isfield(deviceInfo, 'instrument_model')
    meta.instrument_model = deviceInfo.instrument_model;
else
    meta.instrument_model = 'JCU Unknown';
end

if isfield(deviceInfo, 'instrument_firmware')
    meta.instrument_firmware = deviceInfo.instrument_firmware;
else
    meta.instrument_firmware = '';
end

if isfield(deviceInfo, 'instrument_serial_no')
    meta.instrument_serial_no = deviceInfo.instrument_serial_no;
elseif isfield(deviceInfo, 'instrument_serial_number')
    meta.instrument_serial_no = deviceInfo.instrument_serial_number;
else
    meta.instrument_serial_no = '';
end

time = data.TIME;

if isfield(deviceInfo, 'instrument_sample_interval')
    meta.instrument_sample_interval = deviceInfo.instrument_sample_interval;
else
    meta.instrument_sample_interval = mean(diff(time*24*3600));
end

if isfield(deviceInfo, 'instrument_burst_interval')
    meta.instrument_burst_interval = deviceInfo.instrument_burst_interval;
end

if isfield(deviceInfo, 'instrument_burst_duration')
    meta.instrument_burst_duration = deviceInfo.instrument_burst_duration;
end

if isfield(deviceInfo, 'instrument_burst_samples')
    meta.instrument_burst_samples = deviceInfo.instrument_burst_samples;
end

% While some basic metadata has been extracted not sure what is required
% for later procesing so copy all calibration_X or configuration_X entries
header_keys = fieldnames(deviceInfo);
ind = find(~cellfun(@isempty, regexp(header_keys, '^calibration_|^configuration_', 'match')));
for k = 1:numel(ind)
   meta_name = char(header_keys{ind(k)});
   meta.(meta_name) = deviceInfo.(meta_name);
end

%%
vNames = fieldnames(data);
exclude_var_names = 'TIME';
idx = ~ismember(vNames, exclude_var_names);
vNames = vNames(idx);
ts_vars = vNames;

dimensions = IMOS.gen_dimensions('timeSeries', 1, {'TIME'}, {@double}, time);
idx = getVar(dimensions, 'TIME');
dimensions{idx}.data = time;
% not sure if what smoothing window does
%dimensions{idx}.comment = ['Time stamp corresponds to the start of the measurement which lasts ' num2str(meta.instrument_average_interval) ' seconds.'];

% define toolbox struct.
vars0d = IMOS.featuretype_variables('timeSeries'); %basic vars from timeSeries

coords1d = 'TIME LATITUDE LONGITUDE NOMINAL_DEPTH';
vars1d = IMOS.gen_variables(dimensions,ts_vars,{},fields2cell(data,ts_vars),'coordinates',coords1d);

sample_data.meta = meta;
sample_data.dimensions = dimensions;
sample_data.variables = [vars0d, vars1d];

indexes = IMOS.find(sample_data.variables,xattrs.keys);
for vind = indexes
    iname = sample_data.variables{vind}.name;
    sample_data.variables{vind} = combineStructFields(sample_data.variables{vind},xattrs(iname));
end

end



