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
icapres = femp(h.ICAw(h.r), 'ICA') && ...
	femp(h.ICAw(h.r).ICA, 'icaweights');

if ~icapres
	warndlg('No ICA weights found. You first need to perform ICA',...
		'no ICA weights found!');
	return
end

% check if current EEG is recovered:
isreco = winreject_isrecovered(h);

% CHANGE - this should be a separate func:
% if not recovered - recover
if ~isreco
	h.EEG = recoverEEG(h.ICAw, h.r, 'local', h.recovopts{:});
        h.rEEG = h.r;
    guidata(hObj, h);
end

% open compo view window

