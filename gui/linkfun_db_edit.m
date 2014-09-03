function linkfun_db_edit(hObj)

% FIXHELPINFO
% 
% LINKFUN_DB_EDIT
% Link function that spawns fuzzy gui for 
% eegDb commands. After the command has been
% chosen LINKFUN_DB_EDIT opens relevant gui
% and after edits have been made - checks 
% these and applies to the database
%
% input:
% hObj - handle to the eegDb figure

commands = {...
	'filename - edit',...
	'filepath - add',...
	'filepath - edit',...
	'filter - edit',...
	'epoch - edit',...
	'plot and mark',...
	'multiselect',...
	'recover in EEGlab',...
	'versions - open',...
	'versions - new',...
	'ICA - run',...
	'ICA - options'...
	};

func = {...
	'',...
	'',...
	'',...
	@linkfun_filter_edit,...
	'',...
	'plot and mark',...
	@linkfun_multiselect,...
	'',...
	'',...
	'',...
	'',...
	''...
};

com = fuzzy_gui_test(commands);

% if user aborts - return
if isempty(com) || com == 0
	return
end

% if func for this command is empty - display error
if isempty(func{com})
	error('Command not implemented');
else
	% else - evaluate
	feval(func{com}, hObj);
end
