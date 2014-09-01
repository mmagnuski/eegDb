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
s = 30;
c = [0 0.45 0.95];
type = 'fill';
lineColor = [0 0.75 0.75];
tooltip = false;
label = 'Variance';
sd = []; outm = 'zscore';
% plotout - sd outliers plotted with
% "rich red color"
plotout = [1 0 0];

% make sure data is columnwise:
sz = size(data);
if sz(1) == 1
    data = data(:);
end

%%
% MM - added nargin to run only when additional arguments are
%      provided
if nargin > 2
    args = {'s', 'c', 'type', 'lineColor', 'tooltip',...
        'label', 'sd', 'outm'};
    vars = args;
    
    for a = 1:length(args)
        reslt = find(strcmp(args{a}, varargin));
        if ~isempty(reslt)
            reslt = reslt(1);
            eval([vars{a}, ' = varargin{reslt+1};']);
            varargin([reslt, reslt+1]) = [];
            if isempty(varargin)
                break
            end
        end
    end
end

% MM - added to avoid try catch
if ~(~isempty(h) && ishandle(h))
    h = gca;
end   

c = repmat(c, length(data),1);
datind = 1:length(data);

% MM - added for outlier detection
if ~isempty(sd) && isnumeric(sd)
    
    switch outm
        case 'none'
            % nothing!
        case 'zscore'
            
            % simple z-score selection
            std_val = zscore(data);
            outlim = (std_val < -sd | std_val > sd);
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
            outlim = (dragmean_z(:) < -sd | ...
                dragmean_z(:) > sd);
    end

    if sum(outlim) > 0
    c(outlim, :) = repmat(plotout, [sum(outlim), 1]);
    end
end

%%

% MM - tooltip will be useful later to check data trials
%      but I couldn't find an obvious solution, will add
%      it later
if ~tooltip
    scatter(h, datind, data, s, c, type);
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
ylabel(h, label);


% lines
tick = repmat(round(length(data)/4)*[1,2,3,4],2,1);
lims = repmat(get(h, 'Ylim'), size(tick,2),1)';
line(tick, lims ,'LineStyle','--', 'Color', lineColor, 'Parent', h);
