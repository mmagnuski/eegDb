function log = ICAw_testfiles(ICAw)

% log = ICAw_testfiles(ICAw)
% tests for file presence of all ICAw records
% (checks whether .set file is present)

len = length(ICAw);
log = false(1, len);

for r = 1:len
    % take correct path:
    pth = ICAw_path(ICAw(r).filepath);
    
    % check directory:
    fls = dir([pth, ICAw(r).filename]);
    
    if ~isempty(fls)
        log(r) = true;
    end
end