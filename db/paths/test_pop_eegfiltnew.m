function test_pop_eegfiltnew()

% persistent isfilt

% if isempty(isfilt)
    isfilt = ~isempty(which('pop_eegfiltnew'));
% end

if ~isfilt
    % add filtering
    
    % get eeglab path
    eegpth = fileparts(which('eeglab.m'));
    
    % should be in relevant plugin
    lst = dir(fullfile(eegpth, 'plugins'));
    lst = lst([lst.isdir]); % only directories
    
    % looking for firfilt
    isplug = ~cellfun(@(x) isempty(strfind(x, 'firfilt')), {lst.name});
    
    if any(isplug)
        isplug  = find(isplug);
        isplug = isplug(1); % only first one taken - CHANGE maybe
        addpath(fullfile(eegpth, 'plugins', lst(isplug).name));
        isfilt = true;
    end
end