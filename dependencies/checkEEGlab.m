function [iseeglab, funacc, detail] = checkEEGlab()
% checkEEGlab() checks whether eeglab and its
% functions are accessible
%
% Usage:
%   [iseeglab, funacc, detail] = checkEEGlab()
% more info:
%   checkEEGlab checks whether:
%       1. EEG, ALLEEG and CURRENTSET are
%          global and present in the base
%          workspace (output: iseeglab)
%       2. eeglab functions are on matlab path
%          - checks only the basic eeglab subfolders,
%            does not check for plugins etc.
%          (output: funacc)
%   a detailed info about the checks can be found in
% detail         - a structure containing following fields:
%       .var     - this field contains a structure that informs
%                  whether given eeglab variables are golbal
%                  (eeglab makes variables such as EEG global)
%                  every field of .var structure corresponds
%                  to an eeglab variable and the value of that
%                  fields informs whether this variable is global
%       .paths   - subfolders of eeglab that are checked for being
%                  on the matlab search path
%       .access  - logical values informing whether given eeglab
%                  subfolder is on matlab search path:
%                      .access(2) tells whether .paths(2)
%                      is accessible to matlab

%% 1. checking globals
% EEGlab declares as global variables:
% ALLCOM, ALLEEG, CURRENTSET, CURRENTSTUDY, 
% EEG, LASTCOM, PLUGINLIST, STUDY

% we are checking only EEG, ALLEEG and CURRENTSET
check = {'EEG', 'ALLEEG', 'CURRENTSET'};
globcall = 'whos(''global'');';
globals = evalin('base', globcall);
globnam = {globals.name};
iseeglab = true; funacc = true;

% checking globals:
for chg = check
    isglob = strcmp(chg, globnam);
    if isempty(isglob) || sum(isglob) == 0
        iseeglab = false;
        detail.globvar.(chg{1}) = false;
    else
        detail.globvar.(chg{1}) = true;
    end
end

% checking locals:
for chg = check
    isloc = evalin('base', ['exist(''', chg{1}, ''', ''var'');']);
    if sum(isloc) == 0
        iseeglab = false;
        detail.locvar.(chg{1}) = false;
    else
        detail.locvar.(chg{1}) = true;
    end
end

%% 2. checking whether functions are on path
% path to eeglab:
eeglabpath = which('eeglab.m');
eeglabpath = eeglabpath(1:end-length('eeglab.m'));

% paths to check:
detail.paths = {'functions', 'functions\javachatfunc',...
    'functions\resources', 'functions\miscfunc',...
    'functions\timefreqfunc', 'functions\statistics',...
    'functions\popfunc', 'functions\studyfunc',...
    'functions\guifunc', 'functions\sigprocfunc',...
    'functions\adminfunc'};

% checkig path by path:
allpath = path; npth = 1;
for pth = detail.paths
    check = strfind(allpath, [eeglabpath, pth{1}]);
    if isempty(check)
        funacc = false;
        detail.access(npth) = false;
    else
        detail.access(npth) = true;
    end
    npth = npth + 1;
end

