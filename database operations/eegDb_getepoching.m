function [epochstruct, epochtype, dtinf] = eegDb_getepoching(eegDb)

% FIXHELPINFO
% `epochstruct` - structure with relevant fields describing the epoching
% `epochtype`   - type of epoching (0 - no epoching, 1 - consecutive
%                 windows, 2 - event-locked epochs)
% `dtinf`       - whether epoching info was found in datainfo


dtinf = false;
epochstruct = struct();

epochtype = eegDb_whatepoch(eegDb);

if epochtype == 0
    % check datainfo
    epochtype = eegDb_whatepoch(eegDb, true);
    dtinf = true;
end

if epochtype > 0
    if dtinf
        epochstruct = eegDb.datainfo.epoch;
    else
        epochstruct = eegDb.epoch;
    end
end
