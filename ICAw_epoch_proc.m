% this script allows to recover consecutive
% files mentioned in and ICAw structure,
% remove bad epochs, accept removal of IC
% that were set as 'to consider' (ica_ifremove),
% optionally remove additional epochs after IC
% removal and add channels to badchan structure

% BRANCH
% CHECK

% checking for 'laststep':
cnt = true;
if ~exist('laststep', 'var')
    r = 1;
else
    r = laststep;
end

while cnt && r <= length(ICAw)
    %% checking register
    % disp filename
    disp('File: ');
    disp(ICAw(r).filename);
    
    % checks for removed and ica_ifremove:
    remo = ~isempty(ICAw(r).removed);
    icaremo = isempty(ICAw(r).ica_ifremove);
    
    if remo
        disp('The file has already some epochs scheduled for removal.');
        ifremep = input('Remove these epochs?  ');
    end
    
    % add option for ICA removed
    
    if icaremo
        disp('The file does not have components scheduled for consideration.');
    end
    
    if remo || icaremo
        cnt = input('Do you want to continue anyway?  ');
    end
    
    %% processing
    if cnt
    % recovering file:
    EEG = recoverEEG(ICAw, r);
    
    % store handle to EEGLAB window:
    eegfig = findobj('Tag', 'EEGLAB');
    
    % get screen resolution:
    oldUnits = get(0,'units');
    set(0,'units','pixels');
    ScreenSize = get(0,'ScreenSize');
    ScreenSize = ScreenSize(3:4);
    set(0,'units',oldUnits);
    clear oldUnits
    
    %% starting the GUI:
    
    % variables used when iterating through
    % components to consider
    rem = ICAw(r).ica_remove;
    ifrem = ICAw(r).ica_ifremove;
    allc = 1:size(ICAw(r).icaweights, 1);
    ifrem = sort(ifrem);
    lefc = allc; lefc(rem) = [];
    crem = 0; cspa = 0;
    
    h = ICAw_ep_proc_GUI(r);
    % update text in the GUI
    ICAw_gui_upd_txt(ICAw, r, h);
    
    
    allelecs = 1:size(EEG.data,1);
    goodelecs = allelecs;
    goodelecs(ICAw(r).badchan) = [];
    
    %% removing bad epochs
    eegplot(EEG.data(goodelecs,:,:), 'srate', EEG.srate, ...
        'winlength', 2, 'eloc_file', EEG.chanlocs(goodelecs), ...
        'limits', [EEG.times(1), EEG.times(end)], ...
        'events', EEG.event, 'butlabel', 'WYPIERDOL', ...
        'command', 'disp(''Dane zasrane!'')', 'title',...
        'Wypierdol obrzydliwe epoki', 'position', ...
        [20, 60, ScreenSize(1) - 40, ScreenSize(2) - 120]);
    
    % waiting for EEGPLOT
    rejplot = findobj('Tag', 'EEGPLOT');
    uiwait(rejplot(1));
    
    % if some epochs were selected for removal: remove
    if exist('TMPREJ', 'var') && ~isempty(TMPREJ)
        rem_ep = TMPREJ(:,2) / (TMPREJ(1,2) - TMPREJ(1,1));
        EEG = pop_selectevent( EEG, 'epoch', rem_ep', ...
            'deleteevents','off','deleteepochs','on',...
            'invertepochs','on');
        % we only add some more (if prev marked):
        ICAw = ICAw_add_remep(ICAw, r, rem_ep');
        clear TMPREJ
    end
    
    % creating addinf, information about components
    % to consider (how many left, etc.)
    addinf.ifrejnum = length(ICAw(r).ica_ifremove);
    
    %% considering components
    % for each ifremove component:
    for ifr = 1:length(ifrem)
        
        % remember how many components are present:
        prevc = size(EEG.icaweights, 1);
        
        % updating addinf
        addinf.currcomp = ifrem(ifr);
        addinf.leftcomp = length(ifrem) - ifr;
        addinf.comprem  = crem;
        addinf.compspa  = cspa;
        
        % updating GUI text:
        ICAw_gui_upd_txt2(addinf, h);
        
        % find current compo:
        whchcmp = find(lefc == addinf.currcomp);
        
        goodelecs = allelecs;
        goodelecs(ICAw(r).badchan) = [];
        
        %% ===opening panels===
        % 1. before vs after removal:
        % simulate removing comps :
        EEG2 = pop_subcomp( EEG, whchcmp, 0);
        % open window:
        eegplot(EEG.data(goodelecs,:,:), 'srate', EEG.srate, ...
            'winlength', 2, 'eloc_file', EEG.chanlocs(goodelecs), ...
            'limits', [EEG.times(1), EEG.times(end)], 'data2',...
            EEG2.data(goodelecs,:,:), 'events', EEG.event, ...
            'title', 'Obczaj zmiany', 'tag', 'befaft', 'position',...
            [round(ScreenSize(1)/4 + 40), round(ScreenSize(2)/3),...
            ScreenSize(1)- 410, ScreenSize(2) - ...
            (round(ScreenSize(2)/3) + 60)]);
        % h_befaft = findobj('Tag', 'befaft');
        
        % 2. component timecourse:
        if isempty(EEG.icaact)
            % ADD compute comp timecourse
            disp('no data in EEG.icaact field, recomputing...');
            EEGunr = reshape(EEG.data, [size(EEG.data,1), EEG.pnts * EEG.trials]);
            EEG.icaact = reshape(EEG.icaweights * EEG.icasphere * squeeze(...
                EEGunr(EEG.icachansind,:)), [ size(EEG.icaweights, 1), EEG.pnts,...
                EEG.trials]);
        end
        eegplot(EEG.icaact(whchcmp,:,:), 'srate', EEG.srate, ...
            'winlength', 2,'limits', [EEG.times(1), EEG.times(end)],...
            'events', EEG.event, 'title', 'Component Timecourse', 'position',...
            [40, 50, ScreenSize(1)- 80, round(ScreenSize(2)/3) - 80],...
            'tag', 'comptim');
        
        
        % 3. component properties
        pop_prop( EEG, 0, whchcmp, NaN, {'freqrange' [1 60] });
        fg = findobj('type', 'figure');
        set(fg(1), 'Position', [20, round(ScreenSize(2)/3),...
            round(ScreenSize(1)/4 - 40), ...
            ScreenSize(2) - (round(ScreenSize(2)/3) + 80)])
        % ======================
        
        %% time to inspect comps (uiwait)
        % removing comps via EEGlab GUI:
        EEG = pop_subcomp( EEG, whchcmp, 1);
        % wait for ICAw GUI:
        uiwait(h.figure1);
        clear EEG2
        
        %% clearing up, preparing for the next step
        % checking whether there is less components now:
        % if so some have been removed
        nowc = size(EEG.icaweights, 1);
        if nowc < prevc
            % componenet was removed
            rem = [rem, ifrem(ifr)]; %#ok<AGROW>
            lefc(whchcmp) = [];
            crem = crem + 1;
            EEG = eeg_checkset(EEG);
        else
            % component was spared:
            cspa = cspa + 1;
        end
        
        % close all figures except EEGlab and ICAw GUI:
        hfig = findobj('type', 'figure');
        closefigs = setdiff(hfig, [eegfig, h.figure1]);
        close(closefigs);
    end
    
    %% epoch removal one more time
    eegplot(EEG.data(goodelecs,:,:), 'srate', EEG.srate, ...
        'winlength', 2, 'eloc_file', EEG.chanlocs(goodelecs), ...
        'limits', [EEG.times(1), EEG.times(end)], ...
        'events', EEG.event, 'butlabel', 'WYPIERDOL', ...
        'command', 'disp(''Dane zasrane!'')', 'title',...
        'Wypierdol obrzydliwe epoki', 'position', ...
        [20, 60, ScreenSize(1) - 40, ScreenSize(2) - 120]);
    
    % waiting for EEGPLOT
    rejplot = findobj('Tag', 'EEGPLOT');
    uiwait(rejplot(1));
    
    % if some epochs were selected for removal: remove
    if exist('TMPREJ', 'var') && ~isempty(TMPREJ)
        rem_ep = TMPREJ(:,2) / (TMPREJ(1,2) - TMPREJ(1,1));
        EEG = pop_selectevent( EEG, 'epoch', rem_ep', ...
            'deleteevents','off','deleteepochs','on',...
            'invertepochs','on');
        % this will need to CHANGE so that
        % if some epochs were marked for re-
        % jection we only add some more:
        ICAw = ICAw_add_remep(ICAw, r, rem_ep');
        clear TMPREJ
    end
    
    % update ICAw
    ICAw(r).ica_remove = rem;
    ICAw(r).ica_ifremove = [];
    end
    
    % change looping variables
    r = r + 1;
    cnt = input('Continue with another file?   ');
end


% clearing up:
laststep = r;

ifc = 0;
remsub = 0;
for a = 1:length(ICAw)
if ~isempty(ICAw(a).ica_ifremove)
remsub = remsub + 1;
ifc = ifc + length(ICAw(a).ica_ifremove);
end
end

fprintf('Remaining subjects: %d \n', remsub)
fprintf('Remaining components: %d \n', ifc);

clearvars -except ICAw laststep

