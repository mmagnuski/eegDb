function [ICAw, path] = ICAw_loadbase(varargin)

% ICAw_loadbase loads a ICAw database
% if not for time-saving shortcuts
% it would be useless as an elaborate
% interface to matlab load() function
% WARNING! NON-UNIVERSAL

% CHANGE
% BRANCH
% NOT-USED

Drop = false;
PTH = 'Dropbox\DANE\MGR\EEG';
fnm = 'ICAw_set.mat';

if nargin>0
    fnm = ['ICAw_', varargin{1}, '.mat'];
end

%% checking Dropbox path:
% create possible pre-paths and take the path
% as stated in the database
checkpre = {'D:\', '\\Swps-01143\e\'};

if Drop
    % look for 'Dropbox' in the path:
    postpath = []; %#ok<UNRCH>
    pathterm = 'Dropbox';
    dr = regexp(PTH, pathterm, 'once');
    if ~isempty(dr)
        dr = dr(1);
        postpath = PTH(dr:end);
    end
else
    postpath = PTH;
end

% check prepaths:
if ~isempty(postpath)
    for a = 1:length(checkpre)
        if isdir([checkpre{a}, postpath])
            path = [checkpre{a}, postpath];
            break
        end
    end
end

addsep = '';
if ~(path(end) == filesep)
    addsep = filesep;
end

disp('Loading database from:');
disp([path, addsep, fnm]);
loaded = load([path, addsep, fnm]);
fld = fields(loaded);

% ADD in future - search through fields
% for ICAw and other info about the data
ICAw = loaded.(fld{1});

