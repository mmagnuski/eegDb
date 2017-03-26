function mapping = db_compare_ICA(dt1, dt2, corr_thres)

% correlates icawinv from two datasets to find the 
% correspondence.
%
% mapping = db_compare_ICA(dt1, dt2, corr_thres)
% 
% Returns a mapping vector where
% mapping(n) = i means the n'th component from
% first dataset corresponds to i'th component
% from second dataset. No correspondence is marked
% with zeros.
%
% dt1 and dt2 can be icawinv matrices or eegDb databases
% corr_thres is correlation treshold above which components
% are concerned identical, default treshold is 0.9

% 
% see also: corr
% FIXHELPINFO

% c = corr(EEG.icawinv, db(12).ICA.icawinv);

if ~exist('corr_thres', 'var')
    corr_thres = 0.9;
end

winv1 = unpack_wininv(dt1);
winv2 = unpack_wininv(dt2);
c = corr(winv1, winv2);

[mxval, mxind] = max(c);
mask = mxval >= corr_thres;
from_inds = mxind(mask);
to_inds   = find(mask);

mapping = ones(1, size(c, 1));
mapping(from_inds) = to_inds;


function winv = unpack_wininv(dt)

if ~isnumeric(dt)
	if femp(dt, 'ICA')
		if femp(dt.ICA, 'icawinv')
			winv = dt.ICA.icawinv;
		end
	elseif femp(dt, 'icawinv')
			winv = dt.icawinv;
	else
		error('Cannot unpack icawinv');
    end
else   
    winv = dt;
end
