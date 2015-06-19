function replot_topo(topocache, compN, axh)

% NOHELPINFO

% 2015a seems to have problems with setting 
% ContourMatrix of Contour

persistent is2014b
if isempty(is2014b)
    v = version('-release');
    v_year = str2num(v(1:4)); %#ok<ST2NM>
    is2014b = v_year > 2014 || ...
        (v_year == 2014 && strcmp(v(5), 'b'));
end

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

allcompN = [topocache.CompNum];
gettopo = allcompN == compN;
topo = topocache(gettopo).Children;

start = size(topo,1);
hnd = zeros(start,1);

% loop through children of the topo:
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
    
    % CHANGE - below structure is transformed to
    %          a cell matrix, this could use struct_unroll
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
    if ~( strcmp(topo{nump, 1}, 'contour') && is2014b )
        hnd(nump) = eval([topo{nump, 1}, '(', addcom,...
            '''Parent'', axh, command{:});']);
    else
        % make sure we do not set ContourMatrix
        cmat = strcmp('ContourMatrix', command);
        if any(cmat)
            cmat_ind = find(cmat);
            command(cmat_ind:cmat_ind+1) = [];
        end

        [~, hnd(nump)] = eval([topo{nump, 1}, '(', addcom,...
            '''Parent'', axh, command{:});']);
    end
end

% transport color limits
set(axh, 'CLim', topocache(gettopo).Info.CLim);

% temp fix - set colormap
% (should be modifiable)
colormap('jet');

% set XLim and YLim if not equal
fld = {'XLim', 'YLim'};
for f = 1:length(fld)
    val = topocache(gettopo).Info.(fld{f});
    if ~isequal(val, get(axh, fld{f}))
        set(axh, fld{f}, val);
    end
end
if is2014b
    set(axh, 'Visible', 'off');
end