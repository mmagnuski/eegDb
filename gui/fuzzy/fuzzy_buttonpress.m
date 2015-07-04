function fuzzy_buttonpress(hObj, evnt)

% check for 'return' and arrows

% a button has been pressed!

% we don't care about case so we don't want modifiers
if ~isempty(evnt.Modifier)
    return
end

% get pressed character
ch = evnt.Character;


if ~isempty(ch)
    
    % get user data and text
    uData = get(hObj, 'UserData');
    text = uData.lowerText(uData.active);
    
    % modify uData.typed - typed text
    if length(ch) == 1 && length(evnt.Key) == 1
        
        % get active text
        uData.typed = [uData.typed, ch];
        
    elseif strcmp(evnt.Key, 'backspace')
        
        text = uData.lowerText;
        uData.active(~uData.active) = true;
        uData.typed = uData.typed(1:end-1);

    elseif any(strcmp(evnt.Key, {'return', 'escape'}))
        if strcmp(evnt.Key, 'escape')
            udat.active = [];
        end
    	uiresume(hObj);
    	return
    elseif uData.allowHighlight
        if strcmp(evnt.Key, 'uparrow')
            uData.highlightPosition = uData.highlightPosition - 1;
        elseif strcmp(evnt.Key, 'downarrow')
            uData.highlightPosition = uData.highlightPosition + 1;
        end
    else
        return
    end
    
    % pass text to fuzzy_search
    if ~isempty(uData.typed) 
        
        % use fuzzy_search
        uData.inds = fuzzy_search(text, uData.typed);
        
        % update active
        actv = ~cellfun(@isempty, uData.inds);
        uData.inds = uData.inds(actv);
        uData.active(uData.active) = actv;
    else
        text = uData.lowerText;
        uData.active(~uData.active) = true;
        uData.inds = cell(1, uData.textItems);
    end
    
    % refresh gui:
    refresh_fuzzy(hObj, uData);
end
