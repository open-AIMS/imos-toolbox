function deviceInfo = parse_inf_file( deviceInfo, inf_filename )
% parse_inf_file parse WLR/RCM info file 
%
% Text file with some infomation required for processing that isn't
% available in the instrument raw data file. In the format of key=value
%
% Currently supported keys are
% instrument_model : instrument model 'RCM4', 'RCM5', 'RCM7', 'WLR5', 'WLR7'
% start_time : time of first sample in format 'YYYY/MM/DDTHH:MM'
% sample_interval : in seconds
% revolutions_per_count : required for 'RCM4', 'RCM5'
% guard_kit_fitted : 0==no, 1==yes, required for 'RCM4' (maybe 'RCM5'?)
% temperature_range : for 'RCM7' what was the selected 
%   temperature range, allowed valued 'TEMP_LOW', 'TEMP_HIGH', 'TEMP_WIDE'

%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%

%% open info file, get everything from it as lines
%
% An example info file looks like
% instrument_model=WLR7 # model, uppercase
% start_time=1990/05/03T13:00 # time of first sample in data file
% sample_interval=3600.0 # sample interval in seconds


fid     = -1;
all_lines = {};
try
    fid = fopen(inf_filename, 'rt');
    if fid == -1, error(['couldn''t open ' filename 'for reading']); end
    
    % read in the data
    all_lines = textscan(fid, '%s', 'Whitespace', '\r\n', 'CommentStyle','#');
    all_lines = all_lines{1};
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end

deviceInfo.inf_lines = all_lines;

%% parse inf file
pat = 'instrument_model=(\w+)';
tkns = regexp(all_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if isempty(ind)
    error('Inf file must have instrument_model value.');
else
    deviceInfo.instrument_model = strtrim(tkns{ind}{1}{1});
end

pat = 'start_time=(\S+)';
tkns = regexp(all_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if isempty(ind)
    error('Inf file must have start_time value.');
else
    deviceInfo.start_time = strtrim(tkns{ind}{1}{1});
end

pat = 'sample_interval=(\w+)';
tkns = regexp(all_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if isempty(ind)
    error('Inf file must have sample_interval value.');
else
    deviceInfo.sample_interval = str2double(strtrim(tkns{ind}{1}{1}));
end

% only for RCM4 and RCM5
pat = 'revolutions_per_count=(\w+)';
tkns = regexp(all_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if contains(deviceInfo.instrument_model, {'RCM4', 'RCM5'}) && isempty(ind)
    error('RCM4 and RCM5 inf file must have revolutions_per_count value.');
end
if ~isempty(ind)
    deviceInfo.sample_revolutions_per_count = str2double(strtrim(tkns{ind}{1}{1}));
end

pat = 'guard_kit_fitted=(\w+)';
tkns = regexp(all_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    deviceInfo.guard_kit_fitted = str2double(strtrim(tkns{ind}{1}{1}));
end

% only for RCM7
pat = 'temperature_range=(\w+)';
tkns = regexp(all_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    % should only be TEMP_LOW, TEMP_HIGH, TEMP_WIDE
    allowed_temperature_ranges = {'TEMP_LOW', 'TEMP_HIGH', 'TEMP_WIDE'};
    temp_range = strtrim(tkns{ind}{1}{1});
    if ~contains(temp_range, allowed_temperature_ranges)
        error(['Not a valid temperature range specified, must be one of ' strjoin(allowed_temperature_ranges, ',')]);
    end
    deviceInfo.temperature_range = temp_range;
end

%%
% do some checks

if contains(deviceInfo.instrument_model, {'RCM4', 'RCM5'}) && ~isfield(deviceInfo, 'guard_kit_fitted')
    error('RCM4/RCM5 inf file must have guard_kit_fitted value set [0/1].');
end

if contains(deviceInfo.instrument_model, 'RCM7') && ~isfield(deviceInfo, 'temperature_range')
   error(['RCM7 inf file must have valid temperature range specified, must be one of ' strjoin(allowed_temperature_ranges, ',')]);
end

%%
ncols = NaN;
ncoeff = NaN; % number of coefficients
has_time_base = false;

switch deviceInfo.instrument_model
    case 'WLR5'
        ncols = 4;
        ncoeff = 4;
        has_time_base = false;
        
    case 'WLR7'
        ncols = 5;
        ncoeff = 4;
        has_time_base = true;
        
    case {'RCM4', 'RCM5'}
        ncols = 6;
        ncoeff = 6;
        has_time_base = false;
        
    case 'RCM7'
        ncols = 6;
        ncoeff = 6;
        has_time_base = true;
        
    otherwise
        error(['Aanderaa ' deviceInfo.instrument_make ' not supported.']);
end

deviceInfo.ncols = ncols;
deviceInfo.ncoeff = ncoeff;
deviceInfo.has_time_base = has_time_base;

end