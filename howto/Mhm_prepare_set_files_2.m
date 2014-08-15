function Mhm_prepare_set_files(ICAw, varargin)

%% ustaw mastref i avgref:
% oba na false je¿eli bez rereferencji (tylko lokalizacje elektr)
% tylko avref je¿eli referencja do œredniej
% mastref je¿eli referencja do mastoidów

% clear chan names

%% defaults
IN = 'D:\Dropbox\DANE\CAT N170\EEG\';
chanIN = 'D:\Dropbox\DANE\MGR\EEG\eloc\GSN-HydroCel-65 1.0.sfp';
OUT = 'D:\Dropbox\DANE\CAT N170\EEG\SET\';
TrPth = ['D:\Dropbox\MATLAB scripts & projects\',...
    'EEGlab scripts\DIN Translate\Translation ',...
    'matrices\CAT N170 task fin.mat'];
mastref = false;
avgref = false;

% load translation matrix:
ld = load(TrPth);
fld = fields(ld);
Trnsl = ld.(fld{1});

% get file list from input folder
flist = prep_list(IN, '*.raw'); 

%% ~~==welcome to the code==~~



for S = 1:length(flist)
    
    % reading in given file:
    EEG = pop_readegi([IN, flist{S}]);
    
    % translate
    EEG = DIN_Translate(Trnsl, EEG);
    
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
    
    % saving files
    pop_saveset( EEG, 'filepath', OUT, 'filename', ...
        fli);
end