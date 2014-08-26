function [ICAw, EEG] = ICAw_rejTMP(ICAw, r, EEG, TMPREJ)

% NOHELPINFO

% taking care of rejections
% in and out from ICAw/EEG
ICAw_present = true;

% check for segments
% THIS is kept but segmenting is not officially supported
if ICAw_present && isfield(ICAw.epoch, 'segment') && ...
        isnumeric(ICAw(r).epoch.segment) && ~isempty(ICAw(r).epoch.segment)
    
    
    if (~isfield(ICAw(r).epoch, 'winlen') ||...
            isempty(ICAw(r).epoch.winlen)) && ...
            (isfield(ICAw(r).epoch, 'locked')
        winlen = 1;
    end
    
    
    nseg = floor(winlen/ICAw(r).epoch.segment);
    seg_pres = true;
else
    seg_pres = false;
end

% CHANGE: this is used when EEG --> ICAw
% % reshaping to segment rules
% if seg_pres
%     rejected = reshape(zerovec,...
%         [nseg, EEG.trials/nseg]);
%     rejected = rejected';
% else
%     rejected = zerovec;
% end

% get rejtypes:
rejt = ICAw_getrej(ICAw, r);

tmpsz = size(TMPREJ);
% remfields = {'autorem', 'userrem'};
% known_auto = {'prob', 'mscl', 'freq'};
% goes_to    = {'rejjp', 'rejfreq', 'rejfreq'};

rejCol = cell2mat({ICAw(r).marks.color}');


% checking rejection methods
for f = 1:size(rejCol, 1)
    
    % color matrix to test for color place
    rejcol = repmat(rejCol(f,:), [tmpsz(1), 1]);
    
    foundadr = sum(TMPREJ(:, 3:5)...
        - rejcol, 2) == 0;
    clear rejcol
    
    newrej = TMPREJ(foundadr, 2) / EEG.pnts; %EEG.pnts instead of EEG.srate MZ
    zerovec = false(EEG.trials, 1);
    zerovec(newrej) = true;

    clear foundadr newrej
    
    if ICAw_present
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
        if isempty(ICAw(r).marks(f).value)
            ICAw(r).marks(f).value = false(EEG.etc.orig_numep, 1);
            orig_numep = EEG.etc.orig_numep;
        else
            orig_numep = length(ICAw(r).marks(f).value);
        end
        
        adr = 1:orig_numep;
        
        % CHANGE - some commented out code - probably not needed
        % if femp(ICAw(r), 'prerej') || ~(length(adr) == ...
        %         size(EEG.data, 3))
        %     adr(ICAw(r).prerej) = [];
        % end
        
        % CHANGE
        % this is some quick bugfix, that could 
        % not work / have much sens / etc.
        % it seems to be used to work for adding selections 
        % even when some epochs have been rejected
        if femp(ICAw(r).reject, 'post') || ~(length(adr) == ...
                size(EEG.data, 3))
            adr(ICAw(r).reject.post) = [];
        end
        
        ICAw(r).marks(f).value(adr) = rejected;
        
        clear rejected
    end
end

% update EEG:
EEG.reject.ICAw = ICAw_getrej(ICAw, r);

% CHANGE - this should also be changed
% EEG.reject.ICAw is used but there are no 
% precise rules for this and it is untracked
%
% cut out postrej (prerej are not in
% removed):
for v = 1:length(EEG.reject.ICAw.value)
    EEG.reject.ICAw.value{v}(ICAw(r).reject.post) = [];
end

clear tmpsz nseg

