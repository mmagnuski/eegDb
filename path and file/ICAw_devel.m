function ICAw_devel(opt)

% ICAw_devel(opt);
% function for switching between usage and development
% of ICAw.
%
% update
% ------
% Currently, because things moved to GitHub - one can
% switch between master branch and some development 
% branches with 'git checkout'. Nevertheless Dropbox
% repo will be maintained for some time (cloned from
% master branch at GitHub) so this may still come in 
% handy (for example for switching between Dropbox and
% Git repositories).
% 
% opt:
% 'on' - switches to development settings
%           (different path settings that is)
% 'off'  - switches to user settings
% 
% To switch to developer-mode one has to:
% ICAw_devel('devel');
% but before relevant paths have to be set within the 
% function (these are tested for existance and added/
% removed so they should work for whoever uses the
% function). Good luck developing ICAw!
%
% Soon, 'commit' option will become available, used
% to release well-tested versions of ICAw


% ==================
% ADD path if DEVEL:
% add paths when in devel (remove when in user)
% these paths are checked for existence and added
% when going to development mode
addp{1} = 'D:\DATA\eegDb\';
addp{2} = 'D:\DATA\eegDb\eeglabsubst\';
%
% <=== add your addp here

% ==================
% REMove path if DEVEL:
% remove paths when in devel (add when in user)
% these paths are checked for existence and added
% when going to user mode
rmp{1} = ['D:\Dropbox\MATLAB scripts & projects\',...
    'EEGlab scripts\ICAw\'];
rmp{2} = ['D:\Dropbox\MATLAB scripts & projects\',...
    'EEGlab scripts\ICAw\tests\'];
%
% <=== add your rmp here

add = [];
rem = [];
% check option
switch opt
    case 'on'
        add = addp;
        cd(addp{1});
        rem = rmp;
        
    case 'off'
        add = rmp;
        rem = addp;
end

% add paths
for pt = add
    if isdir(pt{1})
        addpath(pt{1});
    end
end

% remove paths
for pt = rem
    if isdir(pt{1})
        rmpath(pt{1});
    end
end