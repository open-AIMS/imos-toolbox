%%
function [header, data, xattrs] = readCSV(filename)
% READCSV parse Odyssey CSV file. Currently only tested on Integrating
% Light Sensor.

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

headerLines = allLines(1:9);
dataLines = allLines(10:end);
clear('allLines');

header.instrument_make = 'Odyssey';

pat = 'Site Name\s+,(\w+)';
tkns = regexp(headerLines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    header.site_name = strtrim(tkns{ind}{1}{1});
end

pat = 'Site Number\s+,(\w+)';
tkns = regexp(headerLines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    header.site_number = strtrim(tkns{ind}{1}{1});
end

pat = 'Logger\s+,(.+)';
tkns = regexp(headerLines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    header.instrument_model = strtrim(tkns{ind}{1}{1});
end

pat = 'Logger Serial Number\s+,(\w+)';
tkns = regexp(headerLines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    header.instrument_serial_number = strtrim(tkns{ind}{1}{1});
end

% data
splitData = split(dataLines, ',');
splitData = strtrim(splitData);
[nrows, ncols] = size(splitData);

if ncols ~= 5
    error('Unknown data file format.');
end

% Do not know enough about data format to create programatic column
% mapping, so set by hand
%M = Odyssey.extract_column_map(headerline);
M = containers.Map();
M('Date') = 2;
M('Time') = 3;
M('RAW_VALUE') = 4;
M('CALIBRATED_VALUE') = 5;

data.TIME = datenum(join([splitData(:,M('Date')), splitData(:,M('Time'))]), 'dd/mm/yyyy HH:MM:SS');
xattrs('TIME') = struct('comment', 'TIME');

if isKey(M,'RAW_VALUE')
    data.RAW_VALUE = str2double(splitData(:,M('RAW_VALUE')));
    xattrs('RAW_VALUE') = struct('units', 'counts');
end

% TODO: check if CALIBRATED_VALUE == PAR?
if isKey(M,'CALIBRATED_VALUE')
    data.CALIBRATED_VALUE = str2double(splitData(:,M('CALIBRATED_VALUE')));
    xattrs('CALIBRATED_VALUE') = struct('units', 'counts');
end

end
