function  ICAw = ICAw_apply_icarem(ICAw, rec)

% Applies remove and ifremove info from ICA_desc
% to ICAw, cool stuff!
% 
% FIXHELPINFO

% if r's not given - assume all records:
if ~exist('rec', 'var')
    rec = 1:length(ICAw);
end

% just simply apply reject from ICA_desc

% apply for all r:
for r = 1:length(rec)
    if femp(ICAw(rec(r)).ICA, 'desc') % ADD additional checks
        ICAw(rec(r)).ICA.remove = find([ICAw(rec(r)).ICA.desc.reject]);
        ICAw(rec(r)).ICA.ifremove = find([ICAw(rec(r)).ICA.desc.ifreject]);
    end
end
%