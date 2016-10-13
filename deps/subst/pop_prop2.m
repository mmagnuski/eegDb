% pop_prop() - plot the properties of a channel or of an independent
%              component. 
% Usage:
%   >> pop_prop( EEG);           % pops up a query window 
%   >> pop_prop( EEG, typecomp); % pops up a query window 
%   >> pop_prop( EEG, typecomp, comp, hfig, spectopo_options);
%
% Inputs:
%   EEG        - EEGLAB dataset structure (see EEGGLOBAL)
%
% Optional inputs:
%   comp - channel or component number[s] to display {default: 1}
%
%   hfig  - if this parameter is present or non-NaN, buttons 
%                allowing the rejection of the component are drawn. 
%                If non-zero, this parameter is used to back-propagate
%                the color of the rejection button.
%   spectopo_options - [cell array] optional cell arry of options for 
%                the spectopo() function. 
%                For example { 'freqrange' [2 50] }
% 
% Author: Arnaud Delorme, CNL / Salk Institute, 2001
%
% See also: pop_runica(), eeglab()

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
% 02-17-02 removed event index option -ad
% 03-17-02 debugging -ad & sm
% 03-18-02 text settings -ad & sm
% 03-18-02 added title -ad & sm

function h = pop_prop2(EEG, comp, hfig, spec_opt)

% TODOs
% [ ] varargin for hfig, specopts etc.
% [ ] CONSIDER turinging to an object

if nargin < 1
	help pop_prop;
	return;   
end

if length(comp) > 1
  real_comp = comp(2);
  comp = comp(1);
else
  real_comp = comp;
end

if nargin < 4
	spec_opt = {};
end
if nargin == 1
    comp = 1;
end
if isempty(EEG.icaweights)
   error('No ICA weights recorded for this dataset -- first run ICA on it');
end   

if comp < 1 | comp > EEG.nbchan % should test for > number of components ??? -sm
   error('Component index out of range');
end


% CHANGE - take colors from opts
% do not use icadefs
BACKCOLOR        = [0.8, 0.8, 0.8];
FIGBACKCOLOR     = [1, 1, 1];
GUIBUTTONCOLOR   = [0.8, 0.8, 0.8]; 

basename = [ 'Component ', int2str(comp) ];

h.fig = figure('name', ['pop_prop() - ' basename ' properties'], 'color', FIGBACKCOLOR, 'numbertitle', 'off', 'visible', 'off');
pos = get(h.fig,'Position');
set(h.fig,'Position', [pos(1) pos(2)-500+pos(4) 500 500], 'visible', 'on');

% CHANGE - do not create fake axis
% create fake axis?
h.ax = axes('parent', h.fig);
pos = get(h.ax,'position'); % plot relative to current axes

q = [pos(1) pos(2) 0 0];
s = [pos(3) pos(4) pos(3) pos(4)]./100;
axis off;

% plotting topoplot
% -----------------
h.topo = axes('parent', h.fig, 'Visible', 'off', ...
    'Units','Normalized', 'Position',[-10 60 40 42].*s+q);

set(h.topo, 'ylim', [-0.5, 0.5]);
set(h.topo, 'xlim', [-0.5, 0.5]);

% just replot from cache
topocache = getappdata(hfig, 'topocache');
replot_topo(topocache, real_comp, h.topo);

basename = ['IC', int2str(real_comp)];

% title
title(basename, 'fontsize', 14); 

% plotting erpimage
% -----------------
h.erpim = axes('Units','Normalized', 'Position',[45 62 48 38].*s+q);
eeglab_options; 
if EEG.trials > 1
    % put title at top of erpimage
    EEG.times = linspace(EEG.xmin, EEG.xmax, EEG.pnts);
    
    % CHANGE - smoothing taken from options
    if EEG.trials < 6
      ei_smooth = 1;
    else
      ei_smooth = 3;
    end
    
    % plot component
     icaacttmp = eeg_getdatact(EEG, 'component', comp);
     offset = nan_mean(icaacttmp(:));
     era    = nan_mean(squeeze(icaacttmp)')-offset;
     era_limits=get_era_limits(era);
     erpimage_silent( icaacttmp - offset, ...
               ones(1, EEG.trials) * 10000, ...
               EEG.times*1000, '', ...
               ei_smooth, 1, ...
               'caxis', 2/3, ...
               'cbar','erp', ...
               'yerplabel', '', ...
               'erp_vltg_ticks', era_limits);   

    % erpimage usually behaves badly and deletes
    % provided axis, so we have to get it again:
    if ~ishandle(h.erpim)
        h.erpim = gca;
    end
    axes(h.erpim);
    title(sprintf('%s activity \\fontsize{10}(global offset %3.3f)', basename, offset), 'fontsize', 14);
else
    % CHECK and CHANGE - I did not edit this part

    % put title at top of erpimage
    EI_TITLE = 'Continous data';
    axis off
    ERPIMAGELINES = 200; % show 200-line erpimage
    while size(EEG.data,2) < ERPIMAGELINES*EEG.srate
       ERPIMAGELINES = 0.9 * ERPIMAGELINES;
    end
    ERPIMAGELINES = round(ERPIMAGELINES);
    if ERPIMAGELINES > 2   % give up if data too small
        if ERPIMAGELINES < 10
            ei_smooth = 1;
        else
            ei_smooth = 3;
        end
      erpimageframes = floor(size(EEG.data,2)/ERPIMAGELINES);
      erpimageframestot = erpimageframes*ERPIMAGELINES;
      eegtimes = (1:erpimageframes) * (1000/EEG.srate);

     icaacttmp = eeg_getdatact(EEG, 'component', comp);
     offset = nan_mean(icaacttmp(:));
     erpimage(reshape(icaacttmp(:,1:erpimageframestot),erpimageframes,ERPIMAGELINES)-offset,ones(1,ERPIMAGELINES)*10000, eegtimes , ...
                EI_TITLE, ei_smooth, 1, 'caxis', 2/3, 'cbar','yerplabel', '');
    else
            axis off;
            text(0.1, 0.3, [ 'No erpimage plotted' 10 'for small continuous data']);
    end
    if ~ishandle(h.erpim)
        h.erpim = gca;
    end
    axes(h.erpim);
end

% plotting spectrum
% -----------------
h.spectrum = axes('units','normalized', 'position',[5 10 95 35].*s+q);

try
    % CHANGE - do not use eeglab_options
    % CHANGE - get options from db_gui or syncer
	eeglab_options; 
		if femp(EEG, 'icaact') 
			[spectra, freqs] = spectopo_silent( EEG.icaact(comp,:), EEG.pnts, ...
                                         EEG.srate, 'mapnorm', ...
                                         EEG.icawinv(:,comp), spec_opt{:} );
        else
    		icaacttmp = (EEG.icaweights(comp,:)*EEG.icasphere) * ...
                        reshape(EEG.data(EEG.icachansind,:,:), ...
                            length(EEG.icachansind), EEG.trials * EEG.pnts);

			[spectra, freqs] = spectopo_silent( icaacttmp, EEG.pnts, ...
                                          EEG.srate, 'mapnorm', ...
                                          EEG.icawinv(:,comp), spec_opt{:} );
        end

    % set up new limits
    % -----------------
    %freqslim = 50;
	%set(gca, 'xlim', [0 min(freqslim, EEG.srate/2)]);
    %spectra = spectra(find(freqs <= freqslim));
	%set(gca, 'ylim', [min(spectra) max(spectra)]);
    
	%tmpy = get(gca, 'ylim');
    %set(gca, 'ylim', [max(tmpy(1),-1) tmpy(2)]);
	set( get(gca, 'ylabel'), 'string', 'Power 10*log_{10}(\muV^{2}/Hz)', 'fontsize', 14); 
	set( get(gca, 'xlabel'), 'string', 'Frequency (Hz)', 'fontsize', 14); 
	title('Activity power spectrum', 'fontsize', 14); 
catch
	axis off;
    lasterror
	text(0.1, 0.3, [ 'Error: no spectrum plotted' 10 ' make sure you have the ' 10 'signal processing toolbox']);
end
	
% display buttons
% ---------------

% CANCEL button
% -------------

% options common for most buttons:
op = {'Style', 'pushbutton', ...
      'backgroundcolor', GUIBUTTONCOLOR, ...
      'Units','Normalized'};

h.cancel  = uicontrol(gcf,  op{:}, 'string', 'Cancel', ...
                      'Position', [-10 -10 15 6].*s+q, ...
                      'callback', 'close(gcf);');

% VALUE button
% -------------
h.value  = uicontrol(gcf, op{:}, 'string', 'Values', ...
                     'Position', [15 -10 15 6].*s+q);

% REJECT button
% -------------

h.status = uicontrol(gcf, op{:}, ...
			'string', 'YOU DECIDE', ...
            'Position', [40 -10 15 6].*s+q, ...
            'tag', 'rejstatus');

% init status to 0
setappdata(h.fig, 'status', 0);

% HELP button
% -------------

% CHANGE - help button should be removed or 'refunctioned'
h.help  = uicontrol(gcf, op{:}, 'string', 'HELP', ...
                    'Position', [65 -10 15 6].*s+q, ...
                    'callback', 'disp(''Please, help!'');');

% you don't need ok when using with eegDb
h.ok  = uicontrol(gcf, op{:}, 'string', 'OK', ...
                  'Position', [90 -10 15 6].*s+q, ...
                  'callback', 'disp(''OK!'')');

% draw the figure for statistical values
% --------------------------------------
index = num2str( comp );

% this is crazy, big block of code as a string:
command = [ ...
	'figure(''MenuBar'', ''none'', ''name'', ''Statistics of the component'', ''numbertitle'', ''off'');' ...
	'' ...
	'pos = get(gcf,''Position'');' ...
	'set(gcf,''Position'', [pos(1) pos(2) 340 340]);' ...
	'pos = get(gca,''position'');' ...
	'q = [pos(1) pos(2) 0 0];' ...
	's = [pos(3) pos(4) pos(3) pos(4)]./100;' ...
	'axis off;' ...
	''  ...
	'txt1 = sprintf(''(\n' ...
					'Entropy of component activity\t\t%2.2f\n' ...
				    '> Rejection threshold \t\t%2.2f\n\n' ...
				    ' AND                 \t\t\t----\n\n' ...
				    'Kurtosis of component activity\t\t%2.2f\n' ...
				    '> Rejection threshold \t\t%2.2f\n\n' ...
				    ') OR                  \t\t\t----\n\n' ...
				    'Kurtosis distibution \t\t\t%2.2f\n' ...
				    '> Rejection threhold\t\t\t%2.2f\n\n' ...
				    '\n' ...
				    'Current thesholds sujest to %s the component\n\n' ...
				    '(after manually accepting/rejecting the component, you may recalibrate thresholds for future automatic rejection on other datasets)'',' ...
					'EEG.stats.compenta(' index '), EEG.reject.threshentropy, EEG.stats.compkurta(' index '), ' ...
					'EEG.reject.threshkurtact, EEG.stats.compkurtdist(' index '), EEG.reject.threshkurtdist, fastif(EEG.reject.gcompreject(' index '), ''REJECT'', ''ACCEPT''));' ...
	'' ...				
	'uicontrol(gcf, ''Units'',''Normalized'', ''Position'',[-11 4 117 100].*s+q, ''Style'', ''frame'' );' ...
	'uicontrol(gcf, ''Units'',''Normalized'', ''Position'',[-5 5 100 95].*s+q, ''String'', txt1, ''Style'',''text'', ''HorizontalAlignment'', ''left'' );' ...
	'h = uicontrol(gcf, ''Style'', ''pushbutton'', ''string'', ''Close'', ''Units'',''Normalized'', ''Position'', [35 -10 25 10].*s+q, ''callback'', ''close(gcf);'');' ...
	'clear txt1 q s h pos;' ];

set( h.value, 'callback', command); 

if isempty( EEG.stats.compenta )
	set(h.value, 'enable', 'off');
end

% set up guidata
% --------------
setappdata(h.fig, 'h', h);
setappdata(h.fig, 'EEG', EEG);
setappdata(h.fig, 'comp', real_comp);

set(h.fig, 'color', FIGBACKCOLOR);


function out = nan_mean(in)

    nans = find(isnan(in));
    in(nans) = 0;
    sums = sum(in);
    nonnans = ones(size(in));
    nonnans(nans) = 0;
    nonnans = sum(nonnans);
    nononnans = find(nonnans==0);
    nonnans(nononnans) = 1;
    out = sum(in)./nonnans;
    out(nononnans) = NaN;

    
function era_limits=get_era_limits(era)
%function era_limits=get_era_limits(era)
%
% Returns the minimum and maximum value of an event-related
% activation/potential waveform (after rounding according to the order of
% magnitude of the ERA/ERP)
%
% Inputs:
% era - [vector] Event related activation or potential
%
% Output:
% era_limits - [min max] minimum and maximum value of an event-related
% activation/potential waveform (after rounding according to the order of
% magnitude of the ERA/ERP)

mn=min(era);
mx=max(era);
mn=orderofmag(mn)*round(mn/orderofmag(mn));
mx=orderofmag(mx)*round(mx/orderofmag(mx));
era_limits=[mn mx];


function ord=orderofmag(val)
%function ord=orderofmag(val)
%
% Returns the order of magnitude of the value of 'val' in multiples of 10
% (e.g., 10^-1, 10^0, 10^1, 10^2, etc ...)
% used for computing erpimage trial axis tick labels as an alternative for
% plotting sorting variable

val=abs(val);
if val>=1
    ord=1;
    val=floor(val/10);
    while val>=1,
        ord=ord*10;
        val=floor(val/10);
    end
    return;
else
    ord=1/10;
    val=val*10;
    while val<1,
        ord=ord/10;
        val=val*10;
    end
    return
end

