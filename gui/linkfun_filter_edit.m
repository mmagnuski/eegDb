function linkfun_filter_edit(hObj)

% NOHELPINFO

% ADD
% [ ] filter tests 
% [ ] red highlight when something wrong
% [x] enter and escape accept and cancel

% get filtering data from main eegDb window
% CONSIDER - db_gui_get and db_gui_set ?
%            shortcuts to get fields from guidata
%            taking care about multiple selections etc.
d = guidata(hObj);

% defaults
filt = [];
val = cell(4,1);


% currently only single record is displayed
% but multiple are edited

% get r as current record or first selected
r = d.r;

if ~isempty(d.selected)
	if ~any(d.selected == r)
		r = d.selected(1);
	end
end

if femp( d.db(r), 'filter' ) && ...
	isnumeric(d.db(r).filter)
	filt = d.db(r).filter;
end

if ~isempty(filt)
	
	% get highpass / lowpass
	val{1} = num2str(filt(1,1));
	val{2} = num2str(filt(1,2));

	% if size is 2 by 2 - also notch
	if isequal(size(filt), [2, 2])
		val{3} = num2str(filt(2,1));
		val{4} = num2str(filt(2,2));
	end
end

optnames = {...
	'Passband lower edge',...
	'Passband higher edge',...
	'Stopband lower edge',...
	'Stopband higher edge',...
	};

h = gui_multiedit('Edit filtering', optnames, val);

% OK and CANCEL Callbacks
set(h.ok, 'Callback', {@checkopt, h, hObj});
set(h.cancel, 'Callback', {@closefun, h.hf});

% enter accepts, escape cancels
set(h.hf, 'KeyPressFcn', {@normal_butpressfun, h, hObj});
set(h.edit, 'KeyPressFcn', {@normal_butpressfun, h, hObj});

% add callback so that enter on button activates its function
set(h.ok, 'KeyPressFcn', {@normal_butpressfun, h, hObj});
set(h.cancel, 'KeyPressFcn', {@cancel_butpressfun, h, hObj});

% give focus to first edit box
uicontrol(h.edit(1));
% wait for gui to finish
uiwait(h.hf);


function closefun(h, e, figh)
	close(figh);


function normal_butpressfun(h, e, hwin, hobj)

	if strcmp(e.Key, 'return')
        % if the object is an editbox
		% change focus to update editbox
		% if get(h, 'style')
        try %#ok<TRYNC>
            stl = get(h, 'style');
            disp(stl);
            if strcmp(stl, 'edit')
                if hwin.edit(1) == h
                    uicontrol(hwin.edit(2));
                else
                    uicontrol(hwin.edit(1));
                end
            end
        end

		% run checkopts
		checkopt(h, e, hwin, hobj);
	elseif strcmp(e.Key, 'escape')
		closefun(h, e, hwin.hf);
	end

			
function cancel_butpressfun(h, e, hwin, hobj)

	if any(strcmp(e.Key, {'return', 'escape'}))
		closefun(h, e, hwin.hf);
	end


function checkopt(h, e, hwin, hobj)

	% get values
	val = get(hwin.edit, 'String');

	% check if correct
	chr = cellfun(@ischar, val);
	nm = cell(1,4);
	nm(chr) = cellfun(@str2num, val(chr), 'uni', false);
	empt = cellfun(@isempty, nm);

	if all(empt)
		filt = [];
	else
		nm(empt) = {0};
		filt = reshape(cell2mat(nm), [2, 2])';

		if sum(filt(2,:)) == 0
			filt = filt(1,:);
		end
	end

	% get guidata
	d = guidata(hobj);

	% set filtering
	if isempty(d.selected)
		d.db(d.r).filter = filt;
	else
		for r = 1:length(d.selected)
			d.db(d.selected(r)).filter = filt;
		end
	end

	db_gui_refresh(d);

	uiresume(hwin.hf);
	close(hwin.hf);
	
