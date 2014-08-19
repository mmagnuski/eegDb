function ICAw = ICAw_onechan_comp(ICAw, r)

% ICAw = ICAw_onechan_comp(ICAw);
% 
% adds a field ica_onechan to ICAw
% structure that contains ICs that
% are most probably explaining only
% single-electrode activity (ie.
% accounting for single-electrode
% variance unexplained by any other
% component)
%

% BRANCH
% CHANGE - this does not work that well, should be changed

opt.sd = 4;
opt.multip_more = 3;

if ~exist('r', 'var')
    rs = 1:length(ICAw);
else
    rs = r;
end

% loop through records
for r = rs
    
    % take out weights:
    icaw =  ICAw(r).icasphere * ICAw(r).icaweights; % sphere*weights
    % icaw = ICAw(r).icaweights;
    
    
    % above 4 SD & one such elec --> probably one elec comp
    zsc = zscore(icaw, 1, 2);
    outl = abs(zsc) >= opt.sd;
    onel = find(sum(outl, 2) == 1);
    which_outl = outl(onel,:);
    
    % out of proposed onels take only those where
    % the strongest weight is at least 3.5 times stronger
    % than the rest:
    ic_w = icaw(onel, :)';
    val = ic_w(which_outl');
    restval = ic_w;
    restval(which_outl') = [];
    restval = reshape(restval, [size(ic_w,1)-1, size(ic_w, 2)])';
    divval = repmat(val, [1, size(restval, 2)]);
    div = divval ./ restval;
    div = abs(div) >= opt.multip_more;
    div = sum(div, 2) == size(restval, 2);
    
    ICAw(r).ic_onechan = onel(div);
    
end