function add_rejcol_callb(hObject, ~)

% ADD_REJCOL_CALLB is a callback that allows to add new 
% rejection types to eegplot
% 
% see also: eegDb, eegplot2

% get g from userdata:
if ~strcmp(get(hObject, 'Type'), 'figure')
	hfig = get(hObject, 'Parent');
else
	hfig = hObject;
end
g = get(hfig, 'userdata');
marknames = get(g.choose_rejcol, 'String');

% ask for mark name:
markname = gui_editbox('', {'Type mark name'; 'here:'});

% if user aborts do not go any further
if isempty(markname)
    return
end

% if the name is present in rejs ask for another
while sum(strcmp(markname, marknames)) > 0
    markname = gui_editbox('', {'This name is not'; 'cool, try another:'});
    
    % if user aborts do not go any further
    if isempty(markname)
        return
    end
end

% ask for mark color
badcol = true;
while badcol
	% gui for setting color
	c = uisetcolor;

	% check color:
	badcol = any(cellfun(@(x) all(x == c), g.labcol));

	if badcol
		warndlg('This color is already in use, please choose another one.');
	end
end

g.labels = [marknames; markname];
g.labcol = [g.labcol, c];

% set ui dropdown string
set(g.choose_rejcol, 'String', g.labels);

% add TMPNEWREJ to base workspace
ex = evalin('base', 'exist(''TMPNEWREJ'', ''var'');');
st = 1;

if ex
    newrej = evalin('base', 'TMPNEWREJ;');
    st = length(newrej.name) + 1;
end

newrej.name{st} = markname;
newrej.color(st,:) = c;

% CHANGE assing a temporary variable to workspace
assignin('base', 'TMPNEWREJ', newrej);

% give back g to eegplot function:
set(hfig, 'userdata', g);