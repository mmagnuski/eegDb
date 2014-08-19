function time = gettime(varargin)

% time = gettime(varargin)
%
% Gives time in string format.
% 
% 
% EXAMPLES
% --------
%
% 1. Get current time in hh:mm 
%   gettime()
%   17:19
%
% 2. Get extended time information
%   gettime(true)
%   2014.08.19 17:21:56.877

fullopt = false;
getcurr = 4:5;
if nargin > 0
    fullopt = true;
    getcurr = 1:6;
end

curr = clock;
curr = curr(getcurr);

if ~fullopt
    time = num2str(curr(1));
    if curr(2)<10
        time = [ time ':0', num2str(curr(2)) ];
    else
        time = [ time ':', num2str(curr(2)) ];
    end
else
    % 'empty' date to fill
    filldate = {'0000','.00','.00', ' 00', ':00', ':00', '.000'};
    
    % split seconds and milliseconds
    secmsec = curr(6);
    secnds = floor(secmsec);
    msec = floor((secmsec - secnds) * 1000);
    curr(6) = secnds; curr(7) = msec;
    
    % fill the empty date
    for dt = 1:length(curr)
        dgts = num2str(curr(dt));
        filldate{dt}(end - length(dgts) + 1 : end) = dgts;
    end
    
    time = [filldate{:}];
end


