function refresh_fuzzy(hObj, uData)


% normal / highlight color
col = {'\color{black}', '\color{magenta}'};

% set inactive to invisible
activeNum = sum(uData.active);

try
    buttonsNum = length(uData.hButton);
catch %#ok<CTCH>
    buttonsNum = 0;
end

if activeNum > 0
	set(uData.hButton(1:uData.numButtons), 'Visible', 'on');
	setCol = uData.boxColor(uData.active,:);
end
if activeNum < uData.numButtons
	set(uData.hButton(activeNum + 1 : end), 'Visible', 'off');
	set(uData.hText  (activeNum + 1 : end), 'String', '');
end

% get active text
text = uData.origText(uData.active);

% change text in typed
set(uData.hEditText, 'String',  uData.typed );

% change highlight position
% -------------------------
if uData.allowHighlight

	% something to highlight
	if activeNum > 0
		set(uData.hHighlight, 'Visible', 'on');

		% check position
		if uData.highlightPosition < 1

			% fist visible still selected
			uData.highlightPosition = 1;

			% check scrolling:
			if uData.allowScrolling && uData.focus > 1
				uData.focus = uData.focus - 1;
			end

		elseif activeNum > uData.numButtons && ...
			uData.highlightPosition > uData.numButtons

			% last visible is still selected
			uData.highlightPosition = uData.numButtons;
			
			% check scrolling:
			if uData.allowScrolling && uData.focus < activeNum - uData.numButtons + 1
				uData.focus = uData.focus + 1;
			end

		elseif uData.highlightPosition > activeNum
			uData.highlightPosition = activeNum;
		end

		% set position
		X = get(uData.hButton...
			(uData.highlightPosition), 'XData');
        Y = get(uData.hButton...
			(uData.highlightPosition), 'YData');
        X = X + [-uData.highlightRim(1); -uData.highlightRim(1);...
            uData.highlightRim(3); uData.highlightRim(3)];
        Y = Y + [uData.highlightRim(2); -uData.highlightRim(4);...
            -uData.highlightRim(4); uData.highlightRim(2)];

		set(uData.hHighlight, 'XData', X, 'YData', Y);

	else
		set(uData.hHighlight, 'Visible', 'off');
    end
end



% sorting
% -------

if uData.allowSorting && ~isempty(uData.inds) ...
	&& ~isempty(uData.inds{1})
	
	% sort active text
	[~, sortVals] = sort(cellfun(@sum, uData.inds));
	text = text(sortVals);
	setCol = setCol(sortVals, :);
	uData.inds = uData.inds(sortVals);
	uData.sortInds = find(uData.active);
	uData.sortInds = uData.sortInds(sortVals);

end

% check scrolling
% ---------------
if uData.allowScrolling

	% check if focus needs to be reduced
	uData.focus = min( uData.focus, max(1, activeNum - uData.numButtons + 1) ); 


	% update scroll bar if it is allowed:
	if uData.allowSrollBar

		BarLim = calcScrollBar(uData);
		Y = repmat(BarLim, [2, 1]);
		set(uData.hScrollBarFront, 'YData', Y(:));
	end

end


% change props of active buttons
for i = 1: min(uData.numButtons, activeNum)
    
    ind = i + uData.focus - 1;
    thisText = highlightString(text{ind}, uData.inds{ind}, col);
    thisColor = setCol(ind,:);

    set(uData.hButton(i), 'FaceColor', thisColor);
    set(uData.hText(i), 'String', thisText);
end

% give back user data
set(hObj, 'UserData', uData);


function outstr = highlightString(str, ind, col)

% now its really simple - per character
strLen = length(str);
isHgh = false(1,strLen);
isHgh(ind) = true;
outstr = cell(1,length(str));
lastWas = 2;

% CHANGE - PROFILE and OPTIMIZE:
for i = 1:strLen
	issame = lastWas == isHgh(i);

	if ~issame
		if isHgh(i)
			outstr{i} = [col{2}, str(i)];
		else
			outstr{i} = [col{1}, str(i)];
		end
	else
		outstr{i} = str(i);
	end
	lastWas = isHgh(i);
end

outstr = [outstr{:}];
