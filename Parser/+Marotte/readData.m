%%
function [data, xattrs] = readData(filename, deviceInfo)
% parse JCU Marotte CSV file


xattrs = containers.Map('KeyType','char','ValueType','any');
xattrs('TIME') = struct('comment', 'TIME');

is_csv = ~isempty(regexp(filename, '\.csv$','once'));

magExt = '';
if strcmpi(deviceInfo.magnetic_offset_compensation, 'NO')
    magExt = '_MAG';
end

if is_csv
    [data, xattrs] = Marotte.read_data_csv(filename, deviceInfo, magExt);
else
    [data, xattrs] = Marotte.read_data_mat(filename, deviceInfo, magExt);
end

end


