function compsel_compare_changes(h, evnt)

% compare signal with and without rejected components
 
if strcmp(evnt.Key, 'c')
    info = getappdata(h, 'info');
    % get original component numbers
    remcmp = info.comps.all(info.comps.state == 1);
    warn = false;
    % if some components already deleted, check remcmp:
    if isfield(info, 'mapping')
    	isinEEG = arrayfun(@(x) any(info.mapping == x), remcmp);
    	remcmp = arrayfun(@(x) find(info.mapping == x), remcmp(isinEEG));
    	if ~all(isinEEG)
    		warn = true;
    		warntext = sprintf(['%i of %i components selected ', ...
                'for rejection have already been rejected from ', ...
                'the current data, so you are comparing only a ', ...
                'subset of the changes.'], sum(isinEEG == 0), ...
                length(isinEEG));
    	end
    end
    
    if ~isempty(remcmp)
        EEG = getappdata(h, 'EEG');
        EEG2 = pop_subcomp(EEG, remcmp, 0);
        fst = fastplot(EEG, EEG2);
        if warn
        	mh = msgbox(warntext, 'Some components have already been removed', ...
        		'warn');
            ah = get( h, 'CurrentAxes' );
            ch = get( ah, 'Children' );
            set( ch, 'FontSize', 14 );
        end
    end
end