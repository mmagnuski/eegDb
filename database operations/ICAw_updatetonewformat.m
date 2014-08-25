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



% MOVE ICA
% --------
flds = {'icaweights', 'icasphere', 'icawinv', 'icachansind',...
    'ica_remove', 'ica_ifremove', 'ICA_desc'};
asflds = {'icaweights', 'icasphere', 'icawinv', 'icachansind',...
    'remove', 'ifremove', 'desc'};
ICAw = ICAw_pushfields(ICAw, flds, 'ICA', asflds);


% MOVE BADCHAN and BADCHANLAB
% ---------------------------
flds = {'badchan', 'badchanlab'};
asflds = {'bad', 'badlab'};
ICAw = ICAw_pushfields(ICAw, flds, 'chan', asflds);


% REFIELD usecleanline to cleanline
% ---------------------------------
ICAw = ICAw_refield(ICAw, 'usecleanline', 'cleanline');



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
            subf = setdiff(subf, inflds{i});

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
ICAw = rmfield(ICAw, flds(hasFields));

end


% RECODE EPOCHING
% ---------------

% ICAw.winlen --> ICAw.onesecepoch.winlen
%
% move old ICAw.winlen ICAw.distance to ICAw.onesecepoch.winlen etc.
% these are later moved to ICAw.epoch.winlen etc.
% (this may be done in one single step but this way it is easier)
flds = {'winlen', 'distance'};
hasFields = isfield(ICAw, flds);

if any(hasFields)
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

% remove fields
ICAw = rmfield(ICAw, flds(hasFields));

end


% ICAw.onesecepoch.winlen (etc.) --> ICAw.epoch.winlen
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

                % clear onesecepoch
                ICAw(r).onesecepoch = [];

                % apply default onesec options:
                ICAw(r).epoch.winlen = 1;


                % do not copy epoching even if present
                copyEp = false;
            end
                
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

% merge onesecepoch and epoch if onesec present
if hasFields(1)
    % force merge, because ICAw.epoch could not be 
    % trully present if ICAw.onesecepoch is
    ICAw = ICAw_mergefields(ICAw, flds{1}, 'epoch', true);
    
    flds = flds(2:end);
    hasFields = hasFields(2:end);
end

% remove fields
ICAw = rmfield(ICAw, flds(hasFields));





% SORT fileds as the last step
% ----------------------------
ICAw = ICAw_sorter(ICAw);