function [data, xattrs] = read_data_mat(filename, deviceInfo, magExt)

header = struct;
xattrs = containers.Map('KeyType','char','ValueType','any');
xattrs('TIME') = struct('comment', 'TIME');

magExt = '';
if strcmpi(deviceInfo.magnetic_offset_compensation, 'NO')
    magExt = '_MAG';
end

data = load(filename); % load previous save data in mat format

dnames = fieldnames(data);

is_str_member = @(d, k) any(ismember(d, k));

k = 'CSPD';
if is_str_member(dnames, k)
    xattrs(k) = struct('units', 'm/s');
end

k = ['CDIR' magExt];
if is_str_member(dnames, k)
    xattrs(k) = struct('comment', 'degrees CW from North', 'units', 'degrees');
end

k = ['CDIR_CART_RAD' magExt];
if is_str_member(dnames, k)
    xattrs(k) = struct('comment', 'radians CCW from East', 'units', 'radians');
end

if is_str_member(dnames, 'CSPD_UPPER')
    xattrs('CSPD_UPPER') = struct('units', 'm/s', 'typeCastFunc', str2func('single'));
end

if is_str_member(dnames, 'CSPD_LOWER')
    xattrs('CSPD_LOWER') = struct('units', 'm/s', 'typeCastFunc', str2func('single'));
end

if is_str_member(dnames, 'BAT_VOLT')
    xattrs('BAT_VOLT') = struct('comment', 'Voltage (V)', 'units', 'V');
end

if is_str_member(dnames, 'TEMP')
    xattrs('TEMP') = struct('units', 'degrees_Celsius');
end

if is_str_member(dnames, 'TILT')
    xattrs('TILT') = struct('units', 'degree');
end

end