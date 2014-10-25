% caching topoplots:

function EEG = EEG_topo_cache(EEG, hnd)

% HELPINFO

% if no etc.topocache, create:
if ~femp(EEG.etc, 'topocache')
    EEG.etc.topocache = [];
end

if ~exist('hnd', 'var') || isempty(hnd)
    hnd = gcf;
end

% if hnd is 'figure' we scan for uncached topos:
if strcmp(get(hnd, 'Type'),  'figure')
    
    % get axis handles
    ax_hnd = findobj('Parent', hnd, 'Type', 'axes');
    % get tags
    tags = get(ax_hnd, 'tag');
    % remove axes that are not of topo type
    kill = cellfun(@isempty, strfind(tags, 'topo'));
    ax_hnd(kill) = []; tags(kill) = [];
    
else
    % not supported at the moment
    error('Only figure handles allowed at the moment.');
end

% ------------------------
% which topos are uncached

% This (below) should be done if compnum is empty etc.
%if ~exist('compnum', 'var') || isempty(compnum)
    compnum = cellfun(@(x) str2num(regexp(x, '[0-9]+', ...
        'match', 'once')), tags); %#ok<ST2NM>
%end

if isempty(EEG.etc.topocache)
    tocache = compnum;
    h2chache = ax_hnd;
else
    cachedNums = [EEG.etc.topocache.CompNum];
    tocache = setdiff(compnum, cachedNums);
    
    if isempty(tocache)
        return
    else
        
        h2chache = zeros(size(tocache));
        
        for c = 1:length(h2chache)
            h2chache(c) = ax_hnd(compnum == tocache(c));
        end  
    end
end

if ~isempty(h2chache)
    % cache comps
    fig = cachefig(h2chache, 'axes');

    % CHANGE: (we have compnums already)
    % get comp numbers
    for f = 1:length(fig)
        fig(f).CompNum = str2num(regexp(fig(f).Tag, '[0-9]+', 'match', 'once'));
    end

    if isempty(EEG.etc.topocache)
        EEG.etc.topocache = fig;
    else
        EEG.etc.topocache = [EEG.etc.topocache, fig];
    end
    
    % sort according to CompNum
    [~,srt] = sort([EEG.etc.topocache.CompNum]);
    EEG.etc.topocache = EEG.etc.topocache(srt);
end