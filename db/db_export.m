function db_export(db, path_out, varargin)

% db_export allows to export files preprocessed according to db
%
% db_export(db, path_out, optional_arguments)
%
% db       - eegDb database
% path_out - valid path to directory that will contain exported files.
%            be aware that db_export will overwrite in the case of file name
%            conflict.
%
% optional arguments:
% epoch             - [boolean] whether to apply epoching to the file
% remove_components - [boolean] whether to remove ICA components marked for
%                     rejection
% export_marks      - [boolean, character or cell] whether to export marks as
%                     .rej files. If not boolean - defines mark types to export.

% opt.filter
opt.export_marks = false;
opt.epoch = true;
opt.remove_components = true;
opt.interpolate = true;

opt = parse_arse(varargin, opt);

if ~isdir(path_out)
    error('Supplied output directory does not exist.')
end

args = {'local'};
if ~opt.epoch
    args{end + 1} = 'noepoch';
end
if ~opt.remove_components
    args{end + 1} = 'ICAnorem';
end
if opt.interpolate
    args{end + 1} = 'interp';
end

% export files
for r = 1:length(db)
    EEG = recoverEEG(db, r, args{:});
    pop_saveset(EEG, fullfile(path_out, db(r).filename));
end

% export marks
if ~isequal(opt.export_marks, false)
    if iscell(opt.export_marks) || ischar(opt.export_marks)
        for r = 1:length(db)
            db_export_rej(db, r, opt.export_marks, path_out);
        end
    else
        for r = 1:length(db)
            db_export_rej(db, r, 'reject', path_out);
        end
    end
end
