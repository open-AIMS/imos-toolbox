%%
function header = extract_instrument_info(header)

instrument_info = header.instrument_info;

% assume ordering in instrument_info are fixed
header.instrument_make = strtrim(instrument_info{1});
header.instrument_comment = strtrim(instrument_info{2});
tokens = regexp(instrument_info{3}, '([\w-]*)\s+\(SN:(\d+)\)', 'tokens');
header.instrument_model = tokens{1}{1};
header.instrument_serial_number = tokens{1}{2};

ind = find(contains(instrument_info, 'FIRMWARE'));
token = regexp(instrument_info{ind}, 'FIRMWARE:\s+(\w*)', 'tokens');
header.instrument_firmware = token{1}{1};
end
