function ICAw = db_clearica(ICAw, r)

% ICAw = db_clearica(ICAw, r)
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
    ICAw(r).ICA.(ICAfields{f}) = [];
end


% also - remove from the version:
if femp(ICAw(r), 'versions') && femp(ICAw(r), 'current')
	% get current version
	c_ver = ICAw(r).versions.current;

	% remove fields form current version
	for f = 1:length(ICAfields)
	    if femp(ICAw(r).versions.(c_ver).ICA, ICAfields{f})
	        % die, field!
	        ICAw(r).versions.(c_ver).ICA.(ICAfields{f}) = [];
	    end
	end
end