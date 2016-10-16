# fastplot
`fastplot` is a fast and convenient object-oriented signal plotter (an alternative to eeglab's `eegplot`).
It is intended to be easy to work with not only through the gui commands and mouse clicks but also programmaticaly. 
Starting up `fastplot` is very easy:
```matlab
plt = fastplot(EEG);
```

## Keybord and mouse interface
The biggest difference from `eegplot` is that you do not see any buttons - almost the whole figure is used for signal display. 
This is because `fastplot` focuses on keybord-driven operation with mouse being used only for selecting channels / time segments.

### movement
Navigation is available through keybord arrows:  
<img src="http://icons.iconarchive.com/icons/chromatix/keyboard-keys/128/arrow-right-icon.png" alt="right arrow" width="30" height="30"/> - go one unit (one epoch) further in time  
<img src="http://icons.iconarchive.com/icons/chromatix/keyboard-keys/128/arrow-left-icon.png" alt="left arrow" width="30" height="30"/> - go one unit (one epoch) back in time (yes, `fastplot` allows for time-travel!)

You can also navigate the signal vim-like:  
<kbd>h</kbd> - go back one unit  
<kbd>l</kbd> - go one unit forward  
<kbd>w</kbd> - go one window forward  
<kbd>b</kbd> - one window back  

Prefixing the movement with a number executes the movement command this many times.
For example `4w` will move you four windows forward.

<kbd>=</kbd> - scale signal one unit up (this is the same key as <kbd>+</kbd>  
<kbd>-</kbd> - scale signal one unit down  
<kbd>e=</kbd> - add one epoch to the window view  
<kbd>e-</kbd> - remove one epoch from the window view  

### selection
`fastplot` allows you to mark signal in a variety of ways:  
<kbd>m</kbd> - choose currently used mark type  
<kbd>am</kbd> - add mark type  
`left mouse button` - clicking an epoch marks it with current mark type (note that you can mark one epoch with several marks)  
<kbd>shift</kbd> + `left mouse button` - mark all epochs since last mouse click with the current mark type (more precisely - all epochs since but not including last clicked epoch are inverted with respect to currently selected mark type).

## API
`fastplot` allows for easy control through its object oriented interface. 
First to create fastplot object (this also opens the gui):
```matlab
plt = fastplot(EEG);
```

You can invoke movement commands this way:
```matlab
% move the window by 2 units forward
plt.move(2);

% move the window 5 units back:
plt.move(-5);
```

You can ask the gui to refresh:
```matlab
% refresh the gui
plt.refresh();
% refresh(plt) does the same
```

If you know the keybord shortcuts that produce certain behavior of `fastplot` but
you do not know the name of the method that does the same thing programmaticaly - 
you can use the `eval` method. It allows you to pass a string that will be evaluated 
as if it was a series of key presses:
```matlab
% move forward one epoch
plt.eval('>'); % > is understood as right arrow
plt.eval('3b'); % b goes one full window back so 3b goes 3 windows back
```

You can also add marks using `add_mark` method:
```matlab
% adding new mark type
new_mark.name = 'new mark';
new_mark.color = [0.4, 0.7, 0.2];
plt.add_mark(new_mark);
```


## :construction:
And some other stuff:
```matlab
% select mark as currently active
plt.use_mark('new mark');

% mark epochs
plt.mark('reject', [1:3, 5, 8:10]);
```

```
plt.visible_epochs(); % or just plt.epochs()
plt.visible_events(); % or just plt.events()
plt.marks('vis');
```

```

% move the current view three epochs right
plt.move(3);

% evaluate strings as if they were series of button presses:

% add 3 epochs to the view
plt.eval('3e='); % '=' works as '+' - it is the same button
% scale signal up by four units
plt.eval('4=');

% then, after using the gui for a while, you close it,
% but want to reopen it at the same point you closed:
plt.plot() % all settings and selections are retained
```
