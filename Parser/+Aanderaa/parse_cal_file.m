function deviceInfo = parse_cal_file( deviceInfo, cal_filename )
% parse_cal_file read contents of a calibration file and parse depending on
% instrument type

%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%

%% open cal file, get everything from it as lines
fid     = -1;
all_lines = {};
try
    fid = fopen(cal_filename, 'rt');
    if fid == -1, error(['couldn''t open ' filename 'for reading']); end
    
    % read in the data
    all_lines = textscan(fid, '%s', 'Delimiter', '\r\n', 'WhiteSpace', '', 'CommentStyle','#', 'MultipleDelimsAsOne', false);
    %lines = textscan(fid, '%s', 'CommentStyle','#');
    all_lines = all_lines{1};
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end
deviceInfo.cal_lines = all_lines;

%% read cal file type
% TODO: confirm pressure variable is PRES, pretty sure it is
% absolute (PRES) so that depth = f(pressure - gsw_P0/10^4)
% relative (PRES_REL) so that depth = f(pressure)
allowed_instrument_models = Aanderaa.get_allowed_instruments();
deviceInfo.is_new_style_cal_file = contains(all_lines{1}, allowed_instrument_models);
if deviceInfo.is_new_style_cal_file
    deviceInfo = Aanderaa.read_new_style_cal( all_lines, deviceInfo );
else
    deviceInfo = Aanderaa.read_old_style_cal( all_lines, deviceInfo );
end

end