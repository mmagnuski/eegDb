function strtime = seconds2time(s)

% NOHELPINFO

% if ~exist('frmt', 'var')
% 	frmt = ':';
% end

val = [3600, 60, 1];
nm  = {'h', 'min', 's'};
frmt = {'%d', '%d', '%3.2f'};

timv = zeros(1,3);
ispres = false(1,3);

% check division
for t = 1:length(timv)
	ispres(t) = s > val(t);
	if ispres(t)
		timv(t) = floor(s/val(t));
		s = s - val(t) * timv(t);
	end
end

% add rest (ms) to seconds
if s == 0
	frmt{end} = '%d';
else
	timv(3) = timv(3) + s;
end

% print 
strtime = '';
for t = 1:3
	if ispres(t)
		strtime = sprintf([strtime, frmt{t}, ' ', nm{t}, ' '], timv(t));
	end
end

strtime(end) = [];
