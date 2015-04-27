function [isCenter, whichCenter, eventNames] = epoch_centering_events(EEG, eventNames)

% NOHELPINFO

if ~exist('eventNames', 'var')
    eventNames = unique({EEG.event.type});
end

% go through epochs and find epoch-centering event
epN = length(EEG.epoch);
isCenter = false(length(eventNames), epN);
whichCenter = zeros(1, epN);

for e = 1:epN
    % eventlatency sometimes is cell and sometimes mat...
    if iscell(EEG.epoch(e).eventlatency)
        times = cell2mat(EEG.epoch(e).eventlatency);
    else
        times = EEG.epoch(e).eventlatency;
    end

    zero_event = times == 0;

    if any(zero_event)
        whichCenter(e) = find(zero_event);
        zero_event_name = EEG.epoch(e).eventtype(zero_event);

        for evtp = zero_event_name
            nms = strcmp(evtp{1}, eventNames);

            if any(nms)
                isCenter(nms, e) = true;
            end

        end
    end
end