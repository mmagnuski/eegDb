%% checking Component Explorer

%% spectopo scaling of compo activity
disp('Scaling spectrum by component RMS of scalp map power');
            eegspecdB       = sqrt(mean(g.mapnorm.^4)) * eegspecdB;

% plotting topoplot
% -----------------
h = axes('Units','Normalized', 'Position',[-10 60 40 42].*s+q);

%topoplot( EEG.icawinv(:,chanorcomp), EEG.chanlocs); axis square; 

if isfield(EEG.chanlocs, 'theta')
    if typecomp == 1 % plot single channel locations
        topoplot( chanorcomp, EEG.chanlocs, t 'chaninfo', EEG.chaninfo, ...
                 'electrodes','off', 'style', 'blank', 'emarkersize1chan', 12); axis square;
    else             % plot component map
        topoplot( EEG.icawinv(:,chanorcomp), EEG.chanlocs, 'chaninfo', EEG.chaninfo, ...
                 'shading', 'interp', 'numcontour', 3); axis square;
    end;
else
    axis off;
end;
basename = [fastif(typecomp,'Channel ', 'IC') int2str(chanorcomp) ];
% title([ basename fastif(typecomp, ' location', ' map')], 'fontsize', 14); 
title(basename, 'fontsize', 14); 

% plotting erpimage
% -----------------
hhh = axes('Units','Normalized', 'Position',[45 62 48 38].*s+q);
eeglab_options; 
if EEG.trials > 1
    % put title at top of erpimage
    axis off
    hh = axes('Units','Normalized', 'Position',[45 62 48 38].*s+q);
    EEG.times = linspace(EEG.xmin, EEG.xmax, EEG.pnts);
    if EEG.trials < 6
      ei_smooth = 1;
    else
      ei_smooth = 3;
    end
    if typecomp == 1 % plot channel
         offset = nan_mean(EEG.data(chanorcomp,:));
         erp=nan_mean(squeeze(EEG.data(chanorcomp,:,:))')-offset;
         erp_limits=get_era_limits(erp);
         erpimage( EEG.data(chanorcomp,:)-offset, ones(1,EEG.trials)*10000, EEG.times*1000, ...
                       '', ei_smooth, 1, 'caxis', 2/3, 'cbar','erp','erp_vltg_ticks',erp_limits);   
    else % plot component
         icaacttmp = eeg_getdatact(EEG, 'component', chanorcomp);
         offset = nan_mean(icaacttmp(:));
         era    = nan_mean(squeeze(icaacttmp)')-offset;
         era_limits=get_era_limits(era);
         erpimage( icaacttmp-offset, ones(1,EEG.trials)*10000, EEG.times*1000, ...
                       '', ei_smooth, 1, 'caxis', 2/3, 'cbar','erp', 'yerplabel', '','erp_vltg_ticks',era_limits);   
    end;
    axes(hhh);
    title(sprintf('%s activity \\fontsize{10}(global offset %3.3f)', basename, offset), 'fontsize', 14);
else
    % put title at top of erpimage
    EI_TITLE = 'Continous data';
    axis off
    hh = axes('Units','Normalized', 'Position',[45 62 48 38].*s+q);
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
      eegtimes = linspace(0, erpimageframes-1, EEG.srate/1000);
      if typecomp == 1 % plot channel
           offset = nan_mean(EEG.data(chanorcomp,:));
           % Note: we don't need to worry about ERP limits, since ERPs
           % aren't visualized for continuous data
           erpimage( reshape(EEG.data(chanorcomp,1:erpimageframestot),erpimageframes,ERPIMAGELINES)-offset, ones(1,ERPIMAGELINES)*10000, eegtimes , ...
                         EI_TITLE, ei_smooth, 1, 'caxis', 2/3, 'cbar');  
      else % plot component
         icaacttmp = eeg_getdatact(EEG, 'component', chanorcomp);
         offset = nan_mean(icaacttmp(:));
         erpimage(reshape(icaacttmp(:,1:erpimageframestot),erpimageframes,ERPIMAGELINES)-offset,ones(1,ERPIMAGELINES)*10000, eegtimes , ...
                    EI_TITLE, ei_smooth, 1, 'caxis', 2/3, 'cbar','yerplabel', '');
      end
    else
            axis off;
            text(0.1, 0.3, [ 'No erpimage plotted' 10 'for small continuous data']);
    end;
    axes(hhh);
end;	

% plotting spectrum
% -----------------
if ~exist('winhandle')
    winhandle = NaN;
end;
if ~isnan(winhandle)
	h = axes('units','normalized', 'position',[5 10 95 35].*s+q);
else
	h = axes('units','normalized', 'position',[5 0 95 40].*s+q);
end;
%h = axes('units','normalized', 'position',[45 5 60 40].*s+q);
try
	eeglab_options; 
	if typecomp == 1
		[spectra freqs] = spectopo( EEG.data(chanorcomp,:), EEG.pnts, EEG.srate, spec_opt{:} );
	else 
		if option_computeica  
			[spectra freqs] = spectopo( EEG.icaact(chanorcomp,:), EEG.pnts, EEG.srate, 'mapnorm', EEG.icawinv(:,chanorcomp), spec_opt{:} );
        else
    		icaacttmp = (EEG.icaweights(chanorcomp,:)*EEG.icasphere)*reshape(EEG.data(EEG.icachansind,:,:), length(EEG.icachansind), EEG.trials*EEG.pnts); 
			[spectra freqs] = spectopo( icaacttmp, EEG.pnts, EEG.srate, 'mapnorm', EEG.icawinv(:,chanorcomp), spec_opt{:} );
		end;
	end;
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
end;