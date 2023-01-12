function sample_data = rtiParse( filename, ~)
%RTIPARSE Parses matlab export from RoweTechnologies ADCP.
%
% This function uses the readWorkhorseEnsembles function to read in a set
% of ensembles from a raw binary PD0 Workhorse ADCP file. It parses the
% ensembles, and extracts and returns the following:
%
%   - time
%   - temperature (at each time)
%   - pressure (at each time, if present)
%   - salinity (at each time, if present)
%   - water speed (at each time and distance)
%   - water direction (at each time and distance)
%   - Acoustic backscatter intensity (at each time and distance, a separate
%     variable for each beam)
%
% The conversion from the ADCP velocity values currently assumes that the
% ADCP is using earth coordinates (see section 13.4 'Velocity Data Format'
% of the Workhorse H-ADCP Operation Manual).
% Add code to convert Beam coordinates to ENU. RC July, 2020.
%
% Inputs:
%   filename [char]   - matlab data file path.
%
% Outputs:
%   sample_data - sample_data struct containing the data retrieved from the
%                 input file.
%

narginchk(1, 2);
sample_data = struct();

meta = struct();
meta.adcp_info = struct();

filename = filename{1};

[filePath, fileRadName, fileExt] = fileparts(filename);
if strcmpi(fileExt, '.mat')
    tmp = load(filename);
    % if you are loading the file exported straight from Pulse Exporter
    % then have file with array of structs. If you have had to fix some
    % issue on the exported file then save likely have file with a struct
    % containing the array of structs.
    if contains(fieldnames(tmp), 'Ancillary')
        RTImat = tmp;
    else
        RTImat = tmp.RTI;
    end
    clear('tmp');
elseif strcmpi(fileExt, '.ENS')
    RTImat = RTI.imos_ReadRTI(filename);
else
    errormsg('Unable to parse %s. rtiParse currently only handles ENS/MAT format.', filename);
end

sample_data.toolbox_input_file = filename;


% TODO : check how to determine magnetic correction
no_magnetic_corrections = false;
meta.compass_correction_applied = 0;
if no_magnetic_corrections
    magdec_name_extension = '_MAG';
    magdec_attrs = struct('comment','');
else
    magdec_name_extension = '';
    comment_msg = ['A compass correction of ' num2str(meta.compass_correction_applied) ...
        'degrees has been applied to the data by a technician using RTI''s software ' ...
        '(usually to account for magnetic declination).'];
    magdec_attrs = struct('compass_correction_applied',meta.compass_correction_applied, 'comment',comment_msg);
end

dimensions = IMOS.gen_dimensions('adcp');

[time, timePerEnsemble] = RTI.convert_time(RTImat);
%? timePerPing = 60.*ensembles.fixedLeader.tppMinutes + ensembles.fixedLeader.tppSeconds + 0.01.*ensembles.fixedLeader.tppHundredths;

meta.instrument_sample_interval   = mode(diff(time*24*3600));
meta.instrument_average_interval  = mode(timePerEnsemble);

dimensions{1}.data = time;
dimensions{1}.comment = ['Time stamp corresponds to the start of the measurement which lasts ' num2str(meta.instrument_average_interval) ' seconds.'];
dimensions{1}.seconds_to_middle_of_measurement = meta.instrument_average_interval/2;

first_bin_cdist = arrayfun(@(x) x.Ancillary(1), RTImat);
cell_length = arrayfun(@(x) x.Ancillary(2), RTImat);
num_cells = arrayfun(@(x) x.Ensemble(2), RTImat);
% TODO : determine up/down from file
meta.adcp_info.beam_face_config = 'up';
meta.binSize = cell_length';
meta.beam_angle = 20;

distance = Workhorse.cell_cdistance(mode(first_bin_cdist),...
    mode(cell_length),...
    mode(num_cells),...
    meta.adcp_info.beam_face_config);

dimensions{2}.data = distance;  %TODO: it doesn't make sense to use negative values for DIST_ALONG_BEAMS even if downward facing, but we need to be backward compatible.
dimensions{2}.comment = ['Values correspond to the distance between the instrument''s transducers and the centre of each cells. ' ...
    'Data is not vertically bin-mapped (no tilt correction applied). Cells are lying parallel to the beams, at heights above sensor that vary with tilt.'];

meta.adcp_info.coords = struct();
if isfield(RTImat, 'EarthVel')
    meta.adcp_info.coords.frame_of_reference = 'earth';
else
    errormsg('Only handle earth coordinates at the moment.');
end

meta.adcp_info.number_of_beams = mode(arrayfun(@(x) x.Ensemble(3), RTImat));

% TODO
meta.instrument_make = 'Rowe Technologies';
meta.instrument_model = 'RTI ADCP';
tmp = cell(8,1);
for i=1:8
    system_serial_X = mode(arrayfun(@(x) x.Ensemble(i+13), RTImat));
    tmp{i} = char(typecast(uint32(system_serial_X), 'uint8'));
end
meta.instrument_serial_no = [tmp{:}];


%%
%   cvars = fieldnames(cmap);
%   for k=1:numel(cvars)
%     vname = cvars{k};
%     imported.(vname) = cmap.(vname)(imported.(vname));
%   end

beam_vars = cell(1,meta.adcp_info.number_of_beams*2); %ABSIC,CMAG,PERG
beam_vars = {};
vel_vars = {};
imported = struct();

vname = ['UCUR' magdec_name_extension];
imported.(vname) = cell2mat(arrayfun(@(x) x.EarthVel(:,1), RTImat, 'UniformOutput', false))';
vel_vars{end+1} = vname;

vname = ['VCUR' magdec_name_extension];
imported.(vname) = cell2mat(arrayfun(@(x) x.EarthVel(:,2), RTImat, 'UniformOutput', false))';
vel_vars{end+1} = vname;

vname = ['WCUR' magdec_name_extension];
imported.(vname) = cell2mat(arrayfun(@(x) x.EarthVel(:,3), RTImat, 'UniformOutput', false))';
vel_vars{end+1} = vname;

for k = 1:meta.adcp_info.number_of_beams
    vname = ['ABSI' num2str(k)];
    imported.(vname) = cell2mat(arrayfun(@(x) x.Amplitude(:,k), RTImat, 'UniformOutput', false))';
    beam_vars{end+1} = vname;
end

for k = 1:meta.adcp_info.number_of_beams
    vname = ['CMAG' num2str(k)];
    imported.(vname) = cell2mat(arrayfun(@(x) x.Correlation(:,k), RTImat, 'UniformOutput', false))';
    beam_vars{end+1} = vname;
end

ping_count_actual = arrayfun(@(x) x.Ensemble(5), RTImat);
for k = 1:meta.adcp_info.number_of_beams
    vname = ['PGD' num2str(k)];
    imported.(vname) = cell2mat(arrayfun(@(x) x.GoodEarthPings(:,k), RTImat, 'UniformOutput', false));
    imported.(vname) = bsxfun(@rdivide,imported.(vname), ping_count_actual)' * 100;
    beam_vars{end+1} = vname;
end


ts_vars = {};
imported.(['HEADING' magdec_name_extension]) = arrayfun(@(x) x.Ancillary(5), RTImat)';
ts_vars = [ts_vars, ['HEADING' magdec_name_extension]];
imported.('PITCH') = arrayfun(@(x) x.Ancillary(6), RTImat)';
ts_vars = [ts_vars, 'PITCH'];
imported.('ROLL') = arrayfun(@(x) x.Ancillary(7), RTImat)';
ts_vars = [ts_vars, 'ROLL'];
imported.('TEMP') = arrayfun(@(x) x.Ancillary(8), RTImat)';
ts_vars = [ts_vars, 'TEMP'];
imported.('PRES_REL') = arrayfun(@(x) x.Ancillary(11), RTImat)' * 10; %bar to dbar
ts_vars = [ts_vars, 'PRES_REL'];
imported.('TX_VOLT') = arrayfun(@(x) x.SystemSettings(13), RTImat)';
ts_vars = [ts_vars, 'TX_VOLT'];


%%
% derived variables
switch meta.adcp_info.coords.frame_of_reference
    case 'earth'
        all_vel_vars = [vel_vars, 'CSPD', ['CDIR' magdec_name_extension]];
        u = imported.(['UCUR' magdec_name_extension]);
        v = imported.(['VCUR' magdec_name_extension]);
        imported.('CSPD') = hypot(u,v);
        imported.(['CDIR' magdec_name_extension]) = azimuth_direction(u,v);
end

vars0d = IMOS.featuretype_variables('timeSeries'); %basic vars from timeSeries

coords1d = 'TIME LATITUDE LONGITUDE NOMINAL_DEPTH';
vars1d = IMOS.gen_variables(dimensions,ts_vars,{},fields2cell(imported,ts_vars),'coordinates',coords1d);

coords2d_beam = 'TIME LATITUDE LONGITUDE DIST_ALONG_BEAMS';
vars2d_beam = IMOS.gen_variables(dimensions,beam_vars,{},fields2cell(imported,beam_vars),'coordinates',coords2d_beam);

switch meta.adcp_info.coords.frame_of_reference
    case 'beam'
        coords2d_vel = 'TIME LATITUDE LONGITUDE DIST_ALONG_BEAMS';
        vars2d_vel = IMOS.gen_variables(dimensions,all_vel_vars,{},fields2cell(imported,all_vel_vars),'coordinates',coords2d_vel);
    case 'earth'
        coords2d_vel = 'TIME LATITUDE LONGITUDE HEIGHT_ABOVE_SENSOR';
        earth_dims = [1,3];
        
        dimensions{3}.name = 'HEIGHT_ABOVE_SENSOR';
        dimensions{3}.typeCastFunc = IMOS.resolve.imos_type('HEIGHT_ABOVE_SENSOR');
        dimensions{3}.data = distance;
        dimensions{3}.comment = ['Values correspond to the distance between the instrument''s transducers and the centre of each cells. ' ...
            'Data has been vertically bin-mapped using tilt information so that the cells have consistent heights above sensor in time.'];
        
        vars2d_vel = cell(1,numel(all_vel_vars));
        for k=1:numel(all_vel_vars)
            vname = all_vel_vars{k};
            %force conversion for backward compatibility - this incur in at least 4 type-conversion from original data to netcdf - madness!
            typecast_func = IMOS.resolve.imos_type(vname);
            type_converted_var = typecast_func(imported.(vname));
            imported = rmfield(imported,vname);
            vars2d_vel{k} = struct('name',vname,'typeCastFunc',typecast_func,'dimensions',earth_dims,'data',type_converted_var,'coordinates',coords2d_vel);
        end
    otherwise
        errormsg('Frame of reference `%s` not supported',meta.adcp_info.coords.frame_of_reference)
end

sample_data.meta = meta;
sample_data.dimensions = dimensions;
sample_data.variables = [vars0d,vars2d_vel,vars2d_beam,vars1d]; % follow prev conventions

%%particular attributes
xattrs = containers.Map('KeyType','char','ValueType','any');
switch meta.adcp_info.coords.frame_of_reference
    case 'earth'
        xattrs(['UCUR' magdec_name_extension]) = magdec_attrs;
        xattrs(['VCUR' magdec_name_extension]) = magdec_attrs;
        xattrs(['CDIR' magdec_name_extension]) = magdec_attrs;
end

volt_attr = struct('comment', ['This parameter is actually the transmit voltage, which is NOT the same as battery voltage. ' ...
    'The transmit voltage is sampled after a DC/DC converter and as such does not represent the true battery voltage. ' ...
    'It does give a relative illustration of the battery voltage though which means that it will drop as the battery ' ...
    'voltage drops. In addition, The circuit is not calibrated which means that the measurement is noisy and the values ' ...
    'will vary between same frequency WH ADCPs.']);
xattrs('TX_VOLT') = volt_attr;
cast_fun = IMOS.resolve.imos_type('PRES_REL');
xattrs('PRES_REL') = struct('applied_offset',cast_fun(-gsw_P0/10^4)); % (gsw_P0/10^4 = 10.1325 dbar)

indexes = IMOS.find(sample_data.variables,xattrs.keys);
for vind = indexes
    iname = sample_data.variables{vind}.name;
    sample_data.variables{vind} = combineStructFields(sample_data.variables{vind},xattrs(iname));
end

end