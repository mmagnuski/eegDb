function [isCenter, eventNames] = epoch_centering_events(EEG, eventNames)

% NOHELPINFO

if ~exist('eventNames', 'var')
	eventNames = unique({EEG.event.type});
end

% go through epochs and find epoch-centering event
epN = length(EEG.epoch);
isCenter = false(length(eventNames), epN);

for e = 1:epN
	times = cell2mat(EEG.epoch(e).eventlatency);
	zero_event = times == 0;
	zero_event_name = EEG.epoch(e).eventtype(zero_event);

	for evtp = zero_event_name
		nms = strcmp(evtp{1}, eventNames);

		if any(nms)
			isCenter(nms, e) = true;
		end

	end
end