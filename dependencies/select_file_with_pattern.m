function file_list_out = select_file_with_pattern(file_list, pattern_name)

% select_file_with_pattern returns list of files 
% that match a list of patterns (ANY of them).
%
% USAGE:
% file_list_out = select_file_with_pattern(file_list, pattern_name);

fn = size(file_list, 1);
if ~iscell(pattern_name)
    pattern_name = {pattern_name};
end

leave = logical(zeros(fn,1)); %#ok<LOGL>

for f = 1:fn
    patterns = file_list{f,2};
    
    pats = logical(zeros(size(pattern_name))); %#ok<LOGL>
    if isstruct(patterns)
        flds = fields(patterns);
        
        for pat = 1:length(pattern_name)
            isit = sum(strcmp(pattern_name{pat}, flds));
            
            if isit && ~isempty(file_list{f,2}.(pattern_name{pat}))
                pats(pat) = true;
            else
                pats(pat) = false;
            end
        end
        
        % option ANY
        if sum(pats) > 0
            leave(f) = true;
        end
    end
end

file_list_out = [file_list(leave,1), file_list(leave,2)];