### What is it all about?
**`eegDb`** is an egglab plugin that eases up managing preprocessing routines. It allows to create project databases for reproducible eeg preprocessing with eeglab.

### Installation
[See installation instructions](http://eegdb.readthedocs.org/en/latest/Installation/)

### Simple usage example
You can construct a database using a simple database creation GUI:
```matlab
db_create
```
And then navigate and edit the database using `db_gui` function:
```matlab
db = db_gui(db);
```
