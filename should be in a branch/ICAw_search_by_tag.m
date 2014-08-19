function tags = ICAw_search_by_tag(ICAw, r, varargin)

% tags = ICAw_search_by_tag(ICAw, r);
% 
% searches given ICAw record for component
% tags (that is text of format '[tag_text]'
% present in component notes.

% CHECK ICAw_search_by_tag vs ICAw_tag_search

% check if ICA_desc has any info:
if ~femp(ICAw(r), 'ICA_desc')
    error(['ICA_desc field (the field that contains',...
        ' IC descritpions) is absent or empty :(']);
end

% default tag regular expression:
tag_reg = '\[[^\]]+\]';

% look through notes:

notes = {ICAw(r).ICA_desc.notes};
ICind = ~cellfun(@isempty, notes);
notes = notes(ICind);
reg = regexp(notes, tag_reg, 'match');
clear notes tag_reg

% organize into tag bundles:
alltg = [reg{:}];
tagtp = unique(alltg);
clear alltg

% go through tag types and see which ICs 
% are tagged with these:
ICind = find(ICind);
IC_tagged = cell(size(tagtp));
for t = 1:length(tagtp)
    
    % check each IC:
    for ic = 1:length(reg)
        
        if ~isempty(reg{ic}) && sum(strcmp(tagtp{t},...
                reg{ic})) > 0
            IC_tagged{t} = [IC_tagged{t}, ICind(ic)];
        end
    end
end
clear ic t reg ICind

% form output:
tags = [tagtp', IC_tagged'];

