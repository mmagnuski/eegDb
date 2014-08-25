function ICAw = ICAw_clearica(ICAw, r)

% ICAw = ICAw_clearica(ICAw, r)
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
c_ver = ICAw(r).versions.current;

for f = 1:length(ICAfields)
    if femp(ICAw(r).versions.(c_ver).ICA, ICAfields{f})
        ICAw(r).versions.(c_ver).ICA.(ICAfields{f}) = [];
    end
end