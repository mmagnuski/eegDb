function [outputs, handles] = maskitsweet(matri, mask, varargin)
% maskitsweet() allows to image a 2D matrix with transparency masking.
% this is most useful for time-frequency plots where nonsignificant
% values are 'shaded'.
%
% Usage:
% [output, handles] = maskitsweet(matr, mask);
% [output, handles] = maskitsweet(matr, mask, 'key', value, ...)
%
% maskitsweet transforms input 2D matrix to RGB according to a colormap
% - this allows for more control over mask color. If you think that
% it causes you problems add 'NoRGB' to maskitsweet keys.
%
% plotting is not very fast, but should be below 1 second
% (if you have ideas on how to improve maskitsweet with respect
%  to speed with preserving its functionality - let me know!)
%
% ===================
%   MANDATORY INPUT
% ===================
% matr      - the matrix you need to plot (ERSP results for example)
% mask      - boolean matrix of the same size as matr denoting
%             significance
%             (true - significant; false - not significant)
%             mask can also be given as a matrix of p values
%             - then a significance treshold of 0.05 is assumed
%               unless the user provided another calue with the
%               'p' key.
%
% ====================
% OPTIONAL PARAMETERS:
% ====================
% 'boot'       - if you do not have a boolean matrix, but an erspboot
%                matrix (or itcboot etc.) returned by EEGlab, then this
%                key allows you to pass this boot matrix. Remember not to
%                omit the second argument of the function (mask). You can
%                for example pass an empty array ([]) as mask.
%                Example:
%                    maskitsweet(ersp, [], 'boot', erspboot);
% 'p'          - if you have provided maskitsweet with a p-value matrix
%                you can define significance treshold with this key, like:
%                    maskitsweet(ersp, pvals, 'p', 0.01);
%                if p is a vector then multiple levels of shading will
%                be present, for example:
%                    maskitsweet(ersp, pvals, 'p', [0.05, 0.01]
%
% LINE OPTIONS:
% 'lines'      - additionally surround significant areas with lines
%     'LineColor'  - color of these lines (default: black) in [r g b]
%                    max - 1, min - 0 (which means that 0.4 value can
%                    be interpreted as 0.4 * 255).
%                    Example:
%                        maskitsweet(ersp, mask, 'lines', 'LineColor',...
%                            [0.8, 0.2, 0.1]);
%     'LineWidth'  - width of these lines (default: 1)
%
% MASKING OPTIONS:
% 'nosig'      - level of transparency for nonsignificant values
%                max - 1(nontransparent); min - 0(completely transparent)
% 'MaskColor'  - color of the mask (default: [200 200 200]) in [r g b]
%                max - 255, min - 0 (which means that it is
%                the 'normal' RGB)
% 'NoTransp'   - this option lets you escape potential problems with
%                transparency if you experience some. If 'NoTransp' is
%                chosen masking is done by taking a weighted
%                sum: (1-nosig)*pixel_color + nosig*MaskColor for
%                all masked pixels. This should give identical graphical
%                results to setting transparency, only the mechanism is
%                different. This is possible only in RGB mode
%
% LABELING OPTIONS:
% 'Time'       - full vector of time-samples (used to label the x-axis)
%                if time-samples vector contains both negative and posi-
%                tive values ticks will be centered around the time-
%                sample closest to zero
%     'NumTim'     - if time vector is given, this key allows for passing
%                    the preferred number of time ticks. (default: 8)
%     'JumpTime'   - starting from zero or first time-sample (see Time)
%                    JumpTime defines the size (in time units) of tick-step
%                    (if set overrides NumTim)
%     'ForceZero'  - (followed by boolean value) if set to true the time
%                    ticks will be forced to have rounded values
%                    if set to false - they will retain their true value
%                    default: true
%     'ZeroLine'   - (followed by a boolean value) if set to false
%                    maskitsweet doesn't plot a black vertical line
%                    around zero-sample (LineWidth - 2)
%                    (default: true)
%                    if you want to change the appearance of the line
%                    you can find its handle in handles.ZeroLine
% 'Freq'       - full vector of frequency-sample values (used to label
%                the y-axis)
%     'NumFreq'    - if frequency vector is given, this key allows for
%                    passing the preferred number of frequency ticks
%     'JumpFreq'   - JumpFreq defines the size (in frequency units) of
%                    frequency tick-step (if set overrides NumFreq)
%     'ForceFreq'  - (followed by boolean value) if set to true the
%                    frequency ticks will be forced to have rounded values
%                    if set to false - they will retain their true value
%                    default: false
%
% COLOR MAPPING OPTIONS:
% 'CMap'       - colormap that you want to use. Can be a string speci-
%                fying the colormap or the colormap itself (n by 3 matrix)
%                (default: 'jet(128)')
%                Example:
%                    maskitsweet(ersp, mask, 'CMap', 'jet(256)');
% 'MapCent'    - the value that should be mapped to the middle of the
%                colormap. Can be set to [] if we don't want to map
%                any specific value to the middle. If set to [] then
%                MapCent is just the middle between CMin and CMax
%                (default: 0)
% 'CMin'       - minimum value of the color scale
%                    (default: min(min(matri)))
% 'CMax'       - maximum value of the color scale
%                    (default: max(max(matri)))
% 'MapEdge'    - how CMin and CMax should be mapped to edges of the
%                colormap. In other words: how value limits of the
%                color mapping should be set:
%                'max'  - limits are set to MapCent-max and MapCent+max
%                         of abs([CMin, CMax])
%                'min'  - as above but -min and +min
%                'mean' - as above but -mean and +mean
%                'lin'  - if MapCent is set then CMap is trimmed
%                         to map MapCent to the centre of the
%                         colormap and retain the CMin and CMax;
%                         if MapCent is empty then 'lin' results
%                         in ordinary linear scale from CMin to
%                         CMax
%                (default: 'mean')
%                Examples:
%                  > let's assume that you want to plot ITC so all
%                    values of matr are positive and between 0 and 1.
%                    Therefore you want to have a linear scaling all
%                    the way from CMin = 0 to CMax = 1. You type:
%                        maskitsweet(matr, map, 'CMin', 0, 'CMax', 1,...
%                            'MapCent', [], 'MapEdge', 'lin', 'CMap',...
%                            'hot(256)');
%                    (in the example above the colormap is set to hot
%                    because all values of matr are positive and
%                    we don't want any bluish colors in our plot)
%
%                  > if you want to have CMin and CMax to be set auto-
%                    matically but not symmetrical (-CMax ~= CMin) and
%                    have zero still mapped to the centre of the
%                    colormap:
%                        maskitsweet(matr, map, 'MapCent', 0,...
%                            'MapEdge', 'lin');
%
% 'PlotScale'  - allows for adding colorscale at the side of the image.
%                The colorscale is automatically labeled, but handle to it
%                is returned if the user wants to set it his way.
% 'NoRGB'      - this informs maskitsweet that you don't want to have your
%                matrix transformed to RGB. Masking is then done with
%                single value, corresponding to the middle of the colormap
%                unless you define MaskColor as a single value.
%                NonRGB masking gives you less options with respect to the
%                mask color (it has to be a color present in the colormap)
%                but may sometimes be an easier solution
%
% FIGURE OPTIONS:
% 'NoFig'      - this informs maskitsweet that you want to plot in the
%                current figure, without creating a new one
%     'FigH'       - this key allows for passing a specific figure handle
%                    instead of the one that is globally current
%     'AxH'        - this key allows for passing a specific axis handle
%                    to plot the outcome in
%
% ==============
%     OUTPUT
% ==============
% output       - output structure with following fields:
%        .RGBmatrix  - your input matrix, but scaled to the current
%                      colormap and transformed to RGB (present in out-
%                      put only if you did NOT set 'NoRGB')
%        .fullmask   - full mask, in RGB but without transparancy set
%                      (if you set 'NoRGB', then the mask is not in RGB)
%        .alphamask  - transparency data for the fullmask(on the basis
%                      of your mask input)
%        .colormap   - colormap used in translation of the image to RGB
%        .cmaplen    - length of the colormap: size(outputs.colormap, 1)
%        .mapping    - how values of the input matrix were mapped to
%                      colors of the colormap. If a matrix value is
%                      >= mapping(n) and < mapping(n+1) it is mapped
%                      to colormap(n,:). The only exception is the max
%                      value which belongs to colormap(end,:)
%
% handles      - handles structure with following fields:
%        .figure    - handle to the main figure
%        .axis      - handle to the axis of the figure
%        .image     - handle to the image
%        .mask      - handle to the mask
%        .lines     - handles to all the lines
%        .ZeroLine  - handle to the line denoting zero-sample
%                     (present only if time is labeld and
%                      zero-sample (or close to zero) exists)
%        .colorbar  - handle to the colorbar representing scale
%
%
% coded by Mikolaj Magnuski
% imponderabilion@gmail.com
% april 2013

% TO-DOs:
% ADD:
%      [ ] testing for input type
%          [ ] obligatory input
%          [ ] additional input
%      [ ] if Freq given --> default 'JumpFreq' is
%          [1, 2, 4, 5, 8, 10, 15, 20] - whichever
%          is the first one that fits at least 4
%          times in freqlimits but not more than 10
%      [ ] if Time given --> default 'JumpTime' is
%          [25, 50, 100, 150, 200, 250, 500] - whichever
%          is the first one that fits at least 4
%          times in freqlimits but not more than 12
%      [X] p-values as mask
%      [X] multiple layers...
% FIX:
%      [ ] Scale bug (ShowScale and all ticks are zeros)
%      [ ] plot lines -should be plotted below mask - draw later and
%          move down in children chierarchy?
%      [ ] how to group lines? too many handles to little line
%          segments...
% CHECK:
%      figure behavior
%      [ ] opens a new figure
%      [ ] if you pass a figure handle - doesn't
%      [ ] sometimes does not open when EEGlab GUI
%          figure is open - why?
%      [ ] MapEdge 'lin' seems not to be working that well...
% CONSIDER:
%      [ ] adding nonlinear FreqJump option (?)
%      [ ] nonlinear color mapping? (+)
%      [ ] TimeTick / FreqTick - values where
%          ticks should be
%      [ ] joining line segments into line when no breaks/crooks appear
%      [ ] smooth lines? (a'la contour ?)
%      [ ] interpolation (a'la Hipp, 2011, 2013)

%% defaults
%=scaling=
opt.PlotScale = false;
opt.CMin = []; % scaled to the min of the input matrix
opt.CMax = []; % scaled to the max of the input matrix
opt.CMap = 'jet(150)';
opt.MapEdge = 'mean'; opt.MapCent = 0;
%=masking=
opt.MaskColor = [200 200 200];
opt.nosig = 0.6;
opt.NoRGB = false;
opt.NoTransp = false;
opt.p = [];
%=lines=
opt.lines = false;
opt.LineColor = [0, 0, 0];
opt.LineWidth = 1;
%=labeling=
opt.Time = []; % no time labels
opt.NumTim = min([8, size(matri, 2)]);
opt.JumpTime = []; opt.ForceZero = true;
opt.ZeroLine = true;
opt.Freq = []; % no freq labels
opt.NumFreq = min([8, size(matri, 1)]);
opt.JumpFreq = []; opt.ForceFreq = false;
% init figure handles
opt.handles.figure = [];

% checking if the matrix is real:
if ~isreal(matri)
    matri = abs(matri);
end


%% checking for additional input values:
if nargin > 2
    
    % ==simple mass check==
    % option names:
    names = {'lines', 'p', 'LineColor', 'LineWidth', 'nosig', 'Time', 'Freq',...
        'MaskColor', 'NumTim', 'NumFreq', 'JumpTime', 'JumpFreq',...
        'ForceZero', 'ForceFreq', 'ZeroLine', 'CMin', 'CMax',...
        'PlotScale', 'MapCent', 'MapEdge', 'NoRGB', 'CMap', 'NoTransp'};
    % whether followed by value:
    vals = logical([1, 1, 1, 1, 1, 1, 1,...
        1, 1, 1, 1, 1,...
        1, 1, 1, 1, 1, ...
        0, 1, 1, 0, 1, 0]);
    [opt, delv] = check_maskitsweet_inputs(opt, varargin, names, vals);
    % =============
    
    current_vargin = length(varargin) - delv;
    
    % ==using erspboot to create mask==
    if current_vargin > 0
        adr = find(strcmp('boot',varargin));
        if ~isempty(adr)
            erspboot = varargin{adr+1};
            % allocate mask
            mask = false(size(matri));
            
            % fill mask with values out of
            % erspboot limits
            if size(erspboot,2) == 2
                for frq = 1:size(matri,1)
                    outoflims = matri(frq,:) > erspboot(frq,2)...
                        | matri(frq,:) < erspboot(frq,1);
                    mask(frq, outoflims) = true;
                end
            elseif size(erspboot,2) == 1
                for frq = 1:size(matri,1)
                    outoflims = matri(frq,:) > erspboot(frq);
                    mask(frq, outoflims) = true;
                end
            end
            current_vargin = current_vargin - 2;
            clear bt frq erspboot outoflims
        end
    end
    
    % give back those handles!
    handles = opt.handles;
    
    % ==whether to open a new figure==
    if current_vargin > 0
        adr = sum(strcmp('NoFig',varargin))>0;
        if adr
            handles.figure = gcf;
            current_vargin = current_vargin - 1;
        end
    end
    if current_vargin > 0
        adr = find(strcmp('FigH',varargin));
        if ~isempty(adr)
            handles.figure = varargin{adr + 1};
            current_vargin = current_vargin - 2;
        end
    end
    if current_vargin > 0 && ~isempty(handles.figure)
        adr = find(strcmp('AxH',varargin));
        if ~isempty(adr)
            handles.axis = varargin{adr + 1};
            % current_vargin = current_vargin - 2;
        end
    end
    
end
%  ===end of options scan===

% ==check draw lines==
if ischar(opt.lines)
    opt.lines = true;
end

%  ===checking mask matrix===
if ~islogical(mask)
    maskvals = unique(mask);
    if ~(isequal(maskvals, [0; 1]))
        % checking whether values are in 0-1 range
        if max(maskvals) <= 1 && min(maskvals) >= 0
            if isempty(opt.p)
                opt.p = 0.05;
            end
        else
            % throw an error, haha!
            error(['Unrecognized mask matrix input. The mask ',...
                'matrix has to either be (1) logical, (2) numerical with ',...
                'zeros and ones or (3) numerical with real values ranging ',...
                'from 0 to 1']);
        end
    else
        mask = logical(mask);
        opt.p = [];
    end
else
    opt.p = [];
end

% ===building matrix for (multiple) maskings
if ~isempty(opt.p)
    nummasks = length(opt.p);
    [opt.p, sortee] = sort(opt.p, 'descend');
    
    % ADD and CHANGE: use sortee to sort nosig and lines etc.
    % if they have been passed as vector
    
    % check lines
    if length(opt.lines) < nummasks
        newlines = false(size(opt.p));
        newlines(1:length(opt.lines)) = opt.lines;
        opt.lines = newlines;
        clear newlines
    else
        opt.lines = opt.lines(sortee);
    end
    
    % check nosig
    if length(opt.nosig) < nummasks
        % ADD throw a warning?
        opt.nosig = linspace(0.5, 0.8, nummasks);
    else
        opt.nosig = opt.nosig(sortee);
    end
    
    % CHANGE - think about changing this - do we really need
    % multiple boolean matrices in a cell matrix?
    % for now we do it this way:
    
    newmask = cell(nummasks,1);
    tempp = [1.05, opt.p];
    for i = 1:nummasks
        newmask{i} =  mask >= tempp(i) | mask < tempp(i+1);
    end
    pmask = mask;
    mask = newmask;
    clear newmask i nummasks tempp
else
    mask = {mask};
    opt.lines = opt.lines(1);
end

%  =========================
%% ~~=WELCOME TO THE CODE=~~
%  =========================

% ==creating a value-color mapping==
% 1. create colormap

if isempty(get(0, 'CurrentFigure'))
    handles.figure = figure;
elseif ~exist('handles', 'var')
    handles.figure = gcf; % or new figure?
end

if ischar(opt.CMap)
    CMap = eval([opt.CMap, ';']);
else
    CMap = opt.CMap;
end

% colormap size:
[opt, CMap] = MappingModule(CMap, opt, matri);

if ~opt.NoRGB
    % separate layers of RGB - for ease
    % of processing... separately!:
    matri_rgb = cell(3,1);
    for ly = 1:3
        matri_rgb{ly} = zeros(size(matri));
    end
    
    % ==constructing RGB image out of matrix==
    % for each colorstep:
    
    % first step is all below step two
    adr =  matri < opt.mapping(2);
    for ly = 1:3
        matri_rgb{ly}(adr) = CMap(1,ly);
    end
    
    % middle steps
    for i = 2:length(opt.mapping)-1
        adr = matri >= opt.mapping(i) & matri < opt.mapping(i+1);
        for ly = 1:3
            matri_rgb{ly}(adr) = CMap(i,ly);
        end
    end
    
    % last colormap step is all above
    % include the max value
    i = i + 1;
    adr = matri >= opt.mapping(i);
    for ly = 1:3
        matri_rgb{ly}(adr) = CMap(i,ly);
    end
    clear i adr
    
    % now from cell world to 3 dims:
    matri_realrgb = repmat(zeros(size(matri)), [1, 1, 3]);
    
    for ly = 1:3
        matri_realrgb(:,:,ly) = matri_rgb{ly};
    end
    outputs.RGBmatrix = matri_realrgb;
    clear matri_rgb ly
end
% =====


% =constructing mask=
masking = cell(size(mask));
mask_img = cell(size(mask));

for i = 1:length(mask)
    if ~opt.NoTransp
        if ~opt.NoRGB
            % ==normal RGB mask==
            masking{i} = ones(size(mask{i})) * opt.nosig(i);
            masking{i}(mask{i}) = 0;
            mask_img{i} = uint8(ones(size(mask{i},1), size(mask{i},2),3));
            for ly = 1:3
                % CHANGE : MaskColor should be cell too!
                mask_img{i}(:,:,ly) = mask_img{i}(:,:,ly) * opt.MaskColor(ly);
            end
            clear ly
            % ===============
            
        else
            % ==colormap mask==
            % CHANGE: instead of halfmap use CMap!
            if ~length(opt.MaskColor) == 1
                % colormap mask
                halfmap = round(mapuni/2);
                opt.MaskColor = mapping(halfmap);
                clear halfmap
            end
            
            mask_img{i} = ones(size(mask{i})) * opt.MaskColor;
            masking{i} = ones(size(mask{i})) * opt.nosig(i);
            masking{i}(mask) = 0;
            % ============
        end
    end
end

% setting outputs:
if ~opt.NoTransp
    outputs.mask = mask_img;
    outputs.alphamask = masking;
end
outputs.colormap = CMap;
outputs.cmaplen = opt.MapLen;
outputs.mapping = opt.mapping';


%% ==plotting==
% creating figure and axis handles:
if isempty(handles.figure)
    handles.figure = figure;
end
Children = get(handles.figure, 'Children');
if isempty(Children)
    handles.axis = axes('Parent',handles.figure);
else
    % axis handle from the figure or returned by
    % the user
    ChilType = get(Children, 'Type');
    ChilAxis = find(strcmp('axes', ChilType));
    handles.axis = Children(ChilAxis(end));
end

% activate colormap (this is for colorbar to appear correctly)
colormap(handles.axis, CMap);

% plotting the main part
if ~opt.NoRGB
    % RGB mode
    if opt.NoTransp
        for i = 1:length(mask)
            % transparency simulated by weighted sum (the same as
            % weighted mean in this case - sum of weights is one)
            wholemask = repmat(~mask{i}, [1, 1, 3]);
            onelm = sum(sum(~mask{i}));
            % CHECK: not sure if the following is actually quicker:
            multimask = repmat(opt.MaskColor/255, onelm, 1);
            multimask = multimask(:);
            
            matri_realrgb(wholemask) = (1-opt.nosig(i))*...
                matri_realrgb(wholemask) + opt.nosig(i)*multimask;
            
            outputs.mask = matri_realrgb;
            clear onelm wholemask multimask
        end
        % plotting:
        handles.image = image(matri_realrgb, 'Parent', handles.axis);
    else
        % normal transparency
        handles.image = image(matri_realrgb, 'Parent', handles.axis);
        hold on
        
        % loop across masks
        for i = 1:length(mask)
            handles.mask{i} = image(mask_img{i}, 'Parent', handles.axis);
        end
        hold off
    end
    % handles.axis = gca;
else
    % noRGB mode
    handles.image = imagesc(matri, 'Parent',...
        handles.axis, [opt.CMin, opt.CMax]);
    hold on
    for i = 1:length(mask)
        handles.mask{i} = imagesc(mask_img{i}, 'Parent',...
            handles.axis, [opt.CMin, opt.CMax]);
    end
    hold off
end

% setting YDir to be normal:
set(handles.axis, 'YDir', 'normal');

if ~opt.NoTransp || opt.NoRGB
    % setting transparent masking to the mask:
    % CHANGE/CHECK: after setting Alpha sometime a 'basal tick' appears
    for i = 1:length(mask)
        set(handles.mask{i}, 'AlphaData', masking{i});
    end
end

%% ==adding lines if needed==
% ADD/CHANGE - adapt lines to multiple masks
%              some lines should be below some masks (?)
% as for now it simply draws one line
% per difference in mask matrix
for l = 1:length(opt.lines)
    if opt.lines(l)
        if ~isempty(opt.p)
        mask{l} = pmask < opt.p(l);
        end
        % =go through rows=:
        % create within-row diffs:
        difs = diff(mask{l},1,2) ~= 0;
        % indices of nonzero diffs:
        [indi, indj] = find(difs);
        % transform to i, j indices:
        %[indi, indj] = ind2sub(size(difs), adr);
        % now indices to line coords:
        rowY = [indi - 0.5, indi + 0.5];
        rowX = [indj + 0.5, indj + 0.5];
        % ====
        
        % =go through columns=:
        difs = diff(mask{l},1,1) ~= 0;
        [indi, indj] = find(difs);
        colY = [indi + 0.5, indi + 0.5];
        colX = [indj - 0.5, indj + 0.5];
        % ====
        
        % clear unnecessary (?)
        clear adr difs indi indj
        
        % ==drawing lines==
        % allocate handles vector:
        handles.lines = zeros(size(colX,1) + size(rowX,1), 1);
        % for rows:
        for i = 1:size(rowX,1)
            handles.lines(i) = line(rowX(i,:), rowY(i,:), ...
                'Color', opt.LineColor, 'LineWidth', opt.LineWidth, ...
                'Parent', handles.axis);
        end
        lasti = i;
        clear rowX rowY
        
        % for cols:
        for i = 1:size(colX,1)
            handles.lines(lasti + i) = line(colX(i,:), colY(i,:), ...
                'Color', opt.LineColor, 'LineWidth', opt.LineWidth, ...
                'Parent', handles.axis);
        end
        clear colX colY i lasti
    end
end


%% ==labeling axes if needed==
if ~isempty(opt.Time)
    
    len = length(opt.Time);
    if len ~= size(matri, 2)
        warning(['maskitsweet warns you: length of your time ', ...
            'vector and your matrix size along 2nd dimension ',...
            'are different. Labeling aborted :(']);
    else
        
        if isempty(opt.JumpTime)
            % ==No JumpTime, generating==
            labind = round(linspace(1, len, opt.NumTim+1));
            twofirst = [opt.Time(labind(1)), opt.Time(labind(2))];
            opt.JumpTime = round(abs(diff(twofirst)));
            clear twofirst labind
        end
        
        % ==JumpTime!==
        [labind, forcelabs] = JumpLabs(opt.Time, opt.JumpTime);
        
        if  opt.ForceZero
            labs = forcelabs;
        else
            % labels with precision up to one decimal place:
            labs = round(opt.Time(labind)*10)/10;
        end
        
        % transform to cell of strings:
        labs =  arrayfun(@(x) num2str(x), labs, 'uni', false);
        labs =  regexp(labs, '-?[0-9]+\.?[0-9]*', 'match', 'once');
        
        % setting ticks
        set(handles.axis, 'XTick', labind, 'XTickLabel',...
            labs, 'TickLength', [0.02 0.02], ...
            'TickDir', 'out', 'Layer', 'top', 'Box', 'off');
        
        % plotting ZeroLine
        breakpoint = find(forcelabs == 0);
        if  opt.ZeroLine && ~isempty(breakpoint)
            breakpoint = labind(breakpoint);
            handles.ZeroLine = line([breakpoint, breakpoint], ...
                [0.5, size(matri,1)+0.5], 'Color', [0 0 0], ...
                'LineWidth', 2, 'Parent', handles.axis);
        end
    end
end

if ~isempty(opt.Freq)
    len = length(opt.Freq);
    if len ~= size(matri, 1)
        warning(['maskitsweet warns you: length of your freq ', ...
            'vector and your matrix size along 1st dimension ',...
            'are different. Labeling aborted :(']);
    else
        if isempty(opt.JumpFreq)
            % ==No JumpFreq, generating==
            labind = round(linspace(1, len, opt.NumFreq+1));
            twofirst = [opt.Freq(labind(1)), opt.Freq(labind(2))];
            opt.JumpFreq = round(abs(diff(twofirst)));
            clear twofirst labind
        end
        
        % ==JumpTime!==
        [labind, forcelabs] = JumpLabs(opt.Freq, opt.JumpFreq);
        
        if opt.ForceFreq
            labs = forcelabs;
        else
            % labels with precision up to one decimal place:
            labs = round(opt.Freq(labind)*10)/10;
        end
        
        % transform to cell of strings:
        labs =  arrayfun(@(x) num2str(x), labs, 'uni', false);
        labs =  regexp(labs, '[0-9]+\.?[0-9]?', 'match', 'once');
        labs = cellfun(@(x) [x, ' Hz'], labs, 'UniformOutput',...
            false);
        set(handles.axis, 'YTick', labind, 'YTickLabel',...
            labs, 'TickLength', [0.02 0.02], ...
            'TickDir', 'out', 'Layer', 'top', 'Box', 'off');
    end
end

%% ==adding scale if needed==
if opt.PlotScale
    handles.colorbar = colorbar('peer', handles.axis);
    if ~opt.NoRGB
        % label the colorbar appropriately (9 labels):
        labind = round(linspace(1, opt.MapLen, 9));
        % labind = round(linspace(1, outputs.cmaplen, 8));
        
        % labels with precision up to two decimal places:
        labs = round(outputs.mapping(labind)*100)/100;
        % transform to cell of strings:
        labs =  arrayfun(@(x) ['  ', num2str(x)], labs, 'uni', false);
        % change Ticks location:
        labind = labind + 0.5; labind(1) = 1;
        labind(end) = labind(end) - 0.5;
        % set Ticks:
        set(handles.colorbar, 'YTick', labind, 'YTickLabel',...
            labs, 'LineWidth', 1, 'TickLength', [0.02 0.02], 'TickDir',...
            'out', 'Layer', 'top', 'YLim', [1 outputs.cmaplen],...
            'Box', 'off');
    end
end

end

function [labind, forcelabs] = JumpLabs(Vec, Jump)

timj = Vec/Jump;
timjr = round(timj);
timf = abs(timj - timjr);
timfit = (diff(timf) > 0);
timfit = diff(timfit);
timfit = find(timfit == +1) + 1;

% end conditions
m = mean(timf(timfit));
st = std(timf(timfit), 1);
if timf(1) < m || abs(timf(1) - m) < 1.5 * st
    timfit = [1, timfit];
end
if timf(end) < m || abs(timf(end) - m) < 1.5 * st
    timfit = [timfit, length(timf)];
end
labind = timfit;
forcelabs = timjr(timfit)*Jump;
end

function [opt, delv] = check_maskitsweet_inputs(opt, var, names, isval)

varlen = length(var);
delv = 0;
i = 1;
while i <= varlen
    if ischar(var{i})
        whicharg = find(strcmpi(var{i}, names));
        if ~isempty(whicharg)
            if isval(whicharg)
                opt.(names{whicharg}) = var{i+1};
                i = i + 2;
                delv = delv + 2;
            else
                opt.(names{whicharg}) = true;
                i = i + 1;
                delv = delv + 1;
            end
        else
            i = i + 1;
        end
    else
        i = i + 1;
    end
end

end
% CMap, CMin, CMax, MapCent, MapEdge
function [opt, CMap] = MappingModule(CMap, opt, matri)

% setting CMin and CMax if empty:
if isempty(opt.CMin)
    opt.CMin = min(min(matri));
end
if isempty(opt.CMax)
    opt.CMax = max(max(matri));
end

% if MapCent empty - setting it to the middle:
if isempty(opt.MapCent)
    opt.MapCent = opt.CMin + (opt.CMax - opt.CMin)/2;
end

% let scaling begin!
opt.MapLen = size(CMap, 1);
HalfMap = floor(opt.MapLen / 2);
Lims = [opt.CMin, opt.CMax] - opt.MapCent;
absLims = abs(Lims);

switch opt.MapEdge
    case 'max'
        L = max(absLims);
        Lims = [-L, L];
    case 'min'
        L = min(absLims);
        Lims = [-L, L];
    case 'mean'
        L = mean(absLims);
        Lims = [-L, L];
    otherwise % assuming 'lin'
        % linear scaling - we may need to trim the colormap
        
        if absLims(1) < absLims(2)
            % lower limit is closer to the MapCent
            % we will need to trim the beginning of
            % the colormap! (so that the middle of CMap
            % is still mapped approximately to MapCent)
            LimRat = absLims(1)/absLims(2);
            TrimMap = round((1 - LimRat) * HalfMap);
            CMap = CMap(TrimMap:end,:);
            opt.MapLen = size(CMap, 1);
        elseif absLims(1) > absLims(2)
            % upper limit is closer to the MapCent
            % we will need to trim the end of
            % the colormap! (so that the middle of CMap
            % is still mapped approximately to MapCent)
            LimRat = absLims(2)/absLims(1);
            TrimMap = round(LimRat * HalfMap);
            CMap = CMap(1:end-TrimMap,:);
            opt.MapLen = size(CMap, 1);
        end
        
end
% recalculating CMin and CMax on the basis of Lims:
opt.CMin = opt.MapCent + Lims(1);
opt.CMax = opt.MapCent + Lims(2);
opt.mapping = linspace(opt.CMin, opt.CMax, opt.MapLen);
end