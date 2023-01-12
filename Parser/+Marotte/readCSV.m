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
clear('allLines');
%datetime,speed (m/s),heading (degrees CW from North),speed upper (m/s),speed lower (m/s),tilt (radians),direction (radians CCW from East),batt (volts),temp (Celsius)

splitHeader = split(headerline, ',');
[nrows_header, ncols_header] = size(splitHeader');

% data
splitData = split(dataLines{1}, ',');
[ncols, ~] = size(split(dataLines{1}, ','));

if ncols ~= ncols_header
    error('Number of header column names does not equal number of data columns.');
end

% slow
splitData = split(dataLines, ',');
[nrows, ncols] = size(splitData);

% tic; splitData = regexp(dataLines(1:200000), ',', 'split'); toc
% tic; splitData = split(dataLines(1:200000), ','); toc

M = Marotte.extract_column_map(headerline);

magExt = '';
if strcmpi(deviceInfo.magnetic_offset_compensation, 'NO')
    magExt = '_MAG';
end

data.TIME = NaN([nrows, 1]);
data.TIME = datenum(splitData(:,M('Datetime')), 'yyyy-mm-dd HH:MM:SS.FFF');
xattrs('TIME') = struct('comment', 'TIME');

if isKey(M,'Speed')
    data.CSPD = NaN([nrows, 1]);
    data.CSPD = str2doubles(splitData(:,M('Speed')));
    xattrs('CSPD') = struct('units', 'm/s');
end

if isKey(M,'Direction')
    data.(['CDIR' magExt]) = NaN([nrows, 1]);
    data.(['CDIR' magExt]) = str2double(splitData(:,M('Direction')));
    xattrs(['CDIR' magExt]) = struct('comment', 'degrees CW from North', 'units', 'degrees');
end

if isKey(M,'Direction_Radians')
    data.(['CDIR_CART_RAD' magExt]) = NaN([nrows, 1]);
    data.(['CDIR_CART_RAD' magExt]) = str2doubles(splitData(:,M('Direction')));
    xattrs(['CDIR_CART_RAD' magExt]) = struct('comment', 'radians CCW from East', 'units', 'radians');
end

if isKey(M,'Speed_Upper')
    data.CSPD_UPPER = NaN([nrows, 1]);
    data.CSPD_UPPER = str2doubles(splitData(:,M('Speed_Upper')));
    xattrs('CSPD_UPPER') = struct('units', 'm/s', 'typeCastFunc', str2func('single'));
end

if isKey(M,'Speed_Lower')
    data.CSPD_LOWER = NaN([nrows, 1]);
    data.CSPD_LOWER = str2doubles(splitData(:,M('Speed_Lower')));
    xattrs('CSPD_LOWER') = struct('units', 'm/s', 'typeCastFunc', str2func('single'));
end

if isKey(M,'Batt')
    data.BAT_VOLT = NaN([nrows, 1]);
    data.BAT_VOLT = str2double(splitData(:,M('Batt')));
    xattrs('BAT_VOLT') = struct('comment', 'Voltage (V)', 'units', 'V');
end

if isKey(M,'Temp')
    data.TEMP = NaN([nrows, 1]);
    data.TEMP = str2doubles(splitData(:,M('Temp')));
    xattrs('TEMP') = struct('units', 'degrees_Celsius');
end

if isKey(M,'Tilt')
    data.TILT = NaN([nrows, 1]);
    data.TILT = str2doubles(splitData(:,M('Tilt'))) * 180.0 / pi;
    xattrs('TILT') = struct('units', 'degree');
end

end

%%
function y = str2doubles (cs)
%STR2DOUBLES:  Faster alternative to builtin str2double

%https://au.mathworks.com/matlabcentral/fileexchange/61652-faster-alternative-to-builtin-str2double
% plus update in the discussion

if ischar(cs),  y = str2double(cs);  return;  end
siz = size(cs);
cs = cs(:);
cs = deblank(cs);  % (it changes the shpe of 3d input)
%idx = ~cellfun(@isempty, cs); %slower
idx = ~cellfun('isempty', cs);
cs2 = cs(idx);
y2 = sscanf(sprintf('%s#', cs2{:}), '%g#');  % faster
%y2 = cellfun(@(csi) sscanf(csi, '%g#'), cs2);  % slower
y = NaN(siz);
y(idx) = y2;
end
%!test
%! assert(str2doubles('123.45e7') == 123.45e7)
%! assert(str2doubles('123 + 45i') == (123 + 45i))
%! assert(str2doubles('3.14159') == 3.14159)
%! assert(str2doubles('2.7i - 3.14') == (2.7i - 3.14))
%! assert(isequal(str2doubles({'2.71' '3.1415'}), [2.71  3.1415]))
%! assert(str2doubles('1,200.34') == 1200.34)
%! assert(isequaln(str2doubles({'1', ' ', '3'}), [1, NaN, 3]))
%! assert(isequaln(str2doubles(reshape({'1', '2'}, [1,1,2])), reshape([1, 2], [1,1,2])))
