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

try
	set(hfig, 'KeyPressFcn', fun);
	success(1) = true;
catch some_error
	success(1) = false;
end

for i = 1:len
	try
		set(fig_children(i), 'KeyPressFcn', fun);
		success(i+1) = true;
	catch some_error
		success(i+1) = false;
	end
end