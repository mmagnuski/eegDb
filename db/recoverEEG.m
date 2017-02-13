function EEG = recoverEEG(db, r, varargin)

% RECOVEREEG recovers a file from raw data
% according to db database 
%
% EEG = RECOVEREEG(db, r);
%
% db - the db database
% r    - db's record number to recover
% EEG  - eeglab's EEG structure
% 
% RECOVEREEG() performs all modifications (filtering,
% epoching, rejection of epochs etc.) stated in the
% database unless asked to omit some of them
% (cleanline is omitted by default, if you want to
%  run cleanline, add 'cleanline' to function keys)
%
% additional keys:
% 'prerej'      - remove only the prerejected
%                 epochs
% 'noepoch'     - do not epoch or segment the file
% 'loaded'      - the file is loaded - look for corresponding
%                 modifications in the database and recover
% 'dir'         - allows to pass the directory
%                 where files reside (the path
%                 stated in the database can be
%                 different if data are accessed
%                 from a different computer)
% 'local'       - do not update base workspace
% 'nofilter'    - do not filter (for example the data
%                 are currently already filtered)
% 'cleanl'      - perform clean line if requested in the
%                 database record
% 'noICA'       - do not load ICA weights, even if present
%                 in the database
% 'ICAnorem'    - do not reject independent components, even if
%                 scheduled for removal
% 'interp'      - interpolate bad channels as the last step
%                 file recovery.
%
% examples
% 
% to get back EEG of the second file in the database:
% >> EEG = recoverEEG(db, 2);
% 
% see also: db_buildbase, winreject

% =================
% info for hackers:
% --> filtering assumes EEGlab version 12.0.1.0 or
%     newer, but the version is not checked for
% --> other filtering options may be implemented in
%     future
% --> empty entries in ALLEEG are located by scanning
%     for empty fields 'pnts' (isempty([ALLEEG.pnts]))
% --> files should have info whether they were fil-
%     tered (in most cases - they have)
%     db(r).datainfo.filtered !
% --> undocummented field postfilter allows for
%     filtering the data as the last step of re-
%     covery.
%


%% defaults:
prerej = false; cleanl = false;
local = false; nofilter = false;
loaded = false; addfilt = [];
overr_dir = false; noICA = false;
code_id = '\code:'; ICAnorem = false;
interp = false; segment = false;
nosegment = false; noepoch = false;

cidlen = length(code_id);

%% checking additional arguments
if nargin > 2
    % optional arguments
    args = {'interp', 'ICAnorem', 'prerej', 'local',...
        'loaded', 'nofilter', 'noICA', 'nosegment', ...
        'noepoch'};
    
    % simple argument checks
    for a = 1:length(args)
        reslt = strcmp(args{a}, varargin);
        if sum(reslt)>0
            varargin(reslt) = [];
            eval([args{a}, ' = true;']);
            if isempty(varargin)
                break
            end
        end
    end

    
    % give different directory
    reslt = strcmp('dir', varargin);
    if sum(reslt)>0
        overr_dir = true;
        path = varargin{find(reslt) + 1};
    end

    % ADD - check for path override
end

%% initial checks:
% if only one registry given:
if length(db) == 1
    r = 1;
end

% is segment given:
if isfield(db(r).epoch, 'segment') && ...
        ~isempty(db(r).epoch.segment) && isnumeric(db(r).epoch.segment)
    segment = true;
end

%% if 'loaded'
% CONSIDER moving checks for EEG presence to a separate function
% CONSIDER - loaded does not seem to be used much now...
% if EEG is loaded: look for it in the
% db database:
if loaded
    EEG = evalin('base', 'EEG;'); %#ok<*UNRCH>
    CURRENTSET = evalin('base', 'length(ALLEEG)+1');
    ans_adr = db_find(db, 'filename', EEG.filename);
    if isempty(ans_adr)
        disp(['The loaded file is not present in ',...
            'the database. Could not reconstruct.']);
        return
    end
    
    % CHANGE:
    % check below - if more than one found in database
    r = ans_adr(1);
end

% ====================================
% if user chooses to override filepath
if overr_dir
    db(r).filepath = path;
end

% ================================================
% if multiple paths given, check which one applies
if iscell(db(r).filepath)
    pth = db_path(db(r).filepath);
else
    pth = db(r).filepath;
end


%% checking EEGlab:
% CONSIDER encapsulating eeglab checks
if ~loaded
    % path availability and
    % eeglab inteface presence should be
    % distinguished
    [iseegl1, iseegl2] = checkEEGlab();
    iseeglab = iseegl1 & iseegl2;
    
    % declaring globals seems not to be needed
    
    if ~iseeglab
        % ADD - if no eeglab present and 'local' option defined
        % what should the function do?
        
        if ~local
            EEG = eeglab;
            CURRENTSET = 1; CURRENTSTUDY = 0; %#ok<NASGU>
            LASTCOM = ''; ALLCOM = {}; %#ok<NASGU>
        else
            eeg_path('add');
        end
    else
        if ~local
            % ALLEEG may be completely empty:
            isempt = evalin('base', 'isempty(ALLEEG);');
            if isempt
                CURRENTSET = 1;
            else
                % else, echeck empty ALLEEGs by pnts:
                pnts = evalin('base', '{ALLEEG.pnts};');
                emp = find(cellfun(@isempty, pnts));
                if isempty(emp)
                    % no empty entries, add another
                    CURRENTSET = evalin('base', 'length(ALLEEG)+1;');
                else
                    % use first empty entry of ALLEEG
                    CURRENTSET = emp(1);
                end
                clear emp pnts
            end
            clear isempt
        end
    end
else
    iseeglab = true;
end

%% recover file:
if ~loaded
    % CHANGE if there are problems to try-catch
    EEG = db_fastread(pth, db(r).filename);
    
    % make sure event types are in string format
    EEG = db_stringify_event_types(EEG);
    
    % EEG = pop_loadset('filename', db(r).filename, ...
    %     'filepath', pth);
    
    % =====================
    % checking prefunctions
    if isfield(db, 'prefun') && ~isempty(db(r).prefun)
        for pr = 1:size(db(r).prefun,1)
            if ~ischar(db(r).prefun{pr,1}) && isempty(db(r).prefun{pr,2})
                EEG = feval(db(r).prefun{pr,1},EEG);
            elseif ~ischar(db(r).prefun{pr,1})
                EEG = feval(db(r).prefun{pr,1}, EEG, db(r).prefun{pr,2}{:});
            else
                EEG = eval(db(r).prefun{pr,1});
            end
        end
    end
    
    % ==================
    % checking filtering
    if ~nofilter
        % optional filtering:
        if isfield(db(r), 'filter') && ...
                ~isempty(db(r).filter)
            % setting up filter:
            filt = db(r).filter;
            if sum(filt(1,:)) > 0 
                % filtering
                test_pop_eegfiltnew();
                EEG = pop_eegfiltnew(EEG, filt(1,1), filt(1,2));
            end
            
            % ===============
            % notch filtering
            % add notch filering if db(r).filter has
            % two rows...
            if size(db(r).filter, 1) == 2
                EEG = pop_eegfiltnew(EEG, filt(2,1), filt(2,2), [], 1);
            end
            
        elseif ~isempty(addfilt)
            % filtering
            EEG = pop_eegfiltnew(EEG, addfilt(1), addfilt(2));
        end
        
    elseif ~isempty(addfilt)
        % filtering
        EEG = pop_eegfiltnew(EEG, addfilt(1), addfilt(2));
    end
    
    % ==============
    % good channels:
    allchan = 1:size(EEG.data,1);
    allchan(db(r).chan.bad) = [];
    
    % ============================
    % cleanline for good channels:
    if cleanl && db(r).usecleanline
        EEG = pop_cleanline(EEG, 'bandwidth', 2, 'chanlist', allchan,...
            'computepower', 1, 'linefreqs', [50 100] , 'normSpectrum', 0,...
            'p', 0.01, 'pad', 2, 'plotfigures', 0, 'scanforlines', 1,...
            'sigtype', 'Channels', 'tau', 100, 'verb', 1, 'winsize',...
            4, 'winstep', 0.5);
    end
end

% % rereference if needed
% if femp(db(r).chan, 'reref')
%     if strcmp(db(r).chan.reref, 'avg')
%         EEG = pop_reref( EEG, [], 'exclude', db(r).chan.bad, 'keepref', 'on');
%     end
% end


%% adding ICA info
add_comprej = false;
hasica = femp(db(r), 'ICA') && femp(db(r).ICA, 'icaweights');
if ~noICA && hasica
    
    % =====================
    % add weights and stuff:
    EEG.icaweights = db(r).ICA.icaweights;
    EEG.icasphere = db(r).ICA.icasphere;
    EEG.icawinv = db(r).ICA.icawinv;
    EEG.icachansind = db(r).ICA.icachansind;
    
    % add dipfit info:
    fld = femp(db(r), 'dipfit');
    if fld
        EEG.dipfit = db(r).dipfit;
    end
    
    % =======================
    % removing bad components:
    if femp(db(r).ICA, 'reject')
        if ~ICAnorem
            % removing comps:
            EEG = pop_subcomp( EEG, db(r)...
                .ICA.reject, 0);
        else
            % transferring component rejection marks:
            comprej = zeros(1, length(db(r).ICA.icachansind));
            comprej(db(r).ICA.reject) = 1;

            % eeglab removes comprej marks when removing components
            % so we keep it in separate variable and only then apply
            % to EEG:
            add_comprej = true;
        end
    end
    
    % save temp icainfo
    if interp
        temp.icaweights = EEG.icaweights;
        temp.icasphere = EEG.icasphere;
        temp.icawinv = EEG.icawinv;
        temp.icachansind = EEG.icachansind;
    end
end

%% channel location
db_hasloc = ~isempty(db(r).datainfo.chanlocs) && ...
    ~isempty([db(r).datainfo.chanlocs.X]);
if db_hasloc
    EEG.chanlocs = db(r).datainfo.chanlocs;
end

%% interpolating bad channels
if interp
    nchan1 = size(EEG.data, 1);
    EEG = eeg_interp2(EEG, db(r).chan.bad, 'spherical');
    nchan2 = size(EEG.data, 1);
    if nchan1 == nchan2 && ~isempty(EEG.icaweights)
        
        % add weights etc. after interpolation
        % due to interpolaion bug
        if  exist('temp', 'var')
            flds = fields(temp);
            for f = flds'
                EEG.(f{1}) = temp.(f{1});
            end
        end

    end
end

%% postfilter:
if femp(db(r), 'postfilter')
    % filtering
    test_pop_eegfiltnew();
    EEG = pop_eegfiltnew(EEG, db(r).postfilter(1,1),...
        db(r).postfilter(1,2));
end

%% epoching
if femp(db(r), 'epoch') && ~noepoch
    if femp(db(r).epoch, 'locked') && ~db(r).epoch.locked
        
        % ==============
        % onesec options
        options.filename = EEG;
        options.fill = true;
        
        flds = {'filter', 'winlen', 'distance',...
            'leave', 'eventname'};
        
        % checking fields for onesecepoch
        for f = 1:length(flds)
            if femp(db(r).epoch, flds{f})
                options.(flds{f}) = db(r).epoch.(flds{f});
            end
        end
        
        % if prerej is present then no need to use distance
        if femp(db(r).reject, 'pre')
            options.distance = [];
        end
        
        % ===================
        % call to onesecepoch
        EEG = onesecepoch(options);
        clear options
        
    elseif ~isempty(db(r).epoch.events) && ...
            ~isempty(db(r).epoch.limits)
        
        % ==================
        % classical epoching
        epoc = db(r).epoch.events;
        
        % checking for code generator of epochs
        % ADD - function handle for epoching?
        %       or maybe not necessary - there is an
        %       option for user-defined function
        if ischar(epoc) && length(epoc) > cidlen && ...
                strcmp(epoc(1:cidlen), code_id)
            
            epoc = eval(epoc(cidlen + 1:end));
        end
        
        EEG = db_fastepoch(EEG, epoc, db(r).epoch.limits);
        
        % =======================
        % checking for segmenting
        if segment && ~nosegment
            EEG = segmentEEG(EEG, db(r).epoch.segment);
        end
    end
end

% CHANGE
% [ ] if we segment then orig_numep should be adjusted too
% [ ] instead of numep this all can be done in a smarter way
%                1) generally - onesec can add numep too
%                2) numep can be inferred from length of rejections
%                   in db(r)!
%                3) ...
% [ ] in the current version only onesecepoching is checked
%     for while in future releases we want to include also
%     conditional epoch extraction (only correct etc.) which
%     is another prerej
%
%
% ======================
% adding orig_numep info
%
% (this is later used when rejections are added
%  using a recovered file that has some of the
%  rejections already removed)
%
% if epoched signal add orig_numep
EEG.etc.orig_numep = size(EEG.data, 3);

% if onesecepoch was perfromed add onesec info
if femp(db(r).epoch, 'locked') && ~db(r).epoch.locked
    
    % either prerej is nonempty  % or what?
    if femp(db(r).reject, 'pre')
        % there is some info about prerej,
        % we correct orig_numep
        EEG.etc.orig_numep = EEG.etc.orig_numep - length(db(r).reject.pre);
    end
end

%% removing bad epochs
if ~noepoch && ~prerej && ~isempty(db(r).reject.all)
    if segment
        EEG = eeg_rmepoch(EEG, db(r).reject.all(:)');
        
    else
        EEG = pop_selectevent(EEG, 'epoch', db(r).reject.all(:)', ...
            'deleteevents', 'off', 'deleteepochs', 'on', ...
            'invertepochs', 'on');
    end
elseif ~noepoch && ~isempty(db(r).reject.pre)
    if segment
        EEG = eeg_rmepoch(EEG, db(r).reject.pre(:)');
    else
        EEG = pop_selectevent(EEG, 'epoch', db(r).reject.pre(:)', ...
            'deleteevents', 'off', 'deleteepochs', 'on', ...
            'invertepochs', 'on');
    end
end


%% highlight rejections
% highlight automatical rejections (and user
% rejections if present)
% EEG = db_rejdb2EEG(db, r, EEG, prerej);
% CHANGE, CONSIDER:
% sometimes db_getrej gives empty rejection
% type for a given registry - should this be
% allowed, should it be corrected for if
% there are filled rejectons?

% currently only epoch-marks are supported
if ~noepoch
    EEG.reject.db = db_getrej(db, r);
    
    % CONSIDER:
    % for now we assume correction, but should
    % be rather done in db_getrej or something...
    
    % ln = cellfun(@length, EEG.reject.db.value);
    % maxlen = max(ln);
    
    maxlen = EEG.etc.orig_numep;
    
    if ~(prerej || isempty(db(r).reject.all))
        % we have to correct for removed epochs:
        for f = 1:length(EEG.reject.db.value)
            if isempty(EEG.reject.db.value{f})
                EEG.reject.db.value{f} = zeros(maxlen,1);
            end
            
            % remove postrej
            EEG.reject.db.value{f}(db(r).reject.post) = [];
        end
    end
end

% add component rejection marks if necessary
if add_comprej
    EEG.reject.gcompreject = comprej;
end

% stamp the EEG with recovery version info
EEG = db_stampEEG(db, r, EEG);

% just to be on the safe side: checkset
EEG = eeg_checkset(EEG);


%% updating base workspace
if ~local
    assignin('base', 'EEG', EEG);
    assignin('base', 'CURRENTSET', CURRENTSET);
    
    if ~iseeglab
        assignin('base', 'ALLEEG', EEG);
    else
        ALLEEG = evalin('base', 'ALLEEG;');
        ALLEEG = eeg_store(ALLEEG, EEG, CURRENTSET);
        assignin('base', 'ALLEEG', ALLEEG);
    end
    
    evalin('base', 'eeglab redraw');
end
