function hs = gui_multiedit(maintext, opts, optval)

% GUI_MULTIEDIT creates a simple gui with multiple
% edit boxes.
% 
% hs = gui_multiedit(maintext, opts, optval)
% 
% input:
% maintext - string; title text visible on top of the gui
% opts     - cell array of strings; each string is a title
%            corresponding to one edit box
% optval   - cell array of strings; each string is the
%            starting value for the edit box
% 
% output:
% hs          - structure of handles; contains handles to all
%               elements of the figure
% hs.hf       - handle; handle to the figure
% hs.maintxt  - handle; handle to the title text
% hs.txt      - array of handles; handles to consecutive 
%               text boxes (serve as titles to edit boxes)
% hs.edit     - array of handles; handles to consecutive 
%               edit boxes
% hs.ok       - handle; handle to the OK button
% hs.cancel   - handle; handle to the cancel button

% this gui is useful for gathering options
% also one needs to specify: text options on one side
% (and on the second something else?)


if nargin == 0 || isempty(maintext)
    maintext = 'Please fill the fileds below';
end

if nargin < 2 || isempty(opts)
    opts = {'option 1'; 'option 2'; 'option 3'};
end

if nargin < 3 || isempty(optval)
    optval = cell(size(opts));
end

nopt = length(opts);

% width options
desl = 200;
editl = 120;
descdist = 10;
wg = 3 * descdist + editl + desl;

% button sizes
buth = 40; butdh = 5; butdrest = 15;
butdw = 10;
butw = round((wg - 3 * butdw)/2); % two buttons
abvbut = buth + butdh + butdrest;

% main text options
distt = [10 5];
maintxth = 35;

% height options
opth = 30;
optsep = 15;
hg = nopt * opth + (nopt + 1) * optsep + (buth+butdh+butdrest) + ...
    sum(distt) + maintxth;

hs.hf = figure('Units', 'pixels', 'Position', [350, 350, wg, hg],...
    'Visible', 'off', 'menubar', 'none');

% main text
hs.maintxt = uicontrol('Style', 'text',...
        'Units', 'pixels', 'Position', ...
        [descdist, hg - (maintxth + distt(2)), ...
        wg - descdist*2, maintxth], ...
        'String', maintext, 'FontSize', 16, ...
        'Parent', hs.hf);

for o = 1:nopt
    myh = (nopt - o) * opth + (nopt - o) * optsep + abvbut;
    
    % text
    hs.txt(o) = uicontrol('Style', 'text',...
        'Units', 'pixels', 'Position', [descdist, myh, ...
        desl, opth], 'String', opts{o},...
        'FontSize', 12, 'Parent', hs.hf);
    
    % edit
    hs.edit(o) = uicontrol('Style', 'edit',...
        'Units', 'pixels', 'Position', [descdist*2 + desl,...
        myh, editl, opth], 'String', optval{o},...
        'FontSize', 12, 'Parent', hs.hf);
end

% add buttons
hs.ok = uicontrol('Style', 'pushbutton', 'Units', 'pixels',...
    'Position', [butdw, butdh, butw, buth], 'String', 'OK',...
    'FontSize', 14, 'Parent', hs.hf);
hs.cancel = uicontrol('Style', 'pushbutton', 'Units', 'pixels',...
    'Position', [butdw*2 + butw, butdh, butw, buth], 'String', 'Cancel',...
    'FontSize', 14, 'Parent', hs.hf);
    

set(hs.hf, 'Visible', 'on');

