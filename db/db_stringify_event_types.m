function EEG = db_stringify_event_types(EEG)

for e = 1:length(EEG.event)
    if isnumeric(EEG.event(e).type)
        EEG.event(e).type = num2str(EEG.event(e).type);
    end
end