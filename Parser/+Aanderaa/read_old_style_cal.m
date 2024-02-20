function deviceInfo = read_old_style_cal( lines, deviceInfo )
%read_old_style_cal read old style WLR/RCM cal file into a struct

%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%

% old style cal file, based on wlr4cal.m, original comments below
%
% converts aanderaa wlr4&5 data to physical units
%
% craig steinberg 3/12/97
%
% assumes raw data input
% saves to XXXhd.asc and XXXTL.asc and mat files
% asks for and converts date, time info to hour of year and adjusts time zone
%       assumes 20th century i.e. adds 1900 to "95" from aanderaa software
% input: 4 channels ref,temp,p1 andp2
% output: time,temp,depth
%
% raw to physical conversion from fortran programme wlrcal.for
% and coefficents from wlrcal.dat
%
% Programmer: Craig Steinberg 4/12/97, last modified 4/12/97.
% SEE ALSO SLVPLT.M HDR.M
%
% example WLR5
%      880   0             149016
%       -1.241469E2    2.599204E-3  -8.861359E-10  1.359852E-16
%        0.            0.
%       -2.999         3.603E-2     -6.441E-6      1.014E-8
%        0.            0.
%        2             0.
%
% example WLR7, note swapped order of TEMP/PRES coeffs
% 1353	0             149016
% 	-7.4072E+02	1.6468-03	-4.8247-10	4.6403E-17
% 	0.	0.
% 	-3.140	3.486E-02	-4.942E-06	8.844E-09
% 	0.	0.
% 	2.	0.
%
% example RCM7, note some have % comment some don't
%     9139    0       149016	0
% 	-1.148E+01  2.291E-01 0. 0.	% Pressure
% 	0.	0.	0	0
% 	9.831	2.519E-02	-1.549E-06	2.214E-09	% high temp
% 	1.760E-01	-4.5E-04	0	0
% 	-2.686	2.332E-02	-1.344E-06	1.937E-09	% Low temp
% 	1.830E-01	-5.1E-04	0	0
% 	-5.223E-03	3.175E-02	-8.388E-06	4.300E-09	% Wide temp
% 	-3.990E-01	4.340E-03	0	0
% 	0	0	0	0	% Conductivity
% 	0	0	0	0
% 	1	3.500E-01	0	0	% Direction
% 	0	0	0	0
% 	1.1	2.906E-01	0.	0.	% Speed
% 	0	0	0	0

tkns = strsplit(strtrim(lines{1}));
deviceInfo.cal_serial_number = tkns{1};
%C	times are hours since 0000 1/1/83
%C	VALID UNTIL YEAR 2000 - HOURS  0. TO 149016.
deviceInfo.cal_date_start = datestr(str2num(tkns{2})/24.0 + datenum(1983,1,1), 'yyyy/mm/dd');
deviceInfo.cal_date_end = datestr(str2num(tkns{3})/24.0 + datenum(1983,1,1), 'yyyy/mm/dd');

if contains(deviceInfo.instrument_model, 'WLR')
    % old style WLR, 6 lines
    split_lines = {};
    for ii = 1:6
        split_lines{ii} =  str2double(strsplit(strtrim(lines{ii})));
    end
 
    % there seems to have been a change in order of TEMP and PRES
    % coefficients betwwen WLR4/5 and 7
    switch deviceInfo.instrument_model
        case {'WLR4', 'WLR5'}
            % order as specified in wlr4cal.m
            % L1 serial etc
            % L2, L3 pressure coefficients; L4, L5 temperature coefficients
            % L2 = A1,B1,C1,D1 PRESSURE COEFFICIENTS
            % L3 = A2 & B2 ARE ALSO PRESSURE COEFFICIENTS AND ARE ADDED TO A1 & B1 RESPECTIVELY
            % L4 = TA1,TB1,TC1,TD1 TEMPERATURE COEFFICIENTS
            % L5 = TA2,TB2 ARE TEMPERATURE COEFFICIENTS
            coeff = struct();
            vname = 'PRES';
            ind = 2;
            carray = NaN([1, 4]);
            carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
            carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
            carray(3) = split_lines{ind}(3);
            carray(4) = split_lines{ind}(4);
            coeff.(vname) = carray;
            
            vname = 'TEMP';
            ind = 4;
            carray = NaN([1, 4]);
            carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
            carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
            carray(3) = split_lines{ind}(3);
            carray(4) = split_lines{ind}(4);
            coeff.(vname) = carray;
            
            deviceInfo.jflag = split_lines{6}(1); % should be 2 for WLR with a TEMP sensor?
            deviceInfo.nzero = split_lines{6}(2); % ?
            
        case 'WLR7'
            % order as specified in wlr7cal.m
            % L2, L3 temperature coefficients; L4, L5 pressure coefficients
            % L1 serial etc
            % L2 = TA1,TB1,TC1,TD1 TEMPERATURE COEFFICIENTS
            % L3 = TA2,TB2 ARE TEMPERATURE COEFFICIENTS
            % L4 = A1,B1,C1,D1 PRESSURE COEFFICIENTS
            % L5 = A2 & B2 ARE ALSO PRESSURE COEFFICIENTS AND ARE ADDED TO A1 & B1 RESPECTIVELY
            vname = 'TEMP';
            ind = 2;
            carray = NaN([1, 4]);
            carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
            carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
            carray(3) = split_lines{ind}(3);
            carray(4) = split_lines{ind}(4);
            coeff.(vname) = carray;
            
            vname = 'PRES';
            ind = 4;
            carray = NaN([1, 4]);
            carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
            carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
            carray(3) = split_lines{ind}(3);
            carray(4) = split_lines{ind}(4);
            coeff.(vname) = carray;
            
            extra = str2double(strsplit(strtrim(lines{6})));
            deviceInfo.jflag = extra(1); % should be 2 for WLR with a TEMP sensor?
            deviceInfo.nzero = extra(2); % ?
    end
    deviceInfo.coeff = coeff;
    
else
    % old style RCM, 15 lines
    split_lines = {};
    for ii = 1:15
        split_lines{ii} =  str2double(strsplit(strtrim(lines{ii})));
    end

    coeff = struct();
    
    vname = 'PRES';
    ind = 2;
    carray = NaN([1, 4]);
    carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
    carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
    carray(3) = split_lines{ind}(3);
    carray(4) = split_lines{ind}(4);
    coeff.(vname) = carray;
    
    vname = 'TEMP_HIGH';
    ind = 4;
    carray = NaN([1, 4]);
    carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
    carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
    carray(3) = split_lines{ind}(3);
    carray(4) = split_lines{ind}(4);
    coeff.(vname) = carray;
    
    vname = 'TEMP_LOW';
    ind = 6;
    carray = NaN([1, 4]);
    carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
    carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
    carray(3) = split_lines{ind}(3);
    carray(4) = split_lines{ind}(4);
    coeff.(vname) = carray;
    
    vname = 'TEMP_WIDE';
    ind = 8;
    carray = NaN([1, 4]);
    carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
    carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
    carray(3) = split_lines{ind}(3);
    carray(4) = split_lines{ind}(4);
    coeff.(vname) = carray;
    
    % did we ever have any of these?
    % so if all coefficients are zero then assume there is no CNDC sensor
    vname = 'CNDC'; 
    ind = 10;
    carray = NaN([1, 4]);
    carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
    carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
    carray(3) = split_lines{ind}(3);
    carray(4) = split_lines{ind}(4);
    if ~all(carray == 0.0)
        coeff.(vname) = carray;
    end
    
    vname = 'CDIR';
    ind = 12;
    carray = NaN([1, 4]);
    carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
    carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
    carray(3) = split_lines{ind}(3);
    carray(4) = split_lines{ind}(4);
    coeff.(vname) = carray;
    
    vname = 'CSPD';
    ind = 14;
    carray = NaN([1, 4]);
    carray(1) = split_lines{ind}(1) + split_lines{ind+1}(1);
    carray(2) = split_lines{ind}(2) + split_lines{ind+1}(2);
    carray(3) = split_lines{ind}(3);
    carray(4) = split_lines{ind}(4);
    coeff.(vname) = carray;
    
    deviceInfo.coeff = coeff;
end

end