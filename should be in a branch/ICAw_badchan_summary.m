function badelec = ICAw_badchan_summary(ICAw, chanloc)

% badelec = ICAw_badchan_summary(ICAw, chanloc)
% checks bad channels as stated in
% ICAw.badchan and plots the summary
% - topoplot of bad channels occurrance
%
% FIXHELPINFO

% get number of electrodes
elen = length(chanloc);

% allocate badelec
badelec = zeros(elen,1);

% scan ICAw entries looking for bad channels
% at the present moment does not correct
% for subjects split into multiple files

for r = 1:length(ICAw)
    badelec(ICAw(r).badchan) = badelec(ICAw(r).badchan) + 1;
end

% plot the topoplot:
figure;
topoplot(badelec, chanloc, 'gridscale', 64);