function nominalHeight = calculateNominalHeight(siteDepth, instrumentZ, depthStr)
%CALCULATENOMINALDEPTH Calculate nominal height using depth datum string.
%
% Inputs:
%   siteDepth    - site depth (real).
%   instrumentZ  - instrument z-value (real).
%   depthStr     - depth reference string (string).
% Current valid strings are 
%   ABS - above seabead (eg distance from seabed to ADCP)
%   BSL - below sealevel (eg distance from seasurface to WQM on suface buoy)
%   ASL - above sealevel (eg wind seansor on surface buoy, will be negative
%   number)
%
% Hopefully the site information will have a comment on the datum used.
%
% [mat calculateNominalDepth([ddb Site Sites Depth],[ddb InstrumentDepth], [ddb DepthTxt])]

% Author:       Simon Spagnol <s.spagnol@aims.gov.au>

% Copyright (C) 2018, Australian Ocean Data Network (AODN) and Integrated 
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

nominalHeight = NaN;

depthStr = strtrim(upper(depthStr));

if ~isempty(strfind(depthStr,'LAT'))
   depthStr = 'LAT'; 
end

switch depthStr
    case {'ASB', 'FROM BOTTOM', 'DISTANCE FROM BOTTOM', 'DEPTH FROM THE SEA BED', 'DEPTH FROM SEABED', 'HEIGHT ABOVE BOTTOM'}
        nominalHeight = instrumentZ;
        
    case {'BSL', 'FROM SURFACE'}
        nominalHeight = siteDepth - instrumentZ;
        
    case {'ASL', 'ABOVE SURFACE'} %?
        nominalHeight = -instrumentZ;

    case 'LAT' % already referenced to LAT datum
        nominalHeight = instrumentZ;
        
    otherwise % have to take a guess
        nominalHeight = instrumentZ;
end

end

