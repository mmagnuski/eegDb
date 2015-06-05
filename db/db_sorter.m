function ICAw = db_sorter(ICAw)

% NOHELPINFO
% sort fields of ICAw:

% CHANGE - once eegDb field structure is settled upon
%          this function should be changed to reflect
%          that structure

fldord = {'filename'; 'filepath'; 'datainfo';...
    'chan'; 'filter'; 'cleanline'; ...
    'epoch'; 'marks'; 'reject'; 'ICA';...
    'addrem_rel'; 'addrem_win'; 'notes';...
    'versions'; 'warnings'};

additf = setdiff(fieldnames(ICAw), fldord);
[~, ind] = intersect(fldord, fieldnames(ICAw));
fldord = fldord(sort(ind));
flds = [fldord; additf];
ICAw = orderfields(ICAw, flds);