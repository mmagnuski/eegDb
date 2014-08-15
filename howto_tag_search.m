% searchin for [ICA checked] tag:
nts = {ICAw.notes};
nonempt = find(~cellfun(@isempty, nts));
reg = regexp(nts(nonempt), '\[ICA checked\]');
reg = ~cellfun(@isempty, reg);
tagged = nonempt(reg);

% search within a registry for component tags
for r = 1:length(ICAw)
%tag = '\[[a-z ]+\]';
tag = 'bibl';
nts = {ICAw(r).ICA_desc.notes};
nonempt = find(~cellfun(@isempty, nts));
reg = regexp(nts(nonempt), tag);
reg = ~cellfun(@isempty, reg);
tagged{r} = nonempt(reg);

if ~isempty(tagged{r})
    for t = 1:length(tagged{r})
        wt = ICAw(r).icasphere * ...
            ICAw(r).icaweights;
        figure; topoplot(wt(tagged{r}(t),:),...
            ICAw(r).datainfo.chanlocs(ICAw(r).icachansind));
        title(sprintf('r = %d, tag = ''%s''', r, nts{tagged{r}(t)}));
    end
end
end


% r = 
% [blink] [ref] [heye] [mscl]



% r -- 29
% niepotrzebnie usuniête kompo :(
% (np 12)