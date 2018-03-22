function [name, data, comment] = convertSBEcnvVar(name, data, timeOffset, instHeader, procHeader, mode)
%CONVERTSBECNVVAR Processes data from a SeaBird .cnv file.
%
% This function is able to convert data retrieved from a CNV SeaBird 
% data file generated by the Seabird SBE Data Processing program. This
% function is called from the different readSBE* functions.
%
% Inputs:
%   name        - SeaBird parameter name.
%   data        - data in SeaBird file.
%   timeOffset  - offset to be applied to time value in SeaBird file.
%   instHeader  - Struct containing instrument header.
%   procHeader  - Struct containing processed header.
%   mode        - Toolbox data type mode.
%
% Outputs:
%   name       - IMOS parameter code.
%   data       - data converted to fit IMOS parameter unit.
%   comment    - any comment on the parameter.
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
narginchk(6, 6);

switch name
    
    % elapsed time (seconds since start)
    case 'timeS'
      name = 'TIME';
      data = data / 86400 + timeOffset;
      comment = '';
      
    % elapsed time (minutes since start)
    case 'timeM'
      name = 'TIME';
      data = data / 1440 + timeOffset;
      comment = '';
      
    % elapsed time (hours since start)
    case 'timeH'
      name = 'TIME';
      data = data / 24  + timeOffset;
      comment = '';
    
    % elapsed time (days since start of year)
    case 'timeJ'
      name = 'TIME';
      if timeOffset == 0; timeOffset = 2010; end % clumsy, may need fixing!
      startYear = str2double(datestr(timeOffset, 'yyyy'));
      %data = rem(data, floor(data)) + floor(timeOffset);
      data = data + datenum(startYear-1,12,31);
      comment = '';
    
    % elapsed time (seconds since 01-Jan-2000)
    case 'timeK'
        name = 'TIME';
        data = data / 86400 + datenum(2000,1,1,0,0,0);
        comment = '';
        
    % elapsed time (seconds since 1970-01-01)
    case 'timeY'
      name = 'TIME';
      data = data / 86400 + datenum(1970,1,1,0,0,0);
      comment = '';
        
    % strain gauge pressure (dbar)
    case {'pr', 'prM', 'prdM', 'prSM'}
      name = 'PRES_REL';
      comment = '';
      
    % strain gauge pressure (psi)
    % 1 psi = 0.68948 dBar
    % 1 dbar = 1.45038 psi
    case 'prdE'
        name = 'PRES_REL';
        data = data .* 0.68948;
        comment = '';
      
    % temperature (deg C)
    case {'t090C', 'tv290C', 't090'}
      name = 'TEMP';
      comment = '';
      
    % conductivity (S/m)
    case {'c0S0x2Fm', 'cond0S0x2Fm'}
      name = 'CNDC';
      comment = '';
    
    % conductivity (mS/cm)
    % mS/cm -> 10-1 * S/m
    case {'c0ms0x2Fcm', 'cond0ms0x2Fcm', 'c0mS0x2Fcm', 'cond0mS0x2Fcm'}
      name = 'CNDC';
      data = data ./ 10;
      comment = '';
    
    % conductivity (uS/cm)
    % uS/cm -> 10-4 S/m
    case {'c0us0x2Fcm', 'cond0us0x2Fcm', 'c0uS0x2Fcm', 'cond0uS0x2Fcm'}
      name = 'CNDC';
      data = data ./ 10000;
      comment = '';
    
    % fluorescence (ug/l)
    case 'flC'
      name = 'CPHL';
      comment = 'Artificial chlorophyll data computed from bio-optical sensor raw counts measurements. Originally expressed in ug/l, 1l = 0.001m3 was assumed.';
      
    % artificial chlorophyll from fluorescence (mg/m3)
    case 'flECO0x2DAFL'
      name = 'CPHL';
      comment = 'Artificial chlorophyll data computed from bio-optical sensor raw counts measurements.';
      
    % oxygen (mg/l)
    % mg/l
    case 'sbeox0Mg0x2FL'
      name = 'DOXY';
      comment = '';
      
    % oxygen (ml/l)
    % ml/l
    case 'sbeox0ML0x2FL'
      name = 'DOX';
      comment = '';
    
    % oxygen (umol/L)
    % umol/L
    case 'sbeox0Mm0x2FL'
      name = 'DOX1';
      comment = '';
      
    % oxygen (umol/Kg)
    % umol/Kg
    case {'sbeox0Mm0x2FKg', 'sbeopoxMm0x2FKg'}
      name = 'DOX2';
      comment = '';
    
    % Oxygen [% saturation]
    case {'sbeopoxPS', 'sbeox0PS'}
        name = 'DOXS';
        comment = '';
       
    % Oxygen Temperature, SBE 63 [ITS-90, deg C]
    case 'sbeoxTC'
        name = 'DOXY_TEMP';
        comment = '';
      
    % salinity (PSU)
    case 'sal00'
      name = 'PSAL';
      comment = '';
    
    % PAR/Irradiance, Biospherical/Licor
    case 'par'
      name = 'PAR';
      comment = '';
      
    % CPAR/Corrected Irradiance [%]
    case 'cpar'
      name = 'CPAR';
      comment = '';
      
    % Beam Attenuation, Chelsea/Seatech [1/m]
    case 'bat'
      name = 'BAT';
      comment = '';

    % Beam Transmission, Chelsea/Seatech [%]
    case 'xmiss'
      name = 'BATMISS';
      comment = '';

    % turbidity (NTU)
    case {'obs', 'obs30x2B', 'turbWETntu0', 'upoly0'}
      name = 'TURB';
      comment = '';
      
    % descent rate m/s
    case 'dz0x2FdtM'
      name = 'DESC';
      comment = '';
          
    % density (kg/m3)
    case 'density00'
      name = 'DENS';
      comment = '';
    
    % depth (m)
    case {'depSM', 'depFM'}
      name = 'DEPTH';
      comment = '';
    
    % A/D counts to volts (sensor_analog_output 0 to 7)
    case {'v0', 'v1', 'v2', 'v3', 'v4', 'v5', 'v6', 'v7'}
      origName = name;
      name = getVoltageName(origName, instHeader);
      if ~strcmpi(name, 'not_assigned')
          name = ['volt_', name];
          comment = getVoltageComment(origName, procHeader);
      else
          name = '';
          data = [];
          comment = '';
      end
      
    case 'f1'
        if strcmpi(mode, 'profile')
            name = 'CNDC_FREQ';
            comment = 'Conductivity Frequency in Hz (added for minCondFreq detection)';
        else
            name = '';
            data = [];
            comment = '';
        end
        
    case 'flag'
        if strcmpi(mode, 'profile')
            name = 'SBE_FLAG';
            comment = 'SBE Processing Flag (added for binning). 0 is good, anything else bad.';
        else
            name = '';
            data = [];
            comment = '';
        end
        
    case 'scan'
        if strcmpi(mode, 'profile')
            name = 'ETIME';
            data = data/4;
            comment = 'Elapsed time in seconds (basically number of scan divided by 4Hz, added for surface soak)';
        else
            name = '';
            data = [];
            comment = '';
        end
        
    otherwise 
      name = '';
      data = [];
      comment = '';
end

end

function comment = getVoltageComment(name, header)

comment = '';
switch name
    case 'v0'
        if isfield(header, 'volt0Expr'), comment = header.volt0Expr; end
    case 'v1'
        if isfield(header, 'volt1Expr'), comment = header.volt1Expr; end
    case 'v2'
        if isfield(header, 'volt2Expr'), comment = header.volt2Expr; end
	case 'v3'
        if isfield(header, 'volt3Expr'), comment = header.volt3Expr; end
    case 'v4'
        if isfield(header, 'volt4Expr'), comment = header.volt4Expr; end
    case 'v5'
        if isfield(header, 'volt5Expr'), comment = header.volt5Expr; end
	case 'v6'
        if isfield(header, 'volt6Expr'), comment = header.volt6Expr; end
    case 'v7'
        if isfield(header, 'volt7Expr'), comment = header.volt7Expr; end
end

end

function name = getVoltageName(origName, header)

name = '';
switch origName
    case 'v0'
        if isfield(header, 'sensorIds') && isfield(header, 'sensorTypes')
            name = header.sensorTypes{strcmpi(header.sensorIds, 'volt 0')};
        end
    case 'v1'
        if isfield(header, 'sensorIds') && isfield(header, 'sensorTypes')
            name = header.sensorTypes{strcmpi(header.sensorIds, 'volt 1')};
        end
    case 'v2'
        if isfield(header, 'sensorIds') && isfield(header, 'sensorTypes')
            name = header.sensorTypes{strcmpi(header.sensorIds, 'volt 2')};
        end
	case 'v3'
        if isfield(header, 'sensorIds') && isfield(header, 'sensorTypes')
            name = header.sensorTypes{strcmpi(header.sensorIds, 'volt 3')};
        end
    case 'v4'
        if isfield(header, 'sensorIds') && isfield(header, 'sensorTypes')
            name = header.sensorTypes{strcmpi(header.sensorIds, 'volt 4')};
        end
    case 'v5'
        if isfield(header, 'sensorIds') && isfield(header, 'sensorTypes')
            name = header.sensorTypes{strcmpi(header.sensorIds, 'volt 5')};
        end
	case 'v6'
        if isfield(header, 'sensorIds') && isfield(header, 'sensorTypes')
            name = header.sensorTypes{strcmpi(header.sensorIds, 'volt 6')};
        end
    case 'v7'
        if isfield(header, 'sensorIds') && isfield(header, 'sensorTypes')
            name = header.sensorTypes{strcmpi(header.sensorIds, 'volt 7')};
        end
end

name = regexprep(name, '[^a-zA-Z0-9]', '_'); % to make a valid var name for structure, only keep word characters

end