function [epochstruct, epochtype, dtinf] = eegDb_getepoching(eegDb)

% FIXHELPINFO
% `epochstruct` - structure with relevant fields describing the epoching
% `epochtype`   - type of epoching (0 - no epoching, 1 - consecutive
%                 windows, 2 - event-locked epochs)
% `dtinf`       - whether epoching info was found in datainfo


dtinf = false;
epochstruct = struct();

% check if epoching info is in epoch field
epochtype = eegDb_whatepoch(eegDb);

% if not in epoch field - check datainfo.epoch
if epochtype == 0
    % check datainfo
    epochtype = eegDb_whatepoch(eegDb, true);
    dtinf = true;
end

% give back structure of fields describing the epoching
if epochtype > 0
    if dtinf
        epochstruct = eegDb.datainfo.epoch;
    else
        epochstruct = eegDb.epoch;
    end

    % give default winlen if not defined
    if epochtype == 1 && ~femp(epochstruct, 'winlen')
    	epochstruct.winlen = 1;
    end
end
