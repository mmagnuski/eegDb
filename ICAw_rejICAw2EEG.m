function EEG = ICAw_rejICAw2EEG(ICAw, r, EEG, prerej)

% taking care of rejections
% in and out from ICAw/EEG
ICAw_present = true;


% check for segments
if ICAw_present && isfield(ICAw, 'segment') && ...
        isnumeric(ICAw(r).segment) && ~isempty(ICAw(r).segment)
    nseg = floor(ICAw(r).winlen/ICAw(r).segment); %#ok<NASGU>
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


if (  prerej || ( isempty(ICAw(r).removed))  ) && isfield(...
        ICAw, 'autorem') && ~isempty(ICAw(r).autorem)
    known_auto = {'prob', 'mscl', 'freq'};
    goes_to    = {'rejjp', 'rejfreq', 'rejfreq'};
    flds = fields(ICAw(r).autorem);
    
    % we assume that autorem has fields
    for f = 1:length(flds)
        % checking if we know given rejection type
        kn = find(strcmp(flds{f}, known_auto));
        
        % if we know, continue (else - ADD)
        if ~isempty(kn)
            
            rejections = ICAw(r).autorem.(flds{f});
            
            % translating different rejection formats
            if seg_pres
                % segment option:
                rejections = rejections';
                rejections = rejections(:)';
            end
            
            if ~(length(rejections) == EEG.trials) || ...
                    sum(rejections > 1) > 0
                % rejction info is not in ones and zeros
                % translate to zeros and ones:
                rejct = zeros(1, EEG.trials);
                rejct(rejections) = 1;
                rejections = rejct;
                clear rejct
            end
            
            % ADD - if lenght of rejections is not euqal
            % to EEG.trials but  rejections are all zeros
            % and ones or true and false - throw an error
            % or try to solve somehow
            
            % highlight:
            EEG.reject.(goes_to{kn}) = rejections;
        end
    end
    clear f kn
end

%% clean up this later
if (  prerej || ( isempty(ICAw(r).removed) )  ) && isfield(...
        ICAw, 'userrem') && ~isempty(ICAw(r).userrem)
    known_auto = {'userreject', 'usermaybe', 'userdontknow'};
    goes_to    = {'userreject', 'usermaybe', 'userdontknow'};
    flds = fields(ICAw(r).userrem);
    
    % we assume that autorem has fields
    for f = 1:length(flds)
        % checking if we know given rejection type
        kn = find(strcmp(flds{f}, known_auto));
        
        % if we know, continue (else - ADD)
        if ~isempty(kn)
            
            rejections = ICAw(r).userrem.(flds{f});
            
            % translating different rejection formats
            if seg_pres
                % segment option:
                rejections = rejections';
                rejections = rejections(:)';
            end
            
            if ~(length(rejections) == EEG.trials) || ...
                    sum(rejections > 1) > 0
                % rejction info is not in ones and zeros
                % translate to zeros and ones:
                rejct = zeros(1, EEG.trials);
                rejct(rejections) = 1;
                rejections = rejct;
                clear rejct
            end
            
            % ADD - if lenght of rejections is not euqal
            % to EEG.trials but  rejections are all zeros
            % and ones or true and false - throw an error
            % or try to solve somehow
            
            % highlight:
            EEG.reject.(goes_to{kn}) = rejections;
            EEG.reject.([goes_to{kn}, 'col']) = ICAw(r).userrem.color.(flds{f});
        end
    end
    clear f kn
end

