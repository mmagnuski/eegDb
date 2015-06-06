function db = db_sorter(db)

% NOHELPINFO
% sort fields of db:

% CHANGE - once eegDb field structure is settled upon
%          this function should be changed to reflect
%          that structure

fldord = {'filename'; 'filepath'; 'datainfo';...
    'chan'; 'filter'; 'cleanline'; ...
    'epoch'; 'marks'; 'reject'; 'ICA';...
    'addrem_rel'; 'addrem_win'; 'notes';...
    'versions'; 'warnings'};

additf = setdiff(fieldnames(db), fldord);
[~, ind] = intersect(fldord, fieldnames(db));
fldord = fldord(sort(ind));
flds = [fldord; additf];
db = orderfields(db, flds);