function ICAw = db_copybase(ICAw, opt, varargin)

% db_copybase() allows to copy (with optional changes)
% whole ICAw database. db_copybase() can also be used
% to add fields with an identical value for all database
% records.
% 
% Usage 1: copying database with changes
%     ICAw2 = db_copybase(ICAw, opt)
% where:
% ICAw  - ICAw database
% opt   - a structure informing about requested changes
%         to the original ICAw. (see example 1)
%
% Usage 2: copying fields between databases
%     ICAw = db_copybase(ICAw, opt, ICAw2)
% where:
% ICAw  - structure to copy fields to
% opt   - defines which fields to copy
%         if a field is present in opt and empty
%         it is copied from the other database
%         if the field is present in opt but has
%         some content then this content is copied
%         rather than the content of the other data-
%         base's field. (see example 2)
% ICAw2 - structure to copy fields from
% 
% ===EXAMPLES===
%    Example 1:
%        if one wants to change ICAw to perform
%        epoching with respect to certain event
%        (lets call it 'kaboom') in certain time-
%        range (-1 - 2 seconds) such change can 
%        be done by:
%            opt.epoch_events = 'kaboom';
%            opt.epoch_limits = [-1 2];
%            ICAw = db_copybase(ICAw, opt);
%    Example 2:
%        if one wants to change ICAw by copying some
%        fields from another database ('ica_remove' 
%        and 'badchan') and setting some other fields
%        ('filter') to a specific value ([2 45]):
%                opt.ica_remove = [];
%                opt.badchan = [];
%                opt.filter = [2 45];
%                ICAw = db_copybase(ICAw, opt, ICAw2);



fld = fieldnames(opt);
secondbase = false;

if nargin > 2
    ICAw2 = varargin{1};
    secondbase = true;
end


for f = 1:length(fld)
    % iterate through database records and change field:
    for r = 1:length(ICAw)
        if ~secondbase || ~isempty(opt.(fld{f}))
            ICAw(r).(fld{f}) = opt.(fld{f});
        else
            % look for the same filename in other database
            [~, ans_adr] = db_checkbase(ICAw2, ICAw(r), 'silent');
            if ~isempty(ans_adr) && length(ans_adr{1}) == 1
                ICAw(r).(fld{f}) = ICAw2(ans_adr{1}).(fld{f});
            end
        end
            
    end
end

% sorting fields
ICAw = db_sorter(ICAw);