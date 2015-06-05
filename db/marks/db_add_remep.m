function ICAw = db_add_remep(ICAw, r, ep_rem)

% db_add_remep() function allows for adding
% additional removals to the ICAw structure database
% 
% ICAw = db_add_remep(ICAw, r, rem_ep)
% Where ICAw is the ICAw structure, r is
% the record index to update and rem_ep is
% a 1 by N vector with epoch indices to remove

% ! WARNING ! db_add_remep does not consider pre and post

% CONSIDER - one high-level function for marks management
%          - multiple low-level functions used by it
%          - now there are many different functions for this
%            and it gets messy

% create vector with epoch indices:
eps = 1:max([max(ICAw(r).reject.all), max(ep_rem)])+1;
% remove already removed indices:
eps(ICAw(r).reject.all) = [];
% check whether its not too short
diflen = max(ep_rem) - length(eps);
if diflen > 0
    eps(end+1:end+diflen) = eps(end)+1:eps(end)+diflen;
end
% looking for epoch nums in eps:
addrem = eps(ep_rem);
% updating ICAw removed filed:
ICAw(r).reject.all = sort([ICAw(r).reject.all, addrem]);