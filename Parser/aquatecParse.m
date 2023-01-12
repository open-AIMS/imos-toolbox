function sample_data = aquatecParse( filename, mode )
%AQUATECPARSE Parses a raw data file retrieved from an Aquatec AQUAlogger.
%
% Parses a raw data file retrieved from an Aquatec AQUAlogger 520. The
% AQUAlogger 520 range of sensors provide logging capability for temperature
% and pressure.
% (http://www.aquatecgroup.com)
%
% The following variants on the AQUAlogger 520 exist:
%   - 520T:  temperature
%   - 520P:  pressure
%   - 520PT: pressure and temperature
%
% The raw data file format for all loggers is identical; every line in a
% file, including sample data, is a key-value pair, separated by a comma.
% The following lines are examples:
%
% VERSION,3.0
% LOGGER TYPE,520PT Pressure & Temperature
% LOGGER,23-502,SYD100 T2
% DATA,23:00:01 24/06/2008,29412,16.310779,26345,1.025358,
% DATA,23:00:02 24/06/2008,29411,16.312112,26346,1.025938,
%
% If the logger was configured to use burst mode, the bursts are averaged.
%
% Inputs:
%   filename    - cell array of filename names (Only supports one currently).
%   mode        - Toolbox data type mode.
%
% Outputs:
%   sample_data - struct containing sample data.
%
% Author: 		Paul McCarthy <paul.mccarthy@csiro.au>
% Contributor: 	Brad Morris <b.morris@unsw.edu.au>
%				Guillaume Galibert <guillaume.galibert@utas.edu.au>
%

%
% Copyright (C) 2017, Australian Ocean Data Network (AODN) and Integrated
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

if ~iscellstr(filename), error('filename must be a cell array of strings'); end

sample_data            = struct;
sample_data.meta       = struct;
sample_data.dimensions = {};
sample_data.variables  = {};

%
% read in the filename
%

% read in the header information into 'keys' and
% 'meta', and the rest of the filename into 'data'
fid = -1;
keys = {};
meta = {};
try
    filename = filename{1};
    fid = fopen(filename, 'rt');
    
    % note the use of fgets - the newline is kept, so we can reconstruct
    % the first data line read after all the metadata has been read in
    line = fgets(fid);
    while ischar(line) ...
            && ~strncmp(line, 'DATA', 4) ...
            && ~strncmp(line, 'BURSTSTART', 10)
        
        line = textscan(line, '%s%[^\n]', 'Delimiter', ',');
        keys{end+1} = deblank(line{1});
        meta{end+1} = deblank(line{2});
        
        line = fgets(fid);
    end
    
    % we reached end of filename before any
    % DATA or BURSTSTART lines were read
    if ~ischar(line), error(['no data in ' filename]); end
    
    % read the rest of the filename into 'data'
    % - we've already got the first line
    rawdata = char(fread(fid, inf, 'char')');
    rawdata = [line rawdata];
    
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end

%
% get basic metadata
%

model    = getValues({'LOGGER TYPE'},keys, meta);
model    = strtrim(strrep(model, 'Pressure & Temperature', ''));
model    = strtrim(strrep(model, 'Pressure', ''));
model    = strtrim(strrep(model, 'Temperature', ''));
firmware = getValues({'VERSION'},    keys, meta);
serial   = getValues({'LOGGER'},     keys, meta);
serial   = textscan(serial{1}, '%s', 1, 'Delimiter', ',');

sample_data.toolbox_input_file        = filename;
sample_data.meta.instrument_make      = 'Aquatec';
sample_data.meta.instrument_model     = ['Aqualogger ' model{1}];
sample_data.meta.instrument_firmware  = firmware{1};
sample_data.meta.instrument_serial_no = serial{1}{1};
sample_data.meta.featureType          = mode;
%
% get regime data (mode, sample rate, etc)
%

regime = getValues({'REGIME'}, keys, meta);
regime = textscan(regime{1}, '%s', 'Delimiter', ',');
regime = deblank( regime{1});

%
% figure out what data (temperature, pressure) is in the filename
%
heading = getValues({'HEADING'}, keys, meta);
heading = textscan(heading{1}, '%s', 'Delimiter', ',');
heading = deblank (heading{1});
units = getValues({'UNITS'}, keys, meta);
units = strtrim(strsplit(units{1}, ','));

numFields = length(heading);
% indices to raw data, engineering data is raw column + 1
timeIdx   = find(ismember(heading, 'Timecode'));
tempIdx   = find(ismember(heading, 'Ext temperature'));
presIdx   = find(ismember(heading, 'Pressure'));
batteryIdx = find(ismember(heading, 'Battery voltage'));
depthIdx = find(ismember(heading, 'Depth'));

% try to determine timecode format string based on two (currently) known 
% csv versions
isV3csv = str2num(sample_data.meta.instrument_firmware) <= 3;
isV4csv = str2num(sample_data.meta.instrument_firmware) == 4;

if isV3csv
    % attempt to guess datetime format, based on wiki example and one
    % example from Aquatec
    
    startTime = char(getValues({'START TIME'}, keys, meta));
    % simple test if system date format chosen with AM/PM string, fail early
    if contains(startTime, 'AM') || contains(startTime, 'PM')
        error('Version 3 CSV : Unknown datetime format. Please reexport bin file with dd/mm/yyyy HH:MM:SS date format.');
    end
    
    format = '%f%f%f%f%f%f';
    delims = {':', '/'};
    timedata = textscan(startTime, format, 'Delimiter', delims);
    % if old format as documented on IMOS wiki '23:00:01 24/06/2008'
    % but really have no idea of actual format as version 3 csv timecode
    % isn't documented.
    if timedata{6} > 61
        datetimeFormat = 'HH:MM:SS dd/mm/yyyy';
        timecodeYearIdx   = 6;
        timecodeMonthIdx   = 5;
        timecodeDayIdx    = 4;
        timecodeSecondIdx = 3;
        timecodeMinuteIdx = 2;
        timecodeHourIdx   = 1;
    elseif timedata{3} > 61
        datetimeFormat = 'dd/mm/yyyy HH:MM:SS';
        timecodeYearIdx   = 3;
        timecodeMonthIdx  = 2;
        timecodeDayIdx    = 1;
        timecodeSecondIdx = 6;
        timecodeMinuteIdx = 5;
        timecodeHourIdx   = 4;
    else
        error('Version 3 CSV : Unknown datetime format. Please reexport bin file with dd/mm/yyyy HH:MM:SS date format.');
    end
    
elseif isV4csv
    % ideally the user has unselected "Use system date format" and choosen
    % one of two options, but if user has used system date format highly
    % likely this will fail
    
    timecodeString = strsplit(units{1},',');
    timecodeString = timecodeString{1};
    % simple test if system date format chosen with AM/PM, fail early
    if contains(timecodeString, 'AM') || contains(timecodeString, 'PM')
        error('Version 4 CSV : Unknown datetime format. Please reexport bin file with dd/mm/yyyy HH:MM:SS or mm/dd/yyyy HH:MM:SS date format.');
    end
    
    if contains(timecodeString, 'dd/MM/yyy')
        datetimeFormat = 'dd/mm/yyyy HH:MM:SS';
        timecodeYearIdx   = 3;
        timecodeMonthIdx  = 2;
        timecodeDayIdx    = 1;
        timecodeSecondIdx = 6;
        timecodeMinuteIdx = 5;
        timecodeHourIdx   = 4;
    elseif contains(timecodeString, 'MM/dd/yyy')
        datetimeFormat = 'mm/dd/yyyy HH:MM:SS';
        timecodeYearIdx   = 3;
        timecodeMonthIdx  = 1;
        timecodeDayIdx    = 2;
        timecodeSecondIdx = 6;
        timecodeMinuteIdx = 5;
        timecodeHourIdx   = 4;
    else
        error('Version 4 CSV : Unknown datetime format. Please reexport bin file with dd/mm/yyyy HH:MM:SS or mm/dd/yyyy HH:MM:SS date format.');
    end
else
    error('Unknown CSV version.');
end

% if continuous mode was used, we need to save the start and stop
% times so we can interpolate sample times and sample interval
startTime = getValues({'START TIME'}, keys, meta);
startTime = datenum(startTime{1}, datetimeFormat);

stopTime = getValues({'STOP TIME'}, keys, meta);
stopTime = datenum(stopTime{1}, datetimeFormat);

% turn sample interval into serial date units
sampleInterval  = textscan(regime{2}, '%f%s');
if strncmp(sampleInterval{2}, 'minute', 6)
    sampleInterval = sampleInterval{1}/3600;
else
    sampleInterval = sampleInterval{1}/86400;
end

sample_data.meta.instrument_sample_interval = 24*3600*sampleInterval;

% figure out if burst or continuous mode is used - if burst
% mode is used, we need to average the samples in each burst
isBurst         = regime{1};
samplesPerBurst = 1;

% if the logger was using burst mode, we need to save the number
% of samples per burst so we know how many to average over
if strcmp(isBurst, 'Burst Mode')
    isBurst         = true;
    samplesPerBurst = str2double(regime{3});
else
    isBurst = false;
end

% If the data is internally averaged during the burst sampling then there
% is only one data point stored. Need to take this into account and not
% average again here. BDM (08/03/2010)
isAveraged=getValues({'AVERAGED'},keys,meta);
if strcmp(isAveraged{1},'Yes')
    isAveraged=true;
else
    isAveraged=false;
end

% construct a format string
format = cell([1,numFields+1]);
format(:) = {'%f'};
format{1} = '%*s'; % 'DATA' string
if ~isempty(timeIdx)
    format{timeIdx+1} = '%s';
end
format = [format{:}];
delims = ',';

rawdata = textscan(rawdata, format, 'Delimiter', delims);

data = struct;
% if the filename contains timestamps, use them
if ~isempty(timeIdx)
    format = '%f%f%f%f%f%f';
    delims = {':' '/'};
    timedata = textscan(strjoin(rawdata{timeIdx},'\n'), format, 'Delimiter', delims);
    
    iBadTimeStamp = (timedata{timecodeYearIdx} == 0) | ...
        ((timedata{timecodeMonthIdx} < 1) | (timedata{timecodeMonthIdx} > 12)) | ...
        (timedata{timecodeDayIdx} == 0 );
    if any(iBadTimeStamp)
        disp(['Info : ' num2str(sum(iBadTimeStamp)) ' bad TIME values (and their corresponding measurements) had to be discarded in ' filename '.']);
        for i=1:length(rawdata)
            rawdata{i}(iBadTimeStamp) = [];
        end
    end
    data.TIME = datenum(timedata{timecodeYearIdx}, timedata{timecodeMonthIdx}, timedata{timecodeDayIdx}, timedata{timecodeHourIdx}, timedata{timecodeMinuteIdx}, timedata{timecodeSecondIdx});
else
    % otherwise generate timestamps from
    % the start time and sample interval
    data.TIME = startTime:sampleInterval:stopTime;
end

% get temperature if present
if ~isempty(tempIdx)
    temp = rawdata{tempIdx+1};
    
    % handle degC, degF, degK
    tempUnits = matlab.lang.makeValidName(units{tempIdx+1});
    if strcmp(tempUnits, 'x_C')
        data.TEMP = temp;
    elseif strcmp(tempUnits, 'x_F')
        data.TEMP = toCelsius(temp, 'fahrenheit');
    elseif strcmp(tempUnits, 'x_K')
        data.TEMP = toCelsius(temp, 'kelvin');
    else
        error(['Unknown temperature units : ' tempUnits]);
    end
end

% get pressure if present
if ~isempty(presIdx)
    % Aqualogger measures absolute pressure (seawater + atmospheric)
    pres = rawdata{presIdx+1};
    
    % we set the 65535 values to NaN
    iNaN = pres >= 65535;
    pres(iNaN) = NaN;
    
    presUnits = strtrim(units{presIdx+1});
    % handle bar,dbar,mbar,psi,Pa,kPa -> dbar
    if strcmp(presUnits, 'bar')
        presConv = 10.0;
    elseif strcmp(presUnits, 'dbar')
        presConv = 1.0;
    elseif strcmp(presUnits, 'mbar')
        presConv = 0.01;
    elseif strcmp(presUnits, 'psi') % 1 psi = 0.68948 dBar
        presConv = 0.68948;
    elseif strcmp(presUnits, 'kPa')
        presConv = 0.01;
    elseif strcmp(presUnits, 'Pa')
        presConv = 0.0001;
    else
        error(['Unknown pressure units : ' presUnits]);
    end
    data.PRES = pres*presConv;
end

% get battery voltage if present
if ~isempty(batteryIdx)
    data.BAT_VOLT = rawdata{batteryIdx+1};
end

%
% if burst mode, we need to average the bursts
%
if isBurst
    % Only average bursts if not already internally averaged
    % (BDM - 08/03/2010)
    if ~isAveraged
        numBursts = length(data.TIME) / samplesPerBurst;
        newdata = struct;
        vNames = fieldnames(data);
        for i = 1:length(vNames)
            v = char(vNames{i});
            newdata.(v) = NaN([numBursts, 1]);
        end
        
        vNames = setdiff(fieldnames(data), 'TIME');
        vNames = {vNames{:}};
        for k = 1:numBursts
            % get indices for the current burst
            burstIdx = 1 + (k-1)*samplesPerBurst;
            burstIdx = burstIdx:(burstIdx+samplesPerBurst-1);
            
            % time is the mean of the burst timestamps
            newdata.TIME(k) = mean(data.TIME(burstIdx));
            
            % temp/pres etc are means of the burst samples
            for vName = vNames
                v = char(vName);
                newdata.(v)(k) = mean(data.(v)(burstIdx));
            end
        end
        
        data = newdata;
    end
end

if isnan(sample_data.meta.instrument_sample_interval) || sample_data.meta.instrument_sample_interval <= 0
    sample_data.meta.instrument_sample_interval = median(diff(TIME*24*3600));
end

%
% set up the sample_data structure
%
% dimensions definition must stay in this order : T, Z, Y, X, others;
% to be CF compliant
sample_data.dimensions{1}.name          = 'TIME';
sample_data.dimensions{1}.typeCastFunc  = str2func(netcdf3ToMatlabType(imosParameters(sample_data.dimensions{1}.name, 'type')));
sample_data.dimensions{1}.data          = sample_data.dimensions{1}.typeCastFunc(data.TIME);

sample_data.variables{end+1}.name         = 'TIMESERIES';
sample_data.variables{end}.typeCastFunc   = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
sample_data.variables{end}.data           = sample_data.variables{end}.typeCastFunc(1);
sample_data.variables{end}.dimensions     = [];
sample_data.variables{end+1}.name         = 'LATITUDE';
sample_data.variables{end}.typeCastFunc   = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
sample_data.variables{end}.data           = sample_data.variables{end}.typeCastFunc(NaN);
sample_data.variables{end}.dimensions     = [];
sample_data.variables{end+1}.name         = 'LONGITUDE';
sample_data.variables{end}.typeCastFunc   = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
sample_data.variables{end}.data           = sample_data.variables{end}.typeCastFunc(NaN);
sample_data.variables{end}.dimensions     = [];
sample_data.variables{end+1}.name         = 'NOMINAL_DEPTH';
sample_data.variables{end}.typeCastFunc   = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
sample_data.variables{end}.dimensions     = [];
sample_data.variables{end}.data           = sample_data.variables{end}.typeCastFunc(NaN);

% we have already generated time for missing timeIdx case, why test now?
%if isempty(timeIdx), error('time column is missing'); end

coordinates = 'TIME LATITUDE LONGITUDE NOMINAL_DEPTH';

% add a temperature variable if present
if ~isempty(tempIdx) && any(~isnan(data.TEMP))
    sample_data.variables{end+1}.name       = 'TEMP';
    sample_data.variables{end}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
    sample_data.variables{end}.dimensions   = 1;
    sample_data.variables{end}.data         = sample_data.variables{end}.typeCastFunc(data.TEMP);
    sample_data.variables{end}.coordinates  = coordinates;
end

% add a pressure variable if present
if ~isempty(presIdx) && any(~isnan(data.PRES))
    sample_data.variables{end+1}.name       = 'PRES';
    sample_data.variables{end}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
    sample_data.variables{end}.dimensions   = 1;
    sample_data.variables{end}.data         = sample_data.variables{end}.typeCastFunc(data.PRES);
    sample_data.variables{end}.coordinates  = coordinates;
    
    % add a battery variable if present
    if ~isempty(batteryIdx) && any(~isnan(data.BAT_VOLT))
        sample_data.variables{end+1}.name       = 'BAT_VOLT';
        sample_data.variables{end}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(sample_data.variables{end}.name, 'type')));
        sample_data.variables{end}.dimensions   = 1;
        sample_data.variables{end}.data         = sample_data.variables{end}.typeCastFunc(data.BAT_VOLT);
        sample_data.variables{end}.coordinates  = coordinates;
    end
end

end

function [match, nomatch] = getValues(key, keys, values)
%GETVALUES Returns a cell aray of values for the given key(s), as contained in
% the given data.
%
% Inputs:
%   key     - Cell array of strings containing the key(s) to look up
%   keys    - Cell array of keys, corresponding to the values array.
%   values  - Cell array of values, corresponding to the keys array
%
% Outputs:
%   match   - values of entries with the given key.
%   nomatch - values of entries without the given key
%
match   = {};
nomatch = {};

for k = 1:length(keys)
    
    % search for a match
    found = false;
    for m = 1:length(key)
        if strcmp(key{m}, keys{k}), found = true; break; end
    end
    
    % save the match (or non-match)
    if found, match  {end+1} = values{k}{1};
    else      nomatch{end+1} = values{k}{1};
    end
end
end
