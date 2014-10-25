function fig = cache_figure(h)

% fig = cache_figure(h)
% caches children of figure h in
% variable fig, allowing to re-
% create it later with replot(fig)
%
% h can be:
% (1) figure handle,
% (2) axes handles
% (3) regexp string used in sear-
%     ching for the figure or axes
%     by tag
% 
% Currently only axis children are
% cached, sorry!

% coded by M Magnuski
% May, 2014
% e-mail: mmagnuski@swps.edu.pl

if isempty(h)
   fig = [];
   return
end

if ishandle(h(1))
    [h, tp] = check_h_types(h);
elseif ischar(h(1))
    h = findobj('-regexp', h);
    [h, tp] = check_h_types(h);
else
    help cache_figure
    error('Wrong input type, see help above.');
end

% ADD
% here a call is issued to cachefig():
fig = cachefig(h, tp);

function [h, tp] = check_h_types(h)
% Checks whether all handles are of the same
% type (axes) or just one handle of type figure.
% If both figures and other types are present
% in h - only first figure is returned.
% If axes and other types are present (but no
% figures) all axes are returned.

ish = ishandle(h);
if ~(mean(ish) == 1)
    warning('Some values passed are not handles');
    h = h(ish);
end

tps = get(h, 'Type');

% handle checking:
h2 = [];
chcktps = {'figure', 'axes'};
t = 1;

while isempty(h2) && t <= 2
    h2 = handle_typechecker(h, tps, chcktps{t});
    t = t + 1;
end

h = h2;
if isempty(h2)
    tp = [];
else
    tp = chcktps{t-1};
end


% helper function - checks for handle
% type presence and type consistency
function h = handle_typechecker(h, tps, tp)

istp = strcmp(tp, tps);
numtp = sum(istp);
numh = length(h);

if numtp > 0
    % at least one of given type present
    h = h(istp);
    
    % check for warnings
    if numtp > 1 && isequal(tp, 'figure')
        warning(['More than one figure handle passed',...
            ', only first one considered.']);
    elseif numh > 1
        addstr = '';
        if isequal(tp, 'axis'); addstr = 's'; end
        
        % warning when different handle types present
        warning(['Handles are of different types',...
            ', only %s handle%s considered.'], tp, addstr);
    end
    return
else
    h = [];
end
