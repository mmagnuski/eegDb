function fuzzy_buttonpress(hObj, evnt)

% 'backspace', 'return'

% a button has been pressed!

% we don't care about case so we don't want modifiers
if ~isempty(evnt.Modifier)
	return
end

% add char to char string
key = evnt.Character;

% test Key for backspace and return

if ~isempty(key)
	
	% get active text
	uData = get(hObj, 'UserData');
	textActive = uData.text(uData.textActive);

	% modify uData.typed - typed text

	if strcmp(key, 'backspace')

		uData.typed = uData.typed(1:end-1);
		% special case if uData.typed goes empty!
	elseif length(key) == 1
		uData.typed = [uData.typed, key];
	else
		return
	end

	% pass text to fuzzy_search
	uData.inds = fuzzy_search(textActive, uData.typed);
	% update active 
	uData.actv = ~cellfun(@isempty, uData.inds);
	uData.textActive(uData.textActive) = uData.actv;

	% refresh gui:
	refresh_fuzzy(hObj, textActive(uData.actv), uData);
end
