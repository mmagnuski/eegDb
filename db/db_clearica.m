function db = db_clearica(db, r)

% db = db_clearica(db, r)
%
% removes ica info from a given record
% (both in the active 'front' and the
% current version)
%

ica_fields = {'icachansind', 'icasphere',...
    'icaweights', 'icawinv', 'remove',...
    'ifremove', 'desc'};

for f = 1:length(ica_fields)
    db(r).ICA.(ica_fields{f}) = [];
end
