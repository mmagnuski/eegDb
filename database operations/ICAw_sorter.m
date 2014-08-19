function ICAw = ICAw_sorter(ICAw)

% NOHELPINFO
% sort fields of ICAw:

% CHANGE - once eegDb field structure is settled upon
%          this function should be changed to reflect
%          that structure

fldord = {'subjectcode'; 'filename'; 'filepath'; 'datainfo';...
    'tasktype'; 'badchan'; 'filter'; 'usecleanline'; 'onesecepoch'; 'winlen';
    'distance'; 'epoch_events'; 'epoch_limits';...
    'epoch_segment'; 'prerej'; 'postrej'; 'removed';...
    'icaweights'; 'icasphere';...
    'icawinv'; 'icachansind'; 'ica_remove'; 'ica_ifremove'; ...
    'ica_desc'; 'addrem_rel'; 'addrem_win'; 'adjust'; 'notes';...
    'warnings'};

additf = setdiff(fieldnames(ICAw), fldord);
[~, ind] = intersect(fldord, fieldnames(ICAw));
fldord = fldord(sort(ind));
flds = [fldord; additf];
ICAw = orderfields(ICAw, flds);