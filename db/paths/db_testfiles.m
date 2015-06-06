function log = db_testfiles(db)

% log = db_testfiles(db)
%
% tests for file presence in all db records
% (checks whether .set file referenced by 
% filepath and filename is present)
% log is a boolean vector where true means 
% that the file was present

len = length(db);
log = false(1, len);

for r = 1:len
    % take correct path:
    pth = db_path(db(r).filepath);
    
    % check directory:
    fls = dir([pth, db(r).filename]);
    
    if ~isempty(fls)
        log(r) = true;
    end
end