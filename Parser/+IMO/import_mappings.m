function [multispec_vars, ts_vars, isMultispec] = import_mappings(header, data)
%function [imap, vel_vars, beam_vars, ts_vars] = import_mappings(sensors, num_beams, name_extension, frame_of_reference)
%
% Load the import mappings for workhorse ADCP
%
% Inputs:
%
% header [struct] - A structure with instrument info.
% data [struct] - Parsed data struct
%
% Outputs:
% imap[struct] - the import mapping structure.
%                fieldnames - destination variable names
%                fieldvalues[cell[char]] - location in the ensembles struct.
% multispec_vars[cell] - cell containing multispec variable names (2d-arrays).
% ts_vars[cell] - cell containing series variable names (1d-arrays).
%
% Examples:
%
% author: hugo.oliveira@utas.edu.au
%

narginchk(2, 2);

multispec_vars = {};
allowed_multispec_vars = {'IRRADIANCE', 'RADIANCE', 'MULTISPEC'};
idx = contains(allowed_multispec_vars, fieldnames(data));
isMultispec = any(idx);
if isMultispec
    multispec_vars = allowed_multispec_vars(idx);
end

vNames = fieldnames(data);
exclude_var_names = ['TIME', 'WAVELENGTHS', multispec_vars];
idx = ~ismember(vNames, exclude_var_names);
vNames = vNames(idx);

ts_vars = vNames;

end
