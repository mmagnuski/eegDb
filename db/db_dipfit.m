function db = db_dipfit(db, varargin)

% NOHELPINFO

% =================
% info for hackers:
% 

% TODOs:
% [ ] universalize even more (model and transform
%     settings etc.

%% options
% above this residiual variance
% dipoles are rejected
rv_thrsh = 100;

% path to save temporary db's to
% (the last one being final)
save_path = [];
%save_path = 'D:\Dropbox\CURRENT PROJECTS\Beta 2013-2014\Baseline\';

% whether to remove dipoles that are located
% outside the skull/brain
out = 'off';
rs = 1:length(db);
norpl = false;

%% test varargin
if ~isempty(varargin)
    key = {'savepath', 'rv', 'rmout', 'norpl', 'r', 'remel'};
    var = {'save_path', 'rv_thrsh', 'out', 'norpl', 'rs', 'remel'};
    v = 1;
    while v <= length(varargin)
        cmp = find(strcmp(varargin{v}, key));
        
        if ~isempty(cmp)
            cmp = cmp(1);
            eval([var{cmp}, ' = varargin{v + 1};']);
            v = v + 1;
        end
        
        v = v + 1;
    end
end

if ~exist('remel', 'var')
    remel = [];
end

%% ==welcome to the code==

% prepath:
% prepath = '\\Swps-01222w\c';
% addpath(['D:\Dropbox\Dropbox\MATLAB scripts & ',...
%     'projects\EEGlab common (1)']);
eegpth = fileparts(which('eeglab'));

% check dipfit version
bgpth = [eegpth, '\plugins\'];
lst   = dir(bgpth);
lst   = lst([lst.isdir]);
where = regexpWhere({lst.name}, 'dipfit');
dipver = lst(where).name(7:end);

% add path
addpath([eegpth, '\plugins\dipfit', dipver, '\']);

% transform vector
transf = [0.092784, -13.3654, -1.9004, 0.10575, 0.003062,...
    -1.5708, 10.0078, 10.0077, 10.1331];
hdmf = [eegpth, '\plugins\dipfit', dipver, '\',...
    'standard_BEM\standard_vol.mat'];
mrif = [eegpth, '\plugins\dipfit', dipver, '\',...
    'standard_BEM\standard_mri.mat'];
chanf = [eegpth, '\plugins\dipfit', dipver, '\',...
    'standard_BEM\elec\standard_1005.elc'];

if ~isempty(save_path) && ~isdir(save_path)
    mkdir(save_path);
end


for r = rs
    %% preliminary checks
    % check if ICA weights present
    ICApres = ~isempty(db(r).ICA.icaweights);
    
    % if no ICA weights then check next file
    if ~ICApres
        continue
    end
    clear ICApres
    
    % if dipfit info already present:
    if norpl && femp(db(r), 'dipfit')
        continue
    end
    
    % add prepath if not present
    %     if ~strcmp(prepath, db(r).filepath(1:length(prepath)))
    %         sepind = strfind(db(r).filepath, '\');
    %         db(r).filepath = [prepath, db(r).filepath(sepind(1):end)];
    %     end
    
    %% recover and check
    % recover EEG
    EEG = recoverEEG(db, r, 'ICAnorem', 'local');
    
    % check channels
    allchn = 1:length(EEG.chanlocs);
    
    % remove E62 and E63
    remind = zeros(1, length(remel));
    elstep = 0;
    for el = 1:length(remel)
        elind = strcmp(remel{el}, {EEG.chanlocs.labels});
        
        if sum(elind) == 1
            elstep = elstep + 1;
            remind(elstep) = find(elind);
        end
    end
    
    % trim if some were not found:
    remind = remind(1:elstep);
    clear elstep el elind
    
    % remove these channels and badchannels:
    allchn(union(db(r).chan.bad, remind)) = [];
    goodchan = allchn;
    clear allchn remind
    
    %% DIPfit
    % dipfit options
    EEG = pop_dipfit_settings( EEG, 'hdmfile', hdmf, 'coordformat', 'MNI',...
        'mrifile', mrif, 'chanfile', chanf, 'coord_transform', transf,...
        'chansel', goodchan);
    clear goodchan
    
    % locate components:
    EEG = pop_multifit(EEG, 1 : size(EEG.icaweights, 1),...
        'threshold', rv_thrsh, 'rmout', out, 'plotopt', ...
        {'normlen' 'on'});
    
    % we are interested only in EEG.dipfit
    db(r).dipfit = EEG.dipfit;
    clear EEG
    
    % save temporary file:
    if ~isempty(save_path)
        save([save_path, 'db_dipfit.mat'], 'db');
    end
end