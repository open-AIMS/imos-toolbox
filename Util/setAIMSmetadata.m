function metadataStr = setAIMSmetadata(site, metadataField)
% setAIMSmetadata This function allows a generic config file to be used 
% with the %IMOS toolbox for processing AIMS data.
% The function call [mat setAIMSmetadata('[ddb Site]','naming_authority')]
% in global_attributes_timeSeries.txt calls this function with the site and the
% datafield as arguements. This function then passes back an appropriate
% string for that site and field. 
% If the site is not recognised, default strings are returned.

%%
% IMOS Site Names
% NRS : National Reference Stations eg
%   NRSDAR : Darwin
%   NRSYON : Yongala
%   NRSNIN : Ningaloo
% ITF : Indonesian Through Flow (shallow) mooring array. Withdrawn.
% PIL : Pilbara mooring array. Withdrawn.
% KIM : Kimberley mooring array. Withdrawn.
% NIN : Ningaloo Reef Tantabiddi 50m mooring (IMOS). Withdrawn.
% GBR : GBR mooring array
% NWS : North West Self array (200m)
% TAN : Ningaloo Reef Tantabiddi 100m  mooring (AIMS), partly funded for a
%   period by IMOS
% CAM : Camden Sound moorings CAM050/CAM100 Aug-2014 -- Jul-2015. Withdrawn.
%
% Other Site Names
% SCR : RV Falkor cruise FK150410 (AIMS 6204) at Scott Reef and surrounds

%%
dbsite = executeQuery( 'Sites', 'Site', site);
research_activity_is_not_empty = isfield(dbsite, 'ResearchActivity') && ~isempty(dbsite.ResearchActivity);
db_research_activity = '';
if research_activity_is_not_empty
    db_research_activity = strtrim(dbsite.ResearchActivity);
end

% Is this site an IMOS related one : IMOS CTDs can have a site label that is
% not a physical site with lat/lon but is usually starts with site name,
% so first do a hardcoded comparison with known AIMS IMOS sites. Else test
% if site is an IMOS one by looking at it's associated db ResearchActivity.
% Still unsure of status of CAM as imos site
imos_sites_prefix = {'NRS', 'GBR', 'NWS', 'ITF', 'KIM', 'PIL', 'TAN', 'CAM', 'WW-'};
isIMOS = startsWith(site, imos_sites_prefix);
if ~isIMOS
    isIMOS = research_activity_is_not_empty && ~isempty(regexp(dbsite.ResearchActivity, '^IMOS', 'once'));
end

% AIMS EcoRRaP
% for some reason they chose ResearchActivity to represent region, but
% didn't say make if "ECORRAP-region" so have to test for all regions
ecorrap_regions = {'Capricorn Bunker', 'Keppel Islands', 'Offshore Central GBR', 'Offshore Northern GBR', 'Palm Islands', 'Torres Strait'};
isECORRAP = research_activity_is_not_empty &&...
    identifySite(db_research_activity, ecorrap_regions);

% AIMS Marine Monitoring Program (MMP) research activity/site
isMMP = research_activity_is_not_empty && ~isempty(regexp(dbsite.ResearchActivity, '^AIMS-MMP', 'once'));

% Schmidt Ocean Institute
isSOI = identifySite(site,{'^SCR'});

% Work for Rio Tinto in Gove
% 'Rio Tinto : Ocean & sediment transport monitoring in Melville Bay'
isRTGOVE = research_activity_is_not_empty && ~isempty(regexp(dbsite.ResearchActivity, '^Rio Tinto : Ocean', 'once'));
% 'Rio Tinto : Gove Alternate Discharge Site'
isRTGOVE = isRTGOVE && ~isempty(regexp(dbsite.ResearchActivity, '^Rio Tinto : Gove', 'once'));
isRTGOVE = isRTGOVE || identifySite(site,{'^ALT'});

% set activity so be able to select correct attributes
activity = 'AIMS';
if isIMOS
    activity = 'IMOS';
elseif isSOI
    activity = 'SOI';
elseif isMMP
    activity = 'AIMS-MMP';
elseif isRTGOVE
    activity = 'AIMS-RT-GOVE';
elseif isECORRAP
    activity = 'AIMS-ECORRAP';
end

fnh = str2func(['getAIMSmetadata_' metadataField]);

try
    metadataStr = fnh(site, dbsite, activity);
catch e
    disp(e);
    warning(['Unknown metadata field : ' metadataField]);
    metadataStr = 'UNKNOWN';
end

end

%%
function result = identifySite(site, token)
f = regexp(site, token);
g = cell2mat(f);
result = ~isempty(g);
end

%%
function [sitename, yy, mm] = splitSite(site)
strsplits = split(site,'-');
sitename = strsplits{1};
[yy,mm] = datevec(strsplits{2},'yymm');

end

%%
function metadataStr = getAIMSmetadata_naming_authority(site, dbsite, activity)

switch activity
    case 'IMOS'
        metadataStr = 'IMOS';
    otherwise
        metadataStr = 'AIMS';
end

end

%%
function metadataStr = getAIMSmetadata_project(site, dbsite, activity)

switch activity
    case 'IMOS'
        metadataStr = 'Integrated Marine Observing System (IMOS)';
    case 'SOI'
        metadataStr = 'Timor Sea Reef Connections';
    case 'AIMS-MMP'
        metadataStr = 'AIMS Marine Monitoring Program';
    case 'AIMS-ECORRAP'
        metadataStr = 'AIMS EcoRRAP';
    otherwise
        if ~isempty(dbsite.ResearchActivity)
            metadataStr = ['AIMS : ' strtrim(dbsite.ResearchActivity)];
        else
            metadataStr = 'AIMS';
        end
end

end

%%
function metadataStr = getAIMSmetadata_institution(site, dbsite, activity)

switch activity
    case 'IMOS'
        if contains(site, {'NRS'})
            metadataStr = 'ANMN-NRS';
        else
            metadataStr = 'ANMN-QLD';
        end
    otherwise
        metadataStr = 'AIMS';
end

end

%%
function metadataStr = getAIMSmetadata_abstract(site, dbsite, activity)

aims_metadataStr = ['The Australian Institute of Marine Science (AIMS) ',...
    'is Australia�s tropical marine research agency. We play a ',...
    'pivotal role in providing large-scale, long-term and ',...
    'world-class research that helps governments, industry and ',...
    'the wider community to make informed decisions about the ',...
    'management of Australia�s marine estate. AIMS is a ',...
    'Commonwealth statutory authority established by the ',...
    'Australian Institute of Marine Science Act 1972.'];

switch activity
    case 'IMOS'
        metadataStr = ['The Queensland and Northern Australia mooring ',...
            'sub-facility is operated by the Australian Institute of Marine ',...
            'Science.  The sub-facility is responsible for ',...
            'moorings in two geographic regions: Queensland''s Great Barrier ',...
            'Reef and Northern Australia; ',...
            'where National Reference Stations and a number of regional moorings are maintained.'];
    case 'SOI'
        metadataStr = ['About halfway between Northwestern Australia ',...
            'and Indonesia lie some of the planet''s most remote and ',...
            'healthy coral reefs, with biodiversity in places rivaling ',...
            'that of the much better known Great Barrier Reef. Yet the ',...
            'physical connections between these reefs, the factors ',...
            'responsible for their health, and the conditions most ',...
            'likely to threaten them are not fully understood. In April 2015, ',...
            'the RV Falkor steamed to the region for a collaborative ',...
            'project aimed at exploring these connections. The work ',...
            'includes expanding on previous research at shallower reefs, ',...
            'as well as the first ever exploration of some deeper sites.'];
    case 'AIMS-ECORRAP'
        metadataStr = [aims_metadataStr ' The EcoRRAP R&D Subprogram '...
            'fills key knowledge gaps essential for the success and ',...
            'cost-effectiveness of reef restoration interventions. An ',...
            'integrated field program, EcoRRAP provides data on region-, ',...
            'temperature- and species-specific coral life-histories. It ',...
            'quantifies natural rates of recovery and adaptation in response ',...
            'to global and local changes, as well as rates of recovery in ',...
            'response to interventions. The central objective is to ',...
            'optimise interventions by understanding the ,how, where, and ',...
            'when. of natural reef recovery. This foundational data will ',...
            'help inform assumptions and decisions across the whole of RRAP ',...
            'and enable the success and cost-effectiveness of intervention ',...
            'research and development.'];
    case {'AIMS-MMP', 'AIMS'}
        metadataStr = aims_metadataStr;
    otherwise
        metadataStr = aims_metadataStr;
end

end

%%
function metadataStr = getAIMSmetadata_references(site, dbsite, activity)

switch activity
    case 'IMOS'
        metadataStr = 'http://imos.org.au, http://www.aims.gov.au/imosmoorings/';
    case 'SOI'
        metadataStr = 'http://data.aims.gov.au/, http://www.schmidtocean.org/story/show/3493';
    case 'AIMS-ECORRAP'
        metadataStr = 'http://data.aims.gov.au/, https://gbrrestoration.org/program/ecorrap/';
    case {'AIMS-MMP', 'AIMS'}
        metadataStr = 'http://data.aims.gov.au/';
    otherwise
        metadataStr = 'http://data.aims.gov.au/';
end

end

%%
function metadataStr = getAIMSmetadata_principal_investigator(site, dbsite, activity)

switch activity
    case 'IMOS'
        if identifySite(site,{'^GBR','NRSYON'})
            metadataStr = 'AIMS, Q-IMOS';
        elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN', 'NWS'})
            metadataStr = 'AIMS, WAIMOS';
        elseif identifySite(site,{'NRSDAR'})
            metadataStr = 'IMOS';
        elseif identifySite(site,{'TAN', 'CAM'})
            metadataStr = 'AIMS';
        else
            metadataStr = 'IMOS';
        end
    case 'SOI'
        metadataStr = 'AIMS, UWA';
    case {'AIMS-MMP', 'AIMS-ECORRAP', 'AIMS'}
        metadataStr = 'AIMS';
    otherwise
        metadataStr = 'AIMS';
end

% if identifySite(site,{'^GBR','NRSYON'})
%     metadataStr = 'AIMS, Q-IMOS';
% elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN', 'NWS'})
%     metadataStr = 'AIMS, WAIMOS';
% elseif identifySite(site,{'NRSDAR'})
%     metadataStr = 'IMOS';
% elseif identifySite(site,{'CAM', 'TAN'})
%     metadataStr = 'AIMS';
% elseif identifySite(site,{'SCR'})
%     metadataStr = 'AIMS, UWA';
% else
%     metadataStr = 'AIMS';
% end

end

%%
function metadataStr = getAIMSmetadata_principal_investigator_email(site, dbsite, activity)

switch activity
    case 'IMOS'
        metadataStr = 'dse@aims.gov.au';
    case 'SOI'
        metadataStr = 'adc@aims.gov.au, greg.ivey@uwa.edu.au';
    otherwise
        metadataStr = 'dse@aims.gov.au';
end

% if identifySite(site,{'^GBR','NRSYON'})
%     metadataStr = 'm.cahill@aims.gov.au';
% elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN', 'NWS'})
%     metadataStr = 'm.cahill@aims.gov.au';
% elseif identifySite(site,{'NRSDAR'})
%     metadataStr = 'm.cahill@aims.gov.au';
% elseif identifySite(site,{'CAM', 'TAN'})
%     metadataStr = 'm.cahill@aims.gov.au';
% elseif identifySite(site,{'SCR'})
%     metadataStr = 'adc@aims.gov.au, greg.ivey@uwa.edu.au';
% else
%     %metadataStr = 'info@emii.org.au';
%     metadataStr = 'adc@aims.gov.au';
% end

end

%%
function metadataStr = getAIMSmetadata_institution_references(site, dbsite, activity)

switch activity
    case 'IMOS'
        metadataStr = 'http://www.aims.gov.au/imosmoorings/, http://www.imos.org.au/aodn.html';
    case 'SOI'
        metadataStr = 'http://data.aims.gov.au, http://www.schmidtocean.org, http://www.imos.org.au/aodn.html';
    case 'AIMS-ECORRAP'
        metadataStr = 'http://data.aims.gov.au/, https://gbrrestoration.org/program/ecorrap/';
    case 'AIMS'
        metadataStr = 'http://data.aims.gov.au/';
    otherwise
        metadataStr = 'http://data.aims.gov.au/';
end

% if identifySite(site,{'SCR'})
%     metadataStr = 'http://data.aims.gov.au, http://www.schmidtocean.org, http://www.imos.org.au/aodn.html';
% elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN', 'GBR', 'NRS', 'NWS', 'TAN'})
%     metadataStr = 'http://www.aims.gov.au/imosmoorings/, http://www.imos.org.au/aodn.html';
% elseif identifySite(site,{'CAM'})
%     metadataStr = 'http://www.aims.gov.au/imosmoorings/, http://www.imos.org.au/aodn.html';
% else
%     metadataStr = 'http://data.aims.gov.au';
% end

end

%%
function metadataStr = getAIMSmetadata_acknowledgement(site, dbsite, activity)

switch activity
    case 'IMOS' % for imos-toolbox v2.6.7+
        metadataStr = getAIMSmetadata_acknowledgement_imos(site, dbsite, activity);
    case 'SOI'
        metadataStr = ['Any users of AIMS data are required to clearly acknowledge the source of the ',...
            'material in this format: "Data was sourced from the ',...
            'Australian Institute of Marine Science (AIMS). ',...
            'The support of the University of Western Australia (UWA), the ',...
            'Australian Research Council and the Schmidt ',...
            'Ocean Institute (SOI) is also acknowledged."'];
    otherwise
        metadataStr = ['Any users of AIMS data are required to clearly acknowledge the source of the ',...
            'material in this format: "Data was sourced from the ',...
            'Australian Institute of Marine Science (AIMS).'];
end

% if isIMOS
%     % v2.6.7+
%     defaultStr = ['Any users of IMOS data are required to clearly acknowledge the source ',...
%         'of the material derived from IMOS in the format: "Data was sourced from Australia''s ',...
%         'Integrated Marine Observing System (IMOS) - IMOS is enabled by the National Collaborative ',...
%         'Research Infrastructure Strategy (NCRIS)."'];
%
%     if identifySite(site,{'GBR','NRSYON'})
%         metadataStr = [defaultStr,...
%             ' The support of the Department of Employment Economic ',...
%             'Development and Innovation of the Queensland State ',...
%             'Government is also acknowledged. The support of the ',...
%             'Tropical Marine Network (University of Sydney, Australian ',...
%             'Museum, University of Queensland and James Cook University) ',...
%             'on the GBR is also acknowledged.'];
%     elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN'})
%         metadataStr = [defaultStr,...
%             ' The support of the Western Australian State Government is also acknowledged.'];
%     elseif identifySite(site,{'NRSDAR'})
%         metadataStr = [defaultStr,...
%             ' The support of the Darwin Port Corporation is also acknowledged.'];
%     elseif identifySite(site,{'CAM'})
%         metadataStr = [defaultStr,...
%             ' The collection of this data was funded by AIMS and IMOS and delivered ',...
%             'through the Queensland and Northern Australia Mooring sub-facility of the ',...
%             'Australian National Mooring Network operated by the Australian Institute of Marine Science.'];
%     elseif identifySite(site,{'TAN100'})
%         strsplits = split(site,'-');
%         [yy,mm] = datevec(strsplits{2},'yymm');
%         % from TAN100-1907 onwards mooring is WA,AIMS,IMOS supported
%         if yy>=2019 && yy<=2021
%             metadataStr = [defaultStr,...
%                 ' The collection of this data was funded by Western Australian State Government ',...
%                 'Department of Jobs, Tourism, Science and Innovation; AIMS and IMOS and delivered ',...
%                 'through the Queensland and Northern Australia Mooring sub-facility of the ',...
%                 'Australian National Mooring Network operated by the Australian Institute of Marine Science.'];
%         else
%             metadataStr = [defaultStr,...
%                 ' The collection of this data was funded by AIMS and delivered ',...
%                 'through the Queensland and Northern Australia Mooring sub-facility of the ',...
%                 'Australian National Mooring Network operated by the Australian Institute of Marine Science.'];
%         end
%     else
%         metadataStr = defaultStr;
%     end
% else % non IMOS
%     if identifySite(site,{'SCR'})
%         metadataStr = ['Any users of AIMS data are required to clearly acknowledge the source of the ',...
%             'material in this format: "Data was sourced from the ',...
%             'Australian Institute of Marine Science (AIMS). ',...
%             'The support of the University of Western Australia (UWA), the ',...
%             'Australian Research Council and the Schmidt ',...
%             'Ocean Institute (SOI) is also acknowledged."'];
%     else
%         metadataStr = ['Any users of AIMS data are required to clearly acknowledge the source of the ',...
%             'material in this format: "Data was sourced from the ',...
%             'Australian Institute of Marine Science (AIMS).'];
%     end
% end

end

function metadataStr = getAIMSmetadata_acknowledgement_imos(site, dbsite, activity)
% getAIMSmetadata_acknowledgement_imos helper function for convoluted imos
% acknowledgement

% v2.6.7+
defaultStr = ['Any users of IMOS data are required to clearly acknowledge the source ',...
    'of the material derived from IMOS in the format: "Data was sourced from Australia''s ',...
    'Integrated Marine Observing System (IMOS) - IMOS is enabled by the National Collaborative ',...
    'Research Infrastructure Strategy (NCRIS)."'];

if identifySite(site,{'GBR','NRSYON'})
    metadataStr = [defaultStr,...
        ' The support of the Department of Employment Economic ',...
        'Development and Innovation of the Queensland State ',...
        'Government is also acknowledged. The support of the ',...
        'Tropical Marine Network (University of Sydney, Australian ',...
        'Museum, University of Queensland and James Cook University) ',...
        'on the GBR is also acknowledged.'];
elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN'})
    metadataStr = [defaultStr,...
        ' The support of the Western Australian State Government is also acknowledged.'];
elseif identifySite(site,{'NRSDAR'})
    metadataStr = [defaultStr,...
        ' The support of the Darwin Port Corporation is also acknowledged.'];
elseif identifySite(site,{'CAM'})
    metadataStr = [defaultStr,...
        ' The collection of this data was funded by AIMS and IMOS and delivered ',...
        'through the Queensland and Northern Australia Mooring sub-facility of the ',...
        'Australian National Mooring Network operated by the Australian Institute of Marine Science.'];
elseif identifySite(site,{'TAN100'})
    strsplits = split(site,'-');
    [yy, mm] = datevec(strsplits{2},'yymm');
    % from TAN100-1907 onwards mooring is WA,AIMS,IMOS supported
    if yy>=2019 && yy<=2021
        metadataStr = [defaultStr,...
            ' The collection of this data was funded by Western Australian State Government ',...
            'Department of Jobs, Tourism, Science and Innovation; AIMS and IMOS and delivered ',...
            'through the Queensland and Northern Australia Mooring sub-facility of the ',...
            'Australian National Mooring Network operated by the Australian Institute of Marine Science.'];
    else
        metadataStr = [defaultStr,...
            ' The collection of this data was funded by AIMS and delivered ',...
            'through the Queensland and Northern Australia Mooring sub-facility of the ',...
            'Australian National Mooring Network operated by the Australian Institute of Marine Science.'];
    end
else
    metadataStr = defaultStr;
end

end

%%
function metadataStr = getAIMSmetadata_project_acknowledgement(site, dbsite, activity)
% getAIMSmetadata_project_acknowledgement old style acknowledgement. Deprecated.
% Kept for reference

switch activity
    case 'IMOS'
        if identifySite(site,{'GBR','NRSYON'})
            metadataStr = ['The collection of this data was funded by IMOS ',...
                'and delivered through the Queensland and Northern Australia ',...
                'Mooring sub-facility of the Australian National Mooring Network ',...
                'operated by the Australian Institute of Marine Science. ',...
                'IMOS is supported by the Australian Government through the ',...
                'National Collaborative Research Infrastructure Strategy, ',...
                'the Super Science Initiative and the Department of Employment, ',...
                'Economic Development and Innovation of the Queensland State ',...
                'Government. The support of the Tropical Marine Network ',...
                '(University of Sydney, Australian Museum, University of ',...
                'Queensland and James Cook University) on the GBR is also ',...
                'acknowledged.'];
        elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN'})
            metadataStr = ['The collection of this data was funded by IMOS ',...
                'and delivered through the Queensland and Northern Australia ',...
                'Mooring sub-facility of the Australian National Mooring Network ',...
                'operated by the Australian Institute of Marine Science. ',...
                'IMOS is supported by the Australian Government through the ',...
                'National Collaborative Research Infrastructure Strategy, ',...
                'the Super Science Initiative and the Western Australian State Government. '];
        elseif identifySite(site,{'NRSDAR'})
            metadataStr = ['The collection of this data was funded by IMOS',...
                'and delivered through the Queensland and Northern Australia',...
                'Mooring sub-facility of the Australian National Mooring Network',...
                'operated by the Australian Institute of Marine Science.',...
                'IMOS is supported by the Australian Government through the',...
                'National Collaborative Research Infrastructure Strategy,',...
                'and the Super Science Initiative. The support of the Darwin ',...
                'Port Corporation is also acknowledged'];
        else
            metadataStr = ['The collection of this data was funded by IMOS ',...
                'and delivered through the Queensland and Northern Australia ',...
                'Mooring sub-facility of the Australian National Mooring Network ',...
                'operated by the Australian Institute of Marine Science. ',...
                'IMOS is supported by the Australian Government through the ',...
                'National Collaborative Research Infrastructure Strategy, ',...
                'and the Super Science Initiative.'];
        end
    case 'SOI'
        metadataStr = ['Any users of AIMS data are required to clearly acknowledge the source of the ',...
            'material in this format: "Data was sourced from the ',...
            'Australian Institute of Marine Science (AIMS). ',...
            'The support of the University of Western Australia (UWA), the ',...
            'Australian Research Council and the Schmidt ',...
            'Ocean Institute (SOI) is also acknowledged."'];
    otherwise
        metadataStr = ['Any users of AIMS data are required to clearly acknowledge the source of the ',...
            'material in this format: "Data was sourced from the ',...
            'Australian Institute of Marine Science (AIMS).'];
end

end

%%
function metadataStr = getAIMSmetadata_disclaimer(site, dbsite, activity)

switch activity
    case 'IMOS'
        metadataStr = 'Data, products and services from IMOS are provided "as is" without any warranty as to fitness for a particular purpose.';
    otherwise
        metadataStr = 'Data, products and services from AIMS are provided "as is" without any warranty as to fitness for a particular purpose.';
end

end

%%
function metadataStr = getAIMSmetadata_citation(site, dbsite, activity)

switch activity
    case 'IMOS'
        metadataStr = 'The citation in a list of references is: "IMOS [year-of-data-download], [Title], [data-access-URL], accessed [date-of-access].".';
    otherwise
        metadataStr = 'The citation in a list of references is: "AIMS [year-of-data-download], [Title], [data-access-URL], accessed [date-of-access].".';
end

end

%%
function metadataStr = getAIMSmetadata_data_centre(site, dbsite, activity)

switch activity
    case 'IMOS'
        metadataStr = 'Australian Ocean Data Network (AODN)';
    otherwise
        metadataStr = 'AIMS Data Centre (ADC)';
end

end

%%
function metadataStr = getAIMSmetadata_data_centre_email(site, ~, activity)

switch activity
    case 'IMOS'
        metadataStr = 'info@aodn.org.au';
    otherwise
        metadataStr = 'adc@aims.gov.au';
end

end

%%
function metadataStr = getAIMSmetadata_local_time_zone(site, dbsite, activity)
% getAIMSmetadata_local_time_zone guess at local time zone for the site.
% Note does not take into any account daylight saving trial in WA were
% held over the summers of 2006–2007, 2007–2008 and 2008–2009

switch activity
    case 'IMOS'
        if identifySite(site,{'GBR','NRSYON'})
            metadataStr = '+10';
        elseif identifySite(site,{'ITF','NRSDAR','NWSLYN'})
            % NWSLYN in Northern Territory local timezone
            metadataStr = '+9.5';
        elseif identifySite(site,{'^PIL', '^KIM', 'NRSNIN', '^NIN', '^TAN', '^CAM','^NWS'})
            % all other NWS mooring in WA local timezone
            metadataStr = '+8';
        else
            warning('Unkown IMOS getAIMSmetadata_local_time_zone. Setting default +10. Check that is correct for your site.');
            metadataStr = '+10';
        end
    case 'SOI'
        metadataStr = '+8';
    case {'AIMS-MMP', 'AIMS-ECORRAP'}
        metadataStr = '+10';
    case 'AIMS-RT-GOVE'
        metadataStr = '+9.5';
    otherwise
        warning('Use of getAIMSmetadata_local_time_zone is problematic. Setting default +10. Check that is correct for your site.');
        metadataStr = '+10';
end

end


