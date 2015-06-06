function db = db_addpath(db, path)

% db = db_addpath(db, path)
% add path to db database filepath
% this does not delete the previous
% path set up in db database but
% just adds another one into a cell
% array of paths
% The correct path on a given computer
% can be found by using:
% correct_path = db_path(db(r).filepath);

% TODOs:
% [ ] 'ignore cleanline' when all files have been
%      brought to a single folder
% CONSIDER - how intermediate files should be treated and located

cll = 'CleanLine\';
for r = 1:length(db)
    iscl = iscell(db(r).filepath);
    if iscl
        ad_cl = any(~cellfun(@isempty, strfind(...
            db(r).filepath, cll)));
    else
        ad_cl = ~(isempty(strfind(...
            db(r).filepath, cll)));
    end
    
    
    nowpath = path;
    if ad_cl
        nowpath = fullfile(nowpath, cll);
    end
    
    if ~iscl
        pt = db(r).filepath;
        db(r).filepath = []; %#ok<*SAGROW>
        db(r).filepath{1} = pt;
        db(r).filepath{2} = nowpath;
    else
        db(r).filepath{end+1} = nowpath;
    end
end