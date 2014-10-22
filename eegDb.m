% EEGDB
%
% adds necessary paths to folders
%
% see also: addpath


pth = fileparts(which('eegDb'));

% fld = {'database operations', 'dependencies', 'eeglabsubst', 'gui', ...
%     'manage marks', 'manage versions', 'path and file utils', ...
%     'should be in a branch'};
% 
% % add folders to path
% for f = fld
%     addpath(fullfile(pth, f{1}));
% end

% do not add .git etc folders:
lst = dir(pth);
dirlst = lst([lst.isdir]);

dl = false(length(dirlst), 1);

for i = 1:length(dirlst)
    if dirlst(i).name(1) == '.'
        dl(i) = true;
    end
end
dirlst(dl) = [];

disp('adding paths...');
for d = 1:length(dirlst)
    addpath(genpath(fullfile(pth, dirlst(d).name)));
end