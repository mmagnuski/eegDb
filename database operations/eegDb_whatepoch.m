function whatepoching = eegDb_whatepoch(eegDb, testdatainfo)

% EEGDB_WHATEPOCH checks what kind of epoching a given database entry
% has defined.
%
% whatepoching = eegDb_whatepoch(eegDb)
%
% `testdatainfo` -  *logical*, tells eegDb_whatepoch whether
%                   to check eegDb.datainfo.epoch
% `whatepoching` -  *integer*, signals what type of epoching
%                   the eegDb entry has:
%                   0 - no epoching defined
%                   1 - consecutive windows, not locked to events
%                   2 - event-locked epochs
%                   3 - (possibly in the future) when epochs are segmented
%                       (event-locked epochs cut into consec. windows)
%
% see also: eegDb_buildbase

% ADD checks for many entries

if ~exist('testdatainfo', 'var')
    testdatainfo = false;
end

% change stuff if we need to check datainfo
if testdatainfo
    if femp(eegDb.datainfo, 'epoch')
        eegDb.epoch = eegDb.datainfo.epoch;
    else
        whatepoching = 0;
        return
    end
end

whatepoching = 0;
% test if locked value is present and what it says:
if femp(eegDb.epoch, 'locked')
    whatepoching = eegDb.epoch.locked + 1;
end

% additional tests if locked is empty or nor there:
if whatepoching == 0
    f1 = {'winlen', 'distance'};
    f2 = {'events', 'limits'};
    epochfields = fields(eegDb.epoch);
    
    t1 = cellfun(@(x) sum(strcmp(x, epochfields)), f1);
    t2 = cellfun(@(x) sum(strcmp(x, epochfields)), f2);
    
    an = [any(t1), any(t2)];
    
    if an(1) && ~an(2)
        whatepoching = 1;
    elseif ~an(1) && an(2)
        whatepoching = 2;
    elseif ~an(1) && ~an(2)
        whatepoching = 0;
    else
        % some strage mix of epoching
        whatepoching = 3;
    end
end