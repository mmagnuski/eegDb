function palette = color_palette(varargin)

% color_palette()
% with no additional inputs provides a nice
% 5-color palette
% the color palette is returned as a matrix:
% number_of_colors X 3 (the second dimension
% is [R G B] with values 0 - 1)
% 
% color_palette() can be called
% with the name of palette color, like:
% >> colors = color_palette('cosmic bubblegum');
%
% for names of possible color palettes type:
% >> color_palette('display');
%
% to see how a given color palette looks add
% 'display' after the palette's name, for example:
% >> color_palette('rock me', 'display');
% 
% all of the color palettes are from:
% http://www.colourlovers.com/

default_palette = {'B3373C', 'F04050', 'F2A482', 'FFE6A6', '80D1BE'};
palette = color_hex2rgb(default_palette)/255;

if nargin > 0
    pass = true;
    try
        palette = eval([varargin{1}, '(6);']);
    catch error %#ok<NASGU>
        pass = false;
    end
    
    if ~pass
        % checking other palettes:
        
        % COLOR PALETTES
        pnames = {'EDE', 'rock me', 'autumn colors', ...
            'in the midst', 'floral', 'cosmic bubblegum',...
            'S h e', 'pixelated', 'C h i l d h o o d *', ...
            'b u b b l e g u m', 'flowers'};
        pcolor = {{'FCB525', '002D74', 'EE7600', 'E34E35', ...
            '6F90B8'}, {'F9CE04', 'F92604', 'FF4705', '603F7F',...
            'B6E3FB'}, {'8E756E', 'BC8856', 'CB9C42', 'C87239',...
            '503F2F'}, {'A85480', '5C2D70', '2F2766', '274766',...
            '007876'}, {'EA3556', '61D2D6', 'EDE5E2', 'ED146F',...
            'EDDE45', '9BF0E9'}, {'35235D', 'DB2464', 'CB2402',...
            'B8DC3C', '4C49A2', 'A31A48'}, {'D1813C', '692524',...
            '869260', '98A879', 'C1CDA9'}, {'EA7087', 'E0AD7B',...
            'E0E788', '77EA91', '86E8E4'}, {'FFF681', 'FFBCAB',...
            'FFFFC6', 'A58F84', '89B6A2'}, {'F3DCB2', 'FACB97',...
            'F59982', 'ED616F', 'F2116C'}, {'D35252', '02C19D',...
            '11398D', '920808', '08352B'}};
        % END OF COLOR PALETTES
        
        % compare palette request with available palletes:
        pal = find(strcmp(varargin{1}, pnames));
        if ~isempty(pal)
            palette = pcolor{pal};
            palette = color_hex2rgb(palette)/255;
        end
    end
    
    display = find(strcmp('display', varargin));
    if ~isempty(display) && nargin > 1
        figure;
        image(reshape(palette, [size(palette,1),...
            1, 3]));
    elseif ~isempty(display) && nargin == 1
        fprintf('\n');
        fprintf('color palettes:\n');
        for pn = 1:length(pnames)
            fprintf('    ');
        	fprintf([pnames{pn}, '\n']);
        end
        fprintf('(as well as any colormap like: jet or hot)\n');
    end
    
    % get color palettes:
    gt = strcmp('get', varargin);
    if any(gt) && nargin == 1
        palette = pnames;
    end
end
