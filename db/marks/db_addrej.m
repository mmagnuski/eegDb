function db = db_addrej(db, r, rej)

% FIXHELPINFO - description is vague
% db = db_addrej(db, r, rej)
% function that adds rejection info to db database
% this is different from changing mark fields
% the rejections added by db_addrej are final
% (or accepted in other words)
%

% TODOs:
% [ ] compare with db_add_remep
% [ ] add 'collapse' option?
% [ ] what to do with userrem & autorem if we collapse?
%     no longer any userrem or autorem...
% [ ] governing adding and overwriting:
%       overwrite = false;
%
%           if nargin > 3
%               opts = {'overwrite'

f = db_checkfields(db(r).reject, 1, {'pre', 'post', 'all'});
rej = unique(rej);


% if no prerej and no removed
if ~f.fnonempt(1) && ~f.fnonempt(3)
    db(r).reject.all = rej;
    db(r).reject.post = rej;

    % ADD - apply segmenting structure?
    return
end

% CHANGE - previous case has the same code!!
if ~f.fnonempt(1) && f.fnonempt(3)
    % CHANGE - instead of overwriting?
    db(r).reject.all = rej;
    db(r).reject.post = rej;
    % like rej = unique([db(r).reject.all, rej])
    return
end

% if pre is present:
if f.fnonempt(1)
    prej = db(r).reject.pre;
    spared = prej(end) - length(prej);

    if ~isempty(rej)
        tooshort = rej(end) - spared;
    end

    if isempty(rej) || tooshort < 0
        tooshort = 0;
    end

    prewin = 1:prej(end) + tooshort;
    postwin = prewin;
    postwin(prej) = [];
    addrem = postwin(rej);

    db(r).reject.post = rej;
    db(r).reject.all = union(prej, addrem);
end
