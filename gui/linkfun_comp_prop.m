function linkfun_comp_prop(hfig, src, cmp)

% link pop_selectcomps_new with pop_prop


% TODOs
% [ ] if such compo is already open - raise figure
% [ ] remember about non-matching EEG - eegDb comps
%     when some were selected during recovery
% [ ] may be better to first draw outline of pop_prop
%     then add button functions etc and then call some
%     update function


info = getappdata(hfig, 'info');

% if eegDb - check mapping
if info.eegDb_present
	eegcmp = find(info.mapping == cmp);

	% do not open if no mapping
	if isempty(eegcmp)
		return
	end
else
	eegcmp = cmp;
end

% pop prop needs EEG:
EEG = getappdata(hfig, 'EEG');
snc = getappdata(hfig, 'syncer');

% generate figure:
h = pop_prop2(EEG, [eegcmp, cmp], hfig);

% add subgui
add(snc, h.fig, cmp);
% set button status
update_sub_button(snc, cmp);


% add callback to sync from this button:
set(h.status, 'Callback', @(src, ev) snc.chng_comp_status(cmp) );
% add deletion callback:
set(h.fig, 'DeleteFcn', @(src, ev) snc.clear_h(h.fig) );


% CHANGE - use spec_opt in the future
% pop_prop2(EEG, cmp, hfig, spec_opt);


