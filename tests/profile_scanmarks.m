% timeit!

tic
for i = 1:1000
    rejt = ICAw_scanmarks(ICAw2);
end
toc
% Elapsed time is 3.351338 seconds.
