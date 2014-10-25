function s = cacheax(h)

% HELPINFO

% coded by M Magnuski
% May, 2014
% e-mail: mmagnuski@swps.edu.pl

% TODOs:
% [ ] change variable name 'topo'
% [ ] change the way children are checked to
%     be recursive (checkchildren function)
%     or while-do
% [ ] clean up

% general structure:
s.Type = 'axes';
s.Tag = get(h, 'tag');
s.Info = get(h);
s.Children = [];

%
axchildrenh = get(h, 'Children');
axchldtps = get(axchildrenh, 'type');

% ADD: getting by type groupwise
%      and then deal (should be faster)

% topo is the cached topoplot
topo = cell(length(axchldtps), 3);
for ch = 1:length(axchldtps)
    topo{ch,1} = axchldtps{ch};
    topo{ch,2} = 0;
    topo{ch,3} = get(axchildrenh(ch));
end
clear axchldtps axchildrenh

% check who has children:
chldrn = ~cellfun(@isempty, ...
    cellfun(@(x) x.Children, topo(:,3),...
    'UniformOutput', false));
haschildren = find(chldrn);

% get number of children:
ch = cellfun(@(x) length(x.Children),...
    topo(haschildren,3));
numch = sum(ch);

% proceed getting children in order:
st = size(topo,1)+1;
newpos = st:st+numch-1;

st = 1;
for c = 1:length(haschildren)
    for cc = 1:ch(c)
        childh = topo{haschildren(c),3}...
            .Children(cc);
        topo{newpos(st),3} = get(childh);
        topo{newpos(st),1} = topo{newpos(st),3}.Type;
        topo{newpos(st),2} = haschildren(c);
        
        st = st + 1;
    end
end

%% this is repeated code
% check that there are no more children:
chldrn = ~cellfun(@isempty, ...
    cellfun(@(x) x.Children, topo(newpos,3),...
    'UniformOutput', false));
haschildren = find(chldrn);

s.Children = topo;

