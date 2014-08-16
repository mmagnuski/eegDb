%     corrects bad channels' indices for files with missing electrodes
%     for example when reference chans (mastoids etc.) were previously
%     deleted
% 
%     (MZ)
%
%
%     Potentially problematic if used more than once on such a file
%     I don't think we should support undocumented missing channels.
%     CHANGE - add field informing about missing channels to datainfo field
%     (MM)

function corrected=badchan_ind(newICAw,r, chanlocs)

chansy={chanlocs.labels};
chansy=regexp(chansy, '[0-9]+', 'match', 'once');
for t=1:length(chansy)
    if ~isempty(str2num(chansy{t}))
        temp(t)=str2num(chansy{t});
    else
        temp(t)=0;
    end
end
bads=newICAw(r).badchan;
if ~isempty(bads)
    for ch=1:length(bads)
        corrected(ch)=find(temp==bads(ch));
    end
else
    corrected=[];
end

