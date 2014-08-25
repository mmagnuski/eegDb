function ICAw = ICAw_buildbase(PTH, varargin)

% ICAw_buildbase allows to create an ICAw structure
% from files in a given folder
%
% ICAw = ICAw_buildbase(filepath)
%
% FIXHELPINFO
% CHANGE - PRIORITY

% TODOS:
% [ ] change from loop to one call to
%     struct()
% [ ] redefine ICA part...
%     for example: one filed ICA
%     with:
%        - weights etc.
%        - removals, ifremovals
%        - classifications, notes etc.

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
    fls = prep_list(PTH, '*.set');
end

%% ~~~ welcome to the code ~~~
cnt.curr = 0;



% default colors for rejections
g.labels = {'userreject', 'usermaybe', ...
    'userdontknow'};
g.labcol = [252 177 158; ...
    254 239 156; 196 213 253]./255;

% preallocate base:
% maybe next time :)


for f = 1:length(fls)
    %% load set file
    loaded = load([PTH, fls{f}], '-mat');
    EEG = loaded.EEG;
    clear loaded
    
    %% construct fields
    % basic
    ICAw(f).subjectcode = []; %#ok<*AGROW>
    ICAw(f).filename = fls{f};
    ICAw(f).filepath = PTH;
    ICAw(f).tasktype = [];
    ICAw(f).session = [];
    
    % datainfo
    ICAw(f).datainfo.ref = [];
    ICAw(f).datainfo.ref_name = unique({EEG.chanlocs.ref});
    ICAw(f).datainfo.srate = EEG.srate;
    ICAw(f).datainfo.filtered = [];
    ICAw(f).datainfo.cleanline = [];
    ICAw(f).datainfo.chanlocs = EEG.chanlocs;
    
    % filter/cleanline fields
    ICAw(f).badchan = [];
    ICAw(f).filter = [];
    ICAw(f).usecleanline = [];
    
    % prefun
    ICAw(f).prefun = [];
    
    % epoching options
    ICAw(f).onesecepoch = [];
    ICAw(f).epoch_events = [];
    ICAw(f).epoch_limits = [];
    ICAw(f).segment = [];
    
    % removal options
    ICAw(f).prerej = [];
    ICAw(f).autorem = [];
    ICAw(f).userrem = [];
    ICAw(f).postrej = [];
    ICAw(f).removed = [];
    
    % colors for rejection types:
    for b = 1:length(g.labels)
        ICAw(f).userrem.(g.labels{b}) = [];
        ICAw(f).userrem.color.(g.labels{b}) = g.labcol(b,:);
    end
    
    % autorem colors:
    ICAw(f).autorem.color.prob = EEG.reject.rejjpcol;
    ICAw(f).autorem.color.mscl = EEG.reject.rejfreqcol;
    
    % ICA options
    ICAw(f).icaweights = [];
    ICAw(f).icasphere = [];
    ICAw(f).icawinv = [];
    ICAw(f).icachansind = [];
    
    % ICA classification options:
    ICAw(f).ica_remove = [];
    ICAw(f).ica_ifremove = [];
    ICAw(f).ICA_desc = [];
    
    % notes
    ICAw(f).notes = [];
    
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