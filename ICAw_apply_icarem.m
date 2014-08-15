function  ICAw = ICAw_apply_icarem(ICAw, rec)

% Applies remove and ifremove info from ICA_desc
% to ICAw, cool stuff!

% if r's not given - assume all records:
if ~exist('rec', 'var')
    rec = 1:length(ICAw);
end

% just simply apply reject from ICA_desc

% apply for all r:
for r = 1:length(rec)
    if femp(ICAw(rec(r)), 'ICA_desc') % ADD additional checks
        ICAw(rec(r)).ica_remove = find([ICAw(rec(r)).ICA_desc.reject]);
        ICAw(rec(r)).ica_ifremove = find([ICAw(rec(r)).ICA_desc.ifreject]);
    end
end
%