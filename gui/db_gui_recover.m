function h = db_gui_recover(h)

% CHANGE - this is a mess
%        - recovopts should be reworked
%        - comparing EEG and current r/version should be
%          smarter  

% first - recover data if not present
if isempty(h.EEG) || h.r ~= h.rEEG || ...
        ~db_recov_compare(h.EEG.etc.recov, h.db(h.r)) ...
        || ~isequal(h.recovopts, h.last_recovered_opts)
    
    % save recovery options:
    h.last_recovered_opts = h.recovopts;
    
    % TXT display
    set(h.addit_text, 'String', 'Recovering EEG...');
    drawnow;
    
    % RECOVER EEG data
    [h.EEG, h.db] = recoverEEG(h.db, h.r, ...
        'local', 'tempsave', h.recovopts{:});
    h.rEEG = h.r;
    rEEG = h.rEEG;
    
    % update prerej field
    f = db_checkfields(h.EEG, 1,...
        {'onesecepoch'}, 'subfields', true);
    if f.fsubf(1)
        isprerej = find(strcmp('pre', f.subfields{1}));
    end
    
    % CHECK - in case of prerej, postrej division
    %          the following step is important because
    %          it allows for some prerej-postrej-removed
    %          calculations. However, it should not restric
    %          usage of databases that do not use onesecepoch
    %          Checking recov should be done only
    %          for databases using onesecepoch
    %
    % set this file as elligible to some
    % operations (apply rejections, multisel, etc.)
    if f.fsubf(1) && ~isempty(isprerej) ...
            && f.subfnonempt{1}(isprerej)
        h.db(h.r).reject.pre = h...
            .EEG.onesecepoch.prerej;
        % ADD a hack to update h.EEG.etc.recov
        % h.EEG.etc.recov = h.db(h.r);
        h.recov(h.r) = true;
    end
    clear f isprerej
    
    % Update handles structure
    guidata(h.figure1, h);
    
    % file recovered
    set(h.addit_text, 'String', 'EEG recovered');
    
    % refresh gui (CHECK - do we need to?)
    db_gui_refresh(h);
end