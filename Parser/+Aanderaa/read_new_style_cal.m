function deviceInfo = read_new_style_cal( lines, deviceInfo )

% new style cal file examples below (note when read in all empty lines
% are skipped). Fortran format for channel list is
% (i2,1x,a12,1x,a10,1x,i5,1x,a8,e11.3,e11.3)
%
% WLR5   979 22/01/86
%  1 Reference                               9.800E+02  9.800E+02
%  2 Temperature  deg C       2907          -3.000E+00  3.500E+01
%  3 N3 pres 25d  psia        2646 25489     0.000E+00  4.000E+02
%  4 N4 pres 25d  psia        2646 25489     0.000E+00  4.000E+02
%
%  1  0.0000E+00  1.0000E+00  0.0000E+00  0.0000E+00
%  2 -2.8290E+00  3.5960E-02 -7.1470E-06  1.0500E-08
%  3 -1.631836E+02  2.624298E-03 -7.810693E-10  5.085737E-19
%
% WLR7  1260 26/02/96
%  1 Reference                               3.040E+02  3.040E+02
%  2 Temperature  deg C                      0.000E+00  0.000E+00
%  3 N3 pressure  psia        3187 37717     0.000E+00  0.000E+00
%  4 N4 pressure  psia        3187 37717     0.000E+00  0.000E+00
%  5 not used                                0.000E+00  0.000E+00
%
%  1  0.0000E+00  1.0000E+00  0.0000E+00  0.0000E+00
%  2 -1.39647E+00 2.36764E-02 1.65343E-05 -2.9186E-09
%  3 -1.60444E+03 3.367137E-03 -8.83588E-10 4.80352E-17
%  5  0.0000E+00  1.0000E+00  0.0000E+00  0.0000E+00

allowed_instrument_models = Aanderaa.get_allowed_instruments();

tkns = regexp(lines{1}, allowed_instrument_models, 'match');
tkns = [tkns{:}];
if isempty(tkns)
    error('Malformed new style cal file : no instrument model.');
else
    cal_instrument_model = tkns{1};
    if ~strcmp(deviceInfo.instrument_model, cal_instrument_model)
        error('Instrument model in inf file does not match model in cal file.');
    end
end

tkns = strsplit(lines{1});
deviceInfo.cal_serial_number = tkns{2};
deviceInfo.cal_date_start = datestr(datenum(tkns{3}, 'dd/mm/yy'), 'yyyy/mm/dd');

% index to blank line between description and coefficients
ind = find(cellfun(@isempty, lines));
header_lines = lines(2:ind-1);
coeff_lines = lines(ind+1:end);


%%
% maye not the best way but its a start
header = struct();

pat = '(\d+)\s+Reference\s+(\S+)\s+(\S+)';
tkns = regexp(header_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
dstruct = struct(); % description struct
if ~isempty(ind)
    dstruct.ind = str2double(strtrim(tkns{ind}{1}{1}));
    dstruct.value = str2double(strtrim(tkns{ind}{1}{2}));
    dstruct.units = '1';
    header.REFERENCE = dstruct;
end

is_wlr7 = strcmp(cal_instrument_model, 'WLR7');
if is_wlr7
    % for some reason WLR7 cal files don't seem to have sensor model type for TEMP
    pat = '(\d+)\s+Temperature\s+deg C\s+\s+(\S+)\s+(\S+)';    
else
    pat = '(\d+)\s+Temperature\s+deg C\s+(\S+)\s+(\S+)\s+(\S+)';
end
tkns = regexp(header_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
dstruct = struct(); % description struct
if ~isempty(ind)
    dstruct.ind = str2double(strtrim(tkns{ind}{1}{1}));
    if is_wlr7
        dstruct.sensor_serial_number = 'UNKOWN';
        dstruct.valid_min = str2double(strtrim(tkns{ind}{1}{2}));
        dstruct.valid_max = str2double(strtrim(tkns{ind}{1}{3}));
    else
        dstruct.sensor_serial_number = strtrim(tkns{ind}{1}{2});
        dstruct.valid_min = str2double(strtrim(tkns{ind}{1}{3}));
        dstruct.valid_max = str2double(strtrim(tkns{ind}{1}{4}));        
    end
    dstruct.units = 'degrees';
    header.TEMP = dstruct;
end

pat = '(\d+)\s+Temp \.Low\s+deg C\s+(\S+)\s+(\S+)\s+(\S+)';
tkns = regexp(header_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
dstruct = struct(); % description struct
if ~isempty(ind)
    dstruct.ind = str2double(strtrim(tkns{ind}{1}{1}));
    dstruct.sensor_serial_number = strtrim(tkns{ind}{1}{2});
    dstruct.valid_min = str2double(strtrim(tkns{ind}{1}{3}));
    dstruct.valid_max = str2double(strtrim(tkns{ind}{1}{4}));
    dstruct.units = 'degrees';
    header.TEMP_LOW = dstruct;
end

pat = '(\d+)\s+Temp \.Wide\s+deg C\s+(\S+)\s+(\S+)\s+(\S+)';
tkns = regexp(header_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
dstruct = struct(); % description struct
if ~isempty(ind)
    dstruct.ind = str2double(strtrim(tkns{ind}{1}{1}));
    dstruct.sensor_serial_number = strtrim(tkns{ind}{1}{2});
    dstruct.valid_min = str2double(strtrim(tkns{ind}{1}{3}));
    dstruct.valid_max = str2double(strtrim(tkns{ind}{1}{4}));
    dstruct.units = 'degrees';
    header.TEMP_WIDE = dstruct;
end

pat = '(\d+)\s+Temp \.High\s+deg C\s+(\S+)\s+(\S+)\s+(\S+)';
tkns = regexp(header_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
dstruct = struct(); % description struct
if ~isempty(ind)
    dstruct.ind = str2double(strtrim(tkns{ind}{1}{1}));
    dstruct.sensor_serial_number = strtrim(tkns{ind}{1}{2});
    dstruct.valid_min = str2double(strtrim(tkns{ind}{1}{3}));
    dstruct.valid_max = str2double(strtrim(tkns{ind}{1}{4}));
    dstruct.units = 'degrees';
    header.TEMP_HIGH = dstruct;
end

% We don't also parse 'N4 pressure' for WLR4/5 as the coefficients are
% all included in 'N3 pressure' coefficients line.
% Have to handle one special case of 'N3 pres 25d'
pat = '(\d+)\s+N3 pres(?>sure|\ 25d)\s+psia\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)';
tkns = regexp(header_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
dstruct = struct(); % description struct
if ~isempty(ind)
    dstruct.ind = str2double(strtrim(tkns{ind}{1}{1}));
    dstruct.sensor_serial_number = strtrim(tkns{ind}{1}{2});
    dstruct.sensor_model_number = strtrim(tkns{ind}{1}{3});
    dstruct.valid_min = str2double(strtrim(tkns{ind}{1}{4}));
    dstruct.valid_max = str2double(strtrim(tkns{ind}{1}{5}));
    dstruct.units = 'psia';
    header.PRES = dstruct;
end

pat = '(\d+)\s+Conductivity\s+mmho/cm\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)';
tkns = regexp(header_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
dstruct = struct(); % description struct
if ~isempty(ind)
    dstruct.ind = str2double(strtrim(tkns{ind}{1}{1}));
    dstruct.sensor_serial_number = strtrim(tkns{ind}{1}{2});
    dstruct.sensor_model_number = strtrim(tkns{ind}{1}{3});
    dstruct.valid_min = str2double(strtrim(tkns{ind}{1}{4}));
    dstruct.valid_max = str2double(strtrim(tkns{ind}{1}{5}));
    dstruct.units = 'mmho/cm';
    header.CNDC = dstruct;
end

pat = '(\d+)\s+Direction\s+deg\. magn\.\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)';
tkns = regexp(header_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
dstruct = struct(); % description struct
if ~isempty(ind)
    dstruct.ind = str2double(strtrim(tkns{ind}{1}{1}));
    dstruct.sensor_serial_number = strtrim(tkns{ind}{1}{2});
    dstruct.sensor_model_number = strtrim(tkns{ind}{1}{3});
    dstruct.valid_min = str2double(strtrim(tkns{ind}{1}{4}));
    dstruct.valid_max = str2double(strtrim(tkns{ind}{1}{5}));
    dstruct.units = 'degrees';
    header.CDIR_MAG = dstruct;
end

pat = '(\d+)\s+Speed\s+cm/sec\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)';
tkns = regexp(header_lines, pat, 'tokens');
ind = find(~cellfun(@isempty, tkns));
dstruct = struct(); % description struct
if ~isempty(ind)
    dstruct.ind = str2double(strtrim(tkns{ind}{1}{1}));
    dstruct.sensor_serial_number = strtrim(tkns{ind}{1}{2});
    dstruct.sensor_model_number = strtrim(tkns{ind}{1}{3});
    dstruct.valid_min = str2double(strtrim(tkns{ind}{1}{4}));
    dstruct.valid_max = str2double(strtrim(tkns{ind}{1}{5}));
    dstruct.units = 'cm/sec';
    header.CSPD = dstruct;
end


%%
% read in coeff lines
coeff = struct;
cnames = fieldnames(header);
for cname = setxor(cnames, 'REFERENCE')'
    cname = cname{1};
    %cname = char(strtrim(cname));
    cstruct = header.(cname);
    indstr = num2str(cstruct.ind);
    pat = ['^\s?(?>' indstr ')\s+([\S ]+)'];
    tkns = regexp(coeff_lines, pat, 'tokens');
    ind = find(~cellfun(@isempty, tkns));
    if ~isempty(ind)
        if numel(ind) == 1
            carray = str2double(strsplit(tkns{ind}{1}{1}));
            % if CNDC check coeffs, if all zeros assume instrument does not
            % have sensor fitted.
            %is_not_empty_cndc = strcmp(cname, 'CNDC') && ~all(carray == 0.0)
            if strcmp(cname, 'CNDC')
                if ~all(carray == 0.0)
                    coeff.(cname) = str2double(strsplit(tkns{ind}{1}{1}));
                end
            else
                coeff.(cname) = str2double(strsplit(tkns{ind}{1}{1}));
            end
        else
            % the only repeate sensor type is TEMP so need to assign the
            % appropriate TEMP_LOW, TEMP_WIDE and TEMP_HIGH
            for ii = 1:numel(ind)
                
            end
            
        end
    end
end

%%
deviceInfo.header = header;
deviceInfo.coeff = coeff;

end