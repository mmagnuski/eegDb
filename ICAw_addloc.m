function ICAw_addloc(ICAw, varargin)

%% ustaw mastref i avgref:
% oba na false je¿eli bez rereferencji (tylko lokalizacje elektr)
% tylko avref je¿eli referencja do œredniej
% mastref je¿eli referencja do mastoidów

% clear chan names

%% defaults
chanIN = 'C:\Users\Tomek\Desktop\DIAMENTY\GSN-HydroCel-65 1.0.sfp';
mastref = false;
avgref = false;


%% ~~==welcome to the code==~~



for S = 1:length(ICAw)
    % reading in given file:
    EEG = pop_loadset('filepath', ICAw(S).filepath, 'filename', ...
        ICAw(S).filename);
    
    % read in electrode locations:
    EEG = pop_chanedit(EEG, 'load',[],'load',...
        {chanIN 'filetype' 'sfp'}, 'changefield',{68 'datachan' 0});
    
    % Cz is moved to nodatchans, we look where it's located:
    Cz_ind = find(strcmp('Cz', {EEG.chaninfo.nodatchans.labels}));
    
    % how many channels:
    chanlen = length({EEG.urchanlocs.labels});
    
    % channels referenced to Cz:
    refchans = 1:chanlen;
    refchans = num2str(refchans);
    
    % inform EEGlab about current reference
    EEG = pop_chanedit(EEG, 'setref', {refchans, 'Cz'});
    
    if avgref || mastref
        % re-reference to average
        EEG = pop_reref(EEG, [], 'refloc', ...
            EEG.chaninfo.nodatchans(Cz_ind)); %#ok<FNDSB>
        
        if mastref
            % re-reference to mastoids
            EEG = pop_reref(EEG, [29, 47]); %#ok<UNRCH>
        end
    end
    
    % saving files (podaj sowjw sizkde dosptu)
    pop_saveset( EEG, 'filepath', ICAw(S).filepath, 'filename', ...
        ICAw(S).filename);
end