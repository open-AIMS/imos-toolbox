function column_map = extract_column_map(header)

fmt_str = strsplit(header, ',');

%Current known column names
keys = {'datetime', 'speed (m/s)', 'heading (degrees CW from North)', 'speed upper (m/s)', 'speed lower (m/s)', 'tilt (radians)', 'direction (radians CCW from East)', 'batt (volts)', 'temp (Celsius)'};
values = {'Datetime', 'Speed', 'Direction', 'Speed_Upper', 'Speed_Lower', 'Tilt', 'Direction_Radians', 'Batt', 'Temp'};

map = containers.Map(keys, values);
column_map = containers.Map('KeyType','char','ValueType','double');
found_keys = keys(contains(keys, fmt_str));
col_ind = find(contains(fmt_str, keys));
for k = 1:numel(found_keys)
    key = char(found_keys{k});
    column_map(map(key)) = col_ind(k);
end

end