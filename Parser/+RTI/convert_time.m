function [time, timePerEnsemble] = convert_time(RTI)
%
% Compute time variable.
%
% Inputs:
%
% variable[struct] - array of structs containing an RTI Ensemble Data Sets
%
% Outputs:
%
% time[double] - the datenum time.
%
% Example:
%
% vs.Ensemble(7)=2001;
% vs.Ensemble(8)=2;
% vs.Ensemble(9)=3;
% vs.Ensemble(10)=4;
% vs.Ensemble(11)=56;
% vs.Ensemble(12)=12;
% vs.Ensemble(13)=0.5;
% time = RTI.convert_time(vs);
% assert(strcmpi('2001-02-03T04:56:12.005',datestr(time,'yyyy-mm-ddTHH:MM:SS.FFF')));
%

narginchk(1, 1)

if ~any(contains(fieldnames(RTI), 'Ensemble'))
    errormsg('RTI struct contains no Ensemble Data Set');
end

ens_year = arrayfun(@(x) x.Ensemble(7), RTI);
ens_month = arrayfun(@(x) x.Ensemble(8), RTI);
ens_day = arrayfun(@(x) x.Ensemble(9), RTI);
ens_hour = arrayfun(@(x) x.Ensemble(10), RTI);
ens_minute = arrayfun(@(x) x.Ensemble(11), RTI);
ens_second = arrayfun(@(x) x.Ensemble(12), RTI);
ens_hundreth_second = arrayfun(@(x) x.Ensemble(13), RTI);

time = datenum(ens_year, ens_month, ens_day, ens_hour, ens_minute, ens_second + ens_hundreth_second/100.0)';

first_profile_ping = arrayfun(@(x) x.Ensemble(3), RTI);
last_profile_ping = arrayfun(@(x) x.Ensemble(4), RTI);
timePerEnsemble = last_profile_ping - first_profile_ping;

end
