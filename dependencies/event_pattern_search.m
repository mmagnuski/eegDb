function events = event_pattern_search(EEG, event_pattern)

% events = event_pattern_search(EEG, event_pattern)
% this function looks for certain event patterns
% in EEG.event structure and returns event cell matrix
% where each cell contains indices of events that belong
% to one such pattern (repeated several times).
% Multiple patterns can be given as input.
%
% for example:
% you want to identify where baseline is present in a
% eeglab file. Unfortunatelly, the events do not have
% names 'eyes_open', 'eyes_closed' (you want to name
% them this way, but first you have to find them), but
% instead are marked by events 'DI64' and 'D128', which
% are also used to mark other things in the data.
% The only recognizable thing you know is that when
% these events appear in a certain pattern they mark
% baseline period. Concretely, the pattern could be:
% ('DI64', 'D128') * n but ignoring any interweaven
% 'DIN1' and 'DIN2' events
%
% in this specific case you could use event_pattern_search
% defining event_pattern the following way:
% event_pattern = {'baseline', {'DI64', 1; 'D128', 1},...
%        'ignore', {'DIN2','DIN1'}};
%
% then calling:
% events = event_pattern_search(EEG, event_pattern);
% would return you a structure
% where a field with the name of the pattern (in this
% case = 'baseline') stores a cell matrix of all occu-
% rances of this pattern. The occurrances are given as
% indices of events (their 'place' in EEG.event)
%
% coded by M. Magnuski, march 2013
% imponderabilion@gmail.com
% :)

if isempty(EEG.event)
    events = NaN;
else
    % checking if multiple patterns given:
    if iscell(event_pattern{1})
        start = 1;
        fin = length(event_pattern);
    else
        event_pattern = {event_pattern};
        start = 1; fin = 1;
    end
    
    for pat = start:fin
        types = {EEG.event.type};
        
        eventpattern.name = event_pattern{pat}{1};
        eventpattern.pattern = event_pattern{pat}{2};
        eventpattern.i = 2;
        eventpattern.numpat = 0;
        eventpattern.steps = size(eventpattern.pattern,1);
        eventpattern.found = false;
        
        eventpattern.in = false;
        eventpattern.lookfor = '';
        eventpattern.step = [];
        eventpattern.counter = 0;
        eventpattern.events = {};
        eventpattern.trail = [];
        eventpattern.fulltrail = [];
        
        if length(event_pattern{pat}) > 2 && strcmp('ignore',event_pattern{pat}{3})
            eventpattern.ignore = event_pattern{pat}{4};
        else
            eventpattern.ignore = [];
        end
        
        while eventpattern.i <= length(types);
            
            % if we are not on track:
            if ~eventpattern.in
                eventpattern.step = 1;
                eventpattern.i = eventpattern.i-1;
                eventpattern.lookfor = eventpattern.pattern{1,1};
                nextadr = find(strcmp(eventpattern.lookfor, ...
                    types(eventpattern.i:end)));
                
                if isempty(nextadr)
                    break
                else
                    eventpattern.i = eventpattern.i + nextadr(1);
                    eventpattern.in = true;
                    eventpattern.trail = eventpattern.i - 1;
                    eventpattern.counter = 1;
                end
            end
            
            % if we have counted enough of this event
            if eventpattern.counter == eventpattern.pattern...
                    {eventpattern.step,2}
                eventpattern.counter = 0;
                eventpattern.step = eventpattern.step + 1;
                
            end
            
            % we have full pattern exemplar
            if eventpattern.step > eventpattern.steps
                eventpattern.step = 1;
                eventpattern.fulltrail = [eventpattern.fulltrail,...
                    eventpattern.trail];
                eventpattern.trail = [];
            end
            
            eventpattern.lookfor = eventpattern.pattern...
                {eventpattern.step,1};
            
            % ==DEBUG==
            if eventpattern.i > length(types)
                continue
            end
            
            % checking the next event
            if strcmp(eventpattern.lookfor, types(eventpattern.i))
                eventpattern.trail = [eventpattern.trail, eventpattern.i];
                eventpattern.counter = eventpattern.counter + 1;
            elseif sum(strcmp(types(eventpattern.i), eventpattern.ignore)) >= 1
                % nothing :)
            else
                eventpattern.in = false;
                eventpattern.trail = [];
                if ~isempty(eventpattern.fulltrail)
                    eventpattern.numpat = eventpattern.numpat + 1;
                    eventpattern.events{eventpattern.numpat} =...
                        eventpattern.fulltrail;
                    eventpattern.fulltrail = [];
                end
                
            end
            eventpattern.i = eventpattern.i + 1;
        end
        
        % closing list:
        
        if eventpattern.in
            
            % if we have counted enough of this event
            if eventpattern.counter == eventpattern.pattern...
                    {eventpattern.step,2}
                eventpattern.counter = 0;
                eventpattern.step = eventpattern.step + 1;
                
            end
            
            % we have full pattern exemplar
            if eventpattern.step > eventpattern.steps
                eventpattern.step = 1;
                eventpattern.fulltrail = [eventpattern.fulltrail,...
                    eventpattern.trail];
                eventpattern.trail = [];
            end
        end
        
        eventpattern.in = false;
        eventpattern.trail = [];
        if ~isempty(eventpattern.fulltrail)
            eventpattern.numpat = eventpattern.numpat + 1;
            eventpattern.events{eventpattern.numpat} =...
                eventpattern.fulltrail;
            eventpattern.fulltrail = [];
        end
        
        
        
        events.(eventpattern.name) = eventpattern.events;
    end
end

