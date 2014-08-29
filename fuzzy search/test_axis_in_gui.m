% testing 

udat.color = 0.7 + rand(textLength,3)*0.3;

teststring = {'', 'AkredytacjaWielkiejWierzby',...
    'to som chyba miesnie', 'bardzo brzydki sygnal',...
    'dziwne warczenie'};

figPos = [550, 90, 450, 450];
h = figure('Position', figPos, ...
    'DockControls', 'off', 'MenuBar', 'none',...
    'Name', 'Select mark', 'Toolbar', 'none',...
    'Visible', 'on');

figSpace = figPos([3,4]);

textLength = length(teststring);
horLim = [10, figSpace(2) - 10];
keyh = 60;
keyw = diff(horLim);
keyDist = 15;
keyStart = 60;


udat.hAxis = axes('Position', [0, 0, 1, 1],...
    'Visible', 'off');
set(udat.hAxis, 'Xlim', [0, figSpace(1)],'YLim', [0, figSpace(2)]);

% 

butUp = figSpace(2) - keyStart;



hButton(1) = patch('vertices', [horLim(1), butUp; horLim(1), butUp - keyh;...
    horLim(2), butUp - keyh; horLim(2), butUp], 'Visible', 'on',...
    'faceColor', udat.color(1, :), 'edgecolor', 'none',...
    'Faces', 1:4);

hTxt(1) = text('String', 'testingTestyTest', 'FontSize', 18,...
 'Position', [horLim(1), butUp - keyh], 'Visible', 'on');