function [db, EEG] = db_rejTMP(db, r, EEG, TMPREJ)

% NOHELPINFO

% taking care of rejections
% in and out from db/EEG
db_present = true;

% check for segments
% THIS is kept but segmenting is not officially supported
if db_present && isfield(db(r).epoch, 'segment') && ...
        isnumeric(db(r).epoch.segment) && ~isempty(db(r).epoch.segment)
    
    
    if (~isfield(db(r).epoch, 'winlen') ||...
            isempty(db(r).epoch.winlen)) && ...
            isfield(db(r).epoch, 'locked')
        winlen = 1;
    end
    
    
    nseg = floor(winlen/db(r).epoch.segment);
    seg_pres = true;
else
    seg_pres = false;
end

% CHANGE: this is used when EEG --> db
% % reshaping to segment rules
% if seg_pres
%     rejected = reshape(zerovec,...
%         [nseg, EEG.trials/nseg]);
%     rejected = rejected';
% else
%     rejected = zerovec;
% end

% get rejtypes:
rejt = db_getrej(db, r);

tmpsz = size(TMPREJ);
% remfields = {'autorem', 'userrem'};
% known_auto = {'prob', 'mscl', 'freq'};
% goes_to    = {'rejjp', 'rejfreq', 'rejfreq'};

rejCol = cell2mat({db(r).marks.color}');


% checking rejection methods
for f = 1:size(rejCol, 1)
    
    % color matrix to test for color place
    rejcol = repmat(rejCol(f,:), [tmpsz(1), 1]);
    
    foundadr = sum(TMPREJ(:, 3:5)...
        - rejcol, 2) == 0;
    clear rejcol
    if foundadr < 1
        continue
    end
    
    newrej = TMPREJ(foundadr, 2) / double(EEG.pnts); %EEG.pnts instead of EEG.srate MZ
    zerovec = false(EEG.trials, 1);
    zerovec(newrej) = true;

    clear foundadr newrej
    
    if db_present
        % reshaping to segment rules
        if seg_pres
            rejected = reshape(zerovec,...
                [nseg, EEG.trials/nseg]);
            rejected = rejected';
        else
            rejected = zerovec;
        end
        
        % CHANGE - usage of numep etc. so that
        %          filling in data with rejections
        %          would be flawless.
        % fill the field (field name depends on
        % method - autorem is for automatic remo-
        % val userrem is for removal done by the
        % user
        if isempty(db(r).marks(f).value)
            db(r).marks(f).value = false(EEG.etc.orig_numep, 1);
            orig_numep = EEG.etc.orig_numep;
        else
            orig_numep = length(db(r).marks(f).value);
        end
        
        adr = 1:orig_numep;
        
        % CHANGE - some commented out code - probably not needed
        % if femp(db(r), 'prerej') || ~(length(adr) == ...
        %         size(EEG.data, 3))
        %     adr(db(r).prerej) = [];
        % end
        
        % CHANGE
        % this is some quick bugfix, that could 
        % not work / have much sense / etc.
        % it seems to be used to work for adding selections 
        % even when some epochs have been rejected
        if femp(db(r).reject, 'post') || ~(length(adr) == ...
                size(EEG.data, 3))
            adr(db(r).reject.post) = [];
        end
        
        if isempty(db(r).marks(f).value)
            % no previous rejections - create
            % a little weird because they should (?) be added during
            % cutting into segments / epoching...
            if all(diff(adr) == 1) % adr is 1:length(adr)
                db(r).marks(f).value = rejected;
            else
                error(['I don''t know what to do if db(r).marks(f).value', ...
                       ' is empty and adr is not 1:length(adr)']);
            end
        else
            % standard case - modify existing marks
            db(r).marks(f).value(adr) = rejected;
        end
        
        clear rejected
    end
end

% update EEG:
EEG.reject.db = db_getrej(db, r);

% CHANGE - this should also be changed
% EEG.reject.db is used but there are no 
% precise rules for this and it is untracked
%
% cut out postrej (prerej are not in
% removed):
for v = 1:length(EEG.reject.db.value)
    EEG.reject.db.value{v}(db(r).reject.post) = [];
end

clear tmpsz nseg

