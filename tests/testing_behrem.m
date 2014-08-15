aredum = true(1,length(EEG.epoch));

for a = 1:length(EEG.epoch)
    if length(EEG.epoch(a).eventtype) > 1
        aredum(a) = false;
    end
end

% look for types:
tps = unique({EEG.event.type});

% what happens after mask and before name