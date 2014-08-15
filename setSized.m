% updates memory load info in Sternberg files 
%%
function EEG=setSized(EEG)
memoryHOLDstart = strmatch('DIN8', {EEG.event.type});
EEG = pop_editeventfield( EEG, 'indices',  (memoryHOLDstart), 'setSIZE',  '0');
for tr=1:length(memoryHOLDstart)
    a=1;
    while memoryHOLDstart(tr)-a>0 && strcmp('DI16', EEG.event(memoryHOLDstart(tr)-a).type);
        a=a+1; 
    end
    EEG.event(memoryHOLDstart(tr)).setSIZE=a-1;
end