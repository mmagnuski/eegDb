function [ICAw, EEG] = ICAw_rejTMP(ICAw, r, EEG, TMPREJ)

% taking care of rejections
% in and out from ICAw/EEG
ICAw_present = true;

% check for segments
if ICAw_present && isfield(ICAw, 'segment') && ...
        isnumeric(ICAw(r).segment) && ~isempty(ICAw(r).segment)
    
    
    if (~isfield(ICAw(r), 'winlen') ||...
            isempty(ICAw(r).winlen)) && ...
            (isfield(ICAw(r), 'onesecepoch') && ...
            (isempty(ICAw(r).onesecepoch) || ...
            ~isfield(ICAw(r).onesecepoch, 'winlen') || ...
            isempty(ICAw(r).onesecepoch.winlen)))
        winlen = 1;
    end
    
    
    nseg = floor(winlen/ICAw(r).segment);
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

% checking rejection methods
for rmf = 1:size(rejt.color, 1)
    
    % color matrix to test for color place
    rejcol = repmat(ICAw(r).(rejt.infield{rmf}).color...
        .(rejt.field{rmf}), [tmpsz(1), 1]);
    
    foundadr = sum(TMPREJ(:, 3:5)...
        - rejcol, 2) == 0;
    
    newrej = TMPREJ(foundadr, 2)/ EEG.pnts;%EEG.pnts instead of EEG.srate MZ
    zerovec = zeros(EEG.trials,1);
    zerovec(newrej) = 1;
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
        if isempty(ICAw(r).userrem.(rejt.field{rmf}))
        ICAw(r).userrem.(rejt.field{rmf}) =...
            zeros(EEG.etc.orig_numep, 1);
            orig_numep = EEG.etc.orig_numep;
        else
            orig_numep = length(ICAw(r).userrem.(rejt.field{rmf}));
        end
        
        adr = 1:orig_numep;
        
%         if femp(ICAw(r), 'prerej') || ~(length(adr) == ...
%                 size(EEG.data, 3))
%             adr(ICAw(r).prerej) = [];
%         end
        
        if femp(ICAw(r), 'postrej') || ~(length(adr) == ...
                size(EEG.data, 3))
            adr(ICAw(r).postrej) = [];
        end
        
        try
        ICAw(r).userrem.(rejt.field{rmf})(adr) =...
            rejected;
        catch %#ok<CTCH>
            disp(['SprawdŸ co siê dzieje w workspace',...
                'szczególne uwzglêdniaj¹c zmienn¹ ''adr''',...
                'i daj mi (tzn. ko³ajowi) znaæ co jest nie tak.']);
            keyboard
        end
        
        % CHANGE - add use of autorem !!
        
        clear rejected rejcol
    end
end

% update EEG:
EEG.reject.ICAw = ICAw_getrej(ICAw, r);

% cut out postrej (prerej are not in
% removed):
for v = 1:length(EEG.reject.ICAw.value)
    EEG.reject.ICAw.value{v}(ICAw(r).postrej) = [];
end

clear tmpsz nseg

