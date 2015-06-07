% EEGDB_SETUP
%
% setup eegDb package by adding necessary paths 
% to matlab search path
%
% see also: addpath

function eegDb_setup

% get path to this function
pth = fileparts(mfilename('fullpath'));

% get other folders in this path
lst = dir(pth);
dirlst = lst([lst.isdir]);

% do not add ".git" etc folders:
dl = arrayfun(@(x) x.name(1) == '.', dirlst);
dirlst(dl) = [];

disp('adding paths...');
for d = 1:length(dirlst)
    addpath(genpath(fullfile(pth, dirlst(d).name)));
end
