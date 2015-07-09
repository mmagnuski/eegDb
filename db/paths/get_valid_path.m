function pth = get_valid_path(PTH, varargin)

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
% 'dir'    - *string*; directory that should be present
%             in the valid path. In conjunction with 'file'
%             option - the file has to be in the directory
%             denoted by 'dir'
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
opt.file = [];
opt.dir = [];
opt.noerror = false;
if nargin > 1
    opt = parse_arse(varargin, opt);
end
iffile = ~isempty(opt.file);
ifdir = ~isempty(opt.dir);

% if not cell - close in a cell
if ~iscell(PTH)
    PTH = {PTH};
end

% loop through consecutive cells
fnd = false;
for p = 1:length(PTH)
    % and test isdir() on them
    thispth = PTH{p};
    if ifdir
        thispth = fullfile(thispth, opt.dir);
    end
    if isdir(thispth)
        % if filecheck, check if file is present:
        if iffile
            fls = dir(thispth);
            fileok = any(strcmp(opt.file, {fls(~[fls.isdir]).name}));
        end

        % if everything ok - stop looking
        if ~iffile || fileok
            pth = thispth;
            fnd = true;
            break
        end
    end
end

if ~opt.noerror
    if ~fnd
        error('Could not find the correct path');
    end
end
