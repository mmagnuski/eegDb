function outstr = strsep(str, separ)

% strsep(str, separ) separates a string str
% into cell matrix of strings using separ as
% separator
%
% This is just modified strsplit by Levente Hunyadi
% with added function of strjoin if input is cell matrix

if ~iscell(str)
    % get indices of separ
    ind = strfind(str, separ);
    outstr = cell(length(ind)+1, 1);
    ind = [0 ind numel(str)+1];
    
    for k = 2 : numel(ind)
        outstr{k-1} = str(ind(k-1)+1:ind(k)-1);
    end
    
    % delete empty?
else
    lens = cellfun(@length, str);
    % cumulative length (including added spepars)
    cumul = lens;
    
    % building 'cumul' - end inds
    for c = 2:length(cumul) 
        cumul(c) = sum(cumul(c-1:c)) + 1; 
    end
    
    % adding beg inds to cumul:
    tocumul = ones(size(cumul));
    
    % building 'tocumul' - beg inds
    for c = 2:length(tocumul) 
        tocumul(c) = cumul(c-1) + 2; 
    end
    
    cumul = [tocumul(:), cumul(:)];
    
    outstr = repmat(separ, 1, cumul(end,2));
    
    for d = 1:size(cumul, 1)
        outstr(cumul(d, 1):cumul(d, 2)) = str{d};
    end
end