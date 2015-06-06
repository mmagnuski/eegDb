function db = db_clearica(db, r)

% db = db_clearica(db, r)
%
% removes ica info from a given record
% (both in the active 'front' and the
% current version)
%
% [NEWFUN]
% date created: 2014-01-19
%

ICAfields = {'icachansind', 'icasphere',...
    'icaweights', 'icawinv', 'remove',...
    'ifremove', 'desc'};

for f = 1:length(ICAfields)
    db(r).ICA.(ICAfields{f}) = [];
end


% also - remove from the version:
if femp(db(r), 'versions') && femp(db(r), 'current')
	% get current version
	c_ver = db(r).versions.current;

	% remove fields form current version
	for f = 1:length(ICAfields)
	    if femp(db(r).versions.(c_ver).ICA, ICAfields{f})
	        % die, field!
	        db(r).versions.(c_ver).ICA.(ICAfields{f}) = [];
	    end
	end
end