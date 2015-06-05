function ICAw = db_addpath(ICAw, path)

% ICAw = db_addpath(ICAw, path)
% add path to ICAw database filepath
% this does not delete the previous
% path set up in ICAw database but
% just adds another one into a cell
% array of paths
% The correct path on a given computer
% can be found by using:
% correct_path = db_path(ICAw(r).filepath);

% TODOs:
% [ ] 'ignore cleanline' when all files have been
%      brought to a single folder
% CONSIDER - how intermediate files should be treated and located

cll = 'CleanLine\';
for r = 1:length(ICAw)
    iscl = iscell(ICAw(r).filepath);
    if iscl
        ad_cl = any(~cellfun(@isempty, strfind(...
            ICAw(r).filepath, cll)));
    else
        ad_cl = ~(isempty(strfind(...
            ICAw(r).filepath, cll)));
    end
    
    
    nowpath = path;
    if ad_cl
        nowpath = fullfile(nowpath, cll);
    end
    
    if ~iscl
        pt = ICAw(r).filepath;
        ICAw(r).filepath = []; %#ok<*SAGROW>
        ICAw(r).filepath{1} = pt;
        ICAw(r).filepath{2} = nowpath;
    else
        ICAw(r).filepath{end+1} = nowpath;
    end
end