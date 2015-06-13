function varscatter(h, data, varargin)

%   inputs:
%               h       - axis handle
%               data    - component variance
%   optional:
%               's'     - marker size (default: 30, usage: 's', 30)
%               'c'     - marker color(s) (dafault: 0 0.45 0.95 - blueish , 
%                         usage:, 'c', [R G B])
%               'sd'    - mark by sd as red (dafault: do not mark , 
%                         usage:, 'sd', 2.5)
%               'outm'  - method to mark data points as outlayers
%                         ('zscore', 'jackknife')
%               'type'  - marker type (default: 'fill', usage: 'type', 'fill')
%               'lineColor' - default: [0 0.75 0.75]
%% defaults
opt.s = 30;
opt.c = [0 0.45 0.95];
opt.type = 'fill';
opt.lineColor = [0 0.75 0.75];
opt.tooltip = false;
opt.label = 'Variance';
opt.sd = []; opt.outm = 'zscore';
% plotout - sd outliers plotted with
% "rich red color"
plotout = [1 0 0];

% make sure data is columnwise:
sz = size(data);
if sz(1) == 1
    data = data(:);
end

opt = parse_arse(varargin, opt);

% MM - added to avoid try catch
if ~(~isempty(h) && ishandle(h))
    h = gca;
end   

opt.c = repmat(opt.c, length(data),1);
datind = 1:length(data);

% MM - added for outlier detection
if ~isempty(opt.sd) && isnumeric(opt.sd)
    
    switch outm
        case 'none'
            % nothing!
        case 'zscore'
            
            % simple z-score selection
            std_val = zscore(data);
            outlim = (std_val < -opt.sd | std_val > opt.sd);
        case 'jackknife'
            
            % construct a leave-one-out matrix:
            datjk = repmat(data, [1, sz(1)]);
            datjk(logical(eye(size(datjk)))) = [];
            datjk = reshape(datjk, [sz(1) - 1, sz(1)]);
            
            % CHANGE - the steps below are not too smart
            % look at the difference of means
            dragmean = mean(data) - mean(datjk);
            % we do not want those that drag the
            % mean too much
            dragmean_z = zscore(dragmean);
            outlim = (dragmean_z(:) < -opt.sd | ...
                dragmean_z(:) > opt.sd);
    end

    if sum(outlim) > 0
    c(outlim, :) = repmat(opt.plotout, [sum(outlim), 1]);
    end
end

%%

% MM - tooltip will be useful later to check data trials
%      but I couldn't find an obvious solution, will add
%      it later
if ~opt.tooltip
    scatter(h, datind, data, opt.s, opt.c, opt.type);
else
    error('The Universe will explode in 10 seconds...');
end

        
% set limits
set(h, 'XLim', [1, length(data)]);

% temporary fix of:
% Warning: RGB color data not yet supported in Painter's mode 
% CHNAGE - better check if 'Painters' are set and turn off
warning('off');

% set labels
xlabel(h, 'Trial');
ylabel(h, opt.label);


% lines
tick = repmat(round(length(data)/4)*[1,2,3,4],2,1);
lims = repmat(get(h, 'Ylim'), size(tick,2),1)';
line(tick, lims ,'LineStyle','--', 'Color', opt.lineColor, 'Parent', h);
