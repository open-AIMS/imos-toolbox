function [bool, reason] = imosCorrMagVelocitySetQC(sample_data)
% function [bool,reason] = imosCorrMagVelocitySetQC(sample_data)
%
% Check if sample_data is a valid input for imosCorrMagVelocitySetQC.
%
% Inputs:
%
% sample_data [struct] - A toolbox dataset.
%
% Outputs:
%
% bool - True if dataset is valid. False otherwise.
% reason - The reasons why the dataset is invalid.
%
% Example:
%
% %see test_imosCorrMagVelocitySetQC.
%
% author: hugo.oliveira@utas.edu.au
% contributor: s.spagnol@aims.gov.au
%
narginchk(1,1)
reason = {};

if ~IMOS.adcp.contains_adcp_dimensions(sample_data)
    reason{1} = 'Not an adcp file.';
end

avail_variables = IMOS.get(sample_data.variables,'name');
cmag_counter = sum(contains(avail_variables,'CMAG'));
if cmag_counter == 0
    reason{end+1} = 'Missing CMAG variables.';
end

vel_vars = IMOS.meta.velocity_variables(sample_data);
if numel(vel_vars) == 0
    reason{end+1} = 'Missing at leat one velocity variable to flag.';
end

% TODO : confirm that for all adcp instruments that there will alwasy be 
% an equal number of beams and CMAG variables. Another consideration is
% for example a 5-beam (with 5th beam vertical say) how do these beams 
% relate in qc of u/v/w currents
if cmag_counter ~= sample_data.meta.adcp_info.number_of_beams
    reason{end+1} = 'Number of CMAG variables is different to number of beams';
end

if isempty(reason)
    bool = true;
else
    bool = false;
end

end
