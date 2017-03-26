function info = db_get(db, rs, prop)

% danger! THIS FUNCTION SEEMS TO BE NOT FINISHED...
%
% Helper function for getting info about properties 
% of database entries - it is mostly used for checking 
% safty of chnges that user wants to introduce
%
% info = db_get(db, rs, prop)
%
% info is a matrix of information where:
%  0 - given option is unspecified
%  1 - given option is specified but not saved in file (only introduced when recovering)
%  2 - option is specified and saved in EEG file (present in .datainfo of the database)
% -1 - option present both in .datainfo and core entry - may be an error

numR = length(rs);
vec = zeros(5, numR);

% check filtering 

% CHECK which is faster? cellfun?

% FILTER
vec = simple_testfield(db(rs), 'filter', vec, 1);

% CLEANLINE
istrue = @(x) isequal(x, true);
vec = simple_testfield(db(rs), 'cleanline', vec, 2, istrue);

% EPOCHING
% just checking if the field is empty may not be enough...
vec = simple_testfield(db(rs), 'epoch', vec, 3);

% ICA


function vec = simple_testfield(db, fname, vec, n, varargin)
    f = ~cellfun(@isempty, {db.(fname)});
    d = ~cellfun(@(x) femp(x, fname), {db.datainfo});

    if ~isempty(varargin)
        for v = 1:length(varargin)
            f(f) = cellfun(varargin{v}, {db(f).(fname)});
            d(d) = cellfun(@(x) feval(varargin{v}, x.(fname)), {db(f).datainfo});
        end
    end

    vec = fillvec(vec, f, d, n);

function vec = fillvec(vec, f, d, n)
    vec(n,~f & ~d) = 0;
    vec(n, f & ~d) = 1;
    vec(n,~f &  d) = 2;
    vec(n, f &  d) = -1;

