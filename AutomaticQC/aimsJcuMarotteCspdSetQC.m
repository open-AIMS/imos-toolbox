function [sample_data, varChecked, paramsLog] = aimsJcuMarotteCspdSetQC( sample_data, auto )
%AIMSJCUMAROTTECSPDSETQC Quality control procedure for JCU Marotte cspd/cdir.
%
% Inputs:
%   sample_data - struct containing the entire data set and dimension data.
%   auto - logical, run QC in batch mode
%
% Outputs:
%   sample_data - same as input, with QC flags added for variable/dimension
%                 data.
%   varChecked  - cell array of variables' name which have been checked
%   paramsLog   - string containing details about params' procedure to include in QC log
%
% Author: Simon Spagnol <s.spagnol@aims.gov.au>
% 
% Based on teledyneSetQC.m
%

%
% Copyright (C) 2023, Australian Ocean Data Network (AODN) and Integrated 
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
if ~isstruct(sample_data), error('sample_data must be a struct'); end

% auto logical in input to enable running under batch processing
if nargin<2, auto=false; end

varChecked = {};
paramsLog  = [];
isJCU = strcmp(sample_data.meta.instrument_make, 'JCU');
isMarotte = contains(sample_data.meta.instrument_model, 'Marotte');
if ~isMarotte, return; end

%
magExt = '';
if getVar(sample_data.variables, 'CDIR_MAG')
    magExt ='_MAG';
end

% CSPD is necessary in sample_data struct
idCSPD = getVar(sample_data.variables, 'CSPD');

if ~idCSPD, return; end

%
qcSet           = str2double(readProperty('toolbox.qc_set'));
badFlag         = imosQCFlag('bad',             qcSet, 'flag');

cspd = sample_data.variables{idCSPD}.data;
iBad = cspd > 1.1;
sample_data.variables{idCSPD}.flags(iBad) = badFlag;
varChecked = [varChecked, {'CSPD'}];

% depending on the input file it is possible to CDIR magdec corrected but not
% CDIR_CART_RAD
varList = {['CDIR' magExt], 'CDIR_CART_RAD', 'CDIR_CART_RAD_MAG', 'CSPD_UPPER', 'CSPD_LOWER', ['UCUR' magExt], ['VCUR' magExt]};
for k = 1:numel(varList)
    v = varList{k};
    id = getVar(sample_data.variables, v);
    if id
        sample_data.variables{id}.flags(iBad) = badFlag;
        varChecked = [varChecked, {v}];
    end
end

paramsLog = 'CSPD > 1.1m/s flagged bad.';
        
end

