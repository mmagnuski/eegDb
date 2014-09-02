function linkfun_filter_edit(hObj)

% NOHELPINFO

% ADD
% [ ] filter tests 
% [ ] red highlight when something wrong
% [ ] enter and escape accept and cancel

% get filtering data from main eegDb window
% CONSIDER - eegDb_gui_get and eegDb_gui_set ?
%            shortcuts to get fields from guidata
%            taking care about multiple selections etc.
d = guidata(hObj);

% defaults
filt = [];
val = cell(4,1);


% CHANGE - currently only single record
if femp( d.ICAw(d.r), 'filter' ) && ...
	isnumeric(d.ICAw(d.r).filter)
	filt = d.ICAw(d.r).filter;
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
uiwait(h.hf);


function closefun(h, e, figh)
	close(figh);


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
	d.ICAw(d.r).filter = filt;
	winreject_refresh(d);

	uiresume(hwin.hf);
	close(hwin.hf);
	
