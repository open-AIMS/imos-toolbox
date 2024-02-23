function header = parse_sbe26_hex_header( hex_filename )

fid = -1;
lines = {};
try
    fid = fopen(hex_filename, 'rt');
    line = fgetl(fid);
    while ischar(line) && strncmp(line, '*', 1)        
        lines{end+1} = strtrim(line);
        line = fgets(fid);
    end
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end

header = struct;
header.lines = lines;

% '*SBE 26plus V 6.1c  SN 1217    24 Feb 2022  01:48:14'
pat = '\*SBE\s+(\S+)\s+V\s+(\S+)\s+SN\s+(\S+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    header.instrument_model = ['SBE' tkns{ind}{1}{1}];
    header.instrument_firmware = tkns{ind}{1}{2};
    header.instrument_serial_number = tkns{ind}{1}{3};
end

% '*strain gauge pressure sensor: serial number = 2752212, range = 44 psia'
pat = '\*.+sensor: serial number = (\S+), range = (\S+) psia';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    header.pressure_sensor_serial_number = tkns{ind}{1}{1};
    header.pressure_sensor_serial_range = [tkns{ind}{1}{2} ' psia'];
end

% is it always interval in minutes and duration in seconds?
% '*tide measurement: interval = 30.000 minutes, duration = 40 seconds
pat = '\*tide measurement: interval = (\S+) minutes, duration = (\S+) seconds';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    header.instrument_sample_interval = str2double(tkns{ind}{1}{1});
    header.instrument_burst_duration = str2double(tkns{ind}{1}{2});
end

% '*conductivity = NO'
pat = '\*conductivity = (\S+)';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    header.has_conductivity = ~strcmpi(tkns{ind}{1}{1}, 'NO');
end

% TODO
% '*measure waves every 4 tide samples'
% '*512 wave samples/burst at 4.00 scans/sec, duration = 128 seconds'
pat = '\*(\d+) wave samples\/burst at (\S+) scans\/sec, duration = (\d+) seconds';
tkns = regexp(lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    header.has_waves = true; %?
    header.wave_samples_per_burst = str2double(tkns{ind}{1}{1});
    header.wave_sampling_frequency = 1/str2double(tkns{ind}{1}{2});
    header.wave_burst_duration = str2double(tkns{ind}{1}{3});
end


end