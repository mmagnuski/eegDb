% pop_selectcomps() - Display components with button to vizualize their
%                  properties and label them for rejection.
% Usage:
%       >> OUTEEG = pop_selectcomps( INEEG, compnum );
%
% Inputs:
%   EEG    - Input dataset
%   compnum  - vector of component numbers
%
%   optional:
%               - 'main' - handles to main figure ('main', h)
%               - 'rejected' - logical vector indicating previosly rejected
%               compnents ('rejected', vector)
%
%
%
%
% Author: Arnaud Delorme, CNL / Salk Institute, 2001
%
% See also: pop_prop(), eeglab()

% Copyright (C) 2001 Arnaud Delorme, Salk Institute, arno@salk.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% 01-25-02 reformated help & license -ad

function  selcomp_test(EEG, compnum, varargin)

args = {'rejects', 'main'};
%vars = {'fig2', 'rejs'};

% MM:
% dziwny ten error jest...
% wyglada na to, ze z jakiegos powodu pop_selectcomps2
% ma static workspace, spotyka³em siê ju¿ ze static workspace'ami
% ale nie znam niestety regu³ nimi rz¹dz¹cych
%
%  "Error using pop_selectcomps2 (line 55)
%  Attempt to add "fig2" to a static workspace.
%  See MATLAB Programming, Restrictions on Assigning to Variables for
%  details"
%
% for a = 1:length(args)
%     reslt = find(strcmp(args{a}, varargin));
%     if ~isempty(reslt)
%         reslt = reslt(1);
%         eval([vars{a}, ' = varargin{reslt+1};']);
%         varargin([reslt, reslt+1]) = [];
%         if isempty(varargin)
%             break
%         end
%     end
% end


% MM
% tidying up a bit, just cosmetic changes
rejs = [];
fig2 = [];

if nargin > 2
    f = find(strcmp(args(1), varargin));
    if f
        rejs = varargin{f + 1};
    end
    
    f = find(strcmp(args(2), varargin));
    if f
        fig2 = varargin{f + 1};
    end
end


COLREJ = '[1 0.6 0.6]';
COLACC = '[0.75 1 0.75]';
BACKCOLOR = [0.8 0.8 0.8];
GUIBUTTONCOLOR   = [0.8 0.8 0.8];
PLOTPERFIG = 35;

currentfigtag = 'whatever';

if length(compnum) > PLOTPERFIG
    compnum2 = compnum(36:end);
end;




% set up the figure
% -----------------
column =ceil(sqrt( length(compnum) ))+1;
rows = ceil(length(compnum)/column);
if ~exist('fig')
    fig1 = figure('name', 'All component maps: ', 'tag', currentfigtag, ...
        'numbertitle', 'off', 'color', BACKCOLOR);
    set(fig1,'MenuBar', 'none');
    pos = get(fig1,'Position');
    set(fig1,'Position', [pos(1) 20 800/7*column 600/5*rows]);
    incx = 120;
    incy = 110;
    sizewx = 100/column;
    if rows > 2
        sizewy = 90/rows;
    else
        sizewy = 80/rows;
    end;
    pos = get(gca,'position'); % plot relative to current axes
    hh = gca;
    q = [pos(1) pos(2) 0 0];
    s = [pos(3) pos(4) pos(3) pos(4)]./100;
    axis off;
end;

% figure rows and columns
% -----------------------
if EEG.nbchan > 64 % sk¹d ma EEG?
    disp('More than 64 electrodes: electrode locations not shown');
    plotelec = 0;
else
    plotelec = 1;
end;

count = 1;
sl = 1;
for ri = compnum
    if sl == 1 && length(compnum)>35
        compnum = compnum(1:35);
    else
        compnum = compnum;
    end
    if exist('fig')
        button = findobj('parent', fig, 'tag', ['comp' num2str(ri)]);
        if isempty(button)
            error( 'pop_selectcomps(): figure does not contain the component button');
        end;
    else
        button = [];
    end;
    
    if isempty( button )
        % compute coordinates
        % -------------------
        X = mod(count-1, column)/column * incx-10;
        Y = (rows-floor((count-1)/column))/rows * incy - sizewy*1.3;
        
        % plot the head
        % -------------
        ha = axes('Units','Normalized', 'Position',[X Y sizewx sizewy].*s+q);
        if plotelec
            topoplot( EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
                'off', 'style' , 'map', 'chaninfo', EEG.chaninfo, ...
                'gridscale', 18);
            % , 'numcontour', 5);
        else
            topoplot( EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
                'off', 'style' , 'map','electrodes','off', 'chaninfo',...
                EEG.chaninfo);
        end;
        axis square;
        
        % plot the button
        % ---------------
        if ~isempty(rejs) && rejs(ri)
            color= [1 0.6 0.6];
        else
            color = [0.75 1 0.75];
        end
        button = uicontrol(fig1, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
            [X Y+sizewy sizewx sizewy*0.25].*s+q, 'tag', ['comp' num2str(ri)]);
        set( button, 'backgroundcolor', color, 'string', int2str(ri));
        set( button, 'callback', {@getcomp, fig2, str2num(get(button, 'String'))});
        
        
    end;
    
    drawnow;
    count = count +1;
    if count ==35
        sl = 2;
    end
end;

% draw the bottom button
% ----------------------
if ~exist('fig')
    hh = uicontrol(fig1, 'Style', 'pushbutton', 'string', 'Cancel', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[-10 -10  15 sizewy*0.25].*s+q, 'callback', 'close(fig1);' );
    hn = uicontrol(fig1, 'Style', 'edit', 'string', 'notes', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[10 -10  35 sizewy*0.25].*s+q);
    hn2 = uicontrol(fig1, 'Style', 'pushbutton', 'string', 'add notes', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[50 -10  15 sizewy*0.25].*s+q);
    set( hn2, 'Callback', {@getnotes, fig2, get(hn, 'String')});%bierze initial string i zostawia tak
end;

% FOR TEST PURPOSES:
% uiwait(fig1);
    function getcomp(h, e, fig2, comp) %#ok<*INUSL>
        if ~isempty(fig2) && fig2.comp~=comp
            fig2 = guidata(fig2.figure1);
            fig2.comp=comp;
            guidata(fig2.figure1, fig2)
            close(fig1)
        else
            close(fig1)
        end
    end

    function getnotes(h,e,fig2, notes)
        if ~isempty(fig2) && ~strcmp('notes', notes) %notes sa jak narazie zawsze notes (see above)
            
            fig2 = guidata(fig2.figure1);
            r = fig2.r;
            global ICAw %#ok<TLEV>
            ICAw(r).ICA_notes = notes; %different field name prb
        end
    end

end



