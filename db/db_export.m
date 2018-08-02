function db_export(db, varargin)

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
% epoch             - [boolean or 'auto'] whether to apply epoching to the file
% remove_components - [boolean] whether to remove ICA components marked for
%                     rejection
% export_marks      - [boolean, character or cell] whether to export marks as
%                     .rej files. If not boolean - defines mark types to export.


% init options
opt.prefix = '';
opt.epoch = 'auto';
opt.overwrite = true;
opt.export_dir = false;
opt.interpolate = true;
opt.export_marks = true;
opt.remove_components = true;

if nargin > 1
    opt = parse_arse(varargin, opt);
end

if opt.export_dir == false
    opt.export_dir = uigetdir;
end

if ~isdir(opt.export_dir)
    error('Supplied target directory (''export dir'') does not exist.')
end

args = {'local'};
if ~(ischar(opt.epoch) & strcmp(opt.epoch, 'auto')) & ~opt.epoch
    args{end + 1} = 'noepoch';
end
if ~opt.remove_components
    args{end + 1} = 'ICAnorem';
end
if opt.interpolate
    args{end + 1} = 'interp';
end

% step through db and check which files are not already in destination dir
if ~opt.overwrite
    db_filenames = {db.filename};
    in_dest_dir = dir(fullfile(opt.export_dir, '*.set'));
    in_dest_dir = {in_dest_dir.name};
    already_in_dest_dir = ismember(db_filenames, in_dest_dir);
    rs = find(~already_in_dest_dir);
else
    rs = 1:length(db);
end

wb = waitbar(0, 'Exporting files');
step = 1 / length(rs);
current_step = 0;

% export marks

for r = rs
    recover_args = args;
    if strcmp(opt.epoch, 'auto') & ~db(r).epoch.locked
        % no event-locked epochs, which means windows were used, we output
        % continuous signal with .rej annotations
        recover_args{end + 1} = 'noepoch';
    end
    waitbar(current_step, wb, 'Recovering file from db...');
    EEG = recoverEEG(db, r, recover_args{:});
    full_name = fullfile(opt.export_dir, [opt.prefix, db(r).filename]);

    waitbar(current_step, wb, 'Saving file...');
    pop_saveset(EEG, full_name);

    % db_export_rej for epochs should be different...
    if ~isequal(opt.export_marks, false)
        if iscell(opt.export_marks) || ischar(opt.export_marks)
            db_export_rej(db, r, opt.export_marks, path_out);
        else
            db_export_rej(db, r, 'reject', opt.export_dir);
        end
    end

    current_step = current_step + step;
    waitbar(current_step, wb);
end
