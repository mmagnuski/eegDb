# Export files from `db`

Use `db_export` function to export cleaned files to hard drive. `db_export(db)`
uses preprocessing options saved in `db` database to recover clean files and
save these files to selected directory.

## Examples
If you do not specify target directory a GUI will pop up, prompting you to
choose relevant directory.
```matlab
db_export(db)
```

You can specify target directory using `'export_dir'` keyword:
```matlab
db_export(db, 'export_dir', 'C:\Users\doe\data\DiamSar\eeg\clean')
```

`db_export` overwirtes files by default. If you want to export only those files
that are not present in your target directory (so you do not want to overwrite
existing files) use `'overwrite'` keyword:
```matlab
target_dir = 'C:\Users\badger\data\GabCon\eeg\clean'
db_export(db, 'export_dir', target_dir, 'overwrite', false)
```

### :construction: `replace_in_name` arg ... :construction:
