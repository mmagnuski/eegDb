function fncs = listTaggedFuncs(fls, tag)

% NOHELPINFO

ind = false(length(fls), 1);

for f = 1:length(fls)
	cm = comment_search(fls{f}, tag);
	if size(cm, 1) > 0
		ind(f) = true;
	end

end

fncs = fls(ind);