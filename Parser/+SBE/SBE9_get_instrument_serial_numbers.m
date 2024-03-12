function instHeader = SBE9_get_instrument_serial_numbers(instHeader, instHeaderLines, procHeaderLines)
% SBE9_GET_INSTRUMENT_SERIAL_NUMBERS read SBE9 serial numbers in odd
% locations

% store some SBE9 specific serial numbers, these will only be the primary
% TC serial numbers
tkns = regexp(instHeaderLines, '* Temperature SN = (\d+)', 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    instHeader.temperature_serial_number = tkns{ind}{1}{1};
end

tkns = regexp(instHeaderLines, '* Conductivity SN = (\d+)', 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    instHeader.conductivity_serial_number = tkns{ind}{1}{1};
end

% is it always an 11plus?
tkns = regexp(instHeaderLines, '\* SBE 11plus V (.+)', 'tokens');
ind = find(~cellfun(@isempty, tkns));
if ~isempty(ind)
    instHeader.sbe_11plus_version = tkns{ind}{1}{1};
end

% SBE9 cnv file is slight different in that the main serial number is not
% stored in the '*' header lines but is really the identified by the
% pressure sensor serial number
presSensorExpr = '#\s+<PressureSensor SensorID=\"\d+\" >\s*#\s+<SerialNumber>(\d+)<\/SerialNumber>';
tkns = regexp([procHeaderLines{:}], presSensorExpr, 'tokens');
if ~isempty(tkns)
    instHeader.instrument_serial_no = tkns{1}{1};
    instHeader.pressure_serial_number = tkns{1}{1};
end

end