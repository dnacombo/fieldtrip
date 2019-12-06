function smap = ft_sensitivitymap(cfg,leadfield)

% FT_SENSITIVITYMAP Compute sensitivity map.
% 
% Such maps are used to know how much sources are visible by a type of
% sensor, and how much components shadow some sources. 
%
% Use as
%   [smap] = ft_sensitivitymap(cfg, leadfield)
%
% The configuration should contain
% 
%     cfg.mode          The type of sensitivity map computed. See manual.
%                       Should be 'free', 'fixed', 'ratio', 'radiality',
%                       ['angle', 'remaining', or 'dampening'] NOT IMPLEMENTED
%     cfg.ch_type       'grad' | 'mag' | 'eeg'
%     cfg.excludelist   List of channels to exclude. If empty do not
%                       exclude any (default).  
% 
% 
% See also 

% these are used by the ft_preamble/ft_postamble function and scripts
ft_revision = '$Id$';
ft_nargin   = nargin;
ft_nargout  = nargout;

% do the general setup of the function
ft_defaults
ft_preamble init
ft_preamble debug
ft_preamble trackconfig

% the ft_abort variable is set to true or false in ft_preamble_init
if ft_abort
  return
end

% set the defaults
cfg.mode      = ft_getopt(cfg, 'mode',         'fixed');
cfg.ch_type   = ft_getopt(cfg, 'ch_type',      '');
cfg.excludelist= ft_getopt(cfg, 'excludelist', 'fixed');

for i_s = 1:numel(leadfield.leadfield)
    g = leadfield.leadfield{i_s};
    if isempty(g)
        smap = NaN;
        continue
    end
    if ~strcmp(cfg.mode,'fixed')
        s = svd(g);
    end
    if strcmp(cfg.mode,'free')
        smap(i_s) = s(1);
    else
        gz = norm(g(:,3));
        if strcmp(cfg.mode,'fixed')
            smap(i_s) = gz;
        elseif strcmp(cfg.mode,'ratio')
            smap(i_z) = gz/s(1);
        elseif strcmp(cfg.mode,'radiality')
            smap(i_z) = 1 - (gz/s(1));
        else
            error('not implemented')
            if strcmp(cfg.mode,'angle')
                % this is the python code
                % computing U is done in proj.py make_projector
                
                % co = linalg.norm(dot(g(:,3), U))
                % sensitivity_map[k] = co / gz
            else
                % this is the python code
                % computing proj is done in proj.py make_projector

                % p = linalg.norm(np.dot(proj, gg[:, 2]))
                % if mode == 'remaining':
                %     sensitivity_map[k] = p / gz
                %     elif mode == 'dampening':
                %     sensitivity_map[k] = 1. - p / gz
                % else:
                %     raise ValueError('Unknown mode type (got %s)' % mode)
            end
        end
    end
end
switch cfg.mode
    case {'fixed' 'free'}
        smap = smap ./ max(smap);
end
