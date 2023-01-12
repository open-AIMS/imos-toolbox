function [is_burst_sampling,is_burst_metadata_valid,burst_interval] = get_burst_metadata(sample_data)
%function [is_burst_metadata_valid,burst_interval] = get_burst_metadata(sample_data)
%
% Discover if burst metadata is valid, by inspecting metadata at root level
% and at parser level (meta). If root level is valid, meta level is ignored.
% The burst_interval is also returned.
%
% Inputs:
%
% sample_data - the toolbox data struct.
%
% Outputs:
%
% is_burst_sampling - True if burst data is provided.
% is_burst_metadata_valid - True if both burst_duration and burst_interval are valid
% burst_interval - the burst interval value.
%
%
% author: hugo.oliveira@utas.edu.au
%

is_burst_sampling = false;
burst_interval = [];

valid_burst_duration = false;
valid_burst_interval = false;

if isfield(sample_data,'instrument_burst_duration') && ~isempty(sample_data.instrument_burst_duration)
    is_burst_sampling = true;
    burst_duration = sample_data.instrument_burst_duration;
    valid_burst_duration = ~isnan(burst_duration) && burst_duration>0;
end

if ~valid_burst_duration && isfield(sample_data,'meta') && isfield(sample_data.meta,'instrument_burst_duration') && ~isempty(sample_data.meta.instrument_burst_duration)
    is_burst_sampling = true;
    burst_duration = sample_data.meta.instrument_burst_duration;
    valid_burst_duration = ~isnan(burst_duration) && burst_duration>0;
end

if isfield(sample_data,'instrument_burst_interval') && ~isempty(sample_data.instrument_burst_interval)
    is_burst_sampling = true;
    burst_interval = sample_data.instrument_burst_interval;
    valid_burst_interval = ~isnan(burst_interval) && burst_interval>0;
end

if ~valid_burst_interval && isfield(sample_data,'meta') && isfield(sample_data.meta,'instrument_burst_interval') && ~isempty(sample_data.meta.instrument_burst_interval)
    is_burst_sampling = true;
    burst_interval = sample_data.meta.instrument_burst_interval;
    valid_burst_interval = ~isempty(burst_interval) && ~isnan(burst_interval) && burst_interval>0;
end

is_burst_metadata_valid = is_burst_sampling && valid_burst_duration && valid_burst_interval;

end
