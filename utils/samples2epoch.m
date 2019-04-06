function epoch_idx = samples2epoch(epoch_limits, range_limts)

% Find epochs to which given sample limits belong.
%
% Parameters
% ----------
% epoch_limits : 2d matrix
%     epochs x 2 matrix of epoch sample limits.
% range_limits : 2d matrix
%     ranges x 2 matrix of sample limits to find epochs corresponding to. Each
%     range will be assigned to one epoch. If the range does not overlap with
%     any epoch, it is assigned to "zero-th" epoch.
%
% Returns
% -------
% epoch_idx : vector
%     Vector of epoch indices, where consecutive elements of the vector
%     correspond to consecutive ranges in `range_limts`.

n_ranges = size(range_limts, 1);
epoch_idx = zeros(n_ranges, 1);
for idx = 1:n_ranges
    this_range = range_limts(idx, :);
    overlap = (this_range(1) <= epoch_limits(:, 2)) & ...
              (this_range(2) >= epoch_limits(:, 1));
    this_epoch_idx = find(overlap);

    % currenly ignore muli-epoch spanning artifacts...
    if length(this_epoch_idx) > 1
        this_epoch_idx = this_epoch_idx(1);
    elseif isempty(this_epoch_idx)
        this_epoch_idx = 0;
    end
    epoch_idx(idx) = this_epoch_idx;
end
