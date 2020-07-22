function metadataStr = setAIMSmetadata(site,metadataField)
%This function allows a generic config file to be used with the
%IMOS toolbox for processing AIMS data.
%The function call [mat setAIMSmetadata('[ddb Site]','naming_authority')]
%in global_attributes.txt calls this function with the site and the
%datafield as arguements. This function then passes back an appropriate
%string for that site and field.
%If the site is not reconised, default "IMOS" strings are returned.

%%
% Site Names
% NRS : National Reference Stations eg
%   NRSDAR : Darwin
%   NRSYON : Yongala
%   NRSNIN : Ningaloo
% ITF : Indonesian Through Flow (shallow) mooring array
% PIL : Pilbara mooring array
% KIM : Kimberley mooring array
% NIN : Ningaloo Reef Tantabiddi 50m mooring (IMOS)
% TAN : Ningaloo Reef Tantabiddi 100m  mooring (AIMS)
% SCR : RV Falkor cruise FK150410 (AIMS 6204) at Scott Reef and surrounds
% CAM : Camden Sound moorings CAM050/CAM100 Aug-2014 -- Jul-2015
% TAN100 : Jul-2010 onwards
%

%%
switch metadataField
    % project
    case 'project'
        metadataStr = getAIMSmetadata_project(site);
        return

        % institution
    case 'institution'
        metadataStr = getAIMSmetadata_institution(site);
        return

        % abstract
    case 'abstract'
        metadataStr = getAIMSmetadata_abstract(site);
        return
        
        % references
    case 'references'
        metadataStr = getAIMSmetadata_references(site);
        return
        
        % principal_investigator
    case 'principal_investigator'
        metadataStr = getAIMSmetadata_principal_investigator(site);
        return

        % principal_investigator_email
    case 'principal_investigator_email'
        metadataStr = getAIMSmetadata_principal_investigator_email(site);
        return
        
        % institution_references
    case 'institution_references'
        metadataStr = getAIMSmetadata_institution_references(site);
        return
        
        % acknowledgement, imosToolbox from v2.5 onwards
    case 'acknowledgement'
        metadataStr = getAIMSmetadata_acknowledgement(site);
        return
        
        % project_acknowledgement, imosToolbox to v2.4
    case 'project_acknowledgement'
        metadataStr = getAIMSmetadata_project_acknowledgement(site);
        return
        
        % local_time_zone
    case 'local_time_zone'
        metadataStr = getAIMSmetadata_local_time_zone(site);
        return
        
end
end

%%
function result = identifySite(site,token)
f = regexp(site,token);
g = cell2mat(f);
result = ~isempty(g);
end

%%
function metadataStr = getAIMSmetadata_project(site)

if identifySite(site,{'SCR'})
    metadataStr = 'Timor Sea Reef Connections';
elseif identifySite(site,{'CAM', 'TAN'})
    % current AODN ingest isn't quite setup for not IMOS data yet. Being looked at.
    %metadataStr = 'AIMS';
    metadataStr = 'Integrated Marine Observing System (IMOS)';
else
    metadataStr = 'Integrated Marine Observing System (IMOS)';
end

end

%%
function metadataStr = getAIMSmetadata_institution(site)

if identifySite(site,{'NRS'})
    metadataStr = 'ANMN-NRS';
elseif identifySite(site,{'SCR'})
    metadataStr = 'AIMS';
elseif identifySite(site,{'CAM', 'TAN'})
    % current AODN ingest isn't quite setup for not IMOS data yet. Being looked at.
    %metadataStr = 'AIMS';
    metadataStr = 'ANMN-QLD';
else
    metadataStr = 'ANMN-QLD';
end

end

%%
function metadataStr = getAIMSmetadata_abstract(site)

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
    metadataStr = ['The Queensland and Northern Australia mooring ',...
        'sub-facility is based at the Australian Institute of Marine ',...
        'Science in Townsville.  The sub-facility is responsible for ',...
        'moorings in two geographic regions: Queensland Great Barrier ',...
        'Reef and Northern Australia; ',...
        'where National Reference Stations and a number of regional moorings are maintained.'];
end

end

%%
function metadataStr = getAIMSmetadata_references(site)

if identifySite(site,{'SCR'})
    metadataStr = 'http://data.aims.gov.au/, http://www.schmidtocean.org/story/show/3493';
else
    metadataStr = 'http://imos.org.au, http://www.aims.gov.au/imosmoorings/';
end

end

%%
function metadataStr = getAIMSmetadata_principal_investigator(site)

if identifySite(site,{'GBR','NRSYON'})
    metadataStr = 'AIMS, Q-IMOS';
elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN'})
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
function metadataStr = getAIMSmetadata_principal_investigator_email(site)

if identifySite(site,{'GBR','NRSYON'})
    metadataStr = 'c.steinberg@aims.gov.au';
elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN'})
    metadataStr = 'c.steinberg@aims.gov.au';
elseif identifySite(site,{'NRSDAR'})
    metadataStr = 'c.steinberg@aims.gov.au';
elseif identifySite(site,{'CAM', 'TAN'})
    metadataStr = 'c.steinberg@aims.gov.au';
elseif identifySite(site,{'SCR'})
    metadataStr = 'adc@aims.gov.au, greg.ivey@uwa.edu.au';
else
    %metadataStr = 'info@emii.org.au';
    metadataStr = 'adc@aims.gov.au';
end

end

%%
function metadataStr = getAIMSmetadata_institution_references(site)

if identifySite(site,{'SCR'})
    metadataStr = 'http://data.aims.gov.au, http://www.schmidtocean.org, http://www.imos.org.au/aodn.html';
elseif identifySite(site,{'ITF','PIL', 'KIM', 'NIN', 'GBR', 'NRS'})
    metadataStr = 'http://www.aims.gov.au/imosmoorings/, http://www.imos.org.au/aodn.html';
elseif identifySite(site,{'CAM', 'TAN'})
    metadataStr = 'http://www.aims.gov.au/imosmoorings/, http://www.imos.org.au/aodn.html';
else
    metadataStr = 'http://data.aims.gov.au';
end

end

%%
function metadataStr = getAIMSmetadata_acknowledgement(site)
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
elseif identifySite(site,{'CAM', 'TAN'})
    metadataStr = [defaultStr,...
        ' The collection of this data was funded by AIMS and IMOS and delivered ',...
        'through the Queensland and Northern Australia Mooring sub-facility of the ',...
        'Australian National Mooring Network operated by the Australian Institute of Marine Science.'];
elseif identifySite(site,{'SCR'})
    metadataStr = ['Any users of AIMS data are required to clearly acknowledge the source of the ',...
        'material in this format: "Data was sourced from the ',...
        'Australian Institute of Marine Science (AIMS). ',...
        'The support of the University of Western Australia (UWA), the ',...
        'Australian Research Council and the Schmidt ',...
        'Ocean Institute (SOI) is also acknowledged."'];
else
    metadataStr = defaultStr;
end

end

%%
function metadataStr = getAIMSmetadata_project_acknowledgement(site)

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
function metadataStr = getAIMSmetadata_local_time_zone(site)

if identifySite(site,{'GBR','NRSYON'})
    metadataStr = '+10';
elseif identifySite(site,{'ITF','NRSDAR','NWSLYN'})
    metadataStr = '+9.5';
elseif identifySite(site,{'PIL', 'KIM', 'NIN', 'SCR', 'TAN', 'CAM','NWSBRW','NWSROW','NWSBAR'})
    metadataStr = '+8';
else
    metadataStr = '+10';
end

end


