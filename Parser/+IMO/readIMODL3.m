%%
function [header, data, xattrs] = readIMODL3(fid)
% parse IMO DL3 TXT file

header = struct;
data = struct;
xattrs = containers.Map('KeyType','char','ValueType','any');

try
    frewind(fid);
    allLines = textscan(fid, '%s', 'Delimiter', '\n');
    allLines = allLines{1};
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end

tf = contains(allLines, '-------------------------------');
ind = find(tf);
if isempty(ind)
    error('IMO DL3 TXT format not handled.')
end
headerlines = allLines(1:ind);
dataLines = allLines(ind+1:end);

% split up header lines into currently know sections

% instrument info, assume this is always the first section
ind_end = find(contains(headerlines, '---'));
header.instrument_info = headerlines(1:ind_end(1)-1);

% instrument configuration
ind_conf = find(contains(headerlines, '---CONFIGURATION---'));
ind_end = find(contains(headerlines(ind_conf+1:end), '---'));
header.instrument_configuration = headerlines(ind_conf:ind_conf+ind_end(1)-1);

% instrument calibration
ind_cal = find(contains(headerlines, '---CALIBRATION CONFIGURATION---'));
ind_end = find(contains(headerlines(ind_cal+1:end), '---'));
header.instrument_calibration = headerlines(ind_cal:ind_cal+ind_end(1)-1);

% output format, not in every IMO TXT file
ind_format = find(contains(headerlines, '---OUTPUT FORMAT---'));
if isempty(ind_format)
    header.output_format = {};
    warning('No OUTPUT FORMAT section found. Attempting best guess at data layout.');
else
    ind_end = find(contains(headerlines(ind_format+1:end), '---'));
    header.output_format = headerlines(ind_format:ind_format+ind_end(1)-1);
end

header = IMO.extract_instrument_info(header);
header = IMO.extract_instrument_configuration(header);
header = IMO.extract_instrument_calibration(header);

% data
splitData = split(dataLines, ',');
[nrows, ncols] = size(splitData);

% Use the OUTPUT FORMAT section to map variable to column index, 
% else make best guess based on previously examined files
% TODO:
% At the moment make an artificial division of hyperspectral channels from 
% uSpec (spec_X) and multispectral channels from MS8/MS9 (ChX). Maybe in 
% the future make them all ChX and differentiate on instrument type
if isfield(header, 'output_format') && ~isempty(header.output_format)
    M = IMO.extract_column_map(header);
elseif ncols == 18 % MS8/MS9 with no TEMP or DEPTH sensor
    M = containers.Map('KeyType','char','ValueType','double');
    M('Date') = 3;
    M('Time') = 4;
    M('Wiper') = 5;
    M('Batt') = 6;
    M('Tilt') = 7;
    M('InstrumentTemp') = 8;
    M('Par') = 9;
    M('Ch1') = 10;
    M('Ch2') = 11;
    M('Ch3') = 12;
    M('Ch4') = 13;
    M('Ch5') = 14;
    M('Ch6') = 15;
    M('Ch7') = 16;
    M('Ch8') = 17;
    M('Ch9') = 18;
elseif ncols == 20
    M = containers.Map('KeyType','char','ValueType','double');
    M('Date') = 3;
    M('Time') = 4;
    M('Wiper') = 5;
    M('Batt') = 6;
    M('Depth') = 7;
    M('Temp') = 8;
    M('Tilt') = 9;
    M('InstrumentTemp') = 10;
    M('Par') = 11;
    M('Ch1') = 12;
    M('Ch2') = 13;
    M('Ch3') = 14;
    M('Ch4') = 15;
    M('Ch5') = 16;
    M('Ch6') = 17;
    M('Ch7') = 18;
    M('Ch8') = 19;
    M('Ch9') = 20;
else
    error('Unknown data layout.')
end

data.TIME = datenum([char(splitData(:,M('Date'))) char(splitData(:,M('Time')))],'dd/mm/yyyyHH:MM:SS.FFF');
data.TIME = data.TIME - header.instrument_utc_offset/24.0; % convert to UTC
xattrs('TIME') = struct('comment', 'TIME (UTC)');

if isKey(M,'Wiper')
    data.WIPER_STATUS = str2double(splitData(:,M('Wiper')));
    xattrs('WIPER_STATUS') = struct('comment', 'Wiper Position (0 for open and 1 for closed)');
end

if isKey(M,'Batt')
    data.BAT_VOLT = str2double(splitData(:,M('Batt')));
    xattrs('BAT_VOLT') = struct('comment', 'Input Voltage (V)', 'units', 'V');
end

if isKey(M,'Depth')
    data.DEPTH = str2double(splitData(:,M('Depth')));
    xattrs('DEPTH') = struct('units', 'm');
end

if isKey(M,'Temp')
    data.TEMP = str2double(splitData(:,M('Temp')));
    xattrs('TEMP') = struct('units', 'degrees_Celsius');
end

if isKey(M,'Tilt')
    data.TILT = str2double(splitData(:,M('Tilt')));
    xattrs('TILT') = struct('units', 'degree');
end

if isKey(M,'InstrumentTemp')
    data.INSTRUMENT_TEMP = str2double(splitData(:,M('InstrumentTemp')));
    xattrs('INSTRUMENT_TEMP') = struct('comment', 'Internal instrument temperature',...
        'units', 'degrees_Celsius');
end

if isKey(M,'PercentSignal')
    data.PERCENT_SIGNAL = str2double(splitData(:,M('PercentSignal')));
    xattrs('PERCENT_SIGNAL') = struct('comment', 'Percentage of the peak max counts of the spectrum vs the maximum count threshold (MAXCOUNTS). Typically values 20% to 80% represent usefull measurments.',...
        'units', 'percent');
end

if isKey(M,'IntegrationTime')
    data.INTEGRATION_TIME = str2double(splitData(:,M('IntegrationTime')));
    xattrs('INTEGRATION_TIME') = struct('units', 'milliseconds');
end

% instrument calculated PAR
if isKey(M,'Par')
    data.PAR = str2double(splitData(:,M('Par'))); % umole m^-2 s^-1
    xattrs('PAR') = struct('comment', [header.instrument_model ' instrument derived PAR from integrated irradiance from 400 to 700nm'],...
        'units', 'umole m-2 s-1');
end

if isKey(M,'Ch1')
    number_of_spectral_channels = sum(contains(keys(M), 'Ch'));
    wavelengths = str2double(split(header.instrument_wavelengths, ','));
    vName = 'WAVELENGTHS';
    data.(vName) = wavelengths;
    xattrs(vName) = struct('units', 'nm', 'comment', 'Multispectral wavelengths.');
    
    isIRRADIANCE = strcmp(header.instrument_detector_type, 'IRRADIANCE');
    
    switch header.instrument_detector_type
        case 'IRRADIANCE'
            vName = 'IRRADIANCE';
        case 'RADIANCE'
            vName = 'RADIANCE';
        otherwise
            vName = 'MULTISPEC';
            warning(['Unknown DETECTOR type : ' header.instrument_detector_type]);
    end
    
    wavelengths = str2double(split(header.instrument_wavelengths, ','));
    number_of_spectral_channels = numel(wavelengths);
    data.(vName) = nan([numel(data.TIME), number_of_spectral_channels]);
    for k = 1:number_of_spectral_channels
        key = ['Ch' num2str(k)];
        data.(vName)(:,k) = str2double(splitData(:,M(key)));
    end
    
    xstruct = struct();
    xstruct.('comment') = ['Multispectral ' vName ' data collected at wavelengths of ' header.instrument_wavelengths 'nm'];
    switch header.instrument_detector_type
        case 'IRRADIANCE'
            xstruct.('units') = 'uW cm-2 nm-1';
        case 'RADIANCE'
            xstruct.('units') = 'uW cm-2 nm-1 st-1';
        otherwise
            xstruct.('comment') = ['Unknown multispectral data collected at wavelengths of ' header.instrument_wavelengths 'nm'];
            xstruct.('units') = 'UNKNOWN';
    end
    xattrs(vName) = xstruct;
    
    if isIRRADIANCE
        [data, xattrs] = IMO.calcPAR(data, xattrs, header);
    end
end

if isKey(M,'spec_1')
    number_of_spectral_channels = sum(contains(keys(M), 'spec'));
    wavelengths = str2double(split(header.instrument_wavelengths, ','));
    vName = 'WAVELENGTHS';
    data.(vName) = wavelengths;
    xattrs('WAVELENGTHS') = struct('units', 'nm',...
        'comment', 'Multispectral wavelengths.');
    
    isIRRADIANCE = strcmp(header.instrument_detector_type, 'IRRADIANCE');
    
    switch header.instrument_detector_type
        case 'IRRADIANCE'
            vName = 'IRRADIANCE';
        case 'RADIANCE'
            vName = 'RADIANCE';
        otherwise
            vName = 'MULTISPEC';
            warning(['Unknown DETECTOR type : ' header.instrument_detector_type]);
    end
    
    data.(vName) = nan([numel(data.TIME), number_of_spectral_channels]);
    for k = 1:number_of_spectral_channels
        key = ['spec_' num2str(k)];
        data.(vName)(:,k) = str2double(splitData(:,M(key)));
    end
    xstruct = struct();
    xstruct.('comment') = ['Multispectral ' vName ' data collected at wavelengths of ' header.instrument_wavelengths 'nm'];
    switch header.instrument_detector_type
        case 'IRRADIANCE'
            xstruct.('units') = 'uW cm-2 nm-1';
        case 'RADIANCE'
            xstruct.('units') = 'uW cm-2 nm-1 st-1';
        otherwise
            xstruct.('comment') = ['Unknown multispectral data collected at wavelengths of ' header.instrument_wavelengths 'nm'];
            xstruct.('units') = 'UNKNOWN';
    end
    xattrs(vName) = xstruct;
    
    if isIRRADIANCE
        [data, xattrs] = IMO.calcPAR(data, xattrs, header);
    end
end

end
