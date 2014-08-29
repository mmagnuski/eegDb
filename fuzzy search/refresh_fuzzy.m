function refresh_fuzzy(hObj, uData)


% normal / highlight color
col = {'\color{black}', '\color{magenta}'};

% set inactive invisible
activeNum = sum(uData.active);
buttonsNum = length(uData.hButton);

if activeNum > 0
	set(uData.hButton(1:activeNum), 'Visible', 'on');
	setCol = uData.boxColor(uData.active,:);
end
if activeNum < buttonsNum
	set(uData.hButton(activeNum + 1 : end), 'Visible', 'off');
	set(uData.hText  (activeNum + 1 : end), 'String', '');
end

% get active text
text = uData.origText(uData.active);

% change text in typed
set(uData.hEditText, 'String',  uData.typed );

% change props of active buttons
for i = 1:length(text)
    
    thisText = highlightString(text{i}, uData.inds{i}, col);

    set(uData.hButton(i), 'FaceColor', setCol(i,:));
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
