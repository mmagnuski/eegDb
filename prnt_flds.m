function prnt_flds(strct)

% PRNT_FLDS - Markdown-friendly prints fields of a given structure 

flds = fields(strct)';
fprintf('\n');

for f = flds
	fprintf(['`', f{1}, '`, ']);
end

fprintf('\b\b');
fprintf('\n');
