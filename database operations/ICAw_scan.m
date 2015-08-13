function info = db_scan(db, rs)

% FIXHELPINFO
% Helper function for getting info about properties 
% of database entries - it is mostly used for checking 
% safty of chnges that user wants to introduce
% 
% output rows:
% 1 - filter
% 2 - cleanline
% 3 - epoching
% 4 - prerej
% 5 - postrej
% 6 - ica
% 7 - removed components

% returns vector of information where:
%  0 - given option is unspecified
%  1 - given option is specified but not saved in file (only introduced when recovering)
%  2 - option is specified and saved in EEG file (present in .datainfo of the database)
% -1 - option present both in .datainfo and core entry - may be an error

if ~exist('rs', 'var')
    rs = 1:length(db);
end

numR = length(rs);
info = zeros(5, numR);


% FILTER
info = simple_testfield(db(rs), 'filter', [], info, 1);

% CLEANLINE
istrue = @(x) isequal(x, true);
info = simple_testfield(db(rs), 'cleanline', [], info, 2, istrue);

% EPOCHING
% just checking if the field is empty may not be enough...
info = simple_testfield(db(rs), 'epoch', [], info, 3);

% rem epochs
% pre
info = simple_testfield(db(rs), 'reject', 'pre', info, 4);
% post
info = simple_testfield(db(rs), 'reject', 'post', info, 5);

% ICA
info = simple_testfield(db(rs), 'ICA', 'icaweights', info, 6);

% removed components
info = simple_testfield(db(rs), 'ICA', 'reject', info, 7);


function vec = simple_testfield(db, fname, subf, vec, n, varargin)
    if isempty(subf)
        isf = isfield(db, fname);
        if isf
            f = ~cellfun(@isempty, {db.(fname)});
        else
            f = false(1, length(db));
        end
        d = cellfun(@(x) femp(x, fname), {db.datainfo});

        if ~isempty(varargin)
            for v = 1:length(varargin)
                if isf
                    f(f) = cellfun(varargin{v}, {db(f).(fname)});
                end
                d(d) = cellfun(@(x) feval(varargin{v}, x.(fname)), {db(d).datainfo});
            end
        end
    else
        isf = isfield(db, fname);
        if isf
            getf = {db.(fname)};
            f = cellfun(@(x) femp(x, subf), getf);
        else
            getf = [];
            f = false(1, length(db));
        end

        d    = cellfun(@(x) femp(x, fname), {db.datainfo});
        d(d) = cellfun(@(x) femp(x.fname, subf), {db(d).datainfo});

        if ~isempty(varargin)
            for v = 1:length(varargin)
                if isf
                    f(f) = cellfun(@(x) feval(varargin{v}, x.(subf)), getf(f));
                end
                d(d) = cellfun(@(x) feval(varargin{v}, x.(fname).(subf)), {db(d).datainfo});
            end
        end
    end

    % apply changes
    vec = fillvec(vec, f, d, n);

function vec = fillvec(vec, f, d, n)
    vec(n,~f & ~d) = 0;
    vec(n, f & ~d) = 1;
    vec(n,~f &  d) = 2;
    vec(n, f &  d) = -1;
