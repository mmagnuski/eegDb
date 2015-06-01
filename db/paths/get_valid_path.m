function pth = get_valid_path(PTH)

% FIXHELPINFO

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