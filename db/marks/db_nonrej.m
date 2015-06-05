function nonrejid = db_nonrej(ICAw, r, varargin)

% NOHELPINFO

% CHECK - where is this function used, what should it do?

% TODOs:
% [ ] - the function should check segment by itself
% [ ] - the function should check removed / prerej / postrej / autorem
%       depending on the context (?); now only autorem checks are
%       implemented

% CHANGE - should be rewritten!

%% defaults
giveseg = false; segment = false;
chckflds = {'mscl', 'prob', 'manual'};
nonrejid = [];

%% option checks
if nargin > 1
    check = {'giveseg'};
    
    for c = 1:length(check)
        comp = strcmp(check{c}, varargin);
        if sum(comp) > 0
            comp = find(comp, 1, 'first');
            eval([check{c}, ' = varargin{',...
                num2str(comp + 1), '};']);
        end
    end
    
    if giveseg
        segment = true; %#ok<UNRCH>
    end
end
  
%% initial input checks
% checking segment:
% CHANGE - ICAw.segment may also be ICAw.epoch.segment
if ~segment && isfield(ICAw.epoch, 'segment') && ...
    isnumeric(ICAw(r).epoch.segment)
    segment = true;
end

%% ==welcome to the code==

    % we assume that autorem has fields
    flds = fields(ICAw(r).autorem);

    % CHANGE - now there is no ICAw.autorem by default
    
    for f = 1:length(flds)
        nonrejid_temp = [];
        % checking if we know given rejection type
        kn = find(strcmp(flds{f}, chckflds), 1);
        
        % if we know, continue (else - ADD)
        if ~isempty(kn)
            
            rejections = ICAw(r).autorem.(flds{f});
            
            % translating different rejection formats
            if segment
                sz = size(rejections);
                index = 1:prod(sz);
                index = reshape(index, fliplr(sz))';
                
                % segment options:
                if giveseg
                    rejections = rejections(:, giveseg)'; %#ok<UNRCH>
                    index = index(:,giveseg)';
                    nonrejid_temp = index(~rejections);
                else
                    nonrejid_temp = index(~rejections)';
                end
            end
            
            %% the code below requires reworking so that
            % the funtion works not only for segmented EEG
            % epochs with autorem filled but for other 
            % types too...
            
%             if sum(rejections > 1) > 0
%                 % rejction info is not in ones and zeros
%                 % translate to zeros and ones:
%                 rejct = zeros(1, EEG.trials);
%                 rejct(rejections) = 1;
%                 rejections = rejct;
%                 clear rejct
%             elseif islogical(rejections)
%                 rejections =
%             end
            
            % ADD - if lenght of rejections is not euqal
            % to EEG.trials but  rejections are all zeros
            % and ones or true and false - throw an error
            % or try to solve somehow
            
        end
        
        % adding rejections
        if isempty(nonrejid)
            nonrejid = nonrejid_temp;
        end
        if ~isempty(nonrejid_temp)
            nonrejid = intersect(nonrejid, nonrejid_temp);
        end
    end
end

