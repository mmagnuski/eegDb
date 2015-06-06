function eegDb = db_buildbase(PTH, varargin)

% db_buildbase allows to create an eegDb structure
% from files in a given folder
%
% eegDb = db_buildbase(filepath)
%
% FIXHELPINFO
% CHANGE - PRIORITY

% TODOS:
% [X] change from loop to one call to
%     struct()
% [ ] redefine ICA part...
%     for example: one filed ICA
%     with:
%        - weights etc.
%        - removals, ifremovals
%        - classifications, notes etc.


% optional/undecided fields:
% ---------
% eegDb(f).subjectcode = [];
% eegDb(f).cleanline = [];


%% options for now:
verbose = true;
cnt.per = 1;
cnt.maxl = 20;
cnt.dsp = '.';

%% addit params:
if nargin > 1
    % file names given:
    fls = varargin{1};
else
    % get file names:
    fls = getfiles(PTH, '*.set');
end

%% ~~~ welcome to the code ~~~
cnt.curr = 0;



% default colors for rejections
g.labels = {'userreject', 'usermaybe', ...
    'userdontknow'};
g.labcol = [252 177 158; ...
    254 239 156; 196 213 253]./255;


% BUILDING STRUCTURE ELEMENTS
% ---------------------------

% inner strucutre of marks
mrk = struct(...
    'name',  {'reject', 'maybe'},...
    'color', {g.labcol(1,:), g.labcol(2,:)},...
    'value', [], ...
    'desc',  [], ... % description of the mark (may be as well in more.desc)
    'auto',  [], ... % used for automatic marking
    'more',  []  ... % used for special marks for example badchan
);


% inner structure of ICA
ica.icaweights = [];
ica.icasphere = [];
ica.icawinv = [];
ica.icachansind = [];
ica.desc = [];
ica.remove = [];
ica.ifremove = [];

% your inner epoch
epo.locked = [];
epo.events = [];
epo.limits = [];
epo.winlen = [];
epo.distance = [];
epo.distance = [];

% inner reject
rej.pre = [];
rej.post = [];
rej.all = [];

% chan
ch.labels = [];
ch.reref = [];
ch.bad = [];


% CREATE STRUCTURE
% ----------------

% create obligatory fields:
eegDb = struct('filename', fls, 'filepath', PTH, ...
    'datainfo', [], 'filter', [], 'chan', ch, ...
    'epoch', epo, 'marks', mrk, 'reject', rej, ...
    'ICA', ica, 'notes', []);
clear ica mrk aMark epo rej ch


% add info from files
% -------------------
for f = 1:length(fls)

    % load set file
    % -------------
    loaded = load([PTH, fls{f}], '-mat');
    EEG = loaded.EEG;
    clear loaded
    
    
    % datainfo
    % --------
    eegDb(f).datainfo.ref = [];
    eegDb(f).datainfo.ref_name = unique({EEG.chanlocs.ref});
    eegDb(f).datainfo.srate = EEG.srate;
    eegDb(f).datainfo.filtered = [];
    eegDb(f).datainfo.cleanline = [];
    eegDb(f).datainfo.chanlocs = EEG.chanlocs;
    
    
    % notify about progress
    if verbose
        cnt.per = 1;
        cnt.maxl = 20;
        cnt.dsp = '.';
        
        cnt.curr = cnt.curr + 1;
        if floor(cnt.curr/cnt.per) > cnt.maxl
            fprintf('\n');
            cnt.curr = 1;
        end
        
        if mod(cnt.curr, cnt.per) == 0
            fprintf(cnt.dsp);
        end
    end
    
end

if verbose
    fprintf('\n');
end