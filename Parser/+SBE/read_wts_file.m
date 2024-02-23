function [data, xattrs] = read_wts_file( header, wts_filename, mode)
%read_wts_file reads surface wave time series statistics file (.wts)
% created from the .wb file in Process Wave Burst Data. 

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
%

% from "manual-26plus_019.0.pdf", pg 119
% A .wts file is created from the .wb file in Process Wave Burst Data. 
% A sample surface wave time series statistics file is shown below:
%
% SBE 26plus
% * 0 39714178 1.00 1024 109 5.666 4.466 1024.431
% 6.860774e-003 6.892497e+001 1.972292e-001 7.431193e+000
% 6.293907e-001 3.115848e-001 9.138889e+000 4.114119e-001 6.293907e-001
% * 1 39724978 1.00 1024 112 6.377 5.177 1024.431
% 6.632170e-003 6.662836e+001 1.914052e-001 7.223214e+000
% 4.505061e-001 3.078597e-001 9.000000e+000 3.902955e-001 4.505061e-001
%
% * First line - * flags the beginning of the data for a wave burst. Line
% contains (in order):
%  - Wave burst number
%  - Start of wave burst (seconds since January 1, 2000)
%  - Wave integration time (seconds)
%  - Number of points in the wave burst
%  - Number of individual waves found
%  - Water depth (meters)
%  - Pressure sensor depth (meters)
%  - Density (kg/m^3 )
% *  Second line contains (in order):
%  - Total variance of time series (meters^2 )
%  - Total energy of time series (joules / meters^2 )
%  - Average wave height (meters)
%  - Average wave period (seconds)
% * Third line contains (in order):
%  - Maximum wave height (meters)
%  - Significant wave height (meters) [average height of largest
%    1/3 waves]
%  - Significant period (seconds) [average period of largest 1/3 waves]
%  - H_1/10 (meters) [average height of largest 1/10 waves] -
%    If less than 10 waves, H1/10 is set to 0
%  - H_1/100 (meters) [average height of largest 1/100 waves] -
%    If less than 100 waves, H1/100 is set to 0

% wts is relatively small so just read it all in
fid     = -1;
all_lines = {};
try
    fid = fopen(wts_filename, 'rt');
    if fid == -1, error(['couldn''t open ' wts_filename 'for reading']); end
    
    % read in the data
    all_lines = textscan(fid, '%s', 'Whitespace', '\r\n', 'CommentStyle','#');
    all_lines = all_lines{1};
    fclose(fid);
catch e
    if fid ~= -1, fclose(fid); end
    rethrow(e);
end

if ~strcmp(all_lines{1}, 'SBE 26plus')
    error('read_wts_file: wts file does not appear to an SBE 26plus file.');
end


ind = find(~cellfun(@isempty, strfind(all_lines, '*', 'ForceCellOutput', true)));
nSamples = numel(ind);

data = struct();
data.burst_number = nan([nSamples, 1]); %  - Wave burst number
data.TIME = nan([nSamples, 1]); %  - Start of wave burst (seconds since January 1, 2000)
data.integration_time = nan([nSamples, 1]); %  - Wave integration time (seconds)
data.number_points = nan([nSamples, 1]); %  - Number of points in the wave burst
data.number_waves_found = nan([nSamples, 1]); %  - Number of individual waves found
data.water_depth = nan([nSamples, 1]); %  - Water depth (meters)
data.pressure_sensor_depth = nan([nSamples, 1]); %  - Pressure sensor depth (meters)
data.density = nan([nSamples, 1]); %  - Density (kg/m^3)

data.total_variance = nan([nSamples, 1]); %  - Total variance of time series (meters^2 )
data.total_energy = nan([nSamples, 1]); %  - Total energy of time series (joules / meters^2 )
data.WMSH = nan([nSamples, 1]); %  - Average wave height (meters)
data.WPSM = nan([nSamples, 1]); %  - Average wave period (seconds)

data.WMXH = nan([nSamples, 1]); %  - Maximum wave height (meters)
data.WHTH = nan([nSamples, 1]); %  - Significant wave height (meters) [average height of largest 1/3 waves]
data.WPTH = nan([nSamples, 1]); %  - Significant period (seconds) [average period of largest 1/3 waves]
data.WHTE = nan([nSamples, 1]); %  - H_1/10 (meters) [average height of largest 1/10 waves]
data.h_one_hundreth = nan([nSamples, 1]); %  - H_1/100 (meters) [average height of largest 1/100 waves]

xattrs = containers.Map('KeyType','char','ValueType','any');

for ii = 1:nSamples
    line_ind = ind(ii);
    % TODO a nice way to do this
    C = sscanf(all_lines{line_ind}, '* %d %d %f %d %d %f %f %f');
    data.burst_number(ii) = C(1);
    data.TIME(ii) = C(2);
    data.integration_time(ii) = C(3);
    data.number_points(ii) = C(4);
    data.number_waves_found(ii) = C(5);
    data.water_depth(ii) = C(6);
    data.pressure_sensor_depth(ii) = C(7);
    data.density(ii) = C(8);

    C = sscanf(all_lines{line_ind+1}, '%f %f %f %f');
    data.total_variance(ii) = C(1);
    data.total_energy(ii) =  C(2);
    data.WMSH(ii) =  C(3);
    data.WPSM(ii) =  C(4);

    C = sscanf(all_lines{line_ind+2}, '%f %f %f %f %f');
    data.WMXH(ii) = C(1);
    data.WHTH(ii) = C(2);
    data.WPTH(ii) = C(3);
    data.WHTE(ii) = C(4);
    data.h_one_hundreth(ii) = C(5);
end

% convert to matlab serial date
data.TIME = datenum(2000, 1, 1) + data.TIME/86400;

xattrs('integration_time') = struct('units', 'second');
xattrs('water_depth') = struct('units', 'm');
xattrs('pressure_sensor_depth') = struct('units', 'm');
xattrs('density') = struct('units', 'kg m-3');

xattrs('total_variance') = struct('units', 'm2');
xattrs('total_energy') = struct('units', 'J m-2');
xattrs('WMSH') = struct('units', 'm');
xattrs('WPSM') = struct('units', 'second');

xattrs('WMXH') = struct('units', 'm');
xattrs('WHTH') = struct('units', 'm');
xattrs('WPTH') = struct('units', 'second');
xattrs('WHTE') = struct('units', 'm');
xattrs('h_one_hundreth') = struct('units', 'm');

end