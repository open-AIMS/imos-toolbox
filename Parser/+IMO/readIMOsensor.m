%%
function [header, data, xattrs] = readIMOsensor(fid)
% parse IMO sensor log file. Can only be one sensor per file.

warning('readIMOsensor need revising.');

header = struct;
data = struct;
xattrs = containers.Map('KeyType','char','ValueType','any');
% IMO-MS8
% Sensor Type, Serial Number, Date, Time, Counts, PAR, Tilt, Int Temp
line = strtrim(fgetl(fid));
frewind(fid);

cols = split(line, ',');
nCols = numel(cols) - 4; % number of data columns
serialStr = char(cols(2));

instStr = '';
sensorVariableNames = {};
if strfind(line, '$IMNTU')
    instStr = 'IMNTU';
    formatStr = ['$' instStr];
    sensorVariableNames = {'DATE', 'TIME', 'COUNTS_DARK', 'COUNTS_NTU', 'TURB', 'TILT', 'LED_TEMP'};
    sensorVariableUnits = {'1', '1', 'count', 'count', '1', 'degree', 'degrees_Celsius'};
    sensorVariableComments = {'', '', '', '', '', '', ''};
    header.instrument_model = 'IMNTU';
elseif strfind(line, '$MS8EN')
    instStr = 'MS8EN';
    formatStr = ['$' instStr];
    sensorVariableNames = {'DATE', 'TIME', 'CH1', 'CH2', 'CH3', 'CH4', 'CH5', 'CH6', 'CH7', 'CH8','TILT', 'INTERNAL_TEMP'};
    sensorVariableUnits = {'1', '1', 'uW cm-2', 'uW cm-2', 'uW cm-2', 'uW cm-2', 'uW cm-2', 'uW cm-2', 'uW cm-2', 'uW cm-2', 'degree', 'degrees_Celsius'};
    sensorVariableComments = {'', '', '', '', '', '', '' ,  '', '', '', '', ''};
    header.instrument_model = 'MS8EN';
elseif strfind(line, 'IMO-DL3')
    instStr = 'IMO-DL3';
    formatStr = instStr;
    %Device Id, Serial Number, Vin Counts, Pressure Counts, Temp Counts, Vin (V), Depth (m), Temperature (C)
    sensorVariableNames = {'DATE', 'TIME', 'COUNTS_VIN', 'COUNTS_PRES', 'COUNTS_TEMP', 'VIN', 'DEPTH', 'TEMP'};
    sensorVariableUnits = {'1', '1', 'count', 'count', 'count', 'V', 'm', 'degrees_Celsius'};
    sensorVariableComments = {'', '', '', '', '', '', '', ''};
    header.instrument_model = 'DL3';
else
    error('Uknown IMO sensor');
end

header.instrument_serial_num = char(cols(2));
formatStr = [formatStr ',%*d'];

iChecksum = strfind(line, '*');
if iChecksum
    formatStr = [formatStr ',%[^*]*%s'];
else
    formatStr = [formatStr ',%s'];
end

frewind(fid);
allLines = textscan(fid,formatStr);
dataLines = allLines{1};
if iChecksum
    checksums = uint8(hex2dec(allLines{2}));
    
    cs = zeros([numel(checksums) 1], 'uint8');
    for i=1:numel(checksums)
        line = [instStr ',' serialStr ',' char(dataLines{i})];
        for j = 1:length(line)
            cs(i) = bitxor(cs(i), uint8(line(j)));
        end
    end
    iGoodChecksums = cs==checksums;
    dataLines = dataLines(iGoodChecksums);
    clear('cs');
    clear('checksums');
end
clear('allLines');

%dataLines = textscan(dataLines, 'Delimiter', ',');

splitData = split(dataLines, ',');
data.TIME = datenum([char(splitData(:,1)) char(splitData(:,2))],'ddmmyyyyHHMMSS.FFF');
xattrs('TIME') = struct('comment', 'TIME');

switch instStr
    case 'IMNTU'
        for i=3:7
            vName = char(sensorVariableNames{i});
            vUnit = char(sensorVariableUnits{i});
            vComment = char(sensorVariableComments{i});
            data.(vName) = str2double(splitData(:,i));
            xattrs(vName) = struct('comment', vComment,...
                'units', vUnit);
        end
        
    case 'MS8EN'
        for i=3:12
            vName = char(sensorVariableNames{i});
            vUnit = char(sensorVariableUnits{i});
            vComment = char(sensorVariableComments{i});
            data.(vName) = str2double(splitData(:,i));
            xattrs(vName) = struct('comment', vComment,...
                'units', vUnit);
        end
        
        % PAR calculated
        % put all channel data into one array
        wavelengths = [425, 455, 485, 515, 555, 615, 660, 695];
        
        nChannels = length(wavelengths);
        nSamples = size(data.CH1,1);
        tmpData = zeros([nSamples, nChannels]);
        for i = 1:nChannels
            vName = ['CH' num2str(i)];
            tmpData(:,i)= data.(vName);
        end
        
        % Convert MS8EN/MS9 uW/cm^2/nm data to W/m^2/nm
        tmpData = tmpData ./ 100.0;
        if ~isfield(header, 'instrument_wavelengths')
            header.instrument_wavelengths = strjoin(arrayfun(@num2str, wavelengths, 'UniformOutput', false), ',');
        end
        [data, xattrs] = IMO.calcPAR(data, xattrs, header);
        xattrsPAR = xattrs('PAR');
        xattrsPAR.comment = [xattrsPAR.comment ' For a typical solar spectrum the in-air MS8 derived PAR has an RMS error of 0.015%'];
        xattrs('PAR') = xattrsPAR;
            
            if false
            % derive PAR from MS8EN sampled wavelengths using method from
            % Wojciech Klonowski @ Insitu Marine Optics
            lambda = [425, 455, 485, 515, 555, 615, 660, 695];
            nChannels = 8;
            % new spacing between 400 - 700 nm.
            newLambda = 400:1:700;
            nNewChannels = size(newLambda,2);
            nSamples = size(data.CH1,1);
            avo=6.022140857e+17; % Avogadro's constant * 1e6
            
            % Convert MS8EN data to W/m^2/nm
            tmpData = [data.CH1 data.CH2 data.CH3 data.CH4 data.CH5 data.CH6 data.CH7 data.CH8] / 100;
            
            % IMO: convert to photons per second by dividing by h*c / lambda.
            % factor 1e-9 converts nm to m.
            h=6.626070040e-34; %plancks constant
            c=2.99792458e+08; %3.00e+08;
            tmpData = tmpData ./ ((h*c) ./ (lambda*1e-9));
            % IMO: convert to microMoles per second by dividing by
            % Avogadro's constant * 1e6
            tmpData = tmpData / avo;
            
            % IMO: interpolate multispectral micromolespersec to high res 1nm
            % %IDL% micromolespersec_ipol=interpol(micromolespersec,lambda,new_lambda)
            newData=nan([nSamples, nNewChannels]);
            for i = 1:nSamples
                newData(i,:) = interp1(lambda, tmpData(i, :), newLambda, 'linear', 'extrap');
            end
            
            % IMO: now calculate the integral of micromolespersec_ipol. I would
            % think MATLAB has some sort of INT_TABULATED or Simpson or
            % Trapezoidal functions.
            % %IDL% PAR=int_tabulated(new_lambda,micromolespersec_ipol)
            PAR = nan([nSamples, 1]);
            for i = 1:nSamples
                PAR(i) = trapz(newLambda, newData(i,:));
            end
            
            vName = 'PAR';
            vUnit = 'umole m-2 s-1';
            vComment = 'For a typical solar spectrum the in-air MS8 derived PAR has an RMS error of 0.015%';
            data.(vName) = PAR;
            xattrs(vName) = struct('comment', vComment,...
                'units', vUnit);
            end
            
    case 'IMO-DL3'
        for i=3:8
            vName = char(sensorVariableNames{i});
            vUnit = char(sensorVariableUnits{i});
            vComment = char(sensorVariableComments{i});
            data.(vName) = str2double(splitData(:,i));
            xattrs(vName) = struct('comment', vComment,...
                'units', vUnit);
        end
end

end