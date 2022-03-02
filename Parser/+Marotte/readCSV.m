%%
function [header, data, xattrs] = readCSV(filename, deviceInfo)
% parse JCU Marotte CSV file

header = struct;
data = struct;
xattrs = containers.Map('KeyType','char','ValueType','any');

try
    fid = fopen(filename, 'rt');
    allLines = textscan(fid, '%s', 'Delimiter', '\n');
    allLines = allLines{1};
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end

tf = contains(allLines, 'datetime');
ind = find(tf);
if isempty(ind)
    error('Marotte CSV format not handled.')
end
headerline = allLines{ind};
dataLines = allLines(ind+1:end);
% have seen data lines with a hanging comma, remove it
dataLines = regexprep(dataLines, ',$', '');

%datetime,speed (m/s),heading (degrees CW from North),speed upper (m/s),speed lower (m/s),tilt (radians),direction (radians CCW from East),batt (volts),temp (Celsius)

splitHeader = split(headerline, ',');
[nrows_header, ncols_header] = size(splitHeader');

% data
splitData = split(dataLines, ',');
[nrows, ncols] = size(splitData);

if ncols ~= ncols_header
    error('Number of header column names does not equal number of data columns.');
end

M = Marotte.extract_column_map(headerline);

data.TIME = datenum(splitData(:,M('Datetime')), 'yyyy-mm-dd HH:MM:SS.FFF');
xattrs('TIME') = struct('comment', 'TIME');

if isKey(M,'Speed')
    data.CSPD = str2double(splitData(:,M('Speed')));
    xattrs('CSPD') = struct('units', 'm/s');
end

magExt = '';
if strcmpi(deviceInfo.magnetic_offset_compensation, 'NO')
    magExt = '_MAG';
end

if isKey(M,'Direction')
    data.(['CDIR' magExt]) = str2double(splitData(:,M('Direction')));
    xattrs(['CDIR' magExt]) = struct('comment', 'degrees CW from North', 'units', 'degrees');
end

if isKey(M,'Speed_Upper')
    data.CSPD_UPPER = str2double(splitData(:,M('Speed_Upper')));
    xattrs('CSPD_UPPER') = struct('units', 'm/s', 'typeCastFunc', str2func('single'));
end

if isKey(M,'Speed_Lower')
    data.CSPD_LOWER = str2double(splitData(:,M('Speed_Lower')));
    xattrs('CSPD_LOWER') = struct('units', 'm/s', 'typeCastFunc', str2func('single'));
end

if isKey(M,'Batt')
    data.BAT_VOLT = str2double(splitData(:,M('Batt')));
    xattrs('BAT_VOLT') = struct('comment', 'Voltage (V)', 'units', 'V');
end

if isKey(M,'Temp')
    data.TEMP = str2double(splitData(:,M('Temp')));
    xattrs('TEMP') = struct('units', 'degrees_Celsius');
end

if isKey(M,'Tilt')
    data.TILT = str2double(splitData(:,M('Tilt'))) * 180.0 / pi;
    xattrs('TILT') = struct('units', 'degree');
end

end
