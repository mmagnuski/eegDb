% ICA databse
% fields:
% filename        -  the name of the file
% subject         -  participant's ID
% filepath        -  path to the file
% filter          -  filtering options used when using onesec epoch
% winlen          -  window length used (or epoch length)
% epoch_events    -  'X', 'dummy' or cell matrix of events
% epoch_limits    -  in the dummy/X case its: [0 winlen]
% icaweights      -
% icaphere        -  
% icawinv         -  
% removed         -  all removed epochs/windows
% prerej          -  windows removed before inspection
%                    (for example - based on distance from
%                     defined events using onesecepoch)
% postrej         -  rejected by visual inspection or some
%                    automated procedure
% reref           - not used, should delete probably
% datainfo        - ref: reference channel(s) number(s)
%                   refname: (a string ie. 'linked_mastoids')
%                   filtered: [lowpass highpass] if data has
%                             been already filtered
%                   cleanline: if cleanlined was used (logical)
% notes           - from using MZwin_reject for example
% usecleanline    - if there's a need to use cleanline (logical)
% badchan         - list of bad channels to remove
% expBEFIN        - latency of the begining of exp (Sternberg)
% comments        - comments about newICAw fields (optional)
% onesecepoch     - if onesecepoch was used (logical) needed for
%                   recoverEEG