function r = ICAw_find(ICAw, lookfor, varargin)

% r = ICAw_find(ICAw, lookfor)
% Looks for a specific ICAw entry (or entries)
% and returns their adress in vector r.
%
% at present it is assumed that lookfor is a string
% that is compared against filenames with
% strfind

%% defaults
allr = false;

%% argument checks
if ~isempty(varargin)
    if sum(strcmp('all', varargin)) > 0
        allr = true;
    end
end

%% the code
r = find(~cellfun(@isempty, strfind({ICAw.filename}, lookfor)));

if ~allr
    % by default, if more than one, be strict
    % and compare if the string is exactly the same:
    if length(r) > 1
        fnm = {ICAw(r).filename};
        for rr = 1:length(r)
            if ~isequal(lookfor, fnm{rr})
                r(rr) = NaN;
            end
        end
        
        r(isnan(r)) = [];
    end
end
