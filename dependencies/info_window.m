function handles = info_window(varargin)

% handles = info_window(varargin)
% the function allows to plot progress
% and text in a separate window. Useful
% when an EEGlab function does not have
% a 'verbose' option and floods the screen.
% Now, our communicates will be more visible
% printed in a separate window. :)
% 
% how to use:
% handles = info_window
%           creates the info_window and resturns 
%           a handles structure to it:
%           handles.fig_handle - handle to the figure
%           handles.text1 - handle to the title text field
%           handles.text2 - handle to the description text field
%           handles.axis_handle - handle to the image axis (progress bar)
%
% info_window(act,max,handles)
%           updates the progress bar to represent act/max filled
%           handles is the handles structure returned when init-
%           ializing the window.
%
% info_window('text',texthandles,{texts})
%           updates consecutive text fields represented with texthandles
%           with consecutive text in {texts}.
%           As there are only two fields in info_window the maximum is
%           info_window('text', [handles.text1, handles.text2],...
%               {'text1', 'text2'});
%
%           But actually using:
%               set(handles.text1, 'String', text1);
%           is more convenient because then text1 can be a cell matrix
%           that defines line breakdown.
%
% coded by M Magnuski some time in 2012 
% :)

def_color = [210/255, 240/255, 121/255];

handles = [];
if nargin == 0
    handles.fig_handle = figure('Position',[500,500,400,300], 'Color',...
        def_color, 'Visible','off');
    handles.text2 = uicontrol('Style','text','String',' processing too...' ,...
        'FontSize', 12, 'Position',[25,80,350,130],...
        'BackgroundColor', [210/255, 240/255, 121/255]);
    handles.text1 = uicontrol('Style','text','String',' processing...' ,...
        'FontSize', 16, 'Position',[25,220,350,70],...
        'BackgroundColor', [210/255, 240/255, 121/255]);
    handles.axis_handle = axes('Parent',handles.fig_handle,'units',...
        'pixels','Position',[5 10 390 30], 'TickLength', [0 0],...
        'XTickLabel', [], 'YTickLabel', []);
    
    data = zeros(2,400);
    handles.im_handle = image(data);
    movegui(handles.fig_handle,'center')
    set(handles.axis_handle, 'TickLength', [0 0], 'XTickLabel', [], 'YTickLabel', []);
    set(handles.fig_handle,'Visible','on')
    
    drawnow
    
elseif nargin >= 3
    % if 3 or more input arguments are given
    % that means that user wants to update
    % the info_window figure
    
    if ~ischar(varargin{1})
        % updating progress bar:
        aktualny = varargin{1};
        maks = varargin{2};
        handles = varargin{3};
        % setting prc
        prc = 400;
        
        procent = maks/prc;
        zrobione = round(aktualny/procent);
        data = zeros(2,prc);
        if zrobione>=1
        data(:,1:zrobione) = 35;
        end
        
        set(0,'CurrentFigure', handles.fig_handle);
        set(handles.im_handle,'CData',data);
        set(handles.axis_handle, 'TickLength', [0 0], 'XTickLabel', [], 'YTickLabel', []);
    else
        % updating text:
        teksty = varargin{3};
        for a = 1:length(varargin{2})
            set(varargin{2}(a), 'String', teksty{a});
        end
    end
    drawnow
end
