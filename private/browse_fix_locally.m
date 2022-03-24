function browse_fix_locally(~,data)

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

% if ~any(strcmp(opt.artdata.label,channame))
%   opt.artdata.label{end+1} = channame;
%   opt.artdata.trial{1}(end+1,:) = false;
% end
% opt.artdata.trial{1}(strcmp(opt.artdata.label,channame),data.sampleinfo(1):data.sampleinfo(2)) = true;

if ~isfield(cfg, 'preproc') || ~isfield(cfg.preproc, 'tofix')
  cfg.preproc.tofix = struct('chan',{},'trials',[], 'isinterp', []);
elseif ~isfield(cfg.preproc.tofix, 'isinterp')
  for i = 1:numel(cfg.preproc.tofix)
    for j = 1:numel(cfg.preproc.tofix(i).trials)
      cfg.preproc.tofix(i).isinterp(j) = 0;
    end
  end
end
if any(strcmp(channame,{cfg.preproc.tofix.chan}))
  ch = strcmp(channame,{cfg.preproc.tofix.chan});
  if ismember(cfg.preproc.tofix(ch).trials, currentTrial)
    cfg.preproc.tofix(ch).trials(cfg.preproc.tofix(ch).trials == currentTrial)  = [];
    cfg.preproc.tofix(ch).isinterp(cfg.preproc.tofix(ch).trials == currentTrial)  = [];
  else
    cfg.preproc.tofix(ch).trials(end+1)  = currentTrial;
    cfg.preproc.tofix(ch).isinterp(end+1) = 0;
  end
else
  cfg.preproc.tofix(end+1).chan = channame;
  cfg.preproc.tofix(end).trials  = currentTrial;
  cfg.preproc.tofix(end).isinterp = 0;
end

for i = 1:numel(cfg.preproc.tofix)
  for j = 1:numel(cfg.preproc.tofix(i).trials)
    if cfg.preproc.tofix(i).isinterp(j)
      continue
    end
    tmpcfg = [];
    tmpcfg.method = 'average';
    tmpcfg.badchannel = {cfg.preproc.tofix(i).chan};
    tmpcfg.trials = cfg.preproc.tofix(i).trials(j);
    tmpcfg.neighbours = cfg.neighbours;
    nudata = ft_channelrepair(tmpcfg,opt.orgdata);
    opt.orgdata.trial{cfg.preproc.tofix(i).trials(j)} = nudata.trial{1};
    cfg.preproc.tofix(i).isinterp(j) = 1;
  end
end

setappdata(parentfigure(h),'opt',opt);
setappdata(parentfigure(h),'cfg',cfg);
feval(opt.redraw_cb, h)

return