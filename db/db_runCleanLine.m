function ICAw = db_runCleanLine(ICAw, addopt)

% ICAw = db_runCleanLine(ICAw)
%
% runs CleanLine for records where field 
% cleanline is set to true. 
% Updates ICAw structure.
% FIXHELPINFO - add info about creation of
%               \CleanLine\ folder etc.

% CHANGE - add new filepath argument?
% CHANGE - other options? (parameter scan?)

% TODOs:
% [ ] check for datainfo.cleanline - if true do not run (?)
% [ ] change file operations - use fullfile

cleanr = false(length(ICAw), 1);

% scan ICAw for files to clean:
for r = 1:length(ICAw)
    if femp(ICAw(r), 'cleanline') && ...
            (~islogical(ICAw(r).cleanline) || ...
            ICAw(r).cleanline)
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
    pth = db_path(ICAw(r).filepath);
    EEG = pop_loadset('filename', ICAw(r).filename, ...
        'filepath', pth);
    
    % add orig info (info about orig file)
    ICAw(r).datainfo.origfilename = ICAw(r).filename;
    ICAw(r).datainfo.origfilepath = ICAw(r).filepath;
    
    %% check filtering and filter if necess
    if femp(ICAw(r), 'filter')
        
        % setting up filter:
        filt = [ICAw(r).filter(1),...
            ICAw(r).filter(2)];
        
        % filtering
        EEG = pop_eegfiltnew(EEG, filt(1), filt(2));
        clear filt
        
        % move filter to datainfo
        ICAw(r).datainfo.filter = ICAw(r).filter;
        ICAw(r).filter = [];
    end
    
    %% check options
    thisopt = opt;
    if isstruct(ICAw(r).cleanline)
        thisopt = db_copybase(thisopt, ICAw(r).cleanline);
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
    % update ICAw.datainfo
    ICAw(r).datainfo.cleanline = true;
    
    % cleanline done, no need to perform again
    ICAw(r).cleanline = false;
    
    %% update ICAw filepath
    fsep = filesep;
    
    % update filepath
    if pth(end) == fsep
        ICAw(r).filepath = [pth, 'CleanLine', fsep];
    else
        ICAw(r).filepath = [pth, fsep, 'CleanLine', fsep];
    end
    
    %% save file
    % check if folder exists
    if ~isdir(ICAw(r).filepath)
        mkdir(ICAw(r).filepath);
    end
    
    % save set to disc
    pop_saveset(EEG, 'filename', ICAw(r).filename, ...
        'filepath', ICAw(r).filepath);
     
end