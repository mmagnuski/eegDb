function refresh_fuzzy(hObj, textActive, uData)


% normal / highlight color
col = {'\color{black}', '\color{magenta}'};

% set inactive invisible
activeNum = sum(uData.textActive);
buttonsNum = length(uData.hButton);
activeInd = uData.inds(uData.actv);

if activeNum > 0
	set(uData.hButton(2:activeNum+1), 'Visible', 'on');
	setCol = uData.color(uData.textActive,:);
end
if activeNum < buttonsNum
	set(uData.hButton(activeNum+2:end), 'Visible', 'off');
end

% change text in typed
set(uData.hText(1), 'String',  uData.typed );

% change props of active buttons
for i = 1:length(textActive)
    
    thisText = highlightString(textActive{i}, activeInd{i}, col);

    set(uData.hButton(i + 1), 'backgroundcolor', setCol(i,:));
    set(uData.hText(i + 1), 'Interpreter','latex', 'String', thisText);
end


function outstr = highlightString(str, ind, col)

% now its really simple - per character
strLen = length(str);
isHgh = false(1,strLen);
isHgh(ind) = true;
outstr = cell(1,length(str));
lastWas = 2;

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



