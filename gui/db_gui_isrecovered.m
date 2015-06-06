function isreco = winreject_isrecovered(hObj)

% WINREJECT_ISRECOVERED checks whether given record(s)
% have their corresponding EEG(s) recovered
%
% isreco = winreject_isrecovered(hObj)
%
% input:
% hObj - handle to the eegDb figure

% ADD - there should be a second parameter determining
%       whether to look at selections from multisel or
%       at the current record. Currently looks only at
%       the current record.

% get handles from db_gui
if ishandle(hObj)
	h = guidata(hObj);
elseif isstruct(hObj)
	h = hObj;
else
	error('Unrecognized input. Should be structure or handle.');
end

% this is copied from winreject (and is quite messy):
isreco = ~(isempty(h.EEG) || h.r ~= h.rEEG || ...
	~db_recov_compare(h.EEG.etc.recov, h.db(h.r)));