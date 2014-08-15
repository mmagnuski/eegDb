function test_getpos(spect)

h.fig = figure;
h.ax = axes;
h.startpoint = [];
h.endpoint = [];
h.patch = [];
h.line = [];
h.fig2 = [];
h.freqsel = [];
h.spect = spect;

% h.cursorObj = datacursormode(h.fig);
% set(h.cursorObj, 'enable','on');

h.line = plot(h.ax, spect.freq, squeeze(mean(spect.powspctrm...
    (:, 1, :), 1)), 'LineWidth', 2.5);

set(h.ax, 'ButtonDownFcn',@start_testfcn);
h.XLim = get(h.ax, 'XLim');
h.YLim = get(h.ax, 'YLim');
% hold ?

% update gui data
guidata(h.fig, h);


 
function start_testfcn(fh,e) %#ok<INUSD>
% set(fh,'ButtonMotionFcn',@testfcn);
h = guidata(fh);
if isempty(h.startpoint)
    % if patchobj present - destroy
    if ~isempty(h.patch)
        delete(h.patch)
    end
    
    % get cursor position
    h.startpoint = get(h.ax, 'CurrentPoint');
    
    % plot line there
    Xpos = h.startpoint(1,1);
    hold on
    h.line = plot([Xpos, Xpos], h.YLim, 'LineWidth', 2, ...
        'Color', [0.68, 0.12, 0.22]);
    hold off
    
    % retaining axis limits (should be done in
    % a different way)
    set(h.ax, 'XLim', h.XLim);
    set(h.ax, 'YLim', h.YLim);
    
    guidata(fh, h);
else
    h.endpoint = get(h.ax, 'CurrentPoint');
    
    % delete line
    if ~isempty(h.line)
        delete(h.line);
        h.line = [];
    end
    
    % find the points
    lowX = min([h.endpoint(1,1), h.startpoint(1,1)]);
    % lowY = min([h.endpoint(1,2), h.startpoint(1,2)]);
    hiX = max([h.endpoint(1,1), h.startpoint(1,1)]);
    % hiY = max([h.endpoint(1,2), h.startpoint(1,2)]);
    h.freqsel = [lowX, hiX];
    
    % plot the patch
    h.patch = patch('Vertices', [lowX, h.YLim(1); hiX, h.YLim(1);...
        hiX, h.YLim(2); lowX, h.YLim(2)], 'Faces', 1:4, 'HitTest', ...
        'on', 'FaceAlpha', 0.2, 'ButtonDownFcn', @del_ptch, ...
        'EdgeColor', 'none');
    
    % set it below the line
    % children = get(h.ax, 'Children');
    
    % retaining axis limits (should be done in
    % a different way)
    set(h.ax, 'XLim', h.XLim);
    set(h.ax, 'YLim', h.YLim);
    
    
    % update the other window
    figscatt(h);
    
    h.startpoint = [];
    h.endpoint = [];
end
    
% disp(h.startpoint);
guidata(fh, h);

function figscatt(h)

if ~isempty(h.freqsel)
    % get freqs:
    for fr = 1:2
    [~, freqadr(fr)] = min((abs(h.spect.freq - h.freqsel(fr)))); %#ok<AGROW>
    % frq(fr) = h.spect.freq(freqadr);
    end
    
    % take average power in freq range across epochs
    scattpow = squeeze(mean(h.spect.powspctrm(:,1, ...
        freqadr(1):freqadr(2)), 3));
    
    if ishandle(h.fig2)
        scatter(h.ax2, [1:length(scattpow)]', scattpow(:)); %#ok<NBRAK>
    else
        h.fig2 = figure;
        h.ax2 = axis;
        scatter([1:length(scattpow)]', scattpow(:)); %#ok<NBRAK>
        guidata(h.fig, h);
    end
end
    
    


function del_ptch(hObj, e) %#ok<INUSD>

h = guidata(hObj);
if ~isempty(h.patch)
        delete(h.patch)
        h.patch = [];
end
guidata(h.fig, h);


%  
% function stop_testfcn(fh,e) %#ok<INUSD>
% set(fh,'WindowButtonMotionFcn',[]);
% h = guidata(fh);
% h.endpoint = get(h.ax, 'CurrentPoint');
% guidata(fh, h);
% 
% function testfcn(fh,e)
% h = guidata(fh);
% h.endpoint = get(h.ax, 'CurrentPoint');
% guidata(fh, h);