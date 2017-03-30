function grp = group(dt)

% groups values from a vector into
% sequences of identical numbers
% OUTPUT - matrix where each row
%          represents a sequence of
%          identical numbers
%    first column - value of the 
%          sequence
%    second column - start index of
%          the sequence
%    third column - finish index of 
%          the sequence
%
% EXAMPLE:
% vector = [1,1,2,3,3,3,1,1,1,4,4,4];
% grp = group(vector)
% grp = [1, 1, 2;
%        1, 7, 9;
%        2, 3, 3;
%        3, 4, 6;
%        4, 10, 12]
% 

% written by M. Magnuski, 23 march 2014


% 
if islogical(dt)
    dt = int32(dt);
end
dt(end+1) = dt(end) + 1;
% length
len = length(dt);

% allocate output
grp = zeros(len,3);

% one loop does it all:
o.seq_beg = 1;
o.seq_val = dt(1);
o.seq_num = 1;

for n = 2:len
    if dt(n) ~= o.seq_val
        % finish sequence, start new:
        grp(o.seq_num,:) = [o.seq_val, o.seq_beg, n - 1];
        o.seq_val = dt(n); o.seq_num = o.seq_num + 1;
        o.seq_beg = n;
    end
end

% clean up, remove trailing zeros:
grp = grp(1:o.seq_num-1, :);
% and then sort:
[~, srt] = sort(grp(:,1));
grp = grp(srt, :);