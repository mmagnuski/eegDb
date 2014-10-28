% caching topoplots:

function EEG = EEG_topo_cache(EEG, hnd)

% HELPINFO

% TODOs
% [ ] - separate topo caching and EEG / eegDb part of the story
% [ ] - get input about which comps are already cached
% [ ] - return struct of cached comps (or empty when no new caches)

% if no etc.topocache, create:
if ~femp(EEG.etc, 'topo')
    EEG.etc.topo = [];
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

if isempty(EEG.etc.topo)
    tocache = compnum;
    h2chache = ax_hnd;
else
    cachedNums = [EEG.etc.topo.CompNum];
    tocacheMask = arrayfun(@(x) ~any(cachedNums==x), compnum);
    tocache = compnum(tocacheMask);
    
    if isempty(tocache)
        return
    else
        
        h2chache = ax_hnd(tocacheMask);
        clear tocacheMask
    end
end

if ~isempty(h2chache)
    % cache comps
    fig = cachefig(h2chache, 'axes');

    tocache = num2cell(tocache);
    [fig.CompNum] = deal(tocache{:});

    if isempty(EEG.etc.topo)
        EEG.etc.topo = fig;
    else
        EEG.etc.topo = [EEG.etc.topo, fig];
    end
    
    % sort according to CompNum
    [~,srt] = sort([EEG.etc.topo.CompNum]);
    EEG.etc.topo = EEG.etc.topo(srt);
end