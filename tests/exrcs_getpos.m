%% MATLAB EXERCISES:


%% how to get cursor position:
figure
axes
grid
% (1, 1:2) should be the clicked 2D position
x=get(gca,'CurrentPoint')

% ========
% Interesting Matlab Central response:
Walter Roberson wrote:
>
> Unfortunately so far I haven't found a way for a the program to
> turn on data cursor, only for the user to turn it on.

Here's how to turn it on programatically:

cursorObj = datacursormode(hFig);
set(cursorObj, 'enable','on', 'UpdateFcn',@DataTipsTxt);

See <http://www.mathworks.com/access/helpdesk/help/techdoc/index.html?/access/helpdesk/help/techdoc/creating_plots/f4-44221.html&http>://www.mathworks.com/cgi-bin/texis/webinator/search/#f4-50382
 for how to modify the displayed data-tip (you can use the default by
not changing 'UpdateFcn' above).

% =======================
% ImageAnalyst example:
% Plot data - a line from (1,1) to (10,10).
h=plot(1:10, 'bs-')
grid on;
axis equal;
xlim([0 11]);
ylim([0 11]);
datacursormode on;
% Enlarge figure to full screen.
set(0, 'Units', 'pixels');
screenSize = get(0,'ScreenSize')
set(gcf, 'units','pixels','outerposition', screenSize);
% Ask user to click on a point.
uiwait(msgbox('Click near any data point'));
% Print the x,y coordinates - will be in plot coordinates
[x,y] = ginput(1) % Will be close to 5,5 but not exactly.
% Mark where they clicked with a cross.
hold on;
plot(x,y, 'r+', 'MarkerSize', 20, 'LineWidth', 3);
% Print the coordinate, but this time in figure space.
% Coordinates will be way different, like 267, 196 instead of 5,5.
cpFigure = get(gcf, 'CurrentPoint')
cpAxis = get(gca, 'CurrentPoint')
% Print coordinates on the plot.
label = sprintf('(%.1f, %.1f) = (%.1f, %.1f) in figure space', x, y, cpFigure(1), cpFigure(2));
text(x+.2, y, label);
% Tell use what ginput, cpFigure, and cpAxis are.
message = sprintf('ginput = (%.3f, %.3f)\nCP Axis = [%.3f, %.3f\n              %.3f, %.3f]\nCP Figure = (%.3f, %.3f)\n',...
	x, y, cpAxis(1,1), cpAxis(1,2), cpAxis(2,1), cpAxis(2,2), cpFigure(1), cpFigure(2));
uiwait(msgbox(message));
% Retrieve the x and y data from the plot
xdata = get(h, 'xdata')
ydata = get(h, 'ydata')
% Scan the actual ploted points, figuring out which one comes closest to 5,5
distances = sqrt((x-xdata).^2+(y-ydata).^2)
[minValue minIndex] = min(distances)
% Print the distances next to each data point
for k = 1 : length(xdata)
	label = sprintf('D = %.2f', distances(k));
	text(xdata(k)+.2, ydata(k), label, 'FontSize', 14);
end
% Draw a line from her point to the closest point.
plot([x xdata(minIndex)], [y, ydata(minIndex)], 'r-');
% Tell her what data point she clicked closest to
message = sprintf('You clicked closest to point (%d, %d)',...
	xdata(minIndex), ydata(minIndex));
helpdlg(message);


% =====
% Matlab Central example:
% (by shay)
function problem_test
f2 = figure(2); axes;
f1 = figure(1);
t = timer('TimerFcn',{@testfcn,f1}, 'Period',
0.1,'ExecutionMode','fixedDelay');
set(f1,'WindowButtonDownFcn',{@start_testfcn,t});
set(f1,'WindowButtonUpFcn',{@stop_testfcn,t});
setappdata(f1,'OtherFigure',f2);
setappdata(f1,'Record',[]);
 
function start_testfcn(fh,e,a)
start(a);

function stop_testfcn(fh,e,a)
stop(a);
 
function testfcn(x,xx,fh)

f2 = getappdata(fh,'OtherFigure');
xy = get(0,'PointerLocation');
record = getappdata(fh,'Record');
record = [record; xy];
setappdata(fh,'Record',record);
figure(f2);
plot(record(:,1),'b');
hold on;
plot(record(:,2),'r');
hold off;
figure(fh);


% ======
% another Matlab Central example:
% (by Jerome)

Hi,

I would do it that way :

function problem_test
f2 = figure(2)
set(f2,'doublebuffer','on');
axes;

p=plot(nan,nan,'b',nan,nan,'r');

f1 = figure(1);
set(f1,'WindowButtonDownFcn',@start_testfcn);
set(f1,'WindowButtonUpFcn',@stop_testfcn);
setappdata(f1,'Plots',p);
setappdata(f1,'Record',[]);
 
function start_testfcn(fh,e)
set(fh,'WindowButtonMotionFcn',@testfcn);
 
function stop_testfcn(fh,e)
set(fh,'WindowButtonMotionFcn',[]);
 
function testfcn(fh,e)

xy = get(0,'PointerLocation');
record = getappdata(fh,'Record');
record = [record; xy];
setappdata(fh,'Record',record);

p = getappdata(fh,'Plots');

set(p(1),'xdata',1:size(record,1), ...
    'ydata',record(:,1))
set(p(2),'xdata',1:size(record,1), ...
    'ydata',record(:,2))



% figure;
% 
% annotation('textbox',[left+left/8 top+0.65*top 0.05525 0.065],...
% 'String',{'EMBARRASSMENT'},...
% 'FontSize',24,...
% 'FontName','Humor',...
% 'FitBoxToText','off',...
% 'LineStyle','none');


%% XKCD plot
%# define plot data
x = 1:0.1:10;
y1 = sin(x).*exp(-x/3) + 3;
y2 = 3*exp(-(x-7).^2/2) + 1;

%# plot
fh = figure('color','w');
hold on
plot(x,y1,'b','lineWidth',3);
plot(x,y2,'w','lineWidth',7);
plot(x,y2,'r','lineWidth',3);

xlim([0.95 10])
ylim([0 5])
set(gca,'fontName','Comic Sans MS','fontSize',18,'lineWidth',3,'box','off')

%# add an annotation 
 annotation(fh,'textarrow',[0.4 0.55],[0.8 0.65],...
     'string',sprintf('text%shere',char(10)),'headStyle','none','lineWidth',1.5,...
     'fontName','Comic Sans MS','fontSize',14,'verticalAlignment','middle','horizontalAlignment','left')

%# capture with export_fig
im = export_fig('-nocrop',fh);

%# add a bit of border to avoid black edges
im = padarray(im,[15 15 0],255);

%# make distortion grid
sfc = size(im);
[yy,xx]=ndgrid(1:7:sfc(1),1:7:sfc(2));
pts = [xx(:),yy(:)];
tf = cp2tform(pts+randn(size(pts)),pts,'lwm',12);
w = warning;
warning off images:inv_lwm:cannotEvaluateTransfAtSomeOutputLocations
imt = imtransform(im,tf);
warning(w)

%# remove padding
imt = imt(16:end-15,16:end-15,:);

figure('color','w')
imshow(imt)