function fldch = simplify_fldch(fldch)

% !! [ ] this function does not work with
%        fldch without subfields !!
% function that simplifies fldch
% ie. leaves only information on things that exist
% works on output from db_checkfields

subf = false;
if isfield(fldch, 'subfields')
    subf = true;
end

% CHANGE
% take only fields that have subfields
% that is used by db_applyrej, but may
% not be usefulmore general
fldch.fields = fldch.fields(fldch.fsubf);
% this may be more generally applicable:
% fldch.fields = fldch.fields(fldch.fnonempt);

if subf
    fldch.subfields = fldch.subfields(fldch.fsubf);
    fldch.subfnonempt = fldch.subfnonempt(fldch.fsubf);
end

% remove unnecessary fields
% CHANGE - maybe later if we use the more general
% option - then fsubf may be used later...
fldch = rmfield(fldch, {'fpres', 'fnonempt', 'fsubf'});

if subf
% killing fields that either:
%   - do not have any subfields (CHANGE - to more general)
%   CHANGE the conditions - dependent, multiple conditions
%   are only because I could not figure out why they are not
%   applied - turned out kill vector was not used to prune fldch
kill = false(size(fldch.fields));
for f = 1:length(fldch.subfnonempt)
    if sum(fldch.subfnonempt{f}) == 0 || ...
            isempty(fldch.subfnonempt{f}) ||...
            isempty(fldch.subfields{f})
        kill(f) = true;
        continue
    end
    
    if ~kill(f)
    killin = false(size(fldch.subfields{f}));
    for fi = 1:length(fldch.subfnonempt)
        if ~(fldch.subfnonempt{f}(fi))
            killin(fi) = true;
        end
    end
    fldch.subfields{f}(killin) = [];
    end
end

% killing unnecessary:
fldch.fields(kill) = [];
fldch.subfields(kill) = [];
fldch.subfnonempt(kill) = [];
end