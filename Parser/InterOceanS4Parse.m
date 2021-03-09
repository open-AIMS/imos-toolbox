function sample_data = InterOceanS4Parse( filename, tMode )
%InterOceanS4Parse Parses an ascii (S4A) or binary (S4B) data file from
% an InterOcean S4 current meter.
%
% WARNING: only tested on plain S4 current meter, never been tested on
% directional waves or deep water models. Ideally the binary file would also
% have companion CFG which would outline instrument capabilites.
%
% This function uses readS4B/readS4A functions to read in a set
% of ensembles from a raw binary S4B or engineering units asci S4A file.
% It returns the following:
%
%   - time
%   - velocity east & north components, speed & dir
%   - temperature (at each time, if present)
%   - depth/pressure (at each time, if present)
%   - conductivity (at each time, if present)
%   - compass heading and components hx, hy (at each time, if present)
%
% Not handled yet
%   - voltage reference (at each time, if present)
%   - tilt x & y components (at each time, if present)
%
% The conversion of binary S4B somewhat documented in S4A current meter
% users manual June 1990, and S4Bfile.doc in installer.
%
% Issues:
% - ascii hex dump S4A format is not supported
% - do not have full print format specs for converted ascii S4A files,
% so some information will be missing.
% - depth conversion for binary S4B not correct, assume std res pressure
% range 0-1000, and hires range 0-70m. This value isn't encoded into the
% binary file.
% - vel range assumed a std 350cm/s
%
% Inputs:
%   filename    - raw binary or converted data file from an S4.
%   tMode       - Toolbox data type mode.
%
% Outputs:
%   sample_data - sample_data struct containing the data retrieved from the
%                 input file.
%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%

%
% Copyright (C) 2021, Australian Ocean Data Network (AODN) and Integrated
% Marine Observing System (IMOS).
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation version 3 of the License.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.

% You should have received a copy of the GNU General Public License
% along with this program.
% If not, see <https://www.gnu.org/licenses/gpl-3.0.en.html>.
%
narginchk(1, 2);

filename = filename{1};

% Extract header+data from particular type of file.
[data, header] = readS4file(filename);

% check for electrical/magnetic heading bias (usually magnetic declination)
magExt = '_MAG';
magBiasComment = '';
if isfield(header, 'mag_var') && (header.mag_var ~= 0)
    magExt = '';
    magBiasComment = ['A compass correction of ' num2str(header.mag_var) ...
        'degrees has been applied to the data by a technician using S4''s software ' ...
        '(usually to account for magnetic declination).'];
end

% fill in the sample_data struct
sample_data.toolbox_input_file                = filename;
sample_data.meta.featureType                  = 'timeSeries';
sample_data.meta.instrument_make              = 'InterOcean';
sample_data.meta.instrument_model             = header.model;
sample_data.meta.instrument_serial_no         = header.serial;
sample_data.meta.instrument_sample_interval   = header.sample_interval;
sample_data.meta.instrument_average_interval  = header.sample_duration;
sample_data.meta.instrument_firmware          = header.s4_version;

dims = {
    'TIME',                   data.TIME,     ['Time stamp corresponds to the start of the measurement which lasts ' num2str(sample_data.meta.instrument_average_interval) ' seconds.']; ...
    };
clear time height distance;

nDims = size(dims, 1);
sample_data.dimensions = cell(nDims, 1);
for i=1:nDims
    sample_data.dimensions{i}.name         = dims{i, 1};
    sample_data.dimensions{i}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(dims{i, 1}, 'type')));
    sample_data.dimensions{i}.data         = sample_data.dimensions{i}.typeCastFunc(dims{i, 2});
    sample_data.dimensions{i}.comment      = dims{i, 3};
end
clear dims;

% add information about the middle of the measurement period
sample_data.dimensions{1}.seconds_to_middle_of_measurement = sample_data.meta.instrument_average_interval/2;

% add variables with their dimensions and data mapped
vars = {
    'TIMESERIES',         [],     1,              ''; ...
    'LATITUDE',           [],     NaN,            ''; ...
    'LONGITUDE',          [],     NaN,            ''; ...
    'NOMINAL_DEPTH',      [],     NaN,            ''; ...
    ['VCUR' magExt],      1,    'VCUR',          magBiasComment; ...
    ['UCUR' magExt],      1,    'UCUR',          magBiasComment; ...
    'CSPD',               1,    'CSPD',          ''; ...
    ['CDIR' magExt],      1,    'CDIR',      magBiasComment; ...
    'TEMP',               1,    'TEMP',    ''; ...
    'CNDC',               1,    'CNDC',    ''; ...
    'DEPTH',           1,    'DEPTH',       ''; ...
    'PSAL',               1,	'PSAL',       ''; ...
    'SSPD',               1,    'SSPD',     ''; ...
    'HX',                 1,	'HX',          ''; ...
    'HY',                 1,	'HY',          ''; ...
    ['HEADING' magExt],   1,    'HEADING',        magBiasComment; ...
    'TILTX',              1,    'TILTX',          ''; ...
    'TILTY',              1,    'TILTY',          ''; ...
    'VOLTREF',            1,    'VREF',        ''
    };

nVars = size(vars, 1);
sample_data.variables = {};
for i=1:nVars
    if any(strcmpi(vars{i, 1}, {'TIMESERIES', 'LATITUDE', 'LONGITUDE', 'NOMINAL_DEPTH'}))
        sample_data.variables{end+1}.name         = vars{i, 1};
        sample_data.variables{end}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(vars{i, 1}, 'type')));
        sample_data.variables{end}.dimensions   = vars{i, 2};
        sample_data.variables{end}.data         = sample_data.variables{end}.typeCastFunc(vars{i, 3});
        sample_data.variables{end}.comment      = vars{i, 4};
    else
        vname = vars{i, 3};
        if isfield(data, vname)
            sample_data.variables{end+1}.name         = vars{i, 1};
            sample_data.variables{end}.typeCastFunc = str2func(netcdf3ToMatlabType(imosParameters(vars{i, 1}, 'type')));
            sample_data.variables{end}.dimensions   = vars{i, 2};
            sample_data.variables{end}.data         = sample_data.variables{end}.typeCastFunc(data.(vname));
            sample_data.variables{end}.comment      = vars{i, 4};
            sample_data.variables{end}.coordinates = 'TIME LATITUDE LONGITUDE NOMINAL_DEPTH';
        end
    end
end

for i=1:numel(sample_data.variables)
    if strcmpi(vars{i, 1}, 'PRES_REL')
        sample_data.variables{i}.applied_offset = sample_data.variables{i}.typeCastFunc(-gsw_P0/10^4); % (gsw_P0/10^4 = 10.1325 dbar)
    end
    
    if any(strcmpi(vars{i, 1}, {'VCUR', 'UCUR', 'CDIR', 'HEADING'}))
        sample_data.variables{i}.compass_correction_applied = magDec;
    end
end

end

%%
function direction = getDirectionFromUV(uvel, vvel)
% direction is in degrees clockwise from north
direction = atan(abs(uvel ./ vvel)) .* (180 / pi);

% !!! if vvel == 0 we get NaN !!!
direction(vvel == 0) = 90;

se = vvel <  0 & uvel >= 0;
sw = vvel <  0 & uvel <  0;
nw = vvel >= 0 & uvel <  0;

direction(se) = 180 - direction(se);
direction(sw) = 180 + direction(sw);
direction(nw) = 360 - direction(nw);
end

%%
function [data, header, cfg] = readS4file(filename)
%READS4FILE Read S4 file and extract header and data info. Due to slight 
% diffences in the files (and lack of documentation and enough examples to 
% clarify) header information my not entirely be the same.

[filePath, fileRadName, fileExt] = fileparts(filename);
if strcmpi(fileExt, '.S4B')
    % due to some info (velocity and depth full scale range) not being
    % available in the binary file, attempty to attain this info elsewhere.
    
    % check if cfg file exists
    filename_cfg = [fileRadName '.CFG'];
    dir_list = dir(filePath);
    [lia, ~] = ismember(upper({dir_list.name}), upper(filename_cfg));
    if any(lia) && false % not implemented yet
        % read cfg file
       cfg = parseS4cfg(fullfile(filePath, filename_cfg));
    else
       warning('No cfg file found. Using defaults for AIMS instruments.');
       cfg = struct;
       cfg.serial = 'UNKNOWN';
       % VN range equivalent setting for VE, CSPD.
       % It's the range that is the important bit.
       cfg.VN = struct; % cm/s
       cfg.VN.range = 350; % not in binary file [50, 100, 350], important
       cfg.VN.min = -350;
       cfg.VN.max = 350;
       cfg.VN.res = 'LOW';
       cfg.CNDC = struct; % mS/cm
       cfg.CNDC.range = 70;
       cfg.CNDC.min = 70;
       cfg.CNDC.max = 70;
       cfg.CNDC.res = 'HIGH'; % available in binary file
       cfg.DEPTH = struct; % m
       cfg.DEPTH.range = 70; % [70, 1000, 6000], important
       cfg.DEPTH.min = 0;
       cfg.DEPTH.range = 70;
       cfg.CNDC.res = 'HIGH'; % available in binary file
       cfg.TEMP = struct; % deg
       cfg.TEMP.range = 50;
       cfg.TEMP.min = -5; 
       cfg.TEMP.max = 45;
       cfg.TEMP.res = 'HIGH'; % available in binary file
    end
    [header, data] = readS4B(filename, cfg);
else
    warning('S4A not fully implemented');
    [header, data] = readS4A(filename);
end

% manually add in other current representation as
% velocityMagDirPP will only add CSPD/CDIR from UCUR/VCUR
if isfield(header, 'tabular_format') && strcmp(header.tabular_format, 'SPD')
    theta= data.CDIR * pi/180.0;		% convert to radians
    data.UCUR = data.CSPD .* sin(theta);
    data.VCUR = data.CSPD .* cos(theta);
else
    data.CSPD = sqrt(data.VCUR.^2 + data.UCUR.^2);
    % I'm not sure why this is done with getDirectionUV instead of
    % cdir = atan2(data.VCUR, data.UCUR) * 180/pi; % atan2 goes positive anti-clockwise with 0 on the right side
    % cdir = -cdir + 90; % we want to go positive clockwise with 0 on the top side
    % cdir = cdir + 360*(cdir < 0); % we shift +360 for whatever is left negative
    % But to keep it as per workhorse code
    data.CDIR = getDirectionFromUV(data.UCUR, data.VCUR);
end

% if a tabular data header only ascii file was used then need to set
% some basic info manually
if ~isfield(header, 'number_of_samples')
    header.number_of_samples = size(data.UCUR, 1);
end
if ~isfield(header, 'sample_interval')
    header.sample_interval = (header.matlab_end_time - header.matlab_start_time) / (header.number_of_samples -1) * 86400.0;
end
if ~isfield(header, 'sample_duration')
    header.sample_duration = 0;
end
if ~isfield(header, 's4_version')
    header.s4_version = 'unknown';
end

% does not handle continuous sampling, only handles averaged data timestamps
data.TIME = header.matlab_start_time + (0:header.number_of_samples-1)*header.sample_interval/86400.0;

if numel(data.TIME) ~= size(data.UCUR,1)
    error('Incorrect number of samples versus stated start/end times.')
end

end

%%
function [header, data] = readS4A(filename)
%READS4A read ascii S4 file

% S4A small enough to just read it all in
fid = fopen(filename, 'rt');
fileContent = textscan(fid, '%s', 'Delimiter', '', 'Whitespace', '');
fclose(fid);

% in order to do fixed width format spec pad all lines to 80 chars
fileContent = fileContent{1};
fileContent = cellfun(@(x) pad(x, 80), fileContent, 'UniformOutput', false);

instHeaderLines = {};
iInst = 1;
while ~strncmp('-----', fileContent{iInst},5)
    instHeaderLines{iInst} = fileContent{iInst};
    iInst = iInst + 1;
end
iLastInst = iInst - 1;

dataStr = fileContent{iInst+1};
unitStr = fileContent{iInst+2};

iInst = iInst+4; % start of data
dataLines = fileContent(iInst:end);

header = parseInstrumentHeader(instHeaderLines, dataStr, unitStr);
[data, comment] = parseS4Adata(dataLines, header);

end

%%
function header = parseInstrumentHeader(headerLines, dataStr, unitStr)
%PARSEINSTRUMENTHEADER parse ascii engineering units S4A file

% an ascii S4A header can consist of both header info plus tabular data,
% an example is like this
%
% InterOcean Systems, Inc.    Model S4 Current Meter
% SERIAL NUMBER : 08782058
% HEADER : NWC02_
% CYCLE : ON FOR   0  DAYS,  0  HR,  1  MIN
%         EVERY    0  DAYS,  0  HR,  10  MIN
% AVERAGE COUNT :  120
% CHANNELS AT AVERAGE :  5  6
% TRUE AVERAGING : Enabled
% SRB COUNT :  0
% CHANNELS IN SRB :
% FMT: 3D
% SENSITIVITIES  : X =   249   Y =   251
% OFFSETS        : X =  1735   Y =  1752
% BATTERY TYPE  : A
%  DATE INSTALLED     :  3/09/02
%  HALF SECOND COUNT  :  0
% DATE OF DATA BLOCK  :  3/09/02
% TIME OF DATA BLOCK  : 13:20
% SAMPLES IN BLOCK    :  6899
% S4 VERSION : 5.153
%
% InterOcean Systems, Inc.    Model S4 Current Meter #08782058
% NWC02_                       File : 0580402.S4B
% Xoffset:  +0.00 cm/s     Yoffset:  +0.00 cm/s    Mag.Var.:   0 deg
% Start:  3/09/02 13:20:00  End:  4/26/02 11:00:00   Samp:       1 to    6899
% -------------------------------------------------------------------------------
% Speed   Dir     Hdg   Cond   S-Temp   Depth     Tilt  Salin  Density     SV
% (cm/s) (deg)   (deg) (mS/cm) (deg.C)  (meters)  (deg) (psu)  (Kg/M^3)  (M/s)
% -------------------------------------------------------------------------------
%
% S4A files will have speed/dir (or vn/ve), rest is dependent on print
% options selected on conversion.
% NOTES:
%  - For the purposed of this function everthing not data is the header.
%    In the example above the first part is what is called the "header" in 
%    the manual the second part is tabular data header (with data following).
%  - Only have examples with temp and depth so this routine
%    shouldn't be considered feature complete.

header = struct;
header.is_s4_binary = false;

colStr = strsplit(strtrim(dataStr));
unitStr = strsplit(strtrim(unitStr));

if strcmp(colStr{1},'Speed')
    header.tabular_format = 'SPD';
else
    header.tabular_format = 'VEL';
end

header.column_names = colStr;
header.column_units = unitStr;

serialExpr = 'SERIAL NUMBER : (\S+)';
titleExpr = 'HEADER : (.*)';

cycleonExpr    = 'CYCLE : ON FOR\s+(\d+)\s+DAYS,\s+(\d+)\s+HR,\s+(\d+)\s+MIN';
cycleeveryExpr = 'EVERY\s+(\d+)\s+DAYS,\s+(\d+)\s+HR,\s+(\d+)\s+MIN';

avcountExpr = 'AVERAGE COUNT :\s+(\d+)';
chavgExpr   = 'CHANNELS AT AVERAGE :\s+([\d\s]+)';
trueavExpr  = 'TRUE AVERAGING :\s?(\S+)';
srbcountExpr = 'SRB COUNT :\s+(\d+)';
srbchExpr    = 'CHANNELS IN SRB : (\S+)';
fmtExpr = 'FMT: (\S+)';

sensExpr    = 'SENSITIVITIES  : X =\s+(\d+)\s+Y =\s+(\d+)';
offsetsExpr = 'OFFSETS        : X =\s+(\d+)\s+Y =\s+(\d+)';

batttypeExpr = 'BATTERY TYPE  :\s+(\S+)';
battinstExpr = ' DATE INSTALLED     :\s+(\S+)';
battcntExpr  = ' Sample Count       :\s+(\d+)';

startBlockDateExpr = 'DATE OF DATA BLOCK  :\s+(\S+)';
startBlockTimeExpr = 'TIME OF DATA BLOCK  :\s+(\S+)';

samplesBlockExpr = 'SAMPLES IN BLOCK    :\s+(\d+)';
s4verExpr   = 'S4 VERSION :\s+(\S+)';

% no header expressions
serial2Expr = '^InterOcean.*Model (.*) \#(\w+)';
header2Expr = '(.*) File :\s+(.*)';
offset2Expr = 'Xoffset:\s+(\S+\s+cm\/s)\s+Yoffset:\s+(\S+\s+cm\/s)\s+Mag\.Var\.:\s+(\d+)';
start2Expr = 'Start: (.*) End: (.*) Samp:\s+(\d+)\s+to\s+(\d+)';

exprs = {...
    serialExpr   titleExpr     ...
    cycleonExpr      cycleeveryExpr   ...
    avcountExpr     chavgExpr trueavExpr srbcountExpr srbchExpr fmtExpr...
    sensExpr     offsetsExpr   ...
    batttypeExpr     battinstExpr battcntExpr ...
    startBlockDateExpr    startBlockTimeExpr   ...
    samplesBlockExpr     s4verExpr ...
    serial2Expr header2Expr offset2Expr start2Expr};

for k = 1:length(headerLines)
    % try each of the expressions
    for m = 1:length(exprs)
        % until one of them matches
        tkns = regexp(headerLines{k}, exprs{m}, 'tokens');
        if ~isempty(tkns)
            switch m
                case 1 % serialExpr
                    header.serial = tkns{1}{1};
                    
                case 2 % titleExpr
                    header.title = strtrim(tkns{1}{1});
                    
                case 3 % cycleonExpr, convert to seconds
                    header.sample_duration = str2double(tkns{1}{1})*86400 + ...
                        str2double(tkns{1}{2})*3600.0 + ...
                        str2double(tkns{1}{3})*60.0;
                    
                case 4 % cycleeveryExpr
                    header.sample_interval = str2double(tkns{1}{1})*86400 + ...
                        str2double(tkns{1}{2})*3600.0 + ...
                        str2double(tkns{1}{3})*60.0;
                    
                case 5 % avcountExpr
                    header.sample_naverage = str2double(tkns{1}{1});
                    
                case 6 % chavgExpr
                    header.channels_avg = strtrim(tkns{1}{1});
                    
                case 7 % trueavExpr
                    header.true_averaging = tkns{1}{1};
                    
                case 8 % srbcountExpr
                    header.srb_count = str2double(tkns{1}{1});
                    
                case 9 % srbchExpr
                    header.srb_channels = tkns{1}{1};
                    
                case 10 % fmtExpr
                    header.format = tkns{1}{1};
                    
                case 11 % sensExpr X,Y
                    header.sensitivities = [tkns{1}{1} tkns{1}{2}];
                    
                case 12 % offsetsExpr X,Y
                    header.offsets = [tkns{1}{1} tkns{1}{2}];
                    
                case 13 % batttypeExpr
                    header.battery_type = tkns{1}{1};
                    
                case 14 % battinstExpr
                    header.battery_install_date = tkns{1}{1};
                    
                case 15 % battcntExpr
                    header.battery_sample_count = tkns{1}{1};
                    
                case 16 % startBlockDateExpr
                    header.start_block_MMDDYY = strtrim(tkns{1}{1});
                    
                case 17 % startBlockTimeExpr
                    header.start_block_HHMMSS = strtrim(tkns{1}{1});
                    
                case 18 % samplesExpr
                    header.samples_in_block = tkns{1}{1};
                    
                case 19 % s4verExpr
                    header.s4_version = tkns{1}{1};
                    
                case 20 % serial2Expr
                    % serial2Expr = 'InterOcean Systems, Inc.    Model (.*) #(\d+)  Avg:\s+(\d+)';
                    header.make = 'InterOcean Systems, Inc.';
                    header.model = strtrim(tkns{1}{1});
                    header.serial = strtrim(tkns{1}{2});
                    
                case 21 % header2Expr
                    header.title = strtrim(tkns{1}{1});
                    header.input_file = strtrim(tkns{1}{2});
                    
                case 22 % offset2Expr
                    %offset2Expr = 'Xoffset:\s+(\S+)\s+cm\/s\s+Yoffset:\s+(\S+)\s+cm\/s\s+Mag\.Var\.:\s+(\d+)';
                    header.x_offset = strtrim(tkns{1}{1});
                    header.y_offset = strtrim(tkns{1}{2});
                    header.mag_var = str2double(strtrim(tkns{1}{3}));
                    
                case 23 % start2Expr
                    % when exported as engineering unit S4A option to only
                    % output a range of samples (a way of trimming in/out
                    % water times. So you need the 'Start: etc' line
                    header.samples_start_mmddyyHHMMSS = strtrim(tkns{1}{1});
                    header.samples_end_mmddyyHHMMSS = strtrim(tkns{1}{2});
                    header.samples_start_index = str2double(tkns{1}{3});
                    header.samples_end_index = str2double(tkns{1}{4});
                    header.number_of_samples = header.samples_end_index - header.samples_start_index + 1;
                    header.matlab_start_time = datenum(header.samples_start_mmddyyHHMMSS, 'mm/dd/yy HH:MM:SS');
                    header.matlab_end_time = datenum(header.samples_end_mmddyyHHMMSS, 'mm/dd/yy HH:MM:SS');
            end
        end
    end
    
end

%
if isfield(header, 'start_block_MMDDYY')
    header.matlab_start_block_time = datenum([header.start_block_MMDDYY ' ' header.start_block_HHMMSS], 'mm/dd/yy HH:MM');
end

end

%%
function cfg = parseS4cfg(filename)
%PARSES4CFG parse an S4 cfg file which hopefully has correct ranges, 
% especially for DEPTH if installed.
% 
% If you don't have a cfg but are pretty confident about the ranges, create
% a short cfg file like below. Note that the only thing I'm confident about
% is the range parts. Resolution for CNDC/TEMP/DEPTH are encoded in the 
% S4 binary, but the full depth range scaling factor is not.
%
% 04430794  %%  1: serial
% 0         %%  2: unknown
% 0         %%  3: unknown
% 0         %%  4: unknown
% 0         %%  5: unknown
% 0         %%  6: unknown
% 0         %%  7: unknown
% 0         %%  8: unknown
% 0         %%  9: unknown
% 350       %% 10: VN/VE,CSPD range
% 70        %% 11: CNDC range
% 70        %% 12: DEPTH range, this is important to get right
% LOW       %% 13: ? CNDC res
% LOW       %% 14: ? TEMP res
% LOW       %% 15: ? DEPTH res
%
% long cfg looks like
% 
% 04430794  %%  1: serial
% 0         %%  2: unknown
% 0         %%  3: unknown
% 0         %%  4: unknown
% 0         %%  5: unknown
% 0         %%  6: unknown
% 0         %%  7: unknown
% 0         %%  8: unknown
% 0         %%  9: unknown
%   Vn      %% variable
%  STD      %% res [STD, HIGH]
% cm/s      %% units
%  0        %% unsure
%  350      %% range
% -350      %% min
%  350      %% max
%   Ve  
%  STD
% cm/s
%  0 
%  350 
% -350 
%  350 

fid = fopen(filename, 'rt');
cfgContent = textscan(fid, '%s', 'Delimiter', '', 'Whitespace', '');
fclose(fid);
cfgContent = cfgContent{1};

cfg = struct;
if numel(cfgContent) < 16
    % short cfg
    % have only seen one example so far so not sure if this is correct
    cfg.serial = strtrim(cfgContent{1});
    cfg.VN = struct; % cm/s
    cfg.VN.range = str2double(cfgContent{10});

    cfg.CNDC = struct; % mS/cm
    cfg.CNDC.range = str2double(cfgContent{11});
    cfg.CNDC.res = strtrim(cfgContent{13}); % ?

    cfg.DEPTH = struct; % m
    cfg.DEPTH.range = str2double(cfgContent{12});
    cfg.DEPTH.res = strtrim(cfgContent{15});
else
    % long cfg
    % have seen many examples so far, still not sure if this is correct
    cfg.serial = strtrim(cfgContent{1});
    
    tf = contains(cfgContent, 'Vn');
    if any(tf)
       ind = find(tf);
        cfg.VN = struct; % cm/s
        cfg.VN.res = strtrim(cfgContent{ind+1});
        cfg.VN.range = str2double(cfgContent{ind+4});
        cfg.VN.min = str2double(cfgContent{ind+5});
        cfg.VN.max = str2double(cfgContent{ind+6});
    end
    
    tf = contains(cfgContent, 'Cond');
    if any(tf)
       ind = find(tf);
        cfg.CNDC = struct; % cm/s
        cfg.CNDC.res = strtrim(cfgContent{ind+1});
        cfg.CNDC.range = str2double(cfgContent{ind+4});
        cfg.CNDC.min = str2double(cfgContent{ind+5});
        cfg.CNDC.max = str2double(cfgContent{ind+6});
    end

    tf = contains(cfgContent, 'S-Temp');
    if any(tf)
       ind = find(tf);
        cfg.TEMP = struct; % cm/s
        cfg.TEMP.res = strtrim(cfgContent{ind+1});
        cfg.TEMP.range = str2double(cfgContent{ind+4});
        cfg.TEMP.min = str2double(cfgContent{ind+5});
        cfg.TEMP.max = str2double(cfgContent{ind+6});
    end

    tf = contains(cfgContent, 'Depth');
    if any(tf)
       ind = find(tf);
        cfg.DEPTH = struct; % cm/s
        cfg.DEPTH.res = strtrim(cfgContent{ind+1});
        cfg.DEPTH.range = str2double(cfgContent{ind+4});
        cfg.DEPTH.min = str2double(cfgContent{ind+5});
        cfg.DEPTH.max = str2double(cfgContent{ind+6});
    end
end

end

%%
function [data, comment] = parseS4Adata(dataLines, header)
%PARSES4ADATA parse converted ascii tabular data. Note not all variables
%nor special record blocks are handled.

comment = struct;
data = struct;

% special record block not handled yet
srbLines = {};
if isfield(header, 'srb_count') && (header.srb_count > 0)
    indSrb = header.srb_count+1:header.srb_count+1:length(dataLines);
    srbLines = dataLines(indSrb);
    dataLines(indSrb) = [];
else
    % just in case passed in S4A without the block header
    tf = contains(dataLines, '/');
    dataLines = dataLines(~tf);
end

% The only way I could find to do fixed width processing is to use char
% format (rather than float, which has issues with whitespace). But this
% means you need to know the boundaries of every variable.
if strcmp(header.tabular_format, 'SPD')
    % Speed, Dir, Hdg, Cond, S-Temp, Depth, Tilt, Salin, Density, SV
    fmt = '%5c %6c %8c %8c %8c %12c %6c %8c %7c %9c';
else
    % Vn, Ve, Vref, Hx, Hy, Cond, S-Temp, Depth, Tiltx, Tilty
    % Do not have enough examples to separate out Vref, Hx, Hy, Tiltx,
    % Tilty
    fmt = '%6c %9c %21c %8c %8c %12c %17c';
end

C = cell2mat(cellfun(@(x) str2double(textscan(x, fmt, 'Whitespace', '')), dataLines, 'UniformOutput', false));

if strcmp(header.tabular_format, 'SPD')
    % Speed, Dir
    data.CSPD = C(:,1) / 100.0; % cm/s -> m/s
    data.CDIR = C(:,2);
    % Hdg
    v = C(:,3);
    iHave = ~any(isnan(v));
    if iHave
        data.HEADING = v; % deg
    end
    % Cond
    v = C(:,4);
    iHave = ~any(isnan(v));
    if iHave
        data.CNDC = v / 10.0; % mS/cm -> S/m
    end
    % S-Temp
    v = C(:,5);
    iHave = ~any(isnan(v));
    if iHave
        data.TEMP = v; % deg C
    end
    % Depth
    v = C(:,6);
    iHave = ~any(isnan(v));
    if iHave
        data.DEPTH = v; % m
    end
    % Tilt
    v = C(:,7);
    iHave = ~any(isnan(v));
    if iHave
        data.TILT = v; % deg
    end
    % Salin
    v = C(:,8);
    iHave = ~any(isnan(v));
    if iHave
        data.PSAL = v; % psu
    end    
    % Density
    v = C(:,9);
    iHave = ~any(isnan(v));
    if iHave
        data.DENS = v; %kg/m^3
    end    
    % SV
    v = C(:,10);
    iHave = ~any(isnan(v));
    if iHave
        data.SSPD = v; % m/s
    end      
else
    % Vn, Ve
    data.UCUR = C(:,2) / 100.0; % cm/s -> m/s
    data.VCUR = C(:,1) / 100.0;
    % Cond
    v = C(:,4);
    iHave = ~any(isnan(v));
    if iHave
        data.CNDC = v / 10.0; % mS/cm -> S/m
    end
    % S-Temp
    v = C(:,5);
    iHave = ~any(isnan(v));
    if iHave
        data.TEMP = v; % deg C
    end
    % Depth
    v = C(:,6);
    iHave = ~any(isnan(v));
    if iHave
        data.DEPTH = v; % m
    end
end

end

%%
function [header, data] = readS4B(filename, cfg)
%READS4B read and parse binary S4B file.

% read in the whole file into 'data'
fid = -1;
try
    fid = fopen(filename, 'rb');
    uint8data = fread(fid, Inf, '*uint8','l');
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow e;
end

[~, ~, cpuEndianness] = computer;

header = struct;
header.is_s4_binary = true;
% cannot see if model is encoded in binary file so set manually
header.model = 'S4';

% from S4Bfile.doc contained in the installer package.
%
% The disk file is 2 bytes/record random access.  The first 61
% records are called the header and tell how to interpret the
% remainder of the file.

% record 1-4 :Serial number
block = uint8data(1:8);
header.serial = char(block)';

% record 5-19 : Title (17-19 are Threshold for Adaptive Mode Recording)
block = uint8data(9:38);
header.title = char(block(2:2:end))';

header.amr_threshold = uint8data(33:38);

% record 20-22 : On time
block = uint8data(39:44);
header.cycle_on_DDHHMM = bytecast(block, 'L', 'uint16', cpuEndianness);
header.sample_duration = header.cycle_on_DDHHMM(1)*86400 + header.cycle_on_DDHHMM(2)*3600 + header.cycle_on_DDHHMM(3)*60;

% record 23-25 : Cycle time
block = uint8data(45:50);
header.cycle_every_DDHHMM = bytecast(block, 'L', 'uint16', cpuEndianness);
header.sample_interval = header.cycle_every_DDHHMM(1)*86400 + ...
    header.cycle_every_DDHHMM(2)*3600.0 + ...
    header.cycle_every_DDHHMM(3)*60.0;

% record 26-27 : Avg count
block = bytecast(uint8data(51:54), 'L', 'uint16', cpuEndianness);
header.sample_naverage = block(1)*256 + block(2);

% analog channels
% #, name, res, units, zero_value, full_scale_value
% 1, Vref, LOW, 'V', 0, 5, standard
% 2, Hx, LOW, '', 0, 5, standard
% 3, Hy, LOW, '', 0, 5, standard
% 4, Cond, HIGH, 'mS/cm', 0, 70, optional
% 5, S-Temp, HIGH, 'deg.C', -5, 45, optional
% 6, Depth, HIGH, 'meters, 0, 70, optional (fsv instrument dependent)
% 7, Tiltx, LOW, 'deg', 0, 64, optional
% 8, Tilty, LOW, 'deg', 0, 64, optional

% record 28 : Analog channels at Average Time (LSB = CH. 1, MSB = CH. 8)
block = bytecast(uint8data(55:56), 'L', 'uint16', cpuEndianness);
header.channels_at_avg_time = block;

% the number of analog channels recorded at Average time.
% Take record 28 and count the number of bits set.
CAS = sum(bitget(header.channels_at_avg_time,1:16));

% record 29 :SRB count
header.srb_count = bytecast(uint8data(57:58), 'L', 'uint16', cpuEndianness);

% BC - the number of readings between SRBs, from record 29
BC = header.srb_count;

% record 30 : Format byte
% for firmware >2.397 (standard sampling S4) and >2.597 (adaptive sampling S4)
% bit
% 7(msb), Adaptive, 0/1=disabled/enabled
% 6, Adaptive, 0/1=current/wave
% 5, high-res depth, 0/1=disabled/enabled
% 4, high-res temperature, 0/1=disabled/enabled
% 3, high-res conductivity, 0/1=disabled/enabled
% 2, high-res board, 0/1=not installed/installed
% 1, tilt, 0/1=disabled/enabled
% 0(lsb), reserved, 0 always?

header.format = bytecast(uint8data(59:60), 'L', 'uint16', cpuEndianness);

% assume S4 is std(low) res (10-bit) instrument, check if hires (14-bit)
% board has been installed.
stdres_cond = true;
stdres_temp = true;
stdres_depth = true;
if bitget(header.format, 3, 'uint8')
    stdres_cond = ~bitget(header.format, 4, 'uint8');
    stdres_temp = ~bitget(header.format, 5, 'uint8');
    stdres_depth = ~bitget(header.format, 6, 'uint8');
end
header.stdres_cond = stdres_cond;
header.stdres_temp = stdres_temp;
header.stdres_depth = stdres_depth;

% record 31 : Analog Channels at SRB Time (LSB = CH. 1, MSB = CH. 8)
block = double(uint8data(61:62));
header.channels_at_srb_time = block(1)*256 + block(2);

% CSS- the number of analog channels recorded at SRB time.  Take
% record 31 and count the number of bits set.
CSS = sum(bitget(header.channels_at_srb_time,1:16));

% record 32-33 : X sensitivity
block = bytecast(uint8data(63:66), 'L', 'uint16', cpuEndianness);
header.x_sensitivity = block(1)*256 + block(2);

% record 34-35 : Y sensitivity
block = bytecast(uint8data(67:70), 'L', 'uint16', cpuEndianness);
header.y_sensitivity = block(1)*256 + block(2);

% record 36-37 : X offset
block = bytecast(uint8data(71:74), 'L', 'uint16', cpuEndianness);
header.x_offset = block(1)*256 + block(2);

% record 38-39 : Y offset
block = bytecast(uint8data(75:78), 'L', 'uint16', cpuEndianness);
header.y_offset = block(1)*256 + block(2);

% record 40 : Battery type
header.battery_type = char(uint8data(79));

% record 41-43 : Battery installation date
block = uint8data(81:86);
header.battmmddyy = bytecast(block, 'L', 'uint16', cpuEndianness);

% record 44-47 : Half second count
block = uint8data(87:94);

% record 48-50 : Bytes written count
block = uint8data(95:100);
bytecast(block, 'L', 'uint16', cpuEndianness);

% record 51-53 : Start date
block = uint8data(101:106);
header.startmmddyy = bytecast(block, 'L', 'uint16', cpuEndianness);

% record 54-55 : Start time
block = uint8data(107:110);
header.startHHMM = bytecast(block, 'L', 'uint16', cpuEndianness);

start_yy = header.startmmddyy(3);
if start_yy > 80
    start_yy = start_yy + 1900;
else
    start_yy = start_yy + 2000;
end
start_mm = header.startmmddyy(1);
start_dd = header.startmmddyy(2);
start_HH = header.startHHMM(1);
start_MM = header.startHHMM(2);
header.matlab_start_time = datenum(start_yy, start_mm, start_dd, start_HH, start_MM, 0);

% record 56 : Number of readings mod 32768
block = uint8data(111:112);
r56 = bytecast(block, 'L', 'uint16', cpuEndianness);

% record 57 : Number of readings * 32768
block = uint8data(113:114);
r57 = bytecast(block, 'L', 'uint16', cpuEndianness);

header.samples_in_block = r56 + r57*32768;
header.number_of_samples = header.samples_in_block;

% record 58 : Number of SRBs
header.number_of_srb = bytecast(uint8data(115:116), 'L', 'uint16', cpuEndianness);

% record 59-60 : Version #
header.s4_version = char(uint8data(117:120))';

% record 61 : Spare
header.spare = uint8data(121:122);

% The starting record number of a reading N can be determined by:
% if the data has no SRBs (BC=0)
%         REC = 62 + (N-1) * (2+CAS)
% else
%         REC = 62 + (N-1) * (2+CAS)  + INT((N-1)/BC) * (5+CSS)
N = 1:header.samples_in_block;
if BC == 0
    REC = 62 + (N-1)*(2+CAS);
    SRB = [];
else
    REC = 62 + (N-1)*(2+CAS)  + (floor((N-1)/BC) * (5+CSS));
    SRB = 62 + (1:header.number_of_srb)*BC*(2+CAS);
end

%vel_fsr=350;
vel_fsr = cfg.VN.range;
switch vel_fsr
    case 350
        vel_fac = 5.0;
        
    case 100
        vel_fac = 35.0;
        
    case 50
        vel_fac = 17.5;
        
    otherwise
        disp('Unknown velocity full scale range.')
end

%
iDataBlocks = false(size(uint8data));

% byte offsets into uint8data for the data blocks
r1 = REC*2-1;
r2 = r1+((2+CAS)*2)-1;

for j=1:length(r1)
    iDataBlocks(r1(j):r2(j)) = true;
end

dataSection = uint8data(iDataBlocks);
clear iDataBlocks;
dataSection = bytecast(dataSection, 'L', 'int16', cpuEndianness);
dataSection = reshape(dataSection, 2+CAS, header.samples_in_block)';

nnn = dataSection(:,1);
eee = dataSection(:,2);

vn = zeros([header.samples_in_block 1]);
ve = zeros([header.samples_in_block 1]);

iVel = abs(nnn) >= 2047;
vn(iVel) = (nnn(iVel) - 4096.0) / vel_fac;
vn(~iVel) = nnn(~iVel) / vel_fac;

iVel = abs(eee) >= 2047;
ve(iVel) = (eee(iVel) - 4096.0) / vel_fac;
ve(~iVel) = eee(~iVel) / vel_fac;

data = struct;
data.VCUR = vn / 100.0; % m/s
data.UCUR = ve / 100.0; % m/s

header.hasHdg = false;

if CAS > 0 % analog channels present
    analogData = dataSection(:,3:end);
    analogChannels = find(flip(dec2bin(header.channels_at_avg_time,8))=='1');
    iAnalogChannels = 1:numel(analogChannels);
    
    for j = 1:numel(analogChannels)
        iAnalog = iAnalogChannels(find(analogChannels(j)==analogChannels));
        switch analogChannels(j)
            case 1 % voltage ref
                data.VREF = (5.0 * analogData(:,iAnalog)) / 1023.0;
                
            case 2 %Hx
                data.HX = analogData(:,iAnalog) - 512;
                
            case 3 %Hy
                data.HY = analogData(:,iAnalog) - 512;
                
            case 4 % cond
                if stdres_cond
                    fac = 10.0;
                else
                    fac = 100.0;
                end
                data.CNDC = analogData(:,iAnalog) / fac;
                data.CNDC = data.CNDC / 10.0; % convert mS/cm -> S/m
                
            case 5 % temp
                if stdres_temp
                    fac = 1023.0;
                else
                    fac = 16383.0;
                end
                data.TEMP = (50.0 * analogData(:,iAnalog) / fac) - 5.0; % degC
                
            case 6 % depth
                % how do you test for 1000dbar or deep water 6000dbar range S4?
                % And is dcal really full scale range of depth (m) or is it
                % dbar and makes the assumption of 1 dbar = 1 m, and so
                % DEPTH is really PRES>
                % Ideally would like to just have PRES and let the toolbox
                % calculate DEPTH.
                dcal = cfg.DEPTH.range;
                if stdres_depth
                    fac = 1023.0;
                else
                    fac = 16383.0;
                end
                data.DEPTH = dcal * analogData(:,iAnalog) / fac;
                
            case 7 % tiltx
                data.TILTX = analogData(:,iAnalog) / 16.0;
                
            case 8 % tilty
                data.TILTY = analogData(:,iAnalog) / 16.0;
        end
    end
    
    if all(ismember([2 3], analogChannels))
        data.HEADING = atan2d(data.HY,data.HX); % degrees
    end
end

end
