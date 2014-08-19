function tag_info = ICAw_tag_search(ICAw, r, tags)

% NOHELPINFO
%

tag_info = struct('tagtype',...
    tags, 'r', [], 'comp', []);

for ri = r
    for t = 1:length(tags)
        tag = tags{t};
        nts = {ICAw(ri).ICA_desc.notes};
        nonempt = find(~cellfun(@isempty, nts));
        reg = regexp(nts(nonempt), tag);
        reg = ~cellfun(@isempty, reg);
        tagged = nonempt(reg);
        
        if ~isempty(tagged)
            comps = length(tagged);
            tag_info(t).r = [tag_info(t).r, ...
                ones(1, comps) * ri];
            tag_info(t).comp = [tag_info(t).comp, ...
                tagged];
            
        end
    end
end