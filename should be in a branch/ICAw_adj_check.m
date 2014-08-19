% NON-UNIVERSAL
% CHANGE
% BRANCH

% adjust checker
% shows components marked as artifacts
% by adjust. Only components belonging
% to the first N components are shown

% !! recoverEEG, should understand other epoching
%    than 'dummy' (another field - onesecepoch?)

% settings:
N = 15;

% go through database
for d = laststep:length(newICAw)
    % recover EEG
    EEG = recoverEEG(newICAw, d, 'nofilter');
    
    % open all first 35 comps:
    EEG = eeg_checkset( EEG );
    pop_selectcomps(EEG, 1:35);
    h.allcomp = gcf;
    
    % show separately adjust-chosen components:
    adj = newICAw(d).adjust;
    comps = adj.art(adj.art<=N);
    if ~isempty(comps)
    pop_selectcomps(EEG, comps);
    h.selcomp = gcf;
    end
    
    % display
    if ~isempty(adj.blink)
        disp('Blink comps:');
        disp(adj.blink);
    end
    if ~isempty(adj.horiz)
        disp('Horizontal eye mov comps:');
        disp(adj.horiz);
    end
    if ~isempty(adj.vert)
        disp('Vertical eye mov comps:');
        disp(adj.vert);
    end
    if ~isempty(adj.disc)
        disp('Discontinuous comps:');
        disp(adj.disc);
    end
    
    % edit box:
    [delcom, maydelcom] = ICAw_adj_conf_GUI(comps);
    
    % fill info
    newICAw(d).ica_remove = delcom; %#ok<SAGROW>
    newICAw(d).ica_ifremove = maydelcom; %#ok<SAGROW>
    
    % close all:
    close all
    
    % delete set:
    ALLEEG = pop_delset( ALLEEG, 1 );
end

save('\\Swps-01143\e\Dropbox\DANE\MGR\EEG\ICAw_set.mat', 'newICAw');