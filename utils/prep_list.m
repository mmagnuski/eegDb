function [full_list, addit] = prep_list(folder, extensions, varargin)

% [flist finfo] = prep_list(folders, extensions, varargin)
% extracting filenames with specific extensions starting
% at given path and going up to given depth (default: no
% 'depth digging', only the given folder)
% the results (file names) are returned in a cell array
% (flist). 
%          additionaly if one digs down from a root
% folder, finfo structure may become useful - it
% contains information about which files belong to which
% folders
%
% INPUT:
% folder       - path in string 
%               (or multiple paths as a cell matrix of strings)
% extensions   - string describing file extension in the following format:
%                '*.extension' 
%                (if multiple extensions are specified - they should be in
%                 separate cells of a cell matrix)
%                (use of regular expressions is not yet supported)
%
% optional input:
% 'subfolders' - informs the function that you want to include subfolders
%                (default depth of subfolder search is 1 - immediate sub-
%                 folders are only included)
% 'depth'      - this key lets you define the depth of subfolder search
%                as the next value like in the example below:
%                [flist, finfo] = prep_list('C:\', '*.txt',...
%                    'subfolders', 'depth', 2);
%
% OUTPUT:
% flist        - cell array of strings representing file names
%
% finfo        - structure with following fields:
%      .folders    - cell array of strings representing searched paths
%      .folderfile - cell array of integer arrays - each element of the
%                    cell array corresponds to path in (.folders)
%                    while its contents inform about files in flist
%                    output (each value is an index to flist)
%                    example:
%                        to get all the files that were found in the 
%                        second folder mentioned in finfo.folders we 
%                        can write:
%                        flsinfld2 = flist(finfo.folderfile{2});
%      .filein     - numerical array assigning to each element of flist
%                    the index of the folder (path) where this file was 
%                    found.
%                    It can be understood as an inverse of finfo.folderfile
%                    example:
%                        to get the path of the second file in flist
%                        (flist{2}) we write:
%                        strpathoffile2 = finfo.folders{finfo.filein(2)};
% 
% coded by Mikolaj Magnuski, some time in 2012
% imponderabilion@gmail.com

% checking for additional options
subfold = false; depth = 0;
if nargin > 2
    if sum(strcmp('subfolders', varargin))>0
        subfold = true;
        depthi = strcmp('depth', varargin);
        if sum(depthi)>0
            depth = varargin{find(depthi, 1, 'first')+1};
        else
            depth = 1;
        end
    end
end

if ischar(folder)
    folder = {folder};
end
if ischar(extensions)
    extensions = {extensions};
end

full_list = {};
full_fold_list = {};
folder = folder(:);
addit.folders = folder;
addit.folderfile = cell(length(folder),1);
addit.filein = [];

for i = 1:length(folder)
    % current folder
    nowfold = folder{i};
    if nowfold(end) ~= '\'
        nowfold(end+1) = '\'; %#ok<AGROW>
    end
    
    % walking through extensions:
    for j = 1:length(extensions)
        lista = dir([nowfold, '*', extensions{j}]);
        list = {lista(~[lista.isdir]).name};
        list = list(:);
        clear lista
        
        % removing '.' and '..' if present
        if ~isempty(list)
            if strcmp(list{1}, '.')
                list(1) = [];
            end
            if strcmp(list{1}, '..')
                list(1) = [];
            end
        end
        
        % updating
        addit.folderfile{i,1} = [addit.folderfile{i}, ...
            length(full_list) + 1 : length(full_list) + length(list)];
        addit.filein = [addit.filein; ones(length(list),1) * i];
        full_list = [full_list; list]; %#ok<AGROW>
        
        % looking for subfolders
        if subfold && depth>0
            lista = dir(folder{i});
            fold_list = {lista([lista.isdir]).name}';
            
            % removing '.' and '..' if present
            if ~isempty(fold_list)
                if strcmp(fold_list{1}, '.')
                    fold_list(1) = [];
                end
                if strcmp(fold_list{1}, '..')
                    fold_list(1) = [];
                end
            end
            
            fold_list = cellfun(@(x) [nowfold, x], fold_list, 'UniformOutput', false);
            full_fold_list = [full_fold_list; fold_list]; %#ok<AGROW>
            
            % integrating addit
        end
    end
end

if subfold && depth>0
    [nextlist, nextaddit] = prep_list(full_fold_list, extensions, 'subfolders', 'depth', depth-1);
    
    % updating
    prev_files = length(full_list);
    nextaddit.filein = nextaddit.filein + length(addit.folders);
    
    addit.filein = [addit.filein; nextaddit.filein];
    addit.folders = [addit.folders; nextaddit.folders];
    
    for a = 1:length(nextaddit.folderfile)
        addit.folderfile{i} = addit.folderfile{i} + prev_files;
    end
    
    addit.folderfile = [addit.folderfile; nextaddit.folderfile];
    full_list = [full_list; nextlist];
end

