function compsel_OK(figh)

% NOHELPINFO

% CHECK
% eeglabs pop_selectcomps has this as OK command:
% command = ['[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); ',...
%    'eegh(''[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);''); ',...
%    'close(gcf)'];

info = getappdata(figh, 'info');

if info.db_present && info.otherfigh && femp(info, 'db_gui')

	% get r for syncing
	r = info.rsync;

	% currently winrej uses h, not appdata ( :( )
	h = guidata(info.db_gui);
	eegDb = h.db;

	% components marked as removed
	st2fld = {'reject', 'select', 'maybe'};

	for s = 1:length(st2fld)
		eegDb(r).ICA.(st2fld{s}) = info.comps.all(info.comps.state == s);
	end

	% pass cached topo
	% ----------------
	% eegDb(r).ICA.topo = getappdata(figh, 'topocache');

	% update h
	h.db = eegDb;
	guidata(info.db_gui, h);

	% close fiugre if still alive
	close(figh);
else
	uiresume(figh);
end