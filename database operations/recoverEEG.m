function EEG = recoverEEG(ICAw, r, varargin)

% RECOVEREEG recovers a file from raw data
% according to ICAw database 
%
% EEG = RECOVEREEG(ICAw, r);
%
% ICAw - the ICAw database
% r    - ICAw's record number to recover
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
% >> EEG = recoverEEG(ICAw, 2);
% 
% see also: ICAw_buildbase, winreject

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
%     ICAw(r).datainfo.filtered !
% --> undocummented field postfilter allows for
%     filtering the data as the last step of re-
%     covery.
%

% VERSION info:
% 2014.01.27 --> compressed icaweights temp usage when
%                interpolating
% 2014.03.25 --> moved interpolation before epoching
%                added postfilter between interpolation
%                and epoching
% 2014.06.22 --> changed path checking loop to ICAw_path 
%                function call

% TODOs:
% [ ] path availability and eeglab inteface presence
%     should be distinguished and different actions
%     taken.
% [ ] Additional checks for newfilt availability
%     Tries to add path to the function or toolbox
%     error if not possible.
%        (This is partially done:
%         eeg_path adds path to firfilt by default)
%
% CONSIDER:
% [ ] how to enable using different filters and
%     enable better control over filtering parameters?
% [ ] add option to recover multiple files?
% [ ] far future - dealing with continuous rejections...
% [ ] whether to 'cut out' from autorem and userrem
%     rejection info about epochs in 'removed'
%     this way markings not applied will still be
%     visible
% [ ] remove the paths to eeglab in 'local' or recover
%     previous path?
% [ ] CHANGE 'loaded' behavior - now it only adds ICA,
%     should it perform other modifs (filtering, epoching,
%     etc.)? How should 'loaded' generally work??


%% defaults:
prerej = false; cleanl = false;
local = false; nofilter = false;
loaded = false; addfilt = [];
overr_dir = false; noICA = false;
code_id = '\code:'; ICAnorem = false;
interp = false; segment = false;
nosegment = false;

cidlen = length(code_id);

%% checking additional arguments
if nargin > 2
    % optional arguments
    args = {'interp', 'ICAnorem', 'prerej', 'local',...
        'loaded', 'nofilter', 'noICA', 'nosegment'};
    
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
    
    % addfilter is obsolete and will not be maintained
    %
    %     reslt = strcmp('addfilt', varargin);
    %     if sum(reslt)>0
    %         addfilt = varargin{find(reslt) + 1};
    %     end
    
    % give different directory
    reslt = strcmp('dir', varargin);
    if sum(reslt)>0
        overr_dir = true;
        path = varargin{find(reslt) + 1};
    end
    
    %zmienilam cos - tzn co? [Miko]
    % ADD - check for path override
end

%% initial checks:
% if only one registry given:
if length(ICAw) == 1
    r = 1;
end

% is segment given:
if isfield(ICAw(r).epoch, 'segment') && ...
        ~isempty(ICAw(r).epoch.segment) && isnumeric(ICAw(r).epoch.segment)
    segment = true;
end

%% if 'loaded'
% CONSIDER moving checks for EEG presence to a separate function
% CONSIDER - loaded does not seem to be used much now...
% if EEG is loaded: look for it in the
% ICAw database:
if loaded
    EEG = evalin('base', 'EEG;'); %#ok<*UNRCH>
    CURRENTSET = evalin('base', 'length(ALLEEG)+1');
    [answer, ans_adr] = ICAw_checkbase(ICAw,...
        EEG, 'filename', 'silent');
    if ~answer(1)
        disp(['The loaded file is not present in ',...
            'the database. Could not reconstruct.']);
        return
    end
    
    % CHANGE:
    % check below - if more than one found in database
    r = ans_adr{1}(1);
    
end

%% checking path:
% this is obsolete:
% if ~loaded && ~overr_dir
%     % create possible pre-paths and take the path
%     % as stated in the database
%     checkpre = {'D:\', '\\Swps-01143\e\'};
%     path = ICAw(r).filepath;
%
%     % look for 'Dropbox' in the path:
%     postpath = [];
%     pathterm = 'Dropbox';
%     dr = regexp(path, pathterm, 'once');
%     if ~isempty(dr)
%         dr = dr(1);
%         postpath = path(dr:end);
%     end
%
%     % check prepaths:
%     if ~isempty(postpath)
%         for a = 1:length(checkpre)
%             if isdir([checkpre{a}, postpath])
%                 path = [checkpre{a}, postpath];
%                 break
%             end
%         end
%     end
% end

% ====================================
% if user chooses to override filepath
if overr_dir
    ICAw(r).filepath = path;
end

% ================================================
% if multiple paths given, check which one applies
if iscell(ICAw(r).filepath)
%     if length(ICAw(r).filepath) > 1
%         
%         % loop through possible paths until you find
%         % the correct one (one that exists - that is)
%         for p = 1:length(ICAw(r).filepath)
%             if isdir(ICAw(r).filepath{p})
%                 ICAw(r).filepath = ICAw(r).filepath{p};
%                 break
%             end
%         end
%         clear p
%     else
%         ICAw(r).filepath = ICAw(r).filepath{1};
%     end
    pth = ICAw_path(ICAw(r).filepath);
else
    pth = ICAw(r).filepath;
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
    EEG = eegDb_fastread(pth, ICAw(r).filename);
    
    % EEG = pop_loadset('filename', ICAw(r).filename, ...
    %     'filepath', pth);
    
    % =====================
    % checking prefunctions
    if isfield(ICAw, 'prefun') && ~isempty(ICAw(r).prefun)
        for pr = 1:size(ICAw(r).prefun,1)
            if ~ischar(ICAw(r).prefun{pr,1}) && isempty(ICAw(r).prefun{pr,2})
                EEG = feval(ICAw(r).prefun{pr,1},EEG);
            elseif ~ischar(ICAw(r).prefun{pr,1})
                EEG = feval(ICAw(r).prefun{pr,1}, EEG, ICAw(r).prefun{pr,2}{:});
            else
                EEG = eval(ICAw(r).prefun{pr,1});
            end
        end
    end
    
    % ==================
    % checking filtering
    if ~nofilter
        % optional filtering:
        if isfield(ICAw(r), 'filter') && ...
                ~isempty(ICAw(r).filter)
            
            % setting up filter:
            filt = ICAw(r).filter;
            
            % addfilt is no longer supported
            % its better to create another version
            % entry then to use 'addfilt'
            %
            %             if ~isempty(addfilt)
            %                 if ~(addfilt(1) == 0)
            %                     filt(1) = max(ICAw(r).filter(1),...
            %                         addfilt(1));
            %                 end
            %
            %                 if filt(2) == 0
            %                     filt(2) = addfilt(2);
            %                 elseif ~(addfilt(2) == 0)
            %                     filt(2) = min(filt(2), addfilt(2));
            %                 end
            %             end
            
            % filtering
            test_pop_eegfiltnew();
            EEG = pop_eegfiltnew(EEG, filt(1,1), filt(1,2));
            
            
            % ===============
            % notch filtering
            % add notch filering if ICAw(r).filter has
            % two rows...
            if size(ICAw(r).filter, 1) == 2
                EEG = pop_eegfiltnew(EEG, filt(2,1), filt(2,2), [], 1, [], 0);
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
    allchan(ICAw(r).chan.bad) = [];
    
    % ============================
    % cleanline for good channels:
    if cleanl && ICAw(r).usecleanline
        EEG = pop_cleanline(EEG, 'bandwidth', 2, 'chanlist', allchan,...
            'computepower', 1, 'linefreqs', [50 100] , 'normSpectrum', 0,...
            'p', 0.01, 'pad', 2, 'plotfigures', 0, 'scanforlines', 1,...
            'sigtype', 'Channels', 'tau', 100, 'verb', 1, 'winsize',...
            4, 'winstep', 0.5);
    end
end


%% adding ICA info
if ~noICA && femp(ICAw(r), 'ICA') && ...
    femp(ICAw(r).ICA, 'icaweights')
    
    % =====================
    % add weights and stuff:
    EEG.icaweights = ICAw(r).ICA.icaweights;
    EEG.icasphere = ICAw(r).ICA.icasphere;
    EEG.icawinv = ICAw(r).ICA.icawinv;
    EEG.icachansind = ICAw(r).ICA.icachansind;
    
    % add dipfit info:
    fld = ICAw_checkfields(ICAw, r, {'dipfit'});
    if fld.fnonempt(1)
        EEG.dipfit = ICAw(r).dipfit;
    end
    
    % =======================
    % removing bad components:
    if femp(ICAw(r).ICA, 'reject') && ...
            ~ICAnorem
        % removing comps:
        EEG = pop_subcomp( EEG, ICAw(r)...
            .ICA.reject, 0);
    end
    
    % save temp icainfo
    if interp
        temp.icaweights = EEG.icaweights;
        temp.icasphere = EEG.icasphere;
        temp.icawinv = EEG.icawinv;
        temp.icachansind = EEG.icachansind;
    end
    
end


%% interpolating bad channels
if interp
    EEG = eeg_interp2(EEG, ICAw(r).chan.bad, 'spherical');
    if ~isempty(EEG.icaweights)
        
        % add weights etc. after interpolation
        % due to interpolaion bug
        if  exist('temp', 'var')
            flds = fields(temp);
            for f = flds'
                EEG.(f{1}) = temp.(f{1});
            end
        end
        
        % CHANGE - we shouldn't require icaact in
        %          recoverEEG - it creates twice
        %          as much data
        %         if isempty(EEG.icaact)
        %             EEG.icaact = eeg_getdatact(EEG, 'component', 1:size(EEG.icaweights,1));
        %         end
    end
end

%% postfilter:
if femp(ICAw(r), 'postfilter')
    % filtering
    test_pop_eegfiltnew();
    EEG = pop_eegfiltnew(EEG, ICAw(r).postfilter(1,1),...
        ICAw(r).postfilter(1,2));
end

%% epoching
if femp(ICAw(r), 'epoch')
    if femp(ICAw(r).epoch, 'locked') && ~ICAw(r).epoch.locked
        
        % ==============
        % onesec options
        options.filename = EEG;
        options.fill = true;
        
        flds = {'filter', 'winlen', 'distance',...
            'leave', 'eventname'};
        
        % checking fields for onesecepoch
        for f = 1:length(flds)
            if femp(ICAw(r).epoch, flds{f})
                options.(flds{f}) = ICAw(r).epoch.(flds{f});
            end
        end
        
        % if prerej is present then no need to use distance
        if femp(ICAw(r).reject, 'pre')
            options.distance = [];
        end
        
        % ===================
        % call to onesecepoch
        EEG = onesecepoch(options);
        clear options
        
    elseif ~isempty(ICAw(r).epoch.events) && ...
            ~isempty(ICAw(r).epoch.limits)
        
        % ==================
        % classical epoching
        epoc = ICAw(r).epoch.events;
        
        % checking for code generator of epochs
        % ADD - function handle for epoching?
        %       or maybe not necessary - there is an
        %       option for user-defined function
        if ischar(epoc) && length(epoc) > cidlen && ...
                strcmp(epoc(1:cidlen), code_id)
            
            epoc = eval(epoc(cidlen+1:end));
        end
        
        EEG = eegDb_fastepoch(EEG, epoc, ICAw(r).epoch.limits);
        
        % =======================
        % checking for segmenting
        if segment && ~nosegment
            EEG = segmentEEG(EEG, ICAw(r).epoch.segment);
        end
    end
end

% CHANGE
% [ ] if we segment then orig_numep should be adjusted too
% [ ] instead of numep this all can be done in a smarter way
%                1) generally - onesec can add numep too
%                2) numep can be inferred from length of rejections
%                   in ICAw(r)!
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
if femp(ICAw(r).epoch, 'locked') && ~ICAw(r).epoch.locked
    
    % either prerej is nonempty  % or what?
    if femp(ICAw(r).reject, 'pre')
        % there is some info about prerej,
        % we correct orig_numep
        EEG.etc.orig_numep = EEG.etc.orig_numep - length(ICAw(r).reject.pre);
    end
end

%% removing bad epochs
if ~prerej && ~isempty(ICAw(r).reject.all)
    if segment
        EEG = eeg_rmepoch(EEG, ICAw(r).reject.all(:)');
        
    else
        EEG = pop_selectevent( EEG, 'epoch', ICAw(r).reject.all(:)' ,...
            'deleteevents','off','deleteepochs','on','invertepochs','on');
    end
elseif ~isempty(ICAw(r).reject.pre)
    if segment
        EEG = eeg_rmepoch(EEG, ICAw(r).reject.pre(:)');
    else
        EEG = pop_selectevent( EEG, 'epoch', ICAw(r).reject.pre(:)' ,...
            'deleteevents','off','deleteepochs','on','invertepochs','on');
    end
end


%% highlight rejections
% highlight automatical rejections (and user
% rejections if present)
% EEG = ICAw_rejICAw2EEG(ICAw, r, EEG, prerej);
% CHANGE, CONSIDER:
% sometimes ICAw_getrej gives empty rejection
% type for a given registry - should this be
% allowed, should it be corrected for if
% there are filled rejectons?
EEG.reject.ICAw = ICAw_getrej(ICAw, r);

% CONSIDER:
% for now we assume correction, but should
% be rather done in ICAw_getrej or something...

% ln = cellfun(@length, EEG.reject.ICAw.value);
% maxlen = max(ln);

maxlen = EEG.etc.orig_numep;

if ~(prerej || isempty(ICAw(r).reject.all))
    % we have to correct for removed epochs:
    for f = 1:length(EEG.reject.ICAw.value)
        if isempty(EEG.reject.ICAw.value{f})
            EEG.reject.ICAw.value{f} = zeros(maxlen,1);
        end
        
        % remove postrej
        EEG.reject.ICAw.value{f}(ICAw(r).reject.post) = [];
    end
end

% stamp the EEG with recovery version info
EEG = ICAw_stampEEG(ICAw, r, EEG);

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