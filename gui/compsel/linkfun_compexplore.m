function linkfun_compexplore(hObj)

% opens component viewer and sets everything up
% 
% linkfun_compexplore(hObj)
%
% input:
% hObj - handle to the eegDb figure

% check if hObj is handle
if ~ishandle(hObj)
	error('input must be a handle');
end

% CONSIDER - may look for gui if handle was not
%            correct but it does not seem worthwile
%            or especially useful

% ADD - checks for multiselect
% ADD - managing multiselect (what should be done?)

% get handles
h = guidata(hObj);

% check if icaweights present:
icapres = femp(h.db(h.r), 'ICA') && ...
	femp(h.db(h.r).ICA, 'icaweights');

if ~icapres
	warndlg('No ICA weights found. You need to perform ICA first.',...
		'no ICA weights found!');
	return
end

% check if current EEG is recovered:
isreco = db_gui_isrecovered(h);

% CHANGE - this should be a separate func:
% if not recovered - recover
if ~isreco
	% draw now to close fuzzy gui
	drawnow;

	% recover
	h.EEG = recoverEEG(h.db, h.r, 'local', 'ICAnorem');
    h.rEEG = h.r;

    % update winrej handles
    guidata(hObj, h);
end

% open compo view window
newh.db_gui = h.figure1;
compnum = 1:size(h.db(h.r).ICA.icaweights, 1);
pop_selectcomps_new( h.EEG, compnum, 'eegDb', h.db, ...
					'r', h.r, 'h', newh, 'perfig', 10);
