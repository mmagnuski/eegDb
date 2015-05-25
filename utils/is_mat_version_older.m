function isit_older = is_mat_version_older(ver)

% returns information whether matlab version is older 
% than some specified version number

% written by mmagnuski - april 2015

persistent current_matlab

if isempty(current_matlab)
    v = version;
    year_letter = regexp(v, '[0-9]+[ab]', 'match', 'once');
    
    current_matlab = {str2num(year_letter(1:4)), year_letter(5)}; %#ok<ST2NM>
end


if current_matlab{1} < ver{1}
    isit_older = true;
elseif current_matlab{1} == ver{1}
    % check letter
    isit_older = false;
    if ~(current_matlab{2} == ver{2})&& strcmp(ver{2}, 'b')
        isit_older = true;
    end
else
    isit_older = false;
end