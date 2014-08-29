% TODOs:
% [ ] text centering
% [ ] different color choosing
% [ ] text color adjustment to background color
% [ ] allow setting text color
% [ ] change ordering basing on match
% [ ] enter - accept
% [ ] fix blank
% [ ] fix backspace action



menu_items = {'AkredytacjaWielkiejWierzby',...
    'to som chyba miesnie', 'bardzo brzydki sygnal',...
    'dziwne warczenie'};

% create user data structure
udat.textItems = length(menu_items);
udat.boxColor = 0.7 + rand(udat.textItems,3)*0.3;
udat.origText = menu_items;
udat.lowerText = cellfun(@lower, menu_items, 'Uni', false);
udat.active = true(1, udat.textItems);

% create figure
figPos = [550, 90, 450, 450];
h = figure('Position', figPos, ...
    'DockControls', 'off', 'MenuBar', 'none',...
    'Name', 'Select mark', 'Toolbar', 'none',...
    'Visible', 'off');

% dimensional data
figSpace = figPos([3,4]);
horLim   = [10, figSpace(2) - 10];
keyw     = diff(horLim);
keyh     = 60;
keyDist  = 15;
keyStart = 100;

% edit box color
EditColor = [0.2, 0.1, 0.0];

% create invisible background axis
udat.hAxis = axes('Position', [0, 0, 1, 1],...
    'Visible', 'off');
set(udat.hAxis, 'Xlim', [0, figSpace(1)],'YLim', [0, figSpace(2)]);


% create 'edit box'
up = figSpace(2) - 20;
udat.hEditFrame = patch('vertices', [horLim(1), up; horLim(1), ...
    up - keyh; horLim(2), up - keyh; horLim(2), up],...
    'Visible', 'on', 'faceColor', EditColor, 'edgecolor',...
    'none', 'Faces', 1:4);

udat.hEditText = text('String', '', 'FontSize', 15,...
    'Position', [horLim(1), up - keyh/2] + [35, 0], ...
    'Visible', 'on', 'Color', [0.8, 0.85, 0.9]);

% create options buttons
for i = 1:udat.textItems
    
    butUp = figSpace(2) - keyStart - (i-1) * (keyh + keyDist);
    
    hButton(i) = patch('vertices', [horLim(1), butUp; horLim(1), butUp - keyh;...
        horLim(2), butUp - keyh; horLim(2), butUp], 'Visible', 'on',...
        'faceColor', udat.boxColor(i, :), 'edgecolor', 'none',...
        'Faces', 1:4);

    % ADD text centering etc.
    hTxt(i) = text('String', menu_items{i}, 'FontSize', 15,...
     'Position', [horLim(1), butUp - keyh/2] + [35, 0], 'Visible', 'on');
end


udat.hButton = hButton;
udat.hText = hTxt;
udat.typed = '';

set(h, 'UserData',  udat);
set(h, 'WindowKeyPressFcn', @fuzzy_buttonpress);
set(h, 'Visible', 'on');
