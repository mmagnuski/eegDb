function [varargout] = status_bar_im(varargin)

if nargin == 0
    fig_handle = figure('Position', [50 50 700 70], 'Visible','off');
    axis_handle = axes('Parent',fig_handle,'units','pixels','Position',[5 5 690 60],...
        'TickLength', [0 0], 'XTickLabel', [], 'YTickLabel', []);
    data = zeros(2,100);
    handle = image(data);
    movegui(fig_handle,'center')
    set(fig_handle,'Visible','on')
    ile = nargout;
    if ile >= 1
        varargout{1} = handle;
        if ile == 2
            varargout{2} = fig_handle;
        elseif ile == 3
            varargout{2} = fig_handle;
            varargout{3} = axis_handle;
        end
    end
    drawnow
    
elseif nargin >= 3
    aktualny = varargin{1};
    maks = varargin{2};
    handle = varargin{3};
    fig_handle = varargin{4};

    procent = maks/100;
    zrobione = round(aktualny/procent);
    data = zeros(2,100);
    data(:,1:zrobione) = 35;
    set(0,'CurrentFigure', fig_handle);
    set(handle,'CData',data);
    
    if nargin > 4
        axis_handl = varargin{5};
        set(axis_handl, 'TickLength', [0 0]);
    end
    drawnow
end
