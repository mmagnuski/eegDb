function compsel_compare_changes(h, evnt)

% compare signal with and without rejected components

if strcmp(evnt.Key, 'c')
    info = getappdata(h, 'info');
    remcmp = find(info.comps.state == 1);
    
    if ~isempty(remcmp)
        EEG = getappdata(h, 'EEG');
        EEG2 = pop_subcomp(EEG, remcmp, 0);
        fst = fastplot(EEG, EEG2);
    end
end