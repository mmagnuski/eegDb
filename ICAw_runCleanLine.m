function ICAw = ICAw_runCleanLine(ICAw)

% runs CleanLine for file with field usecleanline set
% to true. Updates ICAw structure
% add new filepath argument?

% TODOs:
% [ ] check for datainfo.cleanline - if true do not run (?)

cleanr = zeros(length(ICAw), 1);

% scan ICAw for files to clean:
for r = 1:length(ICAw)
    if isfield(ICAw(r), 'usecleanline') && ...
            ~isempty(ICAw(r).usecleanline) && ...
            islogical(ICAw(r).usecleanline)
        cleanr(r) = ICAw(r).usecleanline;
    else
        cleanr(r) = false;
    end
end

cleanr = find(cleanr);

% check EEGlab path
eeglab;

% loop through files with cleanline
for C = 1:length(cleanr)
    r = cleanr(C);
    
    % load set
    pth = ICAw_path(ICAw(r).filepath);
    EEG = pop_loadset('filename', ICAw(r).filename, ...
        'filepath', pth);
    
    % add orig info (info about orig file)
    ICAw(r).datainfo.origfilename = ICAw(r).filename;
    ICAw(r).datainfo.origfilepath = ICAw(r).filepath;
    
    %% check filtering and filter if necess
    if isfield(ICAw(r), 'filter') && ...
            ~isempty(ICAw(r).filter)
        
        % setting up filter:
        filt = [ICAw(r).filter(1),...
            ICAw(r).filter(2)];
        
        % filtering
        EEG = pop_eegfiltnew(EEG, filt(1), filt(2));
        clear filt
        
        % move filter to datainfo
        ICAw(r).datainfo.filtered = ICAw(r).filter;
        ICAw(r).filter = [];
    end
    
    % create allchan
    allchan = 1:size(EEG.data,1);
    
    %% run cleanline (default)
    EEG = pop_cleanline(EEG, 'bandwidth', 2, 'chanlist', allchan,...
        'computepower', 1, 'linefreqs', [50 100] , 'normSpectrum', 0,...
        'p', 0.01, 'pad', 2, 'plotfigures', 0, 'scanforlines', 1,...
        'sigtype', 'Channels', 'tau', 100, 'verb', 1, 'winsize',...
        4, 'winstep', 0.5);
    
    % update ICAw.datainfo
    ICAw(r).datainfo.cleanline = true;
    
    % cleanline done, no need to perform again
    ICAw(r).usecleanline = false;
    
    %% save file and update ICAw filepath
    fsep = filesep;
    
    % update filepath
    if pth(end) == fsep
        ICAw(r).filepath = [pth, 'CleanLine', fsep];
    else
        ICAw(r).filepath = [pth, fsep, 'CleanLine', fsep];
    end
    
    % check if folder exists
    if ~isdir(ICAw(r).filepath)
        mkdir(ICAw(r).filepath);
    end
    
    
    % save set to disc
    pop_saveset(EEG, 'filename', ICAw(r).filename, 'filepath', ICAw(r).filepath);
    
    
end