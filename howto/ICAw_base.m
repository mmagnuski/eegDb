% ICA databse
% TODO:
% [ ] update to current format
%
% == necessary fields:
% filename        -  the name of the file
% filepath        -  path to the file
% datainfo        -  structure with subfields:
%   .ref          -  indices of reference electrodes (or 'avg')
%   .ref_name     -  (optional) name of the reference (ex. 'linked
%                     mastoids')
%   .filtered     -  filtering that was already done on the data (for
%                    example [1 0] or [] if no filtering was performed)
%   .cleanline    -  whether CleanLine was run on the data
%   .chanlocs     -  copied from EEG.chanlocs - labels and locations of
%                    electrodes
% filter          -  filtering options used
%
% epoch_events    -  event name or cell matrix of events
% epoch_limits    -  limits to epoch with
%
% onesecepoch     -  if present and non-empty, indicates that the data has
%                    to be cut into consecutive windows
%
% icaweights      -
% icaphere        -  
% icawinv         -  
%
% removed         -  all removed epochs/windows
% prerej          -  windows removed before inspection
%                    (for example - based on distance from
%                     defined events)
% postrej         -  rejected by visual inspection or some
%                    automated procedure