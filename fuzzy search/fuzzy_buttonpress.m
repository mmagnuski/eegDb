function fuzzy_buttonpress(hObj, evnt)

% 'backspace', 'return'

% a button has been pressed!

% we don't care about case so we don't want modifiers
if ~isempty(evnt.Modifier)
	return
end

% get pressed character
ch = evnt.Character;


if ~isempty(ch)
	
	% get user data
	uData = get(hObj, 'UserData');

	% modify uData.typed - typed text

	if strcmp(evnt.Key, 'backspace')
		text = uData.lowerText;
		uData.active(~uData.active) = true;
		uData.typed = uData.typed(1:end-1);
	elseif length(ch) == 1
		% get active text
		text = uData.lowerText(uData.active);
		uData.typed = [uData.typed, ch];
	else
		return
	end


	% pass text to fuzzy_search
	if length(uData.typed) > 0

		% use fuzzy_search
		uData.inds = fuzzy_search(text, uData.typed);

		% update active 
		actv = ~cellfun(@isempty, uData.inds);
		uData.inds = uData.inds(actv);
		uData.active(uData.active) = actv;
	else
		
		uData.inds = cell(1, uData.textItems);
	end

	

	% refresh gui:
	refresh_fuzzy(hObj, uData);
end
