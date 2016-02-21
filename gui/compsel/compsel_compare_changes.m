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
        
        % 1. if options present - apply
        fst_opts = getappdata(h, 'fastplotopts');
        if femp(fst_opts, 'window')
            fst.set_window(fst_opts.window);
            fst.refresh();
        end
        % 2. attach a function to fastplot close action
        %    (or add a listener to the close event)
        set(fst.h.fig, 'CloseRequestFcn', @(o, e) store_fastplotopts(fst, h));
        
        if warn
        	mh = msgbox(warntext, 'Some components have already been removed', ...
        		'warn');
            % change msgbox fontsize following a helpful post here:
            % https://www.mathworks.com/matlabcentral/newsreader/view_thread/73331
            ch = findobj(mh, 'Type', 'Text');
            extent0 = get( ch, 'Extent' ); % text extent in old font
            set( ch, 'FontSize', 14 );
            extent1 = get( ch, 'Extent' ); % text extent in new font

            % need to resize the msgbox object to accommodate new FontName 
            % and FontSize
            delta = extent1 - extent0; % change in extent
            pos = get( mh, 'Position' ); % msgbox current position
            pos = pos + delta; % change size of msgbox
            set( mh, 'Position', pos ); % set new position
        end
    end
end