function compsel_rightclick_changestatus(src, cmp, snc)

% NOHLEPINFO

parentfig = get(src, 'Parent');

butpos = get(src, 'Position');
uni    = get(src, 'Units');

if ~strcmp(get(parentfig, 'Units'), uni)
    set(parentfig, 'Units', uni);
end
pos = get(parentfig, 'CurrentPoint');

XLim = [butpos(1), butpos(1) + butpos(3)];
YLim = [butpos(2), butpos(2) + butpos(4)];

if pos(1) > XLim(1) && pos(1) < XLim(2) && ...
        pos(2) > YLim(1) && pos(2) < YLim(2)
    
    % only then change cmp state:
    snc.chng_comp_status(cmp);
end