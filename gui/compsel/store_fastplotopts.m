function store_fastplotopts(fst, h)

opts.window = fst.window;
opts.num_epochs = fst.opt.num_epoch_per_window;
opts.scale = fst.opt.signal_scale;

if ishandle(h)
    setappdata(h, 'fastplotopts', opts);
end
delete(fst.h.fig);