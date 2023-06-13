%%
function header = extract_instrument_calibration(header)

instrument_calibration = header.instrument_calibration;

% for future processing needs
% strip out section header and add all X = Y entries to header struct as 
% calibration_X = Y.
% Any unimodel options (eg 'IN-WATER'), the Y is set as 'true'
idx = ~contains(instrument_calibration, {'---'});
instrument_calibration = instrument_calibration(idx);
for k = 1:numel(instrument_calibration)
    cfg = strtrim(strsplit(instrument_calibration{k}, '='));
    cfg{1} = matlab.lang.makeValidName(strrep(cfg{1}, ' ', '_'));
    if numel(cfg) == 1
        cfg{2} = 'true';
    end
    header.(['calibration_' cfg{1}]) = cfg{2};
end

% MS8 like instruments
ind = find(contains(instrument_calibration, 'WAVELENGTHS ='));
if ~isempty(ind)
    token = regexp(instrument_calibration{ind}, 'WAVELENGTHS\s+=\s+\[\s?(\S+)\s?\]', 'tokens');
    header.instrument_wavelengths = token{1}{1};
end

% uSpec-LPT Hyperspectral Light Logger
ind = find(contains(instrument_calibration, 'WL ='));
if ~isempty(ind)
    token = regexp(instrument_calibration{ind}, 'WL\s+=\s+\{\s?(\S+)\s?\}', 'tokens');
    header.instrument_wavelengths = token{1}{1};
end

for v = {'WAVELENGTHS' 'FWHM' 'DARKSLOPE' 'DARKYINT' 'GAIN' 'TEMPCO' 'IMM'}
    vname = char(v);
    ind = find(contains(instrument_calibration, [vname ' =']));
    if ~isempty(ind)
        token = regexp(instrument_calibration{ind}, [ vname '\s+=\s+\]?(\S+)\]?' ], 'tokens');
        header.(['instrument_' vname]) = token{1}{1};
    end
end

end