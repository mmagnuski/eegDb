function [isICAw, moreinfo] = ICAw_isbase(somevar)

% PARTIALHELPINFO
% determines whether given variable is 
% an ICAw structure


% is structure
if ~isstruct(somevar)
    isICAw = false;
    moreinfo.struct = false;
    return
end

moreinfo.struct = true;

% has it got the most basic fields?

% CONSIDER - are all these fields necessary
%            for a structure to be an ICAw?
moreinfo.needs_fields = {'filename'; 'filepath'; ...
    'badchan'; 'filter'; 'prerej'; 'postrej'; ...
    'removed'; 'icaweights';...
    'icasphere'; 'icawinv'; 'icachansind'; 'notes';...
    'userrem'};

% if not all fields are present then return
% probability 
flds = fields(somevar);
moreinfo.has_fields = false(size(moreinfo.needs_fields));

for f = 1:length(moreinfo.needs_fields)
    moreinfo.has_fields(f) = sum(...
        strcmp(moreinfo.needs_fields{f}, ...
        flds)) > 0;
end

moreinfo.prob = mean(moreinfo.has_fields);
isICAw = isequal(moreinfo.prob, 1);

% CONSIDER
% series of checks
% 1.fields that both ICAw and EEG have:
% moreinfo.needs_fields = {'filename'; 'filepath'; ...
%     'icaweights'; 'icasphere'; 'icawinv'; ...
%         'icachansind'; 'notes'; 'userrem'};


% CONSIDER
% should the probability be boosted
% by looking at other fields ?
