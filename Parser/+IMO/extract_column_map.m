%%
function column_map = extract_column_map(header)
output_format = header.output_format;
ind = find(contains(output_format, 'ID,'));
fmt_str = output_format{ind};
fmt_str = strsplit(fmt_str, ',');
keys = {'ID', 'SN', 'DD/MM/YYYY', 'hh:mm:ss.sss', 'Volts', 'Depth', 'WaterTemp', 'Tilt', 'DetectorTemp', 'Inttime', '%Sig'};
values = {'ID', 'SN', 'Date', 'Time', 'Batt', 'Depth', 'Temp', 'Tilt', 'InstrumentTemp', 'IntegrationTime', 'PercentSignal'};
map = containers.Map(keys, values);
column_map = containers.Map('KeyType','char','ValueType','double');
found_keys = keys(contains(keys, fmt_str));
col_ind = find(contains(fmt_str, keys));
for k = 1:numel(found_keys)
    key = char(found_keys{k});
    column_map(map(key)) = col_ind(k);
end
% check for hyperspectral like names eg 'spec[1]'
m = cellfun(@(x) regexp(x, 'spec\[(\d+)\]', 'tokens'), fmt_str, 'UniformOutput', false);
ind = find(~cellfun(@isempty, m));
for k = 1:numel(ind)
    col_ind = ind(k);
    new_col_name = ['spec_' char(m{col_ind}{1})];
    column_map(new_col_name) = col_ind;
end
end