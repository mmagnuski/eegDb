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
%               'type'  - marker type (default: 'fill', usage: 'type', 'fill')
%               'lineColor' - default: [0 0.75 0.75]
%% defaults
s = 30;
c = [0 0.45 0.95];
type = 'fill';
lineColor = [0 0.75 0.75];
tooltip = false;
label = 'Variance';
sd = [];
% plotout - sd outliers plotted with
% "rich red color"
plotout = [1 0 0];

%%
% MM - added nargin to run only when additional arguments are
%      provided
if nargin > 2
    args = {'s', 'c', 'type', 'lineColor', 'tooltip',...
        'label', 'sd'};
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

% MM - added for outliers
if ~isempty(sd) && isnumeric(sd)
    std_val = zscore(data);
    outlim = (std_val < -sd | std_val > sd);

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
    error('The Universe explodes in 10 seconds...');
end

        

% set limits
set(h, 'XLim', [1, length(data)]);

% set labels
xlabel(h, 'Trial');
ylabel(h, label);

% lines
tick = repmat(round(length(data)/4)*[1,2,3,4],2,1);
lims=repmat(get(h, 'Ylim'), size(tick,2),1)';
line(tick, lims ,'LineStyle','--', 'Color', lineColor, 'Parent', h);
