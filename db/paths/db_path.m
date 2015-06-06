function pth = db_path(PTH, varargin)

% pth = db_path(PTH);
% 
% goes through path strings in PTH and
% finds pth - the string that is a valid
% directory on the current computer.
%
% FIXHELPINFO
% varargin not used for now

% TODOs:
% [ ] check for filename fields when
%     'withfiles' is active and db was
%     passed
% [ ] add 'multiple' option that
%     allows for multiple correct
%     paths.
% [ ] 'withfiles' option for choosing
%     a folder that is correct and
%     contains a given file/list of
%     files
% [X] automatically detect db structure
%     (filepath field)
% [X] if user passed 'r' index - produce
%     results adequate to:
%     pth = db_path(db(r).filepath);
%     or:
%     pth = db_path(db(r).filepath,...
%         'withfiles', db(r).filename);
% [X] what if the user did not pass 'r'
%     and the structure is longer than
%     one?
%     --> return cell where each cell
%         contains result of db_path
%         on the given r.
%

% optional parameters (from varargin)
r = [];

%% db version
% check if db structure:
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
            pth{step} = db_path(PTH(rnow), varargin{:});
            step = step + 1;
        end
        
        % that's it, return cell results
        return
    end
end

%% path version
pth = get_valid_path(PTH);