function metadataStr = setAIMSmetadata(site,metadataField)
%This function allows a generic config file to be used with the
%IMOS toolbox for processing AIMS data.
%The function call [mat setAIMSmetadata('[ddb Site]','naming_authority')]
%in global_attributes_timeSeries.txt calls this function with the site and the
%datafield as arguements. This function then passes back an appropriate
%string for that site and field.
%If the site is not reconised, default strings are returned.

%%
% IMOS Site Names
% NRS : National Reference Stations eg
%   NRSDAR : Darwin
%   NRSYON : Yongala
%   NRSNIN : Ningaloo
% ITF : Indonesian Through Flow (shallow) mooring array
% PIL : Pilbara mooring array
% KIM : Kimberley mooring array
% NIN : Ningaloo Reef Tantabiddi 50m mooring (IMOS)
% GBR : GBR mooring array
% TAN : Ningaloo Reef Tantabiddi 100m  mooring (AIMS)
% CAM : Camden Sound moorings CAM050/CAM100 Aug-2014 -- Jul-2015
%
% Other Site Names
% SCR : RV Falkor cruise FK150410 (AIMS 6204) at Scott Reef and surrounds

%%
% Is this site an IMOS related one : CTDs can have a site label that is 
% not a physical site with lat/lon but is usually starts with site name, 
% so first do a hardcoded comparison with known AIMS IMOS sites. Else test 
% if site is an IMOS one by looking at it's associated db ResearchActivity.
imos_sites_prefix = {'NRS', 'GBR', 'NWS', 'ITF', 'KIM', 'PIL', 'TAN'};
dbsite = executeQuery( 'Sites', 'Site', site);
isIMOS = startsWith(site, imos_sites_prefix);
if ~isIMOS
    isIMOS = isfield(dbsite, 'ResearchActivity') && ~isempty(dbsite.ResearchActivity) && ~isempty(regexp(dbsite.ResearchActivity, '^IMOS'));
end

try
    fnh = str2func(['getAIMSmetadata_' metadataField]);
    metadataStr = fnh(site, dbsite, isIMOS);
catch e
    disp(e);
    warning(['Unknown metadata field : ' metadataField]);
    metadataStr = 'UNKNOWN';
end

end

%%
function result = identifySite(site,token)
f = regexp(site,token);
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
function metadataStr = getAIMSmetadata_naming_authority(site, dbsite, isIMOS)

if isIMOS
    metadataStr = 'IMOS';
else
    metadataStr = 'AIMS';
end

end

%%
function metadataStr = getAIMSmetadata_project(site, dbsite, isIMOS)

if isIMOS
    metadataStr = 'Integrated Marine Observing System (IMOS)';
else
    if identifySite(site,{'^SCR'})
        metadataStr = 'Timor Sea Reef Connections';
    elseif ~isempty(dbsite.ResearchActivity)
        metadataStr = ['AIMS : ' strtrim(dbsite.ResearchActivity)];
    else
        metadataStr = 'AIMS';
    end
end

end

%%
function metadataStr = getAIMSmetadata_institution(site, dbsite, isIMOS)

if contains(site, {'NRS'})
    metadataStr = 'ANMN-NRS';
else
    if isIMOS
        metadataStr = 'ANMN-QLD';
    else
        metadataStr = 'AIMS-QLD';
    end
end

end

%%
function metadataStr = getAIMSmetadata_abstract(site, dbsite, isIMOS)

if isIMOS
    metadataStr = ['The Queensland and Northern Australia mooring ',...
        'sub-facility is operated by the Australian Institute of Marine ',...
        'Science.  The sub-facility is responsible for ',...
        'moorings in two geographic regions: Queensland''s Great Barrier ',...
        'Reef and Northern Australia; ',...
        'where National Reference Stations and a number of regional moorings are maintained.'];
else
    if identifySite(site,{'SCR'})
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
    else
        metadataStr = ['The Australian Institute of Marine Science (AIMS) ',...
            'is Australia�s tropical marine research agency. We play a ',...
            'pivotal role in providing large-scale, long-term and ',...
            'world-class research that helps governments, industry and ',...
            'the wider community to make informed decisions about the ',...
            'management of Australia�s marine estate. AIMS is a ',...
            'Commonwealth statutory authority established by the ',...
            'Australian Institute of Marine Science Act 1972.'];
    end
end

end

%%
function metadataStr = getAIMSmetadata_references(site, dbsite, isIMOS)

if isIMOS
    metadataStr = 'http://imos.org.au, http://www.aims.gov.au/imosmoorings/';
else
    if identifySite(site,{'SCR'})
        metadataStr = 'http://data.aims.gov.au/, http://www.schmidtocean.org/story/show/3493';
    else
        metadataStr = 'http://data.aims.gov.au/';
    end
end

end

%%
function metadataStr = getAIMSmetadata_principal_investigator(site, dbsite, isIMOS)

if identifySite(site,{'^GBR','NRSYON'})
    metadataStr = 'AIMS, Q-IMOS';
elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN', 'NWS'})
    metadataStr = 'AIMS, WAIMOS';
elseif identifySite(site,{'NRSDAR'})
    metadataStr = 'IMOS';
elseif identifySite(site,{'CAM', 'TAN'})
    metadataStr = 'AIMS';
elseif identifySite(site,{'SCR'})
    metadataStr = 'AIMS, UWA';
else
    metadataStr = 'AIMS';
end

end

%%
function metadataStr = getAIMSmetadata_principal_investigator_email(site, dbsite, isIMOS)

if identifySite(site,{'^GBR','NRSYON'})
    metadataStr = 'm.cahill@aims.gov.au';
elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN', 'NWS'})
    metadataStr = 'm.cahill@aims.gov.au';
elseif identifySite(site,{'NRSDAR'})
    metadataStr = 'm.cahill@aims.gov.au';
elseif identifySite(site,{'CAM', 'TAN'})
    metadataStr = 'm.cahill@aims.gov.au';
elseif identifySite(site,{'SCR'})
    metadataStr = 'adc@aims.gov.au, greg.ivey@uwa.edu.au';
else
    %metadataStr = 'info@emii.org.au';
    metadataStr = 'adc@aims.gov.au';
end

end

%%
function metadataStr = getAIMSmetadata_institution_references(site, dbsite, isIMOS)

if identifySite(site,{'SCR'})
    metadataStr = 'http://data.aims.gov.au, http://www.schmidtocean.org, http://www.imos.org.au/aodn.html';
elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN', 'GBR', 'NRS', 'NWS', 'TAN'})
    metadataStr = 'http://www.aims.gov.au/imosmoorings/, http://www.imos.org.au/aodn.html';
elseif identifySite(site,{'CAM'})
    metadataStr = 'http://www.aims.gov.au/imosmoorings/, http://www.imos.org.au/aodn.html';
else
    metadataStr = 'http://data.aims.gov.au';
end

end

%%
function metadataStr = getAIMSmetadata_acknowledgement(site, dbsite, isIMOS)

if isIMOS
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
        [yy,mm] = datevec(strsplits{2},'yymm');
        % from TAN100-1907 onwards mooring is WA,AIMS,IMOS supported
        if yy>=2019
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
else % non IMOS
    if identifySite(site,{'SCR'})
        metadataStr = ['Any users of AIMS data are required to clearly acknowledge the source of the ',...
            'material in this format: "Data was sourced from the ',...
            'Australian Institute of Marine Science (AIMS). ',...
            'The support of the University of Western Australia (UWA), the ',...
            'Australian Research Council and the Schmidt ',...
            'Ocean Institute (SOI) is also acknowledged."'];
    else
        metadataStr = ['Any users of AIMS data are required to clearly acknowledge the source of the ',...
            'material in this format: "Data was sourced from the ',...
            'Australian Institute of Marine Science (AIMS).'];
    end
end

end

%%
function metadataStr = getAIMSmetadata_project_acknowledgement(site, dbsite, isIMOS)

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

end

%%
function metadataStr = getAIMSmetadata_disclaimer(site, dbsite, isIMOS)

if isIMOS
    metadataStr = 'Data, products and services from IMOS are provided "as is" without any warranty as to fitness for a particular purpose.';
else
    metadataStr = 'Data, products and services from AIMS are provided "as is" without any warranty as to fitness for a particular purpose.';
end

end

%%
function metadataStr = getAIMSmetadata_citation(site, dbsite, isIMOS)

if isIMOS
    metadataStr = 'The citation in a list of references is: "IMOS [year-of-data-download], [Title], [data-access-URL], accessed [date-of-access].".';
else
    metadataStr = 'The citation in a list of references is: "AIMS [year-of-data-download], [Title], [data-access-URL], accessed [date-of-access].".';
end

end

%%
function metadataStr = getAIMSmetadata_data_centre(site, dbsite, isIMOS)

if isIMOS
    metadataStr = 'Australian Ocean Data Network (AODN)';
else
    metadataStr = 'AIMS Data Centre (ADC)';
end

end

%%
function metadataStr = getAIMSmetadata_data_centre_email(site, ~, isIMOS)

if isIMOS
    metadataStr = 'info@aodn.org.au';
else
    metadataStr = 'adc@aims.gov.au';
end

end

%%
function metadataStr = getAIMSmetadata_local_time_zone(site, dbsite, isIMOS)

if identifySite(site,{'GBR','NRSYON'})
    metadataStr = '+10';
elseif identifySite(site,{'ITF','NRSDAR','NWSLYN'})
    metadataStr = '+9.5';
elseif identifySite(site,{'PIL', 'KIM', 'NIN', 'SCR', 'TAN', 'CAM','^NWS'})
    metadataStr = '+8';
else
    warning('Use of getAIMSmetadata_local_time_zone is problematic. Setting default +10. Check that is correct for your site.');
    metadataStr = '+10';
end

end


