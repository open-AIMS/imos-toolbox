function sample_data = construct_sample_data_wts( header, data, xattrs, mode )
%construct_sample_data_wts create sample_data struct from wts wave data
%
% Inputs:
%   filename    - name of the input file to be parsed
%
% Outputs:
%   sample_data - imos instrument sample_data struct

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


% create sample data struct,
% and copy all the data in
sample_data = struct;
sample_data.toolbox_input_file  = header.wts_filename;

%%
meta = struct;
meta.featureType    = mode;
meta.procHeader     = header;

meta.instrument_make = 'Seabird';
if isfield(header, 'instrument_model')
    meta.instrument_model = header.instrument_model;
else
    meta.instrument_model = 'Seabird Unknown';
end

if isfield(header, 'instrument_firmware')
    meta.instrument_firmware = header.instrument_firmware;
else
    meta.instrument_firmware = '';
end

if isfield(header, 'instrument_serial_no')
    meta.instrument_serial_no = header.instrument_serial_no;
elseif isfield(header, 'instrument_serial_number')
    meta.instrument_serial_no = header.instrument_serial_number;
else
    meta.instrument_serial_no = '';
end

time = data.TIME;

% if isfield(header, 'instrument_sample_interval')
%     meta.instrument_sample_interval = header.instrument_sample_interval;
% else
    meta.instrument_sample_interval = mean(diff(time*24*3600));
% end

if isfield(header, 'instrument_burst_duration')
    meta.instrument_burst_duration = header.wave_burst_duration;
end

meta.wave_samples_per_burst = header.wave_samples_per_burst;
meta.wave_sampling_frequency = header.wave_sampling_frequency;
% are these equivalent???
meta.instrument_burst_samples = header.wave_samples_per_burst;
 
% if isfield(deviceInfo, 'instrument_burst_interval')
%     meta.instrument_burst_interval = deviceInfo.instrument_burst_interval;
% end
% 
% if isfield(deviceInfo, 'instrument_burst_duration')
%     meta.instrument_burst_duration = deviceInfo.instrument_burst_duration;
% end
% 
% if isfield(deviceInfo, 'instrument_burst_samples')
%     meta.instrument_burst_samples = deviceInfo.instrument_burst_samples;
% end

% % While some basic metadata has been extracted not sure what is required
% % for later procesing so copy all calibration_X or configuration_X entries
% header_keys = fieldnames(header);
% ind = find(~cellfun(@isempty, regexp(header_keys, '^calibration_|^configuration_', 'match')));
% for k = 1:numel(ind)
%    meta_name = char(header_keys{ind(k)});
%    meta.(meta_name) = header.(meta_name);
% end

%%
% vNames = fieldnames(data);
% exclude_var_names = {'TIME', 'meta'};
% idx = ~ismember(vNames, exclude_var_names);
% vNames = vNames(idx);
% ts_vars = vNames;

% TODO : determine if this is the all the variables that should be copied
ts_vars = {'WMSH', 'WPSM', 'WMXH', 'WHTH', 'WPTH', 'WHTE'};

dimensions = IMOS.gen_dimensions('timeSeries', 1, {'TIME'}, {@double}, time);
idx = getVar(dimensions, 'TIME');
dimensions{idx}.data = time;

% define toolbox struct.
vars0d = IMOS.featuretype_variables('timeSeries'); %basic vars from timeSeries

coords1d = 'TIME LATITUDE LONGITUDE NOMINAL_DEPTH';
vars1d = IMOS.gen_variables(dimensions, ts_vars,{}, fields2cell(data, ts_vars), 'coordinates', coords1d);

sample_data.meta = meta;
sample_data.dimensions = dimensions;
sample_data.variables = [vars0d, vars1d];

% add dimension xattrs
indexes = IMOS.find(sample_data.dimensions, xattrs.keys);
for dind = indexes
    iname = sample_data.dimensions{dind}.name;
    sample_data.dimensions{dind} = combineStructFields(sample_data.dimensions{dind}, xattrs(iname));
end

% add variable xattrs
indexes = IMOS.find(sample_data.variables, xattrs.keys);
for vind = indexes
    iname = sample_data.variables{vind}.name;
    sample_data.variables{vind} = combineStructFields(sample_data.variables{vind}, xattrs(iname));
end

end