function pth = get_valid_path(PTH, varargin)

% FIXHELPINFO
% additional args
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
        % if filecheck, check if file is present:
        if iffile
            fls = dir(PTH{p});
            fileok = any(strcmp(opt.file, {fls(~[fls.isdir]).name}));
        end

        % if it is dir, stop looking
        if ~iffile || fileok
            pth = PTH{p};
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
