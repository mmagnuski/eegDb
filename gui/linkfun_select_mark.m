function linkfun_select_mark(figh)

% LINKFUN_SELECT_MARK brings up fuzzy menu for mark selection
%
% Usage:
% linkfun_select_mark(figh)
% where:
% figh - eegplot2 figure handle
%
% see also: fuzzy_gui, eegplot2

% coded by mmagnuski in january 2015

% get eegplot info structure
g = get(figh, 'userdata');
marknames = get(g.choose_rejcol, 'String');

% ask for mark name:
marknum = fuzzy_gui(marknames);

% if user aborts do not go any further
if isempty(marknum) || marknum == 0
    return
end

% update all
g.wincolor = g.labcol{marknum};
set(figh, 'userdata', g);
set(g.choose_rejcol, 'Value', marknum);
