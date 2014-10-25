function replot_topo(EEG, compN, axh)

% kill axes children:
killch = get(axh, 'Children');
delete(killch);

ommit_fields = {'Type', 'Parent', 'Annotation',...
    'BeingDeleted', 'XDataMode', 'Children'};

% invalid in hggroup (not used yet):
% hg_ommit = {'ContourMatrix', 'Fill', 'LabelSpacing',...
% 	'LevelList', 'LevelListMode', 'LevelStep',...
%     'LevelStepMode', 'LineColor', 'LineStyle',...
%     'LineWidth', 'ShowText' , 'TextList', ...
%     'TextListMode', 'TextStep', 'TextStepMode',...
%     'XData', 'XDataMode', 'YData', 'YDataMode', ...
%     'ZData', 'ZDataMode'}; %

allcompN = [EEG.etc.topocache.CompNum];
gettopo = allcompN == compN;
topo = EEG.etc.topocache(gettopo).Children;

start = size(topo,1);
hnd = zeros(start,1);

for nump = start:-1:1
    
    % get fields:
    flds = fields(topo{nump, 3});
    flds = setdiff(flds, ommit_fields);
    
    % addcom is used for hggroup
    addcom = '';
    
    % special case - fill addcom when
    % hggroup is encountered
    if strcmp(topo{nump,1}, 'hggroup')
        
        % ommit some other fields:
        % flds = setdiff(flds, hg_ommit);
        
        % hggroup_children = hnd(cell2mat(topo(:,2)) ...
        %     == nump);
        % keyboard
        % addcom = '''Children'', hggroup_children, ';
        continue
    end
    
    command = cell(1,length(flds)*2);
    stp = 1;
    
    for f = 1:length(flds)
        if ~isempty(topo{nump, 3}.(flds{f}))
            command{stp} = flds{f};
            command{stp + 1} = topo{nump, 3}.(flds{f});
            stp = stp + 2;
        end
    end
    
    % trim command
    command(stp:end) = []; %#ok<NASGU>
    
    % execute command
    hnd(nump) = eval([topo{nump, 1}, '(', addcom,...
        '''Parent'', axh, command{:});']);
end

% transport color limits
set(axh, 'CLim', EEG.etc.topocache(gettopo).Info.CLim);