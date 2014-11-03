function linkfun_comp_prop(hfig, src, cmp)

% link pop_selectcomps_new with pop_prop


% TODOs
% remember about non-matching EEG - eegDb comps
% when some where selected during recovery

% pop prop needs EEG:
EEG = getappdata(hfig, 'EEG');

% CHANGE - use spec_opt in the future
h = pop_prop2(EEG, cmp, hfig);
% pop_prop2(EEG, cmp, hfig, spec_opt);

% add proper callbacks:
% ...
