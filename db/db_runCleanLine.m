function db = db_runCleanLine(db, addopt)

% db = db_runCleanLine(db)
%
% runs CleanLine for records where field 
% cleanline is set to true. 
% Updates db structure.
% FIXHELPINFO - add info about creation of
%               \CleanLine\ folder etc.

% CHANGE - add new filepath argument?
% CHANGE - other options? (parameter scan?)

% TODOs:
% [ ] check for datainfo.cleanline - if true do not run (?)
% [ ] change file operations - use fullfile

cleanr = false(length(db), 1);

% scan db for files to clean:
for r = 1:length(db)
    if femp(db(r), 'cleanline') && ...
            (~islogical(db(r).cleanline) || ...
            db(r).cleanline)
        cleanr(r) = true;
    end
end

cleanr = find(cleanr);

% check EEGlab path
eeg_path('add');

% default options:
opt.pad = 2;
opt.verb = 0;
opt.p = 0.01;
opt.tau = 100;
opt.winsize = 4;
opt.winstep = 0.5;
opt.bandwidth = 2;
opt.plotfigures = 0;
opt.computepower = 0;
opt.normSpectrum = 0;
opt.scanforlines = 1;
opt.chanlist = 'all';
opt.linefreqs = [50 100];
opt.sigtype = 'Channels';

% change default options if user passes these
if exist('addopt', 'var')
    opt = db_copybase(opt, addopt);
end

% loop through files for cleanline
for C = 1:length(cleanr)
    r = cleanr(C);
    fprintf('cleaning record %d\n', r);
    
    % load set
    pth = db_path(db(r).filepath);
    EEG = pop_loadset('filename', db(r).filename, ...
        'filepath', pth);
    
    % add orig info (info about orig file)
    db(r).datainfo.origfilename = db(r).filename;
    db(r).datainfo.origfilepath = db(r).filepath;
    
    %% check filtering and filter if necess
    if femp(db(r), 'filter')
        
        % setting up filter:
        filt = [db(r).filter(1),...
            db(r).filter(2)];
        
        % filtering
        EEG = pop_eegfiltnew(EEG, filt(1), filt(2));
        clear filt
        
        % move filter to datainfo
        db(r).datainfo.filter = db(r).filter;
        db(r).filter = [];
    end
    
    %% check options
    thisopt = opt;
    if isstruct(db(r).cleanline)
        thisopt = db_copybase(thisopt, db(r).cleanline);
    end
    
    % create allchan
    % CHANGE - do not include bad channels?
    if strcmp(thisopt.chanlist, 'all')
        thisopt.chanlist = 1:size(EEG.data,1);
    end
    
    thisopt = struct_unroll(thisopt);
    
    %% run cleanline
    EEG = pop_cleanline(EEG, thisopt{:});
    
    %% update database record
    % update db.datainfo
    db(r).datainfo.cleanline = true;
    
    % cleanline done, no need to perform again
    db(r).cleanline = false;
    
    %% update db filepath
    fsep = filesep;
    
    % update filepath
    if pth(end) == fsep
        db(r).filepath = [pth, 'CleanLine', fsep];
    else
        db(r).filepath = [pth, fsep, 'CleanLine', fsep];
    end
    
    %% save file
    % check if folder exists
    if ~isdir(db(r).filepath)
        mkdir(db(r).filepath);
    end
    
    % save set to disc
    pop_saveset(EEG, 'filename', db(r).filename, ...
        'filepath', db(r).filepath);
     
end