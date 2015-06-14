function eeg_path(type, varargin)

% adds path to eeglab functions
% ADDING PATH:
% eeg_path(1);
% OR: eeg_path('add');
% (as for now this is just code copied from
% EEGlab's eeglab.m, in the future it will 
% be more elegant)
% REMOVING PATH:
% eeg_path(2);
% OR: eeg_path('rem');


% TODOs:
% [ ] restructure
% [X] one function for adding and removing 
% [ ] persistent option? (what was added before)
% [ ] remove globals option (de-global)
% [X] removing eeglab paths
% [X] eeg_path(1) - add; eeg_path(2) - remove;
% [ ] toolbox paths - check if added. If not:
%     ADD and option for this

%% defaults
opt.external = false;
remglob = true;
% toolboxes = false; % add usage!

%% check input
if nargin > 1
    opt = parse_arse(varargin, opt);
end

% reformat type if char:
if ischar(type)
    type = find(strcmp(type, {'add', 'rem'}));
end

%% look for eeglab.m
eeglabpath = which('eeglab.m');
% take just the filepath:
eeglabpath = eeglabpath(1:end-length('eeglab.m'));
% error if no eeglab.m on file path:
if isempty(eeglabpath)
    error('No eeglab.m found on file path, sorry :(');
end
% if its the current directory:
if strcmpi(eeglabpath, './') || strcmpi(eeglabpath, '.\'),...
        eeglabpath = [ pwd filesep ]; end;

switch type
    case 1
        %% add paths
        %  ---------
        myaddpath( eeglabpath, 'eeg_checkset.m',   [ 'functions' filesep 'adminfunc'        ]);
        myaddpath( eeglabpath, 'eeg_checkset.m',   [ 'functions' filesep 'adminfunc'        ]);
        myaddpath( eeglabpath, ['@mmo' filesep 'mmo.m'], 'functions');
        myaddpath( eeglabpath, 'readeetraklocs.m', [ 'functions' filesep 'sigprocfunc'      ]);
        myaddpath( eeglabpath, 'supergui.m',       [ 'functions' filesep 'guifunc'          ]);
        myaddpath( eeglabpath, 'pop_study.m',      [ 'functions' filesep 'studyfunc'        ]);
        myaddpath( eeglabpath, 'pop_loadbci.m',    [ 'functions' filesep 'popfunc'          ]);
        myaddpath( eeglabpath, 'statcond.m',       [ 'functions' filesep 'statistics'       ]);
        myaddpath( eeglabpath, 'timefreq.m',       [ 'functions' filesep 'timefreqfunc'     ]);
        myaddpath( eeglabpath, 'icademo.m',        [ 'functions' filesep 'miscfunc'         ]);
        myaddpath( eeglabpath, 'eeglab1020.ced',   [ 'functions' filesep 'resources'        ]);
        myaddpath( eeglabpath, 'startpane.m',      [ 'functions' filesep 'javachatfunc' ]);
        
        if opt.external
            %% adding all folders in external
            %  ------------------------------
            
            p = eeglabpath;
            % if base, then reformat:
            if strcmpi(p, './') || strcmpi(p, '.\'), p = [ pwd filesep ]; end;
            dircontent  = dir([ p 'external' ]);
            dircontent  = { dircontent.name };
            for index = 1:length(dircontent)
                if dircontent{index}(1) ~= '.'
                    if ~isempty(strfind('fieldtrip', lower(dircontent{index})))
                        aadpathifnotexist( [ p 'external' filesep dircontent{index} filesep 'utilities' ], 'ft_checkconfig.m');
                        aadpathifnotexist( [ p 'external' filesep dircontent{index} filesep 'forward'   ], 'ft_apply_montage.m');
                        aadpathifnotexist( [ p 'external' filesep dircontent{index} filesep 'inverse'   ], 'dipole_fit.m');
                        aadpathifnotexist( [ p 'external' filesep dircontent{index} ], 'ft_dipolefitting.m' );
                    elseif ~isempty(strfind('biosig', lower(dircontent{index})))
                        aadpathifnotexist( [ p 'external' filesep dircontent{index} filesep 't200_FileAccess' ], 'sopen.m');
                        aadpathifnotexist( [ p 'external' filesep dircontent{index} filesep 't250_ArtifactPreProcessingQualityControl' ], 'regress_eog.m' );
                        aadpathifnotexist( [ p 'external' filesep dircontent{index} filesep 'doc' ], 'DecimalFactors.txt');
                        % biosigflag = 1;
                    elseif exist([p 'external' filesep dircontent{index}]) == 7 %#ok<EXIST>
                        addpathifnotinlist([p 'external' filesep dircontent{index}]);
                    end;
                end;
            end;
        end
        
    case 2
    % remove paths
    allpath = path();
    allpath = strsep(allpath, ';');
    
    % look for paths starting with eeglab path
    ii = strfind(allpath, eeglabpath);
    
    delpth = ~cellfun(@isempty, ii);
    allpath(delpth) = [];
    allpath = strsep(allpath, ';');
    path(allpath);
    
    % if remove globals:
    if remglob
        % ADD use check eeglab
        clearvars -global EEG ALLEEG
    end
end


function aadpathifnotexist(newpath, functionname)
tmpp = which(functionname);
if isempty(tmpp)
    addpath(newpath);
end;

function myaddpath(eeglabpath, functionname, pathtoadd)

tmpp = which(functionname);
tmpnewpath = [ eeglabpath pathtoadd ];
if ~isempty(tmpp)
    tmpp = tmpp(1:end-length(functionname));
    if length(tmpp) > length(tmpnewpath), tmpp = tmpp(1:end-1); end; % remove trailing filesep
    if length(tmpp) > length(tmpnewpath), tmpp = tmpp(1:end-1); end; % remove trailing filesep
    %disp([ tmpp '     |        ' tmpnewpath '(' num2str(~strcmpi(tmpnewpath, tmpp)) ')' ]);
    if ~strcmpi(tmpnewpath, tmpp)
        warning('off', 'MATLAB:dispatcher:nameConflict');
        addpath(tmpnewpath);
        warning('on', 'MATLAB:dispatcher:nameConflict');
    end;
else
    %disp([ 'Adding new path ' tmpnewpath ]);
    addpathifnotinlist(tmpnewpath);
end;

% add path only if it is not already in the list
% ----------------------------------------------
function addpathifnotinlist(newpath)

comp = computer;
if strcmpi(comp(1:2), 'PC')
    newpathtest = [ newpath ';' ];
else
    newpathtest = [ newpath ':' ];
end;
if ismatlab
    p = matlabpath;
else p = path;
end;
ind = strfind(p, newpathtest);
if isempty(ind)
    if exist(newpath) == 7 %#ok<EXIST>
        addpath(newpath);
    end;
end;

% required here because path not added yet
% to the admin folder
function res = ismatlab

v = version;
if v(1) > '4'
    res = 1;
else
    res = 0;
end;