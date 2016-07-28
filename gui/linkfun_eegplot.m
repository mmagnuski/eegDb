function linkfun_eegplot(h)

plotopt = h.plotopts;

if strcmp(plotopt.plotter, 'eegplot')

	% clear base workspace
	evalin('base', 'clear TMPREJ TMPNEWREJ');

	% display badelectrodes according to options
	plotopt.wlen = plotopt.winlen;
	plotopt.badchan = h.db(h.r)...
	    .chan.bad;

	%     if ~femp(h, 'recovopts') || (femp(h, 'recovopts')...
	%             && sum(strcmp('interp', h.recovopts)) == 0)
	%     goodel(h.db(h.r).badchan) = [];
	%     end

	% get rejections from cooleegplot
	plotopts = struct_unroll(plotopt);
	if isempty(plotopt)
	    TMPREJ = cooleegplot(h.EEG, 'eegDb', h.db, ...
	        'r', h.r, 'update', false);
	else
	    TMPREJ = cooleegplot(h.EEG, 'eegDb', h.db, ...
	        'r', h.r, 'update', false, ...
	        plotopts{:});
	end

	% CHECK db_newrejtype - and think about
	%       whether it is of final form or only
	%       a temporary solution (kind of slow...)
	%
	% get additional rejections set in eegplot2
	h.db = db_newrejtype(h.db,...
	    []);

	% Update h structure
	guidata(h.figure1, h);

	if ~isempty(TMPREJ)
	    % get current h
	    h = guidata(h.figure1);
	    
	    if ~exist('rEEG', 'var')
	        rEEG = h.rEEG;
	    end
	    
	    % CHANGE FIXME
	    % update rejections
	    [h.db, h.EEG] = db_rejTMP(h.db,...
	        rEEG, h.EEG, TMPREJ);
	    
	    % Update h structure
	    guidata(h.figure1, h);
	    
	    % remove TMPREJ from base workspace
	    if evalin('base', 'exist(''TMPREJ'', ''var'');')
	        evalin('base', 'clear TMPREJ');
	    end
	end
elseif strcmp(plotopt.plotter, 'fastplot')

    % electrode color
    if ischar(plotopt.ecol)
        if strcmp(plotopt.ecol, 'off')
            plotopt.ecol = [0, 0, 0];
        end
    end

	% add vim opts
	plt = fastplot(h.EEG, 'show', false, 'vim', true,...
        'ecol', plotopt.ecol);
	n_winepoch = plt.opt.num_epoch_per_window;
	windiff = plotopt.winlen - n_winepoch;
	plt.windowsize(windiff);

	% - add mark types from db to fastplot
	mark_types = {h.db(h.r).marks.name};
    for m = 1:length(mark_types)
        if ~strcmp('reject', mark_types{m})
            plt.add_mark(h.db(h.r).marks(m));
        end

        mrks = h.db(h.r).marks(m).value;
        if islogical(mrks)
            mrks(h.db(h.r).reject.post) = [];
            mrks = find(mrks);
        end
        if ~isempty(mrks)
            plt.mark(mark_types{m}, mrks);
        end
    end
    
    % set bad channels
    if ~isempty(h.db(h.r).chan.bad)
        plt.opt.badchan(h.db(h.r)...
            .chan.bad) = true;
    end

	plt.plot();
	uiwait(plt.h.fig);

	% get rejections from fastplot
	% ----------------------------
	mrks = plt.marks;
	mrk_names = mrks.names;
	db_rej = db_getrej(h.db, h.r);

	% check original number of epochs
    if isempty(h.db(h.r).marks(1).value)
        h.db(h.r).marks(1).value = false(h.EEG.etc.orig_numep, 1);
        orig_numep = h.EEG.etc.orig_numep;
    else
        orig_numep = length(h.db(h.r).marks(1).value);
    end

    adr = 1:orig_numep;

    if femp(h.db(h.r).reject, 'post')
        adr(h.db(h.r).reject.post) = [];
    end

    for f = 1:length(mrk_names)
        mrk_in_db = find(strcmp(mrk_names{f}, db_rej.name));
        if isempty(mrk_in_db)
            mrk_in_db = length(h.db(h.r).marks) + 1;
        end
        h.db(h.r).marks(mrk_in_db).name = mrk_names{f};
        h.db(h.r).marks(mrk_in_db).color = mrks.colors(f,:);

        if isempty(h.db(h.r).marks(mrk_in_db).value)
            h.db(h.r).marks(mrk_in_db).value = false(h.EEG.etc.orig_numep, 1);
        end

        h.db(h.r).marks(mrk_in_db).value(adr) = mrks.selected(f,:)';
    end

	% update EEG:
	h.EEG.reject.db = db_getrej(h.db, h.r);

	% cut out postrej (prerej are not in
	% removed):
    for v = 1:length(h.EEG.reject.db.value)
        h.EEG.reject.db.value{v}(h.db(h.r).reject.post) = [];
    end

    h.db(h.r).chan.bad = find(plt.opt.badchan);

	guidata(h.figure1, h);
end