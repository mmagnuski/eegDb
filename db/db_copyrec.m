function db = db_copyrec(db, num)

% NOHELPINFO

len = length(db);
newf = len + 1;
fld = fields(db);

for f = 1:length(fld)
    db(newf).(fld{f}) = db(num).(fld{f});
end
