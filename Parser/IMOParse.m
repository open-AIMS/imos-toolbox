function sample_data = IMOParse( filename, mode )
%IMOParse Parses a .log data file from an IMO sensor
%
% This function is able to read in a .log data file produced by extracting
% out sensor log from DL3 .text file.
%
%   - processed header  - header information generated by Logger Vue software.
%                         Typically first 5 lines.
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
% Code based on workhorseParse.m, SBE37SMParse.m
%
% Each data record starts with a Port Identifier. These Ports correspond
% to the Port numbering on the bulkhead connectors, with the exception
% of Port 0, which is reserved for the DL3�s additional internal sensor
% suite. Each data record contains the date (DD/MM/YYYY), time
% (HH:MM:SS:mil) and the external sensor�s data record encapsulated
% by �< >� characters.
%
% The DL3 (Port 0) data format is as follows:
% Device Id, Serial Number, Vin Counts, Pressure Counts, Temp Counts, Vin
% (V), Depth (m), Temperature (C)
% example
% Port0: 07/04/2017,08:28:46.000,<IMO-DL3,0028,1023,3238,690,11.5,-0.3,28.4>
%
% IMO-NTU output:
% Sensor Type, Serial Number, Date, Time, dark_counts, measured_counts, NTU, tilt, led_temp, checksum
% Message ID $IMNTU
% Serial # 0012
% Date 21022016 ddmmyyyy
% Time 150327.000 hhmmss.sss
% Dark Counts 2122 Counts ADC Digital Counts (LED off)
% Meas Counts 2260 Counts ADC Digital Counts (LED on)
% NTU 1.796 NTU Calibrated NTU Output
% Tilt 66.3 Degrees ddd.d
% LED Temp 26.8125 Degrees Celsius xx.xxxx
% Checksum *7C
% example
% <$IMNTU,0031,30032017,115136.803,1997,1957,0.149,179.0,29.8125*7D>
%
% IMO-MS8
% NOTE: ONLY engineering/cal output MS8EN (output mode 1/cal), not MS8RW
% Sensor Type, Serial Number, Date, Time, (ch irradiance) x 8, Tilt, Int Temp
% PAR units: mW/cm^2
% example
% <$MS8EN,0026,27/03/2017,14:13:55.000,0.141,0.126,0.310,0.173,-0.019,0.048,0.030,0.063,86.8,27.625>
%
% The checksum field consists of a '*' and two hex digits representing
% an 8 bit exclusive OR of all characters between, but not including,
% the '$' and '*'.
%
% The sensor only .log format will only contain sensor data (without <>)
%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
% Contributor:  Guillaume Galibert <guillaume.galibert@utas.edu.au>

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

% read in every line of header in the file, then big read of data
procHeaderLines = {};
try
    fid = fopen(filename, 'rt');
    line = strtrim(fgetl(fid));
    frewind(fid);
    if strcmpi(line, 'In-situ Marine Optics') || contains(line, {'MS8', 'MS9'})
        % most likely a .TXT format DL3 file
        [procHeader, data, xattrs] = IMO.readIMODL3(fid);
    elseif strcmp(line(1), '$') || contains(line, 'IMO-DL3')
        % most likely a .log format MS8/NTU/PAR file
        [procHeader, data, xattrs] = IMO.readIMOsensor(fid);
    else
        error('Unknown IMO format');
    end
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end

procHeader.toolbox_input_file = filename;

% create sample data struct,
% and copy all the data in
sample_data = struct;
sample_data.toolbox_input_file  = filename;

%%
meta = struct;
meta.featureType    = mode;
meta.procHeader     = procHeader;

meta.instrument_make = 'IMO';
if isfield(procHeader, 'instrument_model')
    meta.instrument_model = procHeader.instrument_model;
else
    meta.instrument_model = 'IMO Unknown';
end

if isfield(procHeader, 'instrument_firmware')
    meta.instrument_firmware = procHeader.instrument_firmware;
else
    meta.instrument_firmware = '';
end

if isfield(procHeader, 'instrument_serial_num')
    meta.instrument_serial_no = procHeader.instrument_serial_num;
elseif isfield(procHeader, 'instrument_serial_number')
    meta.instrument_serial_no = procHeader.instrument_serial_number;
else
    meta.instrument_serial_no = '';
end

time = data.TIME;

if isfield(procHeader, 'instrument_sample_interval')
    meta.instrument_sample_interval = procHeader.instrument_sample_interval;
else
    meta.instrument_sample_interval = median(diff(time*24*3600));
end

if isfield(procHeader, 'instrument_burst_interval')
    meta.instrument_burst_interval = procHeader.instrument_burst_interval;
end

if isfield(procHeader, 'instrument_burst_duration')
    meta.instrument_burst_duration = procHeader.instrument_burst_duration;
end

if isfield(procHeader, 'instrument_burst_samples')
    meta.instrument_burst_samples = procHeader.instrument_burst_samples;
end

% While some basic metadata has been extracted not sure what is required
% for later procesing so copy all calibration_X or configuration_X entries
header_keys = fieldnames(procHeader);
ind = find(~cellfun(@isempty, regexp(header_keys, '^calibration_|^configuration_', 'match')));
for k = 1:numel(ind)
   meta_name = char(header_keys{ind(k)});
   meta.(meta_name) = procHeader.(meta_name);
end

%%
[multispec_vars, ts_vars, isMultispec] = IMO.import_mappings(procHeader, data);

if isMultispec
    dimensions = IMOS.gen_dimensions('timeSeries', 2, {'TIME', 'WAVELENGTHS'}, {@double, @single }, {time, []});
    idx = getVar(dimensions, 'TIME');
    if isfield(meta, 'instrument_average_interval')
        dimensions{idx}.comment = ['Time stamp corresponds to the start of the measurement which lasts ' num2str(meta.instrument_average_interval) ' seconds.'];
    elseif isfield(meta, 'instrument_burst_samples')
        dimensions{idx}.comment = ['Time stamp corresponds to the start of the measurement which lasts ' num2str(meta.instrument_burst_samples) ' samples.'];
    end
    
    idx = getVar(dimensions, 'WAVELENGTHS');
    dimensions{idx}.data = dimensions{idx}.typeCastFunc(data.WAVELENGTHS);
    dimensions{idx}.units = 'nm';
    dimensions{idx}.comment = 'Wavelengths nm.';
else
    dimensions = IMOS.gen_dimensions('timeSeries', 1, {'TIME'}, {@double}, {time});
    idx = getVar(dimensions, 'TIME');
    if isfield(meta, 'instrument_average_interval') && ~isempty(meta.instrument_average_interval)
        dimensions{idx}.comment = ['Time stamp corresponds to the start of the measurement which lasts ' num2str(meta.instrument_average_interval) ' seconds.'];
    end
end

% define toolbox struct.
vars0d = IMOS.featuretype_variables('timeSeries'); %basic vars from timeSeries

coords1d = 'TIME LATITUDE LONGITUDE NOMINAL_DEPTH';
vars1d = IMOS.gen_variables(dimensions,ts_vars,{},fields2cell(data,ts_vars),'coordinates',coords1d);

if isMultispec
    coords2d_multispec = 'TIME LATITUDE LONGITUDE NOMINAL_DEPTH WAVELENGTHS';
    vars2d_multispec = IMOS.gen_variables(dimensions,multispec_vars,{},fields2cell(data,multispec_vars),'coordinates',coords2d_multispec);
end

sample_data.meta = meta;
sample_data.dimensions = dimensions;
if isMultispec
    sample_data.variables = [vars0d, vars1d, vars2d_multispec];
else
    sample_data.variables = [vars0d, vars1d];
end

indexes = IMOS.find(sample_data.variables,xattrs.keys);
for vind = indexes
    iname = sample_data.variables{vind}.name;
    sample_data.variables{vind} = combineStructFields(sample_data.variables{vind},xattrs(iname));
end

end


