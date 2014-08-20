
% here - reroot without adding cleanline
% subfolder (i.e. assume all files are
% in another directory, without divisions
% into subfolders present in the original
% filepaths)
cll = 'CleanLine\';
for r = 1:length(ICAw)
    pt = ICAw(r).filepath;
    ad_cl = ~(isempty(strfind(pt, cll)));
    if ad_cl
        disp('cll');
    end
    ICAw(r).filepath = [];
    ICAw(r).filepath{1} = pt;
    ICAw(r).filepath{2} = p;
end