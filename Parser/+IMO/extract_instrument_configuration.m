%%
function header = extract_instrument_configuration(header)

instrument_configuration = header.instrument_configuration;

% for future processing needs
% strip out section header and add all X = Y entries to 
% header struct as configuration_X = Y.
% Any unimodel options (eg 'IN-WATER'), the entries is set as 'true'
idx = ~contains(instrument_configuration, {'---'});
instrument_configuration = instrument_configuration(idx);
for k = 1:numel(instrument_configuration)
    cfg = strtrim(strsplit(instrument_configuration{k}, '='));
    cfg{1} = matlab.lang.makeValidName(strrep(cfg{1}, ' ', '_'));
    if numel(cfg) == 1
        cfg{2} = 'true';
    end
    header.(['configuration_' cfg{1}]) = cfg{2};
end

% instrument mode
ind = find(contains(instrument_configuration, 'IN-WATER'));
if isempty(ind)
    header.instrument_mode = 'AIR_MODE';
else
    header.instrument_mode = 'WATER_MODE';
end

% detector type, eg
% DETECTOR = IRRADIANCE
idx = contains(instrument_configuration, 'DETECTOR =');
token = regexp(instrument_configuration{idx}, 'DETECTOR =\s+(.*)', 'tokens');
header.instrument_detector_type = token{1}{1};

% detector output, eg
% DETECTOR OUTPUT = IRR
idx = contains(instrument_configuration, 'DETECTOR OUTPUT =');
token = regexp(instrument_configuration{idx}, 'DETECTOR OUTPUT =\s+(.*)', 'tokens');
% if not IRR or RAD then error as cannot handle RAW
if ~contains(token{1}{1}, {'IRR', 'RAD', 'ENG (ASCII)'})
    error(['Cannot handle DETECTOR OUTPUT = ' token{1}{1}]');
end

% sampling information, eg
% SAMPLERATE = 1
% SAMPLING MODE = BURSTMODE
% BURST SAMPLES = 10
% BURST INTERVAL = 15
% BURST PROGRAM = 1
idx = contains(instrument_configuration, 'SAMPLERATE =');
hasSAMPLERATE = any(idx);
if hasSAMPLERATE
    token = regexp(instrument_configuration{idx}, 'SAMPLERATE =\s+(\w*)', 'tokens');
    header.instrument_sampling_rate = 1.0/str2num(token{1}{1}); % hertz -> seconds
end

isBurstSampling = false;
isContinuousSampling = false;

ind = find(contains(instrument_configuration, 'SAMPLING MODE ='));
token = regexp(instrument_configuration{ind}, 'SAMPLING MODE =\s+(\w*)', 'tokens');
if contains(instrument_configuration{ind}, 'BURST')
    isBurstSampling = true;
    header.instrument_sampling_mode = 'BURST';
    
    ind = find(contains(instrument_configuration, 'BURST SAMPLES ='));
    token = regexp(instrument_configuration{ind}, 'BURST SAMPLES =\s+(\d*)', 'tokens');
    header.instrument_burst_samples = str2num(token{1}{1});
    if hasSAMPLERATE
        header.instrument_burst_duration = header.instrument_burst_samples * header.instrument_sampling_rate; %seconds
    end
    
    ind = find(contains(instrument_configuration, 'BURST INTERVAL ='));
    token = regexp(instrument_configuration{ind}, 'BURST INTERVAL =\s+(\d*)', 'tokens');
    header.instrument_burst_interval = str2num(token{1}{1}) * 60; %minutes -> seconds
elseif contains(instrument_configuration{ind}, 'CONTINUOUS')
    isContinuousSampling = true;
    header.instrument_sampling_mode = 'CONTINUOUS';
else
    error('Unknown SAMPLING MODE.');
end

ind = find(contains(instrument_configuration, 'TIMEZONE ='));
token = regexp(instrument_configuration{ind}, 'TIMEZONE =\s+([+-]?(?:\d+\.?\d*|\d*\.\d+))', 'tokens');
header.instrument_utc_offset = str2num(token{1}{1}); %hours

ind = find(contains(instrument_configuration, 'WIPE INTERVAL ='));
token = regexp(instrument_configuration{ind}, 'WIPE INTERVAL =\s+(\d*)', 'tokens');
header.instrument_wiper_interval = str2num(token{1}{1}) * 3600; %hours -> seconds

end







