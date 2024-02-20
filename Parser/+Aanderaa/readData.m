function [data, xattrs] = readData(dat_filename, deviceInfo)
% readData read raw aanderaa data (either from transcribed tape or DSU
% download) using information in devicdeInfo structure.
%
% This function is able to read in a .raw data file either from transcribed 
% tape or DSU download, not some of the raw version that have had extra
% header information added to the top.
%
% Inputs:
%   dat_filename - filename of data file.
%   deviceInfo   - struct with instruement setup info, coefficients, etc.
%
% Outputs:
%   sample_data - Struct containing sample data.

%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%

%
% Copyright (c) 2024, Australian Ocean Data Network (AODN) and Integrated
% Marine Observing System (IMOS).
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
%     * Redistributions of source code must retain the above copyright notice,
%       this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in the
%       documentation and/or other materials provided with the distribution.
%     * Neither the name of the AODN/IMOS nor the names of its contributors
%       may be used to endorse or promote products derived from this software
%       without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

data = struct();

xattrs = containers.Map('KeyType','char','ValueType','any');

% data column index mapping
column_mapping = containers.Map('KeyType','char','ValueType','any');
switch deviceInfo.instrument_model
    case {'WLR5', 'WLR7'}
        column_mapping('REF') = 1;
        column_mapping('TEMP') = 2;
        column_mapping('PRES') = 3; % N3
        column_mapping('PRES2') = 4; % N4
        % what is column 5 used for in WLR7?
        
    case {'RCM4', 'RCM5', 'RCM7'}
        column_mapping('REF') = 1;
        column_mapping('TEMP') = 2;
        column_mapping('TEMP_LOW') = 2;
        column_mapping('TEMP_WIDE') = 2;
        column_mapping('TEMP_HIGH') = 2;
        column_mapping('CNDC') = 3;
        column_mapping('PRES') = 4;
        column_mapping('CDIR_MAG') = 5;
        column_mapping('CSPD') = 6;
end

% data files are comparatively small nowadays, so just read entire file
% have allowed user to add comments after a '#'
fid     = -1;
lines = {};
try
    fid = fopen(dat_filename, 'rt');
    if fid == -1, error(['couldn''t open ' dat_filename 'for reading']); end
    % read in the data
    lines = textscan(fid, '%s', 'Delimiter', '\r\n', 'WhiteSpace', '', 'CommentStyle','#', 'MultipleDelimsAsOne', false);
    lines = lines{1};
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end

% some older files might have already been hand edited with some info
% time information added between '***' markers, treet these as comments as
% well
lines =  textscan(strjoin(lines, '\n'), '%s', 'Delimiter', '\r\n', 'WhiteSpace', '', 'CommentStyle','***', 'MultipleDelimsAsOne', false);
lines = lines{1};

% common on tape reads to have possibly bad reads, if data contains
% these only consider data up until that point. An example might be
% '0424 0752 0527 0006 0000* 0424 0752 0517 0006 0000* 0424 0752 0527 0006 0000'
tkns = regexp(lines, '\d+\*', 'match');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    lines = lines(1:ind(1)-1);
end

if deviceInfo.has_time_base
    % have to deal with time base lines
    % c     - first line is start time signal imc,iyr,imo,ida,iho,imi in format
    % c     (i4,5(1x,i4)) with the numbers representing the model code, year,
    % c     month, day, hour, minute.
    % c     - then raw data n1,n2,n3,n4,n5 in the format (i4,4(1x,i4))
    % c     - following the data for 0000h on each day is another time signal of
    % c     format identical to the first one.  note that the time that the
    % c     time signal is output can drift.
    tkns = regexp(lines, '^0007', 'match'); % time base code line start
    idx_timebase = ~cellfun(@isempty, tkns);
    timebaselines = lines(idx_timebase);
    datalines = lines(~idx_timebase);
    
    ind_timebase = find(idx_timebase);
    start_line = strtrim(timebaselines{1});
    dev_start_time = deviceInfo.start_time;
    % model, yearish, month, day, hour, minute
    % eg '0007 0001 0011 0003 0013 0000'
    % but for the first entry the minutes entry will always be zero even if
    % its not. Note for the rest of timebase lines they are written at
    % 00:00:00 of each day.
    st = str2double(strsplit(start_line, ' '));
    st_year = st(2);
    st_month = st(3);
    st_day = st(4);
    st_hour = st(5);
    st_minute = st(6);
    if st_year < 40
        st_year = st_year + 2000;
    else
        st_year = st_year + 1900;
    end
    inst_start_time = sprintf('%4.4d/%2.2d/%2.2dT%2.2d:%2.2d', st_year, st_month, st_day, st_hour, st_minute);
    
else
    datalines = lines;
end
nsamples = numel(datalines);

vname = 'TIME';
data.(vname) = datenum(deviceInfo.start_time, 'YYYY/MM/DDThh:mm') + ((0:nsamples-1)*deviceInfo.sample_interval)/86400;
data.(vname) = data.(vname)(:);
xattrs('TIME') = struct('comment', 'TIME');
    
idata = sscanf(strjoin(datalines, ' ')', '%d', [deviceInfo.ncols numel(datalines)])';

% reference signal, should match what is in the cal file, new cal style only
ref = idata(:,1);
if deviceInfo.is_new_style_cal_file
   if ref(1) ~= deviceInfo.header.REFERENCE.value
      warning('Instrument reference signal value different to calibraion reference signal value.');
   end
end

% if a particular temperature range has been selected.
if isfield(deviceInfo, 'temperature_range')
    temperature_range = deviceInfo.temperature_range;
else
    temperature_range = 'TEMP';
end
vname = 'TEMP';
if isfield(deviceInfo.coeff, temperature_range)
    ind = column_mapping(vname);
    coeff = deviceInfo.coeff.(temperature_range);
    raw_data = idata(:, ind);
    data.(vname) = coeff(1) + coeff(2)*raw_data + coeff(3)*power(raw_data, 2) + coeff(4)*power(raw_data, 3);
    xattrs(vname) = struct('units', 'degree');
else
    error('Inf file temperature_range does not match available coeffs.');
end

vname = 'PRES';
if isfield(deviceInfo.coeff, vname)
    ind = column_mapping(vname);
    coeff = deviceInfo.coeff.(vname);
    if contains(deviceInfo.instrument_model, {'WLR5', 'WLR7'})
        raw_data = idata(:, ind)*1024 + idata(:, ind+1);
    else
        raw_data = idata(:, ind);
    end
    data.(vname) = coeff(1) + coeff(2)*raw_data + coeff(3)*power(raw_data, 2) + coeff(4)*power(raw_data, 3);
    data.(vname) = data.(vname) * 0.68948; % convert psia to dbar
    xattrs('PRES') = struct('units', 'dbar');
end

vname = 'CNDC';
if isfield(deviceInfo.coeff, vname)
    ind = column_mapping(vname);
    coeff = deviceInfo.coeff.(vname);
    raw_data = idata(:, ind);
    data.(vname) = coeff(1) + coeff(2)*raw_data + coeff(3)*power(raw_data, 2) + coeff(4)*power(raw_data, 3);
    data.(vname) = data.(vname) * 0.10; % mmho/cm -> S/m, 1 mho/cm = 100 S/m
    xattrs(vname) = struct('units', 'S m-1');
end

vname = 'CDIR_MAG';
if isfield(deviceInfo.coeff, vname)
    ind = column_mapping(vname);
    coeff = deviceInfo.coeff.(vname);
    raw_data = idata(:, ind);
    data.(vname) = coeff(1) + coeff(2)*raw_data + coeff(3)*power(raw_data, 2) + coeff(4)*power(raw_data, 3);
    xattrs(vname) = struct('units', 'degree');
end

vname = 'CSPD';
if isfield(deviceInfo.coeff, vname)
    ind = column_mapping(vname);
    coeff = deviceInfo.coeff.(vname);
    % c calculate speed calibration coefficient for rcm4's and rcm5's
    % c depends on the revolutions/count value and the integration time
    % and it seems that typically coeff(1) will be 1.1 with the kit and 1.5
    % without, and coeff(3)==coeff(4)==0.0
    if contains(deviceInfo.instrument_model, {'RCM4', 'RCM5'})
        warning('RCM4 and RCM5 CSPD code not fully tested.');
        if deviceInfo.revolutions_per_count ~= 0
            % c coeff(3,6)=42*float(irc)/(tdel*60.0)
            % m sb = 42.0*rpc/(60.*simins);
            rev_scale = 42.0;
            if deviceInfo.guard_kit_fitted
                rev_scale = 46.9;
            end
            coeff(2) = rev_scale* deviceInfo.revolutions_per_count / deviceInfo.sample_interval;
        end
    end
    raw_data = idata(:, ind);
    data.(vname) = coeff(1) + coeff(2)*raw_data + coeff(3)*power(raw_data, 2) + coeff(4)*power(raw_data, 3);
    data.(vname) = data.(vname) / 100; % cm/s -> m/s
    xattrs(vname) = struct('units', 'm s-1');
end

end