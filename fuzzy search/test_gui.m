% 

% ButtonDownFcn
% KeyPressFcn
% KeyReleaseFcn
% CurrentCharacter
% CurrentObject
% CurrentPoint
% HitTest
% WindowButtonMotionFcn
% WindowButtonUpFcn
% WindowKeyPressFcn
% WindowKeyReleaseFcn
% WindowScrollWheelFcn
% Interruptible (CHECK)
%
% set(figure_handle,'CurrentAxes',axes_handle)

% 
% WindowStyle (CHECK)
% WVisual (CHECK)
% WVisualMode
% XDisplay
% XVisual
% XVisualMode


% for SPEED:
% Renderer - check OpenGL

% Resize
% ResizeFcn
% Selected - whether the figure is selected
% SelectionType - mouse selection modifier
% Toolbar (CHECK)
% Pointer (CHECK)
%   PointerShapeCData
%   PointerShapeHotSpot
% CloseRequestFcn
% CurrentAxes
% NextPlot
% OuterPosition

% instead of text uicontrol
% - annotation?


% remember about controlling visibility in figures
% Visible

% test from mathworks docs:
% figure('NumberTitle','off','Menubar','none',...
%        'Name',...
% 				'Press keys to put event data in Command Window',...
%        'Position',[560 728 560 200],...
%        'KeyPressFcn',@(obj,evt)disp(evt));
   
% events have following structure:
%  Character: 'R'
%      Modifier: {'shift'}
%           Key: 'r'

teststring = {'', 'AkredytacjaWielkiejWierzby',...
    'to som chyba miesnie', 'bardzo brzydki sygnal',...
    'dziwne warczenie'};


figPos = [550, 90, 450, 450];
h = figure('Position', figPos, ...
    'DockControls', 'off', 'MenuBar', 'none',...
    'Name', 'Select mark', 'Toolbar', 'none',...
    'Visible', 'off');

figSpace = figPos([3,4]);

textLength = length(teststring);
horLim = [10, figSpace(2) - 10];
keyh = 60;
keyw = diff(horLim);
keyDist = 15;
keyStart = 60;

udat.color = 0.7 + rand(textLength,3)*0.3;
udat.hAxis = axes('Position', [0, 0, 1, 1],...
    'Visible', 'off');
set(udat.hAxis, 'Xlim', [0, figSpace(1)],'YLim', [0, figSpace(2)]);

% 
for i = 1:textLength
    butUp = figSpace(2) - keyStart - (i-1) * (keyh + keyDist);
    

    hButton(i) = patch('vertices', [horLim(1), butUp; horLim(1), butUp - keyh;...
        horLim(2), butUp - keyh; horLim(2), butUp], 'Visible', 'on',...
        'faceColor', udat.color(i, :), 'edgecolor', 'none',...
        'Faces', 1:4);

    hTxt(i) = text('String', teststring{i}, 'FontSize', 15,...
     'Position', [horLim(1), butUp - keyh] + [35, keyh/2], 'Visible', 'on');
end

set(hTxt(1), 'FontWeight', 'bold', 'FontSize', 18);
udat.text = cellfun(@lower, teststring(2:end), 'Uni', false);
udat.textActive = true(1, length(udat.text));
udat.hButton = hButton;
udat.typed = '';
udat.hText = hTxt;

set(h, 'UserData',  udat);
set(h, 'WindowKeyPressFcn', @fuzzy_buttonpress);
set(h, 'Visible', 'on');

% controlling Font
% FontAngle	
% FontName	
% FontSize	
% FontUnits	
% FontWeight	
% ForegroundColor
%
% SEE:
% http://undocumentedmatlab.com/blog/setting-line-position-in-edit-box-uicontrol
% http://undocumentedmatlab.com/blog/cprintf-display-formatted-color-text-in-command-window