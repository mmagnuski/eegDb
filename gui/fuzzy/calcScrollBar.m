function barLim = calcScrollBar(d)

% calculates scroll bar length and position

Lim = [d.bottomDist, d.figSpace(2) - d.editBoxDist];
Len = diff(Lim);
NumActive = sum(d.active);

if NumActive <= d.numButtons
	% bar is max length
	barLim = Lim;
else
	% get unit length
	unit = Len / NumActive;

	barLen = d.numButtons * unit;
	top = Lim(2) - (d.focus - 1) * unit;
	barLim = [top - barLen, top];
end

