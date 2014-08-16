% NON-UNIVERSAL
% BRANCH

% function for running ADJUST on files
% stored in ICAw base

%% load database:
% predirs for Dropbox:
predir = {'D:\Dropbox\', '\\Swps-01143\e\Dropbox\'};
postdir = 'DANE\MGR\EEG\ICAw_set.mat';
outdir = '\\Swps-01143\e\Dropbox\DANE\MGR\EEG\adjust logs\';

% check predirs:
dirs = false(size(predir));
for a = length(predir)
    dirs(a) = isdir(predir{a});
end

gooddir = find(dirs, 1, 'first');
clear dirs

% opening database
loaded = load([predir{gooddir}, postdir]);
newICAw = loaded.newICAw;
clear loaded gooddir

% go through all database records
for a = 1:length(newICAw)
    fprintf('Database record number %d \n', a);
    if isempty(newICAw(a).icaweights)
        continue
    end
    
    % recover EEG
    EEG = recoverEEG(newICAw, a, 'nofilter');
    
    % rec number:
    basenum = num2str(a);
    if length(basenum) == 1
        basenum = ['0', basenum]; %#ok<AGROW>
    end
    
    % contstruct path to log file:
    out = [outdir, 'record_', basenum, '.txt']; 
    
    % ADJUST to classify artif componenets:
    [art, horiz, vert, blink, disc]=ADJUST(EEG,out);
    
    % clear data
    ALLEEG = pop_delset( ALLEEG, 1 );
    EEG = [];
    
    % update ICA base:
    newICAw(a).adjust.art = art;
    newICAw(a).adjust.horiz = horiz;
    newICAw(a).adjust.vert = vert;
    newICAw(a).adjust.blink = blink;
    newICAw(a).adjust.disc = disc;
    clear art horiz vert blink disc
end

% saving database
disp('saving database');
save([predir{gooddir}, postdir], 'newICAw');