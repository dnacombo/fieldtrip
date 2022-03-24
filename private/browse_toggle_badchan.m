function browse_toggle_badchan(~,data)

h = gca;
opt = getappdata(parentfigure(h), 'opt');
cfg = getappdata(parentfigure(h), 'cfg');

val = get(h,'CurrentPoint');
val = [val(1,1) val(1,2)];
% hold on;
% scatter(val(1),val(2));

if strcmp(cfg.viewmode, 'butterfly') || strcmp(cfg.viewmode, 'vertical')
      switch cfg.viewmode
        case 'butterfly'
          % transform 'val' to match data
          val(1) = val(1) * range(opt.hlim) + opt.hlim(1);
          val(2) = val(2) * range(opt.vlim) + opt.vlim(1);
          channame = val2nearestchan(opt.curdata,val);
          channb   = match_str(opt.curdata.label,channame);
          % set chanposind
          chanposind = 1; % butterfly mode, pos is the first for all channels
        case 'vertical'
          % find channel identity by extracting timecourse objects and finding the time course closest to the cursor
          % this is a lot easier than the reverse, determining the y value of each time course scaled by the layout and vlim
          tcobj   = findobj(h, 'tag', 'timecourse');
          tmpydat = get(tcobj, 'ydata');
          tmpydat = cat(1,tmpydat{:});
          tmpydat = tmpydat(end:-1:1,:); % order of timecourse objects is reverse of channel order
          tmpxdat = get(tcobj(1), 'xdata');
          % first find closest sample on x
          xsmp = nearest(tmpxdat,val(1));
          % then find closes y sample, being the channel number
          channb   = nearest(tmpydat(:,xsmp),val(2));
          channame = opt.curdata.label{channb};
          % set chanposind
%           chanposind = match_str(opt.layouttime.label,channame);
      end
      fprintf('channel name: %s\n',channame);
end
xl = xlim;
currentTime = (val(1) - xl(1))/diff(xl) * cfg.blocksize + cfg.blocksize * (opt.trlop-1);
currentSample = round(currentTime * opt.fsample);
currentTrial = find(currentSample > opt.orgdata.sampleinfo(:,1) & currentSample < opt.orgdata.sampleinfo(:,2));

if ~isfield(cfg, 'preproc') || ~isfield(cfg.preproc, 'badchannel') || ~isfield(cfg.preproc.badchannel, 'name')
  cfg.preproc.badchannel = struct('name',{},'col',{});
end
if any(strcmp(channame,{cfg.preproc.badchannel.name}))
  chdel = strcmp(channame,{cfg.preproc.badchannel.name});
  opt.linecolor(channb,:) = cfg.preproc.badchannel(chdel).col;
  cfg.preproc.badchannel(chdel) = [];
else
  cfg.preproc.badchannel(end+1).name = channame;
  cfg.preproc.badchannel(end).col = opt.linecolor(channb,:);
  opt.linecolor(channb,:) = [.8 .8 .8];
end

setappdata(parentfigure(h),'opt',opt);
setappdata(parentfigure(h),'cfg',cfg);
feval(opt.redraw_cb, h)

return