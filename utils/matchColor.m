function col = matchColor(col)

% FIXHELPINFO
% finds matching color
% for example to find good text color
% for given background color

% get complimentary color:
hslCol = rgb2hsl(col);

% rotate hue
% ----------
hslCol(1) = hslCol(1) + 0.5;
if hslCol(1) > 1
    hslCol(1) = hslCol(1) - 1;
end

% increase distance in lightness
% ------------------------------
% 1. get invert move
mv = 0.5 - hslCol(3);
% 2. push away if too close
mv = mv + sign(mv)*0.5*(0.5 - abs(mv));
% 3. apply invert move
hslCol(3) = 0.5 + mv;

% bring back to rgb
col = hsl2rgb(hslCol);
