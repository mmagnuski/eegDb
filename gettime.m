function time = gettime(varargin)


% MM - default is as it used to work
% if any argument is passed gettime
% returns time and date (in string for-
% mat)
fullopt = false;
getcurr = 4:5;
if nargin > 0
    fullopt = true;
    getcurr = 1:6;
end

curr = clock;

curr = num2cell(curr(getcurr));

if ~fullopt
    time = num2str(curr{1});
    if curr{2}<10
        time=[ time ':0', num2str(curr{2})];
    else
        time=[ time ':', num2str(curr{2})];
    end
else
    % 'empty' date to fill
    filldate = {'0000','.00','.00', ' 00', ':00', ':00', '.000'};
    
    % split seconds and milliseconds
    secmsec = curr{6};
    sec = floor(secmsec);
    msec = floor((secmsec - sec) * 1000);
    curr{6} = sec; curr{7} = msec;
    
    % fill the empty date
    for dt = 1:length(curr)
        dgts = num2str(curr{dt});
        filldate{dt}(end - length(dgts) + 1 : end) = dgts;
    end
    
    time = [filldate{:}];
end


