function ICAw = ICAw_addrej(ICAw, r, rej)

% ICAw = ICAw_addrej(ICAw, r, rej)
% function that adds rejection info to ICAw database
% this is different from changing 'userrem' or 'autorem'
% fields - the rejections added by ICAw_addrej are final
% (or accepted in other words)
%
% FIXHELPINFO

% TODOs:
% [ ] compare with ICAw_add_remep
% [ ] add 'collapse' option?
% [ ] what to do with userrem & autorem if we collapse?
% [ ] governing adding and overwriting:
%       overwrite = false;
% 
%           if nargin > 3
%               opts = {'overwrite'

f = ICAw_checkfields(ICAw, r, {'prerej',...
    'postrej', 'removed'});
rej = unique(rej);


% if no prerej and no removed
if ~f.fnonempt(1) && ~f.fnonempt(3)
    ICAw(r).removed = rej;
    ICAw(r).postrej = rej;
    
    % ADD - apply segmenting structure?
    return
end

if ~f.fnonempt(1) && f.fnonempt(3)
    % CHANGE - instead of overwriting?
    ICAw(r).removed = rej;
    ICAw(r).postrej = rej;
    
    return
end

if f.fnonempt(1)
    prej = ICAw(r).prerej;
    spared = prej(end) - length(prej);
    
    if ~isempty(rej)
        tooshort = rej(end) - spared;
    end
    
    if isempty(rej) || tooshort < 0
        tooshort = 0;
    end
    
    prewin = 1:prej(end)+tooshort;
    postwin = prewin;
    postwin(prej) = [];
    addrem = postwin(rej);
    
    ICAw(r).postrej = rej;
    ICAw(r).removed = union(prej, addrem);
end
    