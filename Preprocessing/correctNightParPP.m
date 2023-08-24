function sample_data = correctNightParPP(sample_data, qcLevel, auto)
% CORRECTNIGHTPARPP detrend PAR with night time values.
%
% Inputs:
%   sample_data - cell array of data sets, ideally with PAR.
%   qcLevel     - string, 'raw' or 'qc'. Some pp not applied when 'raw'.
%   auto        - logical, run pre-processing in batch mode.
%
% Outputs:
%   sample_data - the same data sets, with PAR variables modified.
%
% Author:       Simon Spagnol <s.spagnol@aims.gov.au>
%               Virginie van DongenVogels <V.VanDongenVogels@aims.gov.au>


narginchk(2, 3);

if ~iscell(sample_data), error('sample_data must be a cell array'); end
if isempty(sample_data), return;                                    end

% no modification of data is performed on the raw FV00 dataset
if strcmpi(qcLevel, 'raw'), return; end

% auto logical in input to enable running under batch processing
if nargin<3, auto=false; end

nSample = length(sample_data);
% offset in hours from UTC, i.e
% local time = utc time + timezone_offsets
timezone_offsets = nan([nSample, 1]);
descs   = cell(nSample, 1);
include_ppp = false([nSample, 1]); % included via ppp
existed_ppp = false([nSample, 1]);
include = false([nSample, 1]); % include via user select dialog

offsetFile = ['Preprocessing' filesep 'timeOffsetPP.txt'];
currentPProutine = mfilename;

% read previous correctNightParPP values if any
for k = 1:nSample
    % how do you test if the the PP value was set at all?
    test1 = readDatasetParameter(sample_data{k}.toolbox_input_file, currentPProutine, 'include', -1);
    test2 = readDatasetParameter(sample_data{k}.toolbox_input_file, currentPProutine, 'include', -1);
    if (test1 == -1) & (test2 == -1)
        include_ppp(k) = false;
    else
        include_ppp(k) = true;
    end
    include(k) = include_ppp(k);
    timezone_offsets(k) = readDatasetParameter(sample_data{k}.toolbox_input_file, currentPProutine, 'timezone_offsets', NaN);
end
    
for k = 1:nSample
    sam = sample_data{k};
    
    descs{k} = genSampleDataDesc(sam);
    parInd = getVar(sam.variables, 'PAR');
    if ~parInd
        include(k) = false;
    end
    
    if ~isnan(timezone_offsets(k))
        % given my confusion about local time zones depending on source
        % file, this method is often the best
        lon =  sam.geospatial_lon_max;
        [zd, zltr, zone] = timezone(lon);
        timezone_offsets(k) = -zd;
    elseif isfield(sam, 'local_time_zone')
        timezone_offsets(k) = sam.local_time_zone;
    elseif isfield(sam.meta, 'timezone')
        tz = sam.meta.timezone; % string
        if isnan(str2double(tz))
            try
                timezone_offsets(k) = str2double(readProperty(tz, offsetFile));
            catch
                if strncmpi(tz, 'UTC', 3)
                    offsetStr = tz(4:end);
                    timezone_offsets(k) = str2double(offsetStr);
                else
                    timezone_offsets(k) = NaN;
                end
            end
        else
            timezone_offsets(k) = str2double(tz);
        end
    else
        % does this require mapping toolbox?
        lon =  sam.geospatial_lon_max;
        [zd, zltr, zone] = timezone(lon);
        timezone_offsets(k) = -zd;
    end
end

if ~auto
    f = figure(...
        'Name',        'Local Time Offset from UTC',...
        'Visible',     'off',...
        'MenuBar'  ,   'none',...
        'Resize',      'off',...
        'WindowStyle', 'Modal',...
        'NumberTitle', 'off');
    
    helpText = uicontrol('Style',  'text', 'String', 'Local timezone = UTC + offset (hours)');
    cancelButton  = uicontrol('Style',  'pushbutton', 'String', 'Cancel');
    confirmButton = uicontrol('Style',  'pushbutton', 'String', 'Ok');
    
    setCheckboxes  = [];
    offsetFields   = [];
    
    for k = 1:nSample
        setCheckboxes(k) = uicontrol(...
            'Style',    'checkbox',...
            'String',   descs{k},...
            'Value',    include(k), ...
            'UserData', k);
        
        offsetFields(k) = uicontrol(...
            'Style',    'edit',...
            'UserData', k, ...
            'String',   num2str(timezone_offsets(k)));
    end
    
    % set all widgets to normalized for positioning
    set(f,              'Units', 'normalized');
    set(helpText,   'Units', 'normalized');
    set(cancelButton,   'Units', 'normalized');
    set(confirmButton,  'Units', 'normalized');
    set(setCheckboxes,  'Units', 'normalized');
    set(offsetFields,   'Units', 'normalized');
    
    set(f,             'Position', [0.2 0.35 0.6 0.023 * (nSample + 2)]); % need to include 1 extra space for the row of buttons
    
    rowHeight = 1 / (nSample + 2);
    
    set(helpText,  'Position', [0.0 (1.0-rowHeight)  0.5 rowHeight]);
    
    set(cancelButton,  'Position', [0.0 0.0  0.5 rowHeight]);
    set(confirmButton, 'Position', [0.5 0.0  0.5 rowHeight]);
    
    for k = 1:nSample
        rowStart = (1.0-rowHeight) - (k * rowHeight);
        set(setCheckboxes (k), 'Position', [0.0 rowStart 0.6 rowHeight]);
        set(offsetFields  (k), 'Position', [0.8 rowStart 0.2 rowHeight]);
    end
    
    % set back to pixels
    set(f,              'Units', 'normalized');
    set(helpText,       'Units', 'normalized');
    set(cancelButton,   'Units', 'normalized');
    set(confirmButton,  'Units', 'normalized');
    set(setCheckboxes,  'Units', 'normalized');
    set(offsetFields,   'Units', 'normalized');
    
    % set widget callbacks
    set(f,             'CloseRequestFcn',   @cancelCallback);
    set(f,             'WindowKeyPressFcn', @keyPressCallback);
    set(setCheckboxes, 'Callback',          @checkboxCallback);
    set(offsetFields,  'Callback',          @offsetFieldCallback);
    set(cancelButton,  'Callback',          @cancelCallback);
    set(confirmButton, 'Callback',          @confirmCallback);
    
    set(f, 'Visible', 'on');
    
    uiwait(f);
end

% check/update include status and write/update dataset PP parameters
for k = 1:nSample
    % in case user accidently selected a file without PAR
    hasPar = getVar(sample_data{k}.variables, 'PAR') ~= 0;
    if ~hasPar
        include(k) = false;
        if existed_ppp(k)
            writeDatasetParameter(sample_data{k}.toolbox_input_file, currentPProutine, 'include', false);
        end
    else
        if include(k)
            writeDatasetParameter(sample_data{k}.toolbox_input_file, currentPProutine, 'include', true);
            writeDatasetParameter(sample_data{k}.toolbox_input_file, currentPProutine, 'timezone_offsets', timezone_offsets(k));
        end
    end
end

for k = 1:nSample
    
    if ~include(k), continue; end
    
    sam = sample_data{k};
    
    parInd = getVar(sam.variables, 'PAR');
    if ~parInd % shouldn't really get to this point
        include(k) = false;
        continue;
    end
    
    par = sam.variables{parInd}.data;
    timeInd = getVar(sam.dimensions, 'TIME');
    time_utc = sam.dimensions{timeInd}.data;
    
    local_time_zone = timezone_offsets(k);
    time_localtz = time_utc + local_time_zone/24.0;
    
    lon = sam.geospatial_lon_max;
    lat = sam.geospatial_lat_max;
    
    % days in local timezone (matlab datenum format) for use in 
    % sunrise/sunset calculation
    days_localtz = unique(floor(time_localtz));
    % add day before and after timeseries
    days_localtz = [days_localtz(1)-1; days_localtz; days_localtz(end)+1];
    
    [srise, sset, noon] = sunrise(lat, lon ,0, local_time_zone, days_localtz);
    
    par_night_median = nan(size(days_localtz));
    par_night_std = nan(size(days_localtz));
    hbuffer = 2/24; % how may hours (in day units) after sunset/before sunrise
    for i = 2:numel(days_localtz)
        nightIdx = (time_localtz >= sset(i-1)+hbuffer) & (time_localtz < srise(i)-hbuffer);
        night_par = par(nightIdx);
        %night_par = night_par(night_par >= 0.0);
        %night_par = night_par((night_par >= 0.0) & (night_par < 5));
        night_par = night_par(night_par < 5);
        par_night_median(i) = median(night_par, 'omitnan');
        par_night_std(i) = std(night_par, 'omitnan');
    end
    
    igood = isfinite(par_night_median);
    days_localtz = days_localtz(igood);
    par_night_median = par_night_median(igood);
    par_night_std = par_night_std(igood);
    
    % extend medians to cover entire raw timeseries, since we have no
    % other data just replicate the ends
    days_localtz = [days_localtz(1)-1; days_localtz; days_localtz(end)+1];
    par_night_median = [par_night_median(1); par_night_median; par_night_median(end)];
    par_night_std = [par_night_std(1); par_night_std; par_night_std(end)];
    
    par_base = interp1(days_localtz, par_night_median, time_localtz);
    par_corrected = par - par_base;
    
    % tidy up median and std
    trimIdx = (days_localtz < time_localtz(1)) | (days_localtz > time_localtz(end));
    par_night_median(trimIdx) = NaN;
    par_night_std(trimIdx) = NaN;
    
    % save the median nighttime par for later analysis
    [fpath, ffile, ~] = fileparts(sam.toolbox_input_file);
    if ~isfolder(fullfile(fpath))
        fpath = uigetdir('title', 'Select an output folder');
    end
    s = struct;
    s.TIME_UTC = days_localtz - local_time_zone;
    s.PAR_NIGHT_MEDIAN = par_night_median;
    s.PAR_NIGHT_STD = par_night_std;
    save(fullfile(fpath, [ffile '_par_night_median.mat']), '-struct', 's');
    
    % allow user to inspect result and reject if needed
    preview_par();
    selection = questdlg('Use corrected PAR?',...
        'Confirmation',...
        'Yes','No','Yes');
    switch selection
        case 'Yes'
            should_use = true;
        case 'No'
            should_use = false;
    end
            
    if ~should_use
        include(k) = false;
        writeDatasetParameter(sample_data{k}.toolbox_input_file, currentPProutine, 'include', false);
        continue;
    end
    
    % update PAR
    correctNightParComment = 'correctNightParPP: PAR values rebased from median night values.';
    
    sample_data{k}.variables{parInd}.data = par_corrected;
    comment = sample_data{k}.variables{parInd}.comment;
    if isempty(comment)
        sample_data{k}.variables{parInd}.comment = correctNightParComment;
    else
        sample_data{k}.variables{parInd}.comment = [comment ' ' correctNightParComment];
    end
    
    history = sample_data{k}.history;
    if isempty(history)
        sample_data{k}.history = sprintf('%s - %s', datestr(now_utc, readProperty('exportNetCDF.dateFormat')), correctNightParComment);
    else
        sample_data{k}.history = sprintf('%s\n%s - %s', history, datestr(now_utc, readProperty('exportNetCDF.dateFormat')), correctNightParComment);
    end

end

    function keyPressCallback(source, ev)
        %KEYPRESSCALLBACK If the user pushes escape/return while the dialog has
        % focus, the dialog is cancelled/confirmed. This is done by delegating
        % to the cancelCallback/confirmCallback functions.
        %
        if     strcmp(ev.Key, 'escape'), cancelCallback( source,ev);
        elseif strcmp(ev.Key, 'return'), confirmCallback(source,ev);
        end
    end

    function cancelCallback(source, ev)
        %CANCELCALLBACK Cancel button callback. Discards user input and closes the
        % dialog.
        %
        include(:)    = 0;
        timezone_offsets(:) = 0;
        delete(f);
    end

    function confirmCallback(source, ev)
        %CONFIRMCALLBACK. Confirm button callback. Closes the dialog.
        %
        delete(f);
    end

    function checkboxCallback(source, ev)
        %CHECKBOXCALLBACK Called when a checkbox selection is changed.
        % Enables/disables the offset text field.
        %
        idx = get(source, 'UserData');
        val = get(source, 'Value');
        
        include(idx) = val;
        
        if val
            val = 'on';
        else
            val = 'off';
        end
        
        set(offsetFields(idx), 'Enable', val);
        
    end

    function offsetFieldCallback(source, ev)
        %OFFSETFIELDCALLBACK Called when the user edits one of the offset fields.
        % Verifies that the text entered is a number.
        %
        
        val = get(source, 'String');
        idx = get(source, 'UserData');
        
        val = str2double(val);
        
        % reset the offset value on non-numerical
        % input, otherwise save the new value
        if isnan(val)
            set(source, 'String', num2str(offsets(idx)));
        else
            timezone_offsets(idx) = val;
        end
    end

    function preview_par()
        to_datetime = @(x) datetime(x, 'ConvertFrom', 'datenum');
        preview_fig = figure('Name', 'Preview PAR');
        
        mm = 3;
        nn = 1;

        pp = 1;
        ax(pp) = subplot(mm, nn, pp, 'Parent', preview_fig);
        plot(ax(pp), to_datetime(time_localtz), par, 'Color','blue', 'DisplayName', 'PAR original');
        hold('on');
        plot(ax(pp), to_datetime(time_localtz), par_corrected, 'Color','green', 'DisplayName', 'PAR corrected');
        par_noon = interp1(time_localtz, par_corrected, noon);
        plot(ax(pp), to_datetime(noon) ,par_noon, 'Color', 'cyan', 'DisplayName', 'PAR corrected noon');
        legend();
        
        pp = 2;
        ax(pp) = subplot(mm, nn, pp, 'Parent', preview_fig);
        plot(ax(pp), to_datetime(time_localtz), par, 'Color','blue', 'DisplayName', 'PAR original');
        hold('on');
        plot(ax(pp), to_datetime(srise), ones(size(srise)), 'o', 'DisplayName', 'Sunrise');
        plot(ax(pp), to_datetime(sset), ones(size(sset)), '*', 'DisplayName', 'Sunset');
        plot(ax(pp), to_datetime(days_localtz), par_night_median, 'Color', [0.2 0.2 0.2], 'Linestyle', '-', 'Marker', 'd', 'DisplayName', 'PAR med night');
        plot(ax(pp), to_datetime(time_localtz), par_corrected, 'Color','green', 'DisplayName', 'PAR corrected');
        line(ax(pp), to_datetime([time_localtz(1), time_localtz(end)]), [0, 0], 'Color', [0.75 0.75 0.75], 'DisplayName', 'zero');
        ylim(ax(pp), [-5 5]);
        legend();
        
        pp = 3;
        ax(pp) = subplot(mm, nn, pp, 'Parent', preview_fig);
        plot(ax(pp), to_datetime(days_localtz), par_night_median, 'Color', [0.2 0.2 0.2], 'Linestyle', '-', 'Marker', 'd', 'DisplayName', 'PAR med night');
        hold('on');
        plot(ax(pp), to_datetime(days_localtz), par_night_std, 'Color', 'red', 'Linestyle', '-', 'Marker', '.', 'DisplayName', 'PAR std night');
        legend();
        
        linkaxes(ax, 'x');
        uiwait(preview_fig);
    end

end


