function ICAw = db_runica(ICAw, rs)

% NOHLEPINFO

if ~exist('rs', 'var')
	rs = 1:length(ICAw);
end

for r = rs
    if isempty(ICAw(r).ICA.icaweights)
        
        % recover
        EEG = recoverEEG(ICAw, r, 'local');
        
        % select good channels:
        allchan = 1:size(EEG.data,1);
        allchan(ICAw(r).chan.bad) = [];
        
        % perform ICA
        EEG = pop_runica(EEG, 'extended', 1, 'interupt',...
            'off', 'verbose', 'on', 'chanind', allchan);
        
        % apply weights
        ICAw = db_addw(ICAw, r, EEG);
        
    end    
end