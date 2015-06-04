function ICAw = ICAw_copyrec(ICAw, num)

% NOHELPINFO

len = length(ICAw);
newf = len + 1;
fld = fields(ICAw);

for f = 1:length(fld)
    ICAw(newf).(fld{f}) = ICAw(num).(fld{f});
end
