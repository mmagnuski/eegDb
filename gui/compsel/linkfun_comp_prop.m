function linkfun_comp_prop(hfig, src, cmp)

% link pop_selectcomps_new with pop_prop


% TODOs
% [ ] each fastplot should be labeled / titled so
%     it is easy to get around when you have many open
% [ ] if such compo is already open - raise figure
% [ ] remember about non-matching EEG - eegDb comps
%     when some were selected during recovery
% [ ] may be better to first draw outline of pop_prop
%     then add button functions etc and then call some
%     update function


info = getappdata(hfig, 'info');

% if eegDb - check mapping
if info.db_present
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
max_freq = min(65, EEG.srate / 2);
spect_opts = {'freqrange', [0, max_freq]};
h = pop_prop2(EEG, [eegcmp, cmp], hfig, spect_opts);

% add subgui
add(snc, h.fig, cmp);
% set button status
update_sub_button(snc, cmp);


% add callback to sync from this button:
set(h.status, 'Callback', @(src, ev) snc.chng_comp_status(cmp) );
% add deletion callback:
set(h.fig, 'DeleteFcn', @(src, ev) snc.clear_h(h.fig) );
% add callback for ok to close figure
set(h.ok, 'Callback', @(src, ev) close(h.fig) );

% add callback for enter escape, 's' and 'c'
set(h.fig, 'WindowKeyPressFcn', @(o,e) prop_buttonpress(o, e, hfig));


% CHANGE - use spec_opt in the future
% pop_prop2(EEG, cmp, hfig, spec_opt);


% button press function
function prop_buttonpress(hObj, evnt, hfig)

% get pressed character
ch = evnt.Character;

if ~isempty(ch)
    
    if any(strcmp(evnt.Key, {'escape', 'return'}))
    	close(hObj);
    elseif strcmp(evnt.Key, 'c')
        comp = getappdata(hObj, 'comp');
        EEG = getappdata(hObj, 'EEG');
        EEG2 = pop_subcomp(EEG, comp, 0);
        fst = fastplot(EEG, EEG2);
        
        % apply last used opts:
        fst_opts = getappdata(hfig, 'fastplotopts');
        if femp(fst_opts, 'window')
            fst.set_window(fst_opts.window);
            fst.refresh();
        end
        % get options on fastplot close
        set(fst.h.fig, 'CloseRequestFcn', @(o, e) store_fastplotopts(fst, hfig));
    elseif strcmp(evnt.Key, 's')
        comp = getappdata(hObj, 'comp');
        EEG = getappdata(hObj, 'EEG');

        % be sure to have EEG comp num
        plt = fastplot(EEG, 'comp', comp);
    end
end