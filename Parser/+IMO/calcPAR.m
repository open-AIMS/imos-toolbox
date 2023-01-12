%%
function [data, xattrs] = calcPAR(data, xattrs, header)
%CALCPAR Calculate PAR by integrating irradiance over 400 to 700nm
% Requires data (nSamples, nWavelenghts) in W m^-2 nm^-1
% lambda (sample wavelenghts) in nm

IMM = NaN;
ableToCorrectPar = isfield(header, 'instrument_IMM') & isfield(data, 'DEPTH');
if ableToCorrectPar
    IMM = str2double(split(header.instrument_IMM, ','));
end

% PAR calculated
% put all channel data into one array
wavelengths = split(header.instrument_wavelengths, ',');
lambda = str2double(wavelengths);
nChannels = length(lambda);

hasIRRADIANCE = isfield(data, 'IRRADIANCE');
hasCH1 = isfield(data, 'CH1');
if hasIRRADIANCE
    channel_data = data.IRRADIANCE;
    nSamples = size(channel_data, 1);
elseif hasCH1
    % older style
    nSamples = size(data.CH1,1);
    channel_data = zeros([nSamples, nChannels]);
    for i = 1:nChannels
        vName = ['CH' num2str(i)];
        channel_data(:,i)= data.(vName);
    end
else
    warning('No IRRADIANCE or CHx data found, PAR not calculated.');
    return;
end

correctionString = '';
depth_offset = 0.30; % m between pressure sensor and light meter
if ableToCorrectPar
    if strcmp(header.instrument_mode, 'WATER_MODE')
        iBad = data.DEPTH < depth_offset;
        if sum(iBad) > 1
            correctionString = [' Channel data (' num2str(sum(iBad)) ' of ' num2str(length(iBad)) ') has been corrected for ' header.instrument_mode ' deployment and DEPTH values < ' num2str(depth_offset) 'm.'];
            for i = 1:nChannels
                vName = ['CH' num2str(i)];
                channel_data(iBad,i)= channel_data(iBad,i) / IMM(i);
            end
        end
    else
        iBad = data.DEPTH > depth_offset;
        if sum(iBad) > 1
            correctionString = [' Channel data (' num2str(sum(iBad)) ' of ' num2str(length(iBad)) ') has been corrected for ' header.instrument_mode ' deployment and DEPTH values > ' num2str(depth_offset) 'm.'];
            for i = 1:nChannels
                channel_data(iBad,i)= channel_data(iBad,i) * IMM(i);
            end
        end
    end
end

% Convert MS8EN/MS9 uW/cm^2/nm data to W/m^2/nm
channel_data = channel_data ./ 100.0;

% for MS8EN
% lambda = [425, 455, 485, 515, 555, 615, 660, 695];
% for MS9 about
% lambda = [410.4, 438.6, 491.1, 511.8, 550.2, 589.8, 635.6, 659.4, 700.6]

lambda = lambda(:);

% derive PAR from MS8EN sampled wavelengths using method from
% Wojciech Klonowski @ Insitu Marine Optics
nChannels = length(lambda);
nSamples = size(channel_data,1);

% new spacing between 400 - 700 nm.
new_lambdas = 400:1:700;
nNewChannels = size(new_lambdas,2);

% IMO: convert to photons per second by dividing by h*c / lambda.
% factor 1e-9 converts nm to m.
% IMO: convert to microMoles per second by dividing by
% Avogadro's constant * 1e6
% IMO: interpolate multispectral micromoles per sec to high res 1nm
% %IDL% micromolespersec_ipol=interpol(micromolespersec,lambda,new_lambda)
% IMO: now calculate the integral of micromolespersec_ipol. I would
% think MATLAB has some sort of INT_TABULATED or Simpson or
% Trapezoidal functions.
% %IDL% PAR=int_tabulated(new_lambda,micromolespersec_ipol)

h = 6.62607015e-34; % plancks constant, J s
c = 2.99792458e+08; % speed of light, m s^-1
avo = 6.02214076e+23; % Avogadro's constant, mol^-1
denom = h*c*avo; % J m mol-1

channel_data = (channel_data .*  lambda' .* 1e-9) ./ denom; % mol s^-1

interpolated_channels=nan([nSamples, nNewChannels]);
for i = 1:nSamples
    interpolated_channels(i,:) = interp1(lambda, channel_data(i, :), new_lambdas, 'linear', 'extrap');
end

new_par = nan([nSamples, 1]);
for i = 1:nSamples
    new_par(i) = trapz(new_lambdas, interpolated_channels(i,:));
end

% data -> moles m^-2 s^-1
% data * 1e6 -> umoles m^-2 s^-1
if isfield(data, 'PAR')
    vname = 'PAR2';
else
    vname = 'PAR';
end
data.(vname) = new_par * 1e6;
xattrs(vname) = struct('name', vname,...
    'comment', ['Derived PAR calculated by integrating irradiance over 400 to 700nm in 1nm steps.' correctionString],...
    'units', 'umole m-2 s-1');

end
