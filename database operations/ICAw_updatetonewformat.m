function ICAw = ICAw_updatetonewformat(ICAw)

% ICAW_UPDATETONEWFORMAT updates a given ICAw database to
% most current format.
%
% ICAw = ICAw_updatetonewformat(ICAw)
%
% ICAw - structure; eegDb database
%
% see also: ICAw_buildbase

% Copyright 2014 Mikołaj Magnuski (mmagnuski@swps.edu.pl)

% INPROGRESS

% RECODE (USER/AUTO)REM to MARKS
% --------------------------------

% move marks from userrem and autorem
% previously these fields and subfields where used
flds = {'userrem', 'autorem'};
inflds = {{'color', 'name'}, {'color', 'name'}};

% now we use marks:
hasFields = cellfun(@(x) isfield(ICAw, x), flds);

if any(hasFields)
for r = 1:length(ICAw)

    % check if given is present
    for i = 1:length(flds)
        if femp(ICAw(r), flds{i})

            % check subfields:
            subf = fields(ICAw(r).(flds{i}));
            subf = setdiff(subf, inflds{i})

            for f = 1:length(subf)

                % field name
                fname = subf{f};

                % remove 'user'
                u = strfind(fname, 'user');

                if ~isempty(u)
                    fname(u:u+3) = [];
                end

                % move from current field (for example userrem.userreject)
                % to relevant marks       (for example   marks.reject    )
                ICAw(r).marks.(fname).name = ICAw(r).(flds{i}).name.(subf{f});
                ICAw(r).marks.(fname).color = ICAw(r).(flds{i}).color.(subf{f});
                ICAw(r).marks.(fname).value = ICAw(r).(flds{i}).(subf{f});
            end
        end
    end
end

% remove fields
rmfield(ICAw, flds);

end

% RECODE EPOCHING
% ---------------

flds = {'onesecepoch', 'epoch_events', 'epoch_limits', 'segment'};
toFlds = {'', 'events', 'limits', 'segment'};

% now we use marks:
hasFields = cellfun(@(x) isfield(ICAw, x), flds);

if any(hasFields)
for r = 1:length(ICAw)

    % check onesec 
    % -------------
    copyEp = true;
    if femp(ICAw(r), flds{1}) 
        % only cases where it is logical
        % then - after this loop we merge
        % onesecepoch with epoch so other
        % cases are taken care of
        if islogical(ICAw(r).(flds{1}))
            if ICAw(r).(flds{1})
                % set locked to false
                ICAw(r).epoch.locked = false;
                ICAw(r).onesecepoch = [];
                copyEp = false;
            end
                
        end

    if copyEp

        for f = 2:length(flds)

            % simply copy the contents if present
            if femp(ICAw(r), flds{f})
                ICAw(r).epoch.(toFlds{f}) = ICAw(r).(flds{f});
            end

        end
    end
end
end

% remove some fields
rmfield(ICAw, flds(2:end));
% merge onesecepoch if it was present



    % check if given is present
    for i = 1:length(flds)
        if femp(ICAw(r), flds{i})

            % check subfields:
            subf = fields(ICAw(r).(flds{i}));
            subf = setdiff(subf, inflds{i})

            for f = 1:length(subf)

                % field name
                fname = subf{f};

                % remove 'user'
                u = strfind(fname, 'user');

                if ~isempty(u)
                    fname(u:u+3) = [];
                end

                % move from current field (for example userrem.userreject)
                % to relevant marks       (for example   marks.reject    )
                ICAw(r).marks.(fname).name = ICAw(r).(flds{i}).name.(subf{f});
                ICAw(r).marks.(fname).color = ICAw(r).(flds{i}).color.(subf{f});
                ICAw(r).marks.(fname).value = ICAw(r).(flds{i}).(subf{f});
            end
        end
    end
end

end




%% check rejection name and color fields

% for r = 1:length(ICAw)

%% check previous onesecepoch settings:
flds = {'winlen', 'distance'};

for r = 1:length(ICAw)
    if isfield(ICAw, 'onesecepoch') && islogical(ICAw(r).onesecepoch)
        ICAw(r).onesecepoch = [];
        ep = ICAw_checkfields(ICAw, 1, {'epoch_events',...
            'epoch_limits'});
        if sum(ep.fnonempt) == 0
            for f = 1:length(flds)
                if isfield(ICAw(r), flds{f})
                    ICAw(r).onesecepoch.(flds{f}) = ...
                        ICAw(r).(flds{f});
                end
            end
        end
    end
end

if isfield(ICAw,flds)
    ICAw = rmfield(ICAw, flds);
end
