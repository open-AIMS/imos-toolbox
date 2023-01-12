function [sample_data, varChecked, paramsLog] = imosCorrMagVelocitySetQC( sample_data, auto )
%IMOSCORRMAGVELOCITYSETQC Quality control procedure for Teledyne Workhorse (and similar)
% ADCP instrument data, using the correlation magnitude velocity diagnostic variable.
%
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
% Author:       Guillaume Galibert <guillaume.galibert@utas.edu.au>
%

%
% Copyright (C) 2017, Australian Ocean Data Network (AODN) and Integrated 
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

% auto logical in input to enable running under batch processing
if nargin<2, auto=false; end

varChecked = {};
paramsLog = [];
currentQCtest = mfilename;
if ~isstruct(sample_data), error('sample_data must be a struct'); end

[valid, reason] = IMOS.validate_dataset(sample_data, currentQCtest);

if ~valid
    %TODO: we may need to include a global verbose flag to avoid pollution here.
    unwrapped_msg = ['Skipping %s. Reasons: ' cell2str(reason,'')];
    dispmsg(unwrapped_msg,sample_data.toolbox_input_file)
    return
end

avail_variables = IMOS.get(sample_data.variables, 'name');
cmag_counter = sum(contains(avail_variables, 'CMAG'));
cmag_vars = cell(1, cmag_counter);

% get all necessary dimensions and variables id in sample_data struct
idUcur = getVar(sample_data.variables, 'UCUR');
idVcur = getVar(sample_data.variables, 'VCUR');
idWcur = getVar(sample_data.variables, 'WCUR');
idCspd = getVar(sample_data.variables, 'CSPD');
idCdir = getVar(sample_data.variables, 'CDIR');

num_beams = sample_data.meta.adcp_info.number_of_beams;
idCMAG = cell(cmag_counter, 1);
for j=1:cmag_counter
    idCMAG{j}  = getVar(sample_data.variables, ['CMAG' int2str(j)]);
end

% let's get the associated vertical dimension
idVertDim = sample_data.variables{idCMAG{1}}.dimensions(2);
if strcmpi(sample_data.dimensions{idVertDim}.name, 'DIST_ALONG_BEAMS')
    disp(['Warning : imosCorrMagVelocitySetQC applied with a non tilt-corrected CMAGn (no bin mapping) on dataset ' sample_data.toolbox_input_file]);
end

qcSet           = str2double(readProperty('toolbox.qc_set'));
badFlag         = imosQCFlag('bad',             qcSet, 'flag');
goodFlag        = imosQCFlag('good',            qcSet, 'flag');
rawFlag         = imosQCFlag('raw',             qcSet, 'flag');

%Pull out correlation magnitude
sizeData = size(sample_data.variables{idCMAG{1}}.data);

% read in filter parameters
%propFile = fullfile('AutomaticQC', 'imosCorrMagVelocitySetQC.txt');
%cmag     = str2double(readProperty('cmag',   propFile));
propFile = fullfile('AutomaticQC', 'imosCorrMagVelocitySetQC.ini');
ini = IniConfig();
ini.ReadFile(propFile);
instrument_make = sample_data.meta.instrument_make;
instrument_model = sample_data.meta.instrument_model;
% try and key value based on instrument_make, then instrument_model, 
% else use default value
[cmag, status] = ini.GetValues(instrument_make, 'cmag', 64);
if ~status
    [cmag, status] = ini.GetValues(instrument_model, 'cmag', 64);
end
if ~status
    warning('No cmag found in imosCorrMagVelocitySetQC.ini, using default');
end

% read dataset QC parameters if exist and override previous 
% parameters file
currentQCtest = mfilename;
cmag = readDatasetParameter(sample_data.toolbox_input_file, currentQCtest, 'cmag', cmag);

paramsLog = ['cmag=' num2str(cmag)];

sizeCur = size(sample_data.variables{idUcur}.flags);

% same flags are given to any variable
flags = ones(sizeCur, 'int8')*rawFlag;

% Run QC
isub_all = zeros(size(sample_data.variables{idCMAG{1}}.data), 'int8');
for k = 1:num_beams
    isub_all = isub_all + cast(sample_data.variables{idCMAG{k}}.data > cmag, 'int8');
end

% TODO : determine what this test means if have RTI 3 beam instrument.
% assign pass(1) or fail(0) values
% Where 2 or more beams pass, then the cmag test is passed
iPass = isub_all >= 2;
iFail = ~iPass;
clear isub_all;

% Run QC filter (iFail) on velocity data
flags(iFail) = badFlag;
flags(iPass) = goodFlag;

sample_data.variables{idUcur}.flags = flags;
sample_data.variables{idVcur}.flags = flags;
sample_data.variables{idWcur}.flags = flags;

varChecked = {sample_data.variables{idUcur}.name, ...
    sample_data.variables{idVcur}.name, ...
    sample_data.variables{idWcur}.name};

if idCdir
    sample_data.variables{idCdir}.flags = flags;
    varChecked = [varChecked, {sample_data.variables{idCdir}.name}];
end

if idCspd
    sample_data.variables{idCspd}.flags = flags;
    varChecked = [varChecked, {sample_data.variables{idCspd}.name}];
end

% write/update dataset QC parameters
writeDatasetParameter(sample_data.toolbox_input_file, currentQCtest, 'cmag', cmag);

end