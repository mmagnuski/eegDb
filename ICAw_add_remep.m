function ICAw = ICAw_add_remep(ICAw, r, ep_rem)

% ICAw_add_remep() function allows for adding
% additiona removals to the ICAw structure database
% 
% ICAw = ICAw_add_remep(ICAw, r, rem_ep)
% Where ICAw is the ICAw structure, r is
% register index to update and rem_ep is
% a 1 by N vector with info on rejections

% create vector with epoch indices:
eps = 1:max([max(ICAw(r).removed), max(ep_rem)])+1;
% remove already removed indices:
eps(ICAw(r).removed) = [];
% check whether its not too short
diflen = max(ep_rem) - length(eps);
if diflen > 0
    eps(end+1:end+diflen) = eps(end)+1:eps(end)+diflen;
end
% looking for epoch nums in eps:
addrem = eps(ep_rem);
% updating ICAw removed filed:
ICAw(r).removed = sort([ICAw(r).removed, addrem]);