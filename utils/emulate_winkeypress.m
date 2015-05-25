function success = emulate_winkeypress(hfig, fun)

% emulate_winkeypress emulates WindowKeyPressFcn
% by setting a specific function to children of 
% the figure
% 
% usage:
% success = emulate_winkeypress(figure_handle, function_handle);

fig_children = get(hfig, 'Children');
len = length(fig_children);
success = false(len,1);

for i = 1:len
	try
		set(fig_children(i), 'KeyPressFcn', fun);
		success(i) = true;
	catch some_error
		success(i) = false;
	end
end