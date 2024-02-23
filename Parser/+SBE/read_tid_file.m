function [data, xattrs] = read_tid_file( header, tid_filename )

% from "manual-26plus_019.0.pdf", pg 116
% If conductivity logging is not enabled (Conductivity=N; status
% display shows conductivity = NO), the sixth and seventh
% columns are not included in the .tid file.
% 
% Column 1 = Tide measurement number
% Columns 2 and 3 = Date and time of beginning 
% Column 4 = Measured pressure in psia
% Column 5 = Measured water temperature 
% Column 6= Measured conductivity in S/m
% Column 7 = Calculated salinity in PSU
%
% Note that this function does not handle files if Merge Barometric 
% Pressure has been run on the .tid file

% read in every line in the file
formatSpec = '%*d %f %f %f %f %f %f %f %f';
try
    fid = fopen(tid_filename, 'rt');
    rawdata = textscan(fid, formatSpec, 'Delimiter', {' ', '/', ':'}, 'MultipleDelimsAsOne', true);
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end
        
Y   = rawdata{3};
M   = rawdata{1};
D   = rawdata{2};
H   = rawdata{4};
MN  = rawdata{5};
S   = rawdata{6};

data = struct();
xattrs = containers.Map('KeyType','char','ValueType','any');

data.TIME        = datenum(Y, M, D, H, MN+2, S);
if isfield(header, 'instrument_burst_duration')
    comment_str = ['Time stamp corresponds to the start of the measurement, which lasts ' num2str(header.instrument_burst_duration) ' seconds).'];
    xattrs('TIME') = struct('seconds_to_middle_of_measurement', header.instrument_burst_duration/2.0);
    xattrs('TIME') = struct('comment', comment_str);
end
data.PRES_REL    = rawdata{7} * 0.6894757; % 1psi = 0.6894757dbar
xattrs('PRES_REL') = struct('units', 'dbar');
data.TEMP = rawdata{8};
xattrs('PRES_REL') = struct('units', 'degree');

end