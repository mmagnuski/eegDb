function  db = db_apply_icarem(db, rec)

% Applies remove and ifremove info from ICA_desc
% to db, cool stuff!
% 
% FIXHELPINFO

% if r's not given - assume all records:
if ~exist('rec', 'var')
    rec = 1:length(db);
end

% just simply apply reject from ICA_desc

% apply for all r:
for r = 1:length(rec)
    if femp(db(rec(r)).ICA, 'desc') % ADD additional checks
        db(rec(r)).ICA.remove = find([db(rec(r)).ICA.desc.reject]);
        db(rec(r)).ICA.ifremove = find([db(rec(r)).ICA.desc.ifreject]);
    end
end
%