function db = db_addfile(db, fname, r)

% add another file to the database
%
% Usage:
% 1.
% db = db_addfile(db, file_name)
% (then parameters like filtering, filepath and epoching
%  are based on the first database record)
%
% 2.
% db = db_addfile(db, file_name, r)
% (then parameters like filtering, filepath and epoching
%  are based on the r'th database record)

if ~exist('r', 'var')
    r = 1;
end

add_rec = db(r);
for m = 1:length(add_rec.marks)
    add_rec.marks(m).value = [];
end
if length(add_rec.marks) > 3
    add_rec.marks(3:end) = [];
end

add_rec.notes = [];

add_rec.reject.pre = [];
add_rec.reject.post = [];
add_rec.reject.all = [];

add_rec.chan.labels = [];
add_rec.chan.bad = [];


add_rec.filename = fname;

flds = fields(add_rec.ICA);
for f = 1:length(flds)
    add_rec.ICA.(flds{f}) = [];
end

db(end + 1) = add_rec;
