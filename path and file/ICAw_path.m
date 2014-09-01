function pth = ICAw_path(PTH, varargin)

% pth = ICAw_path(PTH);
% 
% goes through path strings in PTH and
% finds pth - the string that is a valid
% directory on the current computer.
%
% varargin not used for now

% TODOs:
% [ ] check for filename fields when
%     'withfiles' is active and ICAw was
%     passed
% [ ] add 'multiple' option that
%     allows for multiple correct
%     paths.
% [ ] 'withfiles' option for choosing
%     a folder that is correct and
%     contains a given file/list of
%     files
% [X] automatically detect ICAw structure
%     (filepath field)
% [X] if user passed 'r' index - produce
%     results adequate to:
%     pth = ICAw_path(ICAw(r).filepath);
%     or:
%     pth = ICAw_path(ICAw(r).filepath,...
%         'withfiles', ICAw(r).filename);
% [X] what if the user did not pass 'r'
%     and the structure is longer than
%     one?
%     --> return cell where each cell
%         contains result of ICAw_path
%         on the given r.
%

% optional parameters (from varargin)
r = [];

%% ICAw version
% check if ICAw structure:
if isstruct(PTH)
    % ADD checking for filename if
    %     'withfiles' was passed
    % check if filepath field present:
    if length(PTH) == 1 || (length(PTH) > 1 && length(r) == 1)
        if isempty(r)
            r = 1;
        end
        
        if femp(PTH(r), 'filepath')
            PTH = PTH(r).filepath;
        else
            % oops, throw an error
            error(['a structure was passed in ',...
                'but it does not contain a ''f',...
                'ilepath'' field or the field ',...
                'is empty.']);
        end
    else
        % the structure is longer than
        % one, return celled results
        if isempty(r)
            r = 1:length(PTH);
        end
        
        rlen = length(r);
        pth = cell(1, rlen);
        step = 1;
        for rnow = r
            pth{step} = ICAw_path(PTH(rnow), varargin{:});
            step = step + 1;
        end
        
        % that's it, return cell results
        return
    end
end

%% path version
% if not cell - close in a cell
if ~iscell(PTH)
    PTH = {PTH};
end

% loop through consecutive cells
fnd = false;
for p = 1:length(PTH)
    % and test isdir() on them
    if isdir(PTH{p})
        % if it is dir, stop looking
        pth = PTH{p};
        fnd = true;
        break
    end
end
if ~fnd
    error('Could not find the correct path');
end
clear fnd p