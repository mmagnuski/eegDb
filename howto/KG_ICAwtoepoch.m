for r = 1:length(ICAw)
    ld = load([ICAw(r).filepath, ICAw(r).filename], '-mat');
    EEG = ld.EEG;
    tps = unique({EEG.event.type});
    isit = find(strcmp('cueDOUBLE', tps));
    if ~isempty(isit)
        ICAw(r).epoch_events = event_types_orig;
    %else
     %   ICAw(r).epoch_events = event_types;
    end
    ICAw(r).epoch_limits = [-0.5, 0.5];
    ICAw(r).onesecepoch = [];
    ICAw(r).prerej = [];
    ICAw(r).postrej = [];
    ICAw(r).removed = [];
    
    try
    fld = ICAw_checkfields(ICAw(r).userrem, 1, [], 'ignore', {'color', 'name'});
    for f = 1:length(fld.fields)
        ICAw(r).userrem.(fld.fields{f}) = [];
    end
    catch
        keyboard
    end
end