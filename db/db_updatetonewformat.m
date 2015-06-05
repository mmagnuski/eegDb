function ICAw = db_updatetonewformat(ICAw)

% ICAW_UPDATETONEWFORMAT updates a given ICAw database to
% most current format.
%
% ICAw = db_updatetonewformat(ICAw)
%
% ICAw - structure; eegDb database
%
% see also: db_buildbase

% Copyright 2014 Mikołaj Magnuski (mmagnuski@swps.edu.pl)

% TODOs:
% [ ] - add a new function db_checkbase that checks 
%       if base is correct, ensures marks.value is logical 
%       and same length etc. 
%       currently db_checkbase is doing something else
%       -that function should be renamed to searchbase
%       for example



% MOVE ICA
% --------
flds = {'icaweights', 'icasphere', 'icawinv', 'icachansind',...
    'ica_remove', 'ica_ifremove', 'ICA_desc'};
asflds = {'icaweights', 'icasphere', 'icawinv', 'icachansind',...
    'reject', 'maybe', 'desc'};
ICAw = db_pushfields(ICAw, flds, 'ICA', asflds);

% check ICA.remove and ICA.ifremove
fldfrm = {'remove', 'ifremove'};
fldto  = {'reject', 'maybe'};
for r = 1:length(ICAw)
    rm = false(1, 2);
    for f = 1:2
        if isfield(ICAw(r).ICA, fldfrm{f})
            rm(f) = true;
            ICAw(r).ICA.(fldto{f}) = ICAw(r).ICA.(fldfrm{f});
        end
    end

    if any(rm)
        ICAw(r).ICA = rmfield(ICAw(r).ICA, fldfrm(rm));
    end
end




% MOVE BADCHAN and BADCHANLAB
% ---------------------------
flds = {'badchan', 'badchanlab'};
asflds = {'bad', 'badlab'};
ICAw = db_pushfields(ICAw, flds, 'chan', asflds);

% ensure field:
for r = 1:length(ICAw)
        if ~isfield(ICAw(r).chan, 'bad')
            ICAw(r).chan.bad = [];
        end
end

% MOVE PREREJ and POSTREJ etc
% ---------------------------
flds = {'prerej', 'postrej', 'removed'};
asflds = {'pre', 'post', 'all'};
ICAw = db_pushfields(ICAw, flds, 'reject', asflds);

% ensure fields:
for r = 1:length(ICAw)
    for f = 1:length(asflds)
        if ~isfield(ICAw(r).reject, asflds{f})
            ICAw(r).reject.(asflds{f}) = [];
        end
    end
end



% REFIELD usecleanline to cleanline
% ---------------------------------
ICAw = db_refield(ICAw, 'usecleanline', 'cleanline');



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

    % enum fields
    if ~femp(ICAw(r), 'marks')
        ff = 0;
    elseif isstruct(ICAw(r).marks)
        % not likely
        ff = length(ICAw(r).marks);
    end

    % check if given is present
    for i = 1:length(flds)
        if femp(ICAw(r), flds{i})

            % check subfields:
            subf = fields(ICAw(r).(flds{i}));
            subf = setdiff(subf, inflds{i});

            for f = 1:length(subf)

                % increment ff
                ff = ff + 1;

                % move from current field (for example userrem.userreject)
                % to relevant marks       (for example   marks.reject    )
                ICAw(r).marks(ff).name = ICAw(r).(flds{i}).name.(subf{f});
                ICAw(r).marks(ff).color = ICAw(r).(flds{i}).color.(subf{f});
                ICAw(r).marks(ff).value = ICAw(r).(flds{i}).(subf{f});
                ICAw(r).marks(ff).desc = [];
                ICAw(r).marks(ff).auto = [];
                ICAw(r).marks(ff).more = [];

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
        ep = db_checkfields(ICAw, 1, {'epoch_events',...
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
hasFields = isfield(ICAw, flds);

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
    ICAw = db_mergefields(ICAw, flds{1}, 'epoch', true);
    
    flds = flds(2:end);
    hasFields = hasFields(2:end);
end

% remove fields
ICAw = rmfield(ICAw, flds(hasFields));


% REMOVE if present and none is nonempty:
% chansind, tasktype, subjectcode
% ---------------------------------------
flds = {'chansind', 'tasktype', 'subjectcode', 'session', 'prefun'};

for f = 1:length(flds)
    if isfield(ICAw, flds{f})
        
        % look for nonempty fields
        em = ~cellfun(@isempty, {ICAw.(flds{f})});
        
        % if no nonempty - delete field
        if ~any(em)
            ICAw = rmfield(ICAw, flds{f});
        end
    end
end



% SORT fileds as the last step
% ----------------------------
ICAw = db_sorter(ICAw);