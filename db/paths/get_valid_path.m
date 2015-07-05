function pth = get_valid_path(PTH)

% GET_VALID_PATH checks which path is valid on a given machine
%
% usage
% -----
% pth = get_valid_path(PTH, ...);
%
% input
% -----
% PTH - *string* or *cell array of strings*; path string(s)
%
% ... - additional key - value pairs
%
% key-value pairs
% ---------------
% 'file'    - *string*; filename that should be present
%             in the valid path
% 'noerror' - *logical*; whether NOT to throw an error when valid
%             path was not found
%             default: false (error is thrown)
%
% examples
% --------
% check which path to Dropbox is correct on given machine:
% PTH = {'D:\Dropbox\', 'C:\Users\Kant\Dropbox\'};
% validpath = get_valid_path(PTH);
%
% check which folder exists AND has file 'data.set' inside:
% PTH = {'C:\DATA\superstudy\', 'C:\DATA\otherstudy\'};
% validpath = get_valid_path(PTH, 'file', 'data.set');
%
% see also: isdir

% additional args
pth = [];
opt.file = [];
opt.noerror = false;
if nargin > 1
    opt = parse_arse(varargin, opt);
end
iffile = ~isempty(opt.file);

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
