function guifun_maxim_evlabs(h)

% adapt event labels
ch2 = get(h, 'children');
tx = ch2(strcmp('text', get(ch2, 'type')));
if ~isempty(tx)
	set(tx, 'rotation', 0);
	p = get(tx, 'position');
	p = cellfun(@(x) x + [0, 0.025, 0], p, 'Uni', false);
	arrayfun(@(x) set(tx(x), 'position', p{x}), 1:length(p));
end