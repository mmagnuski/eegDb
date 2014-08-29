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

textLength = length(teststring);
horLim = [10, figSpace(2) - 10];
keyh = 60;
keyw = diff(horLim);
keyDist = 15;
keyStart = 60;
udat.color = 0.7 + rand(textLength,3)*0.3;


% 
for i = 1:textLength
    butUp = figSpace(2) - keyStart - (i-1) * (keyh + keyDist);
    
    hTxt(i) = text('String', teststring{i}, 'FontSize', 15,...
        'Position', [horLim(1), butUp - keyh] );

    hButton(i) = uicontrol('style', 'text', ...
        'position', [horLim(1), butUp - keyh, keyw, keyh],...
        'backgroundcolor', udat.color(i, :));
end

set(hButton(1), 'FontWeight', 'bold', 'FontSize', 18);
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