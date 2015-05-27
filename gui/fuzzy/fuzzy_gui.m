function [out, typed] = fuzzy_gui(menu_items, opt)

% NOHELPINFO
%
% opt
%    .
%    .allowSorting    - 
%    .allowScrolling  -
%    .allowScrollBar  -
%    .allowHighlight  -
%    .allowEditBox    - NOT IMPLEMENTED
%
%    .scrollBarWidth  -
%    .figPos          - define figure position
%    .figPosAlign     - 'center' to align to center of the screen
%    .inFigPos        - use a specific part of the figure
%    .hFig            - pass figure handle to use existing
%                       figure
%    .hAxis           - use existing axis
%    .boxColor        - edit box color
%    .editColor
%    .highlightColor  - 
%    .buttonFitMode   - NOT IMPLEMENTED
%    .buttonsPerPage  - if defined overrides keyh
%
%    .keyh            - button height
%    

% private fields:
% textItems
% origText
% lowerText
% active
% focus

% TODOs:
% [ ] defferentiate enter vs escape when returning 
%     and no option chosen but text typed
% [ ] option not to use fuzzy search (no edit box)
% [ ] option to reside somewhere in an already present figure
% [ ] add option to restart highligh when new
%     text is added (focus should be restarted too)
% [ ] selection by mouse click
% [ ] add slider info (non-interactive)
% [ ] adjust box height
% [ ] text centering
% [ ] selecting good figure size and position
% [ ] different color choosing
% [ ] text color adjustment to background color
% [ ] (?) allow setting text color

% !!!
% move figure to the centre:
% movegui(h.fig, 'center');

% adding information about the 'focus'
% that is indices of items that are visible
% active - tells which are 'selected'
% sortInds (check this) - what is the current order
% focus - if more elements active than figure
%         presentation capacity - informs about
%         the index of first visible element


% check additional options in opt structure
len = length(menu_items);

% handles - no default
udat.hFig     = [];
udat.hAxis    = [];

udat.buttonsPerPage = [];

% dimensional data
udat.figPos      = [550, 90, 450, 450];
udat.inFigPos    = [0, 0, 450, 450]; % full
udat.figPosAlign = 'center';
udat.figSpace    = udat.figPos([3,4]);
udat.horLim      = [10, udat.figSpace(2) - 10];
udat.horLimEdit  = udat.horLim;
udat.keyh        = 60;

udat.keyDist     = 15;
udat.editBoxDist = 100;
udat.bottomDist  = udat.keyDist;

% setup stuff
udat.allowSorting   = true;
udat.allowScrolling = true;
udat.allowHighlight = true;
udat.allowEditBox   = true;
udat.allowSrollBar  = true;

% scroll bar defaults
udat.scrollBarWidth = 30;  
udat.scrollBarDist  = 15;

% colors
% button, edit box and highlight colors
udat.bgColor = [0.25, 0.25, 0.25];
udat.boxColor = 0.7 + rand(len,3)*0.3;
udat.editColor = [0.2, 0.1, 0.0];
udat.highlightColor = [255, 255, 100]/255;
udat.scrollBarBackColor = [0.35, 0.35, 0.35];
udat.scrollBarFrontColor = [0.45, 0.45, 0.45];


% check input arguments
% ---------------------

if exist('opt', 'var') && isstruct(opt)

    % get field names
    udatFields = fields(udat);
    optFields = fields(opt);

    % check if all fields are known
    outf = setdiff(optFields, udatFields);

    if ~isempty(outf)
        error('Unrecognized options:\n%s', outf);
    end

    % copy fields from opt to udat
    for f = 1:length(optFields)
        udat.(optFields{f}) = opt.(optFields{f});
    end
end



% PRIVATE fields
% --------------
udat.textItems = len;
udat.origText = menu_items;
udat.lowerText = cellfun(@lower, menu_items, 'Uni', false);
udat.active = true(1, udat.textItems);
udat.focus = 1;


% FIGURE & AXIS
% -------------

% create figure
if isempty(udat.hFig) || ~ishandle(udat.hFig)

    udat.hFig = figure('Position', udat.figPos, ...
        'DockControls', 'off', 'MenuBar', 'none',...
        'Name', 'Select mark', 'Toolbar', 'none',...
        'Visible', 'off', 'color', udat.bgColor);
else
    % give focus to the figure
    figure(udat.hFig);
end 

% ! CHANGE ! 
% currently we assume inFigPos is in pixels
% and thus force the units to be such
% in future we should test for 
% >= 1 --> normalized, otherwise --> pixels

% create invisible background axis
if isempty(udat.hAxis) || ~ishandle(udat.hAxis)
    udat.figSpace = udat.inFigPos([3, 4]);
    udat.hAxis = axes('Units', 'pixels', 'Position',...
        udat.inFigPos, 'Visible', 'off');
    set(udat.hAxis, 'Xlim', [0, udat.figSpace(1)],'YLim', [0, udat.figSpace(2)]);
else
    % give focus to axis
    axes(udat.hAxis);
end


% BUTTONS
% -------

% do we need to fit buttons?
if ~isempty(udat.buttonsPerPage)
    buttAndHeight = (udat.figSpace(2) - udat.editBoxDist) / udat.buttonsPerPage;
    buttonLeft = buttAndHeight - udat.keyDist;
    if ~(buttonLeft >= udat.keyDist) || (udat.keyDist + udat.keyDist) > buttAndHeight
        
        % maybe - scale button height to keyDist?
        unit = buttAndHeight / 4;
        udat.keyDist = unit;
        udat.keyh = unit * 3;
    else
        % think about this later
    end
end


% check how many buttons
% ----------------------
udat.numButtons = floor( (udat.figSpace(2) - udat.editBoxDist) / (udat.keyh + udat.keyDist) );
if udat.numButtons > udat.textItems
    udat.numButtons = udat.textItems;
end

% make sure that button spacing is such 
% that they fill the desired space
% ! ADD !




% create highlight
% ----------------

% currently scrolling entails highlight
if udat.allowScrolling
    udat.allowHighlight = true;
end

% draw highlight patch
up = udat.figSpace(2) - udat.editBoxDist;
if udat.allowHighlight
    udat.highlightPosition = 1;
    udat.highlightRim = [udat.horLim(1), 8, udat.horLim(1), 8];
    udat.hHighlight = patch('vertices', [0, up + udat.highlightRim(2);...
        0, up - udat.keyh - udat.highlightRim(4);...
        udat.figSpace(1), up - udat.keyh - udat.highlightRim(4);...
         udat.figSpace(1), up + udat.highlightRim(2)],...
        'Visible', 'on', 'faceColor', udat.highlightColor, 'edgecolor',...
        'none', 'Faces', 1:4);
end



% if scroll patch available
% -------------------------

% reduce buttons on the righthand
if udat.allowSrollBar && udat.allowScrolling
    udat.horLim(2) = udat.horLim(2) - udat.scrollBarWidth - udat.scrollBarDist;

    % draw the backscrollbar
    leftscroll = udat.horLim(2) + udat.scrollBarDist;
    topscroll  = udat.figSpace(2) - udat.editBoxDist;
    
    udat.hScrollBarBack = patch('vertices', ...
        [leftscroll, udat.bottomDist; ...
         leftscroll + udat.scrollBarWidth, udat.bottomDist;...
         leftscroll + udat.scrollBarWidth, topscroll;...
         leftscroll, topscroll], 'Visible', 'on', ...
        'faceColor', udat.scrollBarBackColor, 'edgecolor',...
        'none', 'Faces', 1:4);

    % calculate scroll bar length and position
    BarLim = calcScrollBar(udat);

    % draw the front scroll bar
    leftscroll = udat.horLim(2) + udat.scrollBarDist;
    udat.hScrollBarFront = patch('vertices', ...
        [leftscroll, BarLim(1); ...
         leftscroll + udat.scrollBarWidth, BarLim(1);...
         leftscroll + udat.scrollBarWidth, BarLim(2);...
         leftscroll, BarLim(2)], 'Visible', 'on', ...
        'faceColor', udat.scrollBarFrontColor, 'edgecolor',...
        'none', 'Faces', 1:4);
end



% create 'edit box'
% -----------------
up = udat.figSpace(2) - 20;
udat.hEditFrame = patch('vertices', [udat.horLimEdit(1), up; udat.horLimEdit(1), ...
up - udat.keyh; udat.horLimEdit(2), up - udat.keyh; udat.horLimEdit(2), up],...
    'Visible', 'on', 'faceColor', udat.editColor, 'edgecolor',...
    'none', 'Faces', 1:4);

udat.hEditText = text('String', '', 'FontSize', 15,...
    'Position', [udat.horLimEdit(1), up - udat.keyh/2] + [35, 0], ...
    'Visible', 'on', 'Color', [0.8, 0.85, 0.9]);


% create option buttons
% ---------------------
for i = 1:udat.numButtons
    
    butUp = udat.figSpace(2) - udat.editBoxDist - (i-1) * (udat.keyh + udat.keyDist);
    
    udat.hButton(i) = patch('vertices', [udat.horLim(1), butUp; udat.horLim(1), butUp - udat.keyh;...
        udat.horLim(2), butUp - udat.keyh; udat.horLim(2), butUp], 'Visible', 'on',...
        'faceColor', udat.boxColor(i, :), 'edgecolor', 'none',...
        'Faces', 1:4);

    % ADD text centering etc.
    udat.hText(i) = text('String', menu_items{i}, 'FontSize', 15,...
     'Position', [udat.horLim(1), butUp - udat.keyh/2] + [35, 0], 'Visible', 'on');
end


udat.typed = '';

if udat.allowSorting
    udat.sortInds = 1:udat.textItems;
end


set(udat.hFig, 'UserData',  udat);
set(udat.hFig, 'WindowKeyPressFcn', @fuzzy_buttonpress);
set(udat.hFig, 'Visible', 'on');


% wait for user reaction
% ----------------------
uiwait(udat.hFig);

typed = '';

if ishandle(udat.hFig)
    udat = get(udat.hFig, 'UserData');
else
    out = 0; % CHANGE to -1 ?
    return
end


% resume and return
% -----------------
if any(udat.active)
    if udat.allowSorting
        inds = udat.sortInds;
    else
        inds = find(udat.active);
    end
else
    inds = [];
end

if ~isempty(inds)
    if udat.allowHighlight
        
        if udat.allowScrolling
            out = inds(udat.highlightPosition - 1 + udat.focus);
        else
            out = inds(udat.highlightPosition);
        end
    else
        out = inds(1);
    end
else
    out = 0;
end

if udat.allowEditBox
    typed = get(udat.hEditText, 'String');
end


close(udat.hFig);