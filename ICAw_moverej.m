function ICAw = ICAw_moverej(ICAw, r, epoch_info, perc, varargin)

% ICAw = ICAw_moverej(ICAw, epoch_info, perc, varargin)
% Moves rejections from onesecepoch to any other
% event-based epoching.
% ICAw - the database
% epoch_info - structure describing epoching
% perc       - percent of overlap between bad onesec window
%              and new epoch above (and equal to) which
%              the new epoch is rejected

% copy bad windows to bad epochs:

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
    pth = ICAw_path(ICAw(r).filepath);
    
    EEG = load([pth, ICAw(r).filename], '-mat');
    EEG = EEG.EEG;
    
    % check windows it would be cut into:
    siglen = EEG.pnts;
    
    if femp(ICAw(r).onesecepoch, 'winlen')
        wln = ICAw(r).onesecepoch.winlen;
    else
        wln = 1;
    end
    
    winlen = round(wln * EEG.srate); % in samples
    numwin = floor(siglen / winlen);
    
    win = ones(winlen, numwin);
    win = win .* repmat(1:numwin, [winlen, 1]);
    clear winlen wln numwin
    
    % now see which are prerejected (0)
    win(:,ICAw(r).prerej) = 0;
    lft = find(win(1,:)); % left after prerej
    
    % and see which are rejected (-1)
    win(:,lft(ICAw(r).postrej)) = -1;
    
    % unroll:
    win = win(:)';
    
    % look for epoching events:
    tps = {EEG.event.type};
    ep_ev = epoch_info.epoch_events;
    evn = [];
    
    for e = 1:length(ep_ev)
        evn = unique([evn, find(strcmp(ep_ev{e},...
            tps))]);
    end
    clear tps e
    
    
    if isempty(evn)
        % if no such events - throw error
        error('No epoching events found in file %s :(',...
            ICAw(r).filename);
    end
    
    % latencies
    lat = [EEG.event(evn).latency];
    ep_lim = epoch_info.epoch_limits;
    
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
        
        if witih_data(e)
            ep(ep_smp_adr(e,1):ep_smp_adr(e,2)) = e;
            perc_bad(e) = length(find(win(ep_smp_adr(e,1):...
                ep_smp_adr(e,2)) <= 0)) / diflim_smp;
        end
    end
    clear e ep ep_smp_adr
    
    % kill epochs that do not fit within the data:
    perc_bad(~witih_data) = [];
    
    
    %% move rejections:
    ICAw(r).onesecepoch = [];
    ICAw(r).prerej = [];
    
    if ~addmarks
        ICAw(r).removed = find(perc_bad >= perc);
        ICAw(r).postrej = find(perc_bad >= perc);
    else
        ICAw(r).removed = [];
        ICAw(r).postrej = [];
    end
    
    % clear reject fields
    fld = {'userreject', 'usermaybe', 'userdontknow'};
    for f = 1:length(fld)
        ICAw(r).userrem.(fld{f}) = zeros(length(lat),1);
    end
    
    % add marks to userrem.userreject:
    ep_logic = false(length(lat), 1);
    ep_logic(perc_bad >= perc) = true;
    ICAw(r).userrem.userreject = ep_logic;
    
    % apply epoch events and limits:
    ICAw(r).epoch_events = ep_ev;
    ICAw(r).epoch_limits = ep_lim;
end