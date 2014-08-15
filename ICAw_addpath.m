function ICAw = ICAw_addpath(ICAw, path)

% ICAw = ICAw_addpath(ICAw, path)
% add path to ICAw database filepath
% this does not delete the previous
% path set up in ICAw database but
% just adds another one into a cell
% array of paths
% The correct path on a given computer
% can be found by using:
% correct_path = ICAw_path(ICAw(r).filepath);

% TODOs:
% [ ] 'ignore cleanline' when all files have been
%      brought to a single folder

cll = 'CleanLine\';
for r = 1:length(ICAw)
    iscl = iscell(ICAw(r).filepath);
    if iscl
        pt = ICAw(r).filepath{1};
    else
        pt = ICAw(r).filepath;
    end
    
    ad_cl = ~(isempty(strfind(pt, cll)));
    
    nowpath = path;
    if ad_cl
        nowpath = [nowpath, cll]; %#ok<AGROW>
    end
    
    if ~iscl
        ICAw(r).filepath = []; %#ok<*SAGROW>
        ICAw(r).filepath{1} = pt;
        ICAw(r).filepath{2} = nowpath;
    else
        ICAw(r).filepath{end+1} = nowpath;
    end
end