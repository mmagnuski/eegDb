function log = db_testfiles(ICAw)

% log = db_testfiles(ICAw)
%
% tests for file presence in all ICAw records
% (checks whether .set file referenced by 
% filepath and filename is present)
% log is a boolean vector where true means 
% that the file was present

len = length(ICAw);
log = false(1, len);

for r = 1:len
    % take correct path:
    pth = db_path(ICAw(r).filepath);
    
    % check directory:
    fls = dir([pth, ICAw(r).filename]);
    
    if ~isempty(fls)
        log(r) = true;
    end
end