function guifun_maxim_eegaxis(h)

% test if max is not set
g = get(h, 'userdata');
if g.maxset
	return
else
	g.maxset = true;
	set(h, 'userdata', g);
end

ch = get(h, 'Children');
ch = ch(strcmp('uicontrol', get(ch, 'type')));
set(ch, 'visible', 'off');
try
	set(findobj('tag', 'eyeaxes', 'parent', h), 'visible', 'off');
end

ax = findobj('tag', 'eegaxis', 'parent', h);
ax2 = findobj('tag', 'backeeg', 'parent', h);
set([ax, ax2], 'position', [0.05, 0.04, 0.94, 0.92]);

% chan labels
ylab = get(ax, 'YTickLabel');
if length(ylab) > 50
	if ~iscell(ylab)
		ylab = mat2cell(ylab, ones(1, size(ylab, 1)), size(ylab, 2));
	end
	[ylab(2:2:end)] = deal({' '});
	set(ax, 'YTickLabel', ylab);
end

guifun_maxim_evlabs(ax2);