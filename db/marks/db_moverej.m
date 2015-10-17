function db = db_moverej(db, r, epoch_info, perc, varargin)

% db = db_moverej(db, epoch_info, perc, varargin)
%
% Moves rejections from onesecepoch to any other
% event-based epoching.
% db - the database
% epoch_info - structure describing epoching
% perc       - percent of overlap between bad onesec window
%              and new epoch above (and equal to) which
%              the new epoch is rejected

% ADD some tests and options...
% TEST thoroughly

% load original (unepoched) file:
% eeg_path('add');
rs = r;
addmarks = false;

if nargin > 4
    addmarks = sum(strcmp('addmarks', varargin)) > 0;
end

% add eeglab functions:
% CHANGE - should fist test whether paths
%          are added, if not - add
% eeg_path('add');

for r = rs
    pth = db_path(db(r).filepath);
    
    % get number of samples from EEG
    % (could be later stored in datainfo)
    EEG = load([pth, db(r).filename], '-mat');
    EEG = EEG.EEG;
    siglen = EEG.pnts;
    
    % FIX - not only from onesec
    % check windows it would be cut into:
    if femp(db(r).epoch, 'winlen')
        wln = db(r).epoch.winlen;
    else
        wln = 1;
    end
    
    winlen = round(wln * EEG.srate); % in samples
    numwin = floor(siglen / winlen);
    
    win = ones(winlen, numwin);
    win = win .* repmat(1:numwin, [winlen, 1]);
    clear winlen wln numwin
    
    % now see which are prerejected (0)
    win(:,db(r).reject.pre) = 0;
    lft = find(win(1,:)); % left after prerej
    
    % and see which are rejected (-1)
    win(:,lft(db(r).reject.post)) = -1;
    
    % unroll:
    win = win(:)';
    
    % look for epoching events:
    tps = {EEG.event.type};
    ep_ev = epoch_info.events;
    evn = [];
    
    for e = 1:length(ep_ev)
        evn = unique([evn, find(strcmp(ep_ev{e},...
            tps))]);
    end
    clear tps e
    
    
    if isempty(evn)
        % if no such events - throw error
        error('No epoching events found in file %s :(',...
            db(r).filename);
    end
    
    % latencies
    lat = [EEG.event(evn).latency];
    ep_lim = epoch_info.limits;
    
    % assume floor:
    ep_lim_smp = floor(ep_lim * EEG.srate);
    diflim_smp = diff(ep_lim_smp);
    
    % create epoch structures:
    ep = zeros(size(win));
    ep_smp_adr = zeros(length(lat), 2);
    perc_bad = zeros(length(lat), 1);
    
    % add vector that tests whether
    % epoch fits within the data:
    witih_data = perc_bad;
    
    for e = 1:length(lat)
        ep_smp_adr(e,:) = lat(e) + ep_lim_smp;
        
        % test for within data:
        witih_data(e) = sum( ep_smp_adr(e,:) >= 1 & ...
            ep_smp_adr(e,:) <= siglen) == 2;
        
        % CHANGE - < 0 does not move window preselection
        %          in some cases we may want that
        if witih_data(e)
            ep(ep_smp_adr(e,1):ep_smp_adr(e,2)) = e;
            perc_bad(e) = length(find(win(ep_smp_adr(e,1):...
                ep_smp_adr(e,2)) < 0)) / diflim_smp;
        end
    end
    clear e ep ep_smp_adr
    
    % kill epochs that do not fit within the data:
    perc_bad(~witih_data) = [];
    
    
    %% move rejections:
    flds = {'distance', 'eventname', 'winlen'};
    db(r).epoch = rmfield(db(r).epoch, flds);
    db(r).reject.pre = [];
    
    if ~addmarks
        db(r).reject.all = find(perc_bad >= perc);
        db(r).reject.post = find(perc_bad >= perc);
        db(r).reject.pre = [];
    else
        db(r).reject.all = [];
        db(r).reject.pre = [];
        db(r).reject.post = [];
    end
    
    % FIX - these names are different now
    % clear reject fields
    % fld = {'userreject', 'usermaybe', 'userdontknow'};
    % for f = 1:length(fld)
    %     db(r).reject.(fld{f}) = zeros(length(lat),1);
    % end
    
    % clear marks
    for m = 1:length(db(r).marks)
        db(r).marks(m).value = [];
    end
    
    % add marks to userrem.userreject:
    ep_logic = false(length(lat), 1);
    ep_logic(perc_bad >= perc) = true;
    db(r).userrem.userreject = ep_logic;
    
    % apply epoch events and limits:
    db(r).epoch.events = ep_ev;
    db(r).epoch.limits = ep_lim;
    if femp(epoch_info, 'locked')
        db(r).epoch.locked = epoch_info.locked;
    end
end