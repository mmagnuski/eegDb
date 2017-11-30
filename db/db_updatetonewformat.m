function db = db_updatetonewformat(db)

% DB_UPDATETONEWFORMAT updates a given db database to
% most current format.
%
% db = db_updatetonewformat(db)
%
% db - structure; eegDb database
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
db = db_pushfields(db, flds, 'ICA', asflds);

% check ICA.remove and ICA.ifremove
fldfrm = {'remove', 'ifremove'};
fldto  = {'reject', 'maybe'};
for r = 1:length(db)
    rm = false(1, 2);
    for f = 1:2
        if isfield(db(r).ICA, fldfrm{f})
            rm(f) = true;
            db(r).ICA.(fldto{f}) = db(r).ICA.(fldfrm{f});
        end
    end

    if any(rm)
        db(r).ICA = rmfield(db(r).ICA, fldfrm(rm));
    end
end




% MOVE BADCHAN and BADCHANLAB
% ---------------------------
flds = {'badchan', 'badchanlab'};
asflds = {'bad', 'badlab'};
db = db_pushfields(db, flds, 'chan', asflds);

% ensure field:
for r = 1:length(db)
        if ~isfield(db(r).chan, 'bad')
            db(r).chan.bad = [];
        end
end

% MOVE PREREJ and POSTREJ etc
% ---------------------------
flds = {'prerej', 'postrej', 'removed'};
asflds = {'pre', 'post', 'all'};
db = db_pushfields(db, flds, 'reject', asflds);

% ensure fields:
for r = 1:length(db)
    for f = 1:length(asflds)
        if ~isfield(db(r).reject, asflds{f})
            db(r).reject.(asflds{f}) = [];
        end
    end
end


% REFIELD usecleanline to cleanline
% ---------------------------------
if isfield(db, 'usecleanline')
    db = db_refield(db, 'usecleanline', 'cleanline');
end


% RECODE (USER/AUTO)REM to MARKS
% --------------------------------

% move marks from userrem and autorem
% previously these fields and subfields where used
flds = {'userrem', 'autorem'};
inflds = {{'color', 'name'}, {'color', 'name'}};

% now we use marks:
hasFields = cellfun(@(x) isfield(db, x), flds);

if any(hasFields)
for r = 1:length(db)

    % enum fields
    if ~femp(db(r), 'marks')
        ff = 0;
    elseif isstruct(db(r).marks)
        % not likely
        ff = length(db(r).marks);
    end

    % check if given is present
    for i = 1:length(flds)
        if femp(db(r), flds{i})

            % check subfields:
            subf = fields(db(r).(flds{i}));
            subf = setdiff(subf, inflds{i});

            for f = 1:length(subf)

                % increment ff
                ff = ff + 1;

                % move from current field (for example userrem.userreject)
                % to relevant marks       (for example   marks.reject    )
                db(r).marks(ff).name = db(r).(flds{i}).name.(subf{f});
                db(r).marks(ff).color = db(r).(flds{i}).color.(subf{f});
                db(r).marks(ff).value = db(r).(flds{i}).(subf{f});
                db(r).marks(ff).desc = [];
                db(r).marks(ff).auto = [];
                db(r).marks(ff).more = [];
            end
        end
    end
end

% remove fields
db = rmfield(db, flds(hasFields));
end


% RECODE EPOCHING
% ---------------

% db.winlen --> db.onesecepoch.winlen
%
% move old db.winlen db.distance to db.onesecepoch.winlen etc.
% these are later moved to db.epoch.winlen etc.
% (this may be done in one single step but this way it is easier)
flds = {'winlen', 'distance'};
hasFields = isfield(db, flds);

if any(hasFields)
for r = 1:length(db)
    if isfield(db, 'onesecepoch') && islogical(db(r).onesecepoch)
        db(r).onesecepoch = [];
        ep = db_checkfields(db, 1, {'epoch_events',...
            'epoch_limits'});
        if sum(ep.fnonempt) == 0
            for f = 1:length(flds)
                if isfield(db(r), flds{f})
                    db(r).onesecepoch.(flds{f}) = ...
                        db(r).(flds{f});
                end
            end
        end
    end
end

% remove fields
db = rmfield(db, flds(hasFields));
end


% db.onesecepoch.winlen (etc.) --> db.epoch.winlen
flds = {'onesecepoch', 'epoch_events', 'epoch_limits', 'segment'};
toFlds = {'', 'events', 'limits', 'segment'};

% now we use marks:
hasFields = isfield(db, flds);

if any(hasFields)
for r = 1:length(db)

    % check onesec
    % -------------
    copyEp = true;
    if femp(db(r), flds{1})
        % only cases where it is logical then - after this loop we merge
        % onesecepoch with epoch so other cases are taken care of
        if islogical(db(r).(flds{1}))
            if db(r).(flds{1})

                % set locked to false
                db(r).epoch.locked = false;

                % clear onesecepoch
                db(r).onesecepoch = [];

                % apply default onesec options:
                db(r).epoch.winlen = 1;

                % do not copy epoching even if present
                copyEp = false;
            end
        end
    end

    if copyEp
        for f = 2:length(flds)
            % simply copy the contents if present
            if femp(db(r), flds{f})
                db(r).epoch.(toFlds{f}) = db(r).(flds{f});
            end
        end
    end
end
end

% merge onesecepoch and epoch if onesec present
if hasFields(1)
    % force merge, because db.epoch could not be
    % trully present if db.onesecepoch is
    db = db_mergefields(db, flds{1}, 'epoch', true);

    flds = flds(2:end);
    hasFields = hasFields(2:end);
end

% remove fields
db = rmfield(db, flds(hasFields));


% REMOVE if present and none is nonempty:
% chansind, tasktype, subjectcode
% ---------------------------------------
flds = {'chansind', 'tasktype', 'subjectcode', 'session', 'prefun'};

for f = 1:length(flds)
    if isfield(db, flds{f})

        % look for nonempty fields
        em = ~cellfun(@isempty, {db.(flds{f})});

        % if no nonempty - delete field
        if ~any(em)
            db = rmfield(db, flds{f});
        end
    end
end


% SORT fileds as the last step
% ----------------------------
db = db_sorter(db);


% if versions field is present - remove
% -------------------------------------
if isfield(db, 'versions')
    db = rmfield(db, 'versions');
end
