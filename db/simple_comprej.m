% this script was created from 
% howto_help_with_cluster_cleaning
% it plots first N components in standard eeglab GUI
% and then reads in those marked for rejection into
% ICAw database.

% assumes the variable ICAw is present in the workspace
% CHANGE - check for this or change this into a function

% bad chanlocs: 2, 4
% bad compos:   5

% define r:
rs = 11:20;

for r = rs
    
    
    % =============
    % load dataset:
    EEG = recoverEEG(ICAw, r, 'ICAnorem', 'local');
    
    
    % ==================
    % select components:
    pop_selectcomps(EEG, 1:35);
    hfig = gcf;
    pop_eegplot( EEG, 0, 1, 1);
    sigfig = gcf;
    pos = get(sigfig, 'Position');
    set(sigfig, 'Position', [750, 350, pos(3), pos(4)]);
    figure(hfig);
    uiwait(gcf);
    
    % close sigfig
    try %#ok<TRYNC>
        close(sigfig);
    end
    
    
    % ==============
    % get rejections
    comptorej = EEG.reject.gcompreject;
    ICAw(r).ICA.remove = comptorej;
end