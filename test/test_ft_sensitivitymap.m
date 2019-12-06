% test using the practicalMEEG data


subj = datainfo_subject(1,'/home/maximilien.chaumon/owncloud/Lab/00-Projects/cuttingEEG/PracticalMEEG/data/ds000117-practical');


% load the sensor-level data
filename = fullfile(subj.outputpath, 'raw2erp', subj.name, sprintf('%s_data', subj.name));
load(filename, 'data');

% select the electrophysiological channels
cfg         = [];
cfg.channel = {'MEG'};
data        = ft_selectdata(cfg, data);

% select the 'baseline'
cfg         = [];
cfg.latency = [-0.2 0];
baseline    = ft_selectdata(cfg, data);

% compute the baseline covariance
cfg            = [];
cfg.covariance = 'yes';
baseline_avg   = ft_timelockanalysis(cfg, baseline);

selmag  = ft_chantype(baseline_avg.label, 'megmag');
selgrad = ft_chantype(baseline_avg.label, 'megplanar');

% an SVD gives an indication of the numerical properties of a matrix
[u,s,v] = svd(baseline_avg.cov);

[u,s_mag,v]  = svd(baseline_avg.cov(selmag,  selmag));
[u,s_grad,v] = svd(baseline_avg.cov(selgrad, selgrad));

d_mag = -diff(log10(diag(s_mag))); d_mag = d_mag./std(d_mag);
kappa_mag = find(d_mag>4,1,'first');
d_grad = -diff(log10(diag(s_grad))); d_grad = d_grad./std(d_grad);
kappa_grad = find(d_grad>4,1,'first');

cfg            = [];
cfg.channel    = 'meg';
cfg.kappa      = min(kappa_mag,kappa_grad);
dataw_meg      = ft_denoise_prewhiten(cfg, data, baseline_avg);

% select the 'baseline'
cfg         = [];
cfg.latency = [-0.2 0];
baselinew   = ft_selectdata(cfg, dataw_meg);

% compute the baseline covariance
cfg            = [];
cfg.covariance = 'yes';
baselinew_avg   = ft_timelockanalysis(cfg, baselinew);

selmag  = ft_chantype(baselinew_avg.label, 'megmag');
selgrad = ft_chantype(baselinew_avg.label, 'megplanar');

% compute the svd on the whitened covariance matrix
[u,s,v] = svd(baselinew_avg.cov);
%
cfg                = [];
cfg.preproc.baselinewindow = [-0.2 0];
cfg.preproc.demean = 'yes';
cfg.covariance     = 'yes';
tlckw              = ft_timelockanalysis(cfg, dataw_meg);

% obtain the necessary ingredients for obtaining a forward model
load(fullfile(subj.outputpath, 'anatomy', subj.name, sprintf('%s_headmodel', subj.name)));
load(fullfile(subj.outputpath, 'anatomy', subj.name, sprintf('%s_sourcemodel', subj.name)));
headmodel   = ft_convert_units(headmodel,tlckw.grad.unit);
sourcemodel = ft_convert_units(sourcemodel,tlckw.grad.unit);
sourcemodel.inside = sourcemodel.atlasroi>0;

% compute the forward model for the whitened data
cfg             = [];
cfg.channel     = tlckw.label;
cfg.grad        = tlckw.grad;
cfg.sourcemodel = sourcemodel;
cfg.headmodel   = headmodel;
cfg.method      = 'singleshell';
cfg.singleshell.batchsize = 1000;
leadfield_meg   = ft_prepare_leadfield(cfg); % NOTE: input of the whitened data ensures the correct sensor definition to be used

%% sensitivity map
leadfield_meg.smap = ft_sensitivitymap([],leadfield_meg);

%%

figure;
ft_plot_mesh(sourcemodel,'vertexcolor',leadfield_meg.smap')
