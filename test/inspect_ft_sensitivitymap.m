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
cfg             = [];
cfg.mode        = 'fixed';
cfg.ch_type     = 'megmag';
leadfield_meg.smap = ft_sensitivitymap([],leadfield_meg);

%

figure(88);clf;
ft_plot_mesh(sourcemodel,'vertexcolor',leadfield_meg.smap')


function subj = datainfo_subject(subject, datapath)

if nargin<1 || isempty(subject)
  % this is the default subject
  subject = 15;
end
  
subj_name = sprintf('sub-%02d', subject);

%% specify the root location of all files
if nargin<2 || isempty(datapath)
  f = mfilename('fullpath');
  f = split(f, '/');
  datapath = fullfile('/',f{1:end-2}); % assume that this function lives in a directory one-level down from the datadir
end

%% specify the location of the input and output files

% with the data organized according to BIDS, the sss files are in the
% derivatives folder.
megpath    = fullfile(datapath, 'derivatives', 'meg_derivatives', subj_name, 'ses-meg', 'meg');
mripath    = fullfile(datapath, subj_name, 'ses-mri', 'anat');
eventspath = fullfile(datapath, subj_name, 'ses-meg', 'meg');

outputpath = fullfile(datapath, 'derivatives');
if ~exist(fullfile(outputpath), 'dir')
  mkdir(fullfile(outputpath));
end

subdirs = {'raw2erp' 'sensoranalysis' 'anatomy' 'sourceanalysis' 'groupanalysis'};
for m = 1:numel(subdirs)
  if ~exist(fullfile(outputpath, subdirs{m}), 'dir')
    mkdir(fullfile(outputpath, subdirs{m}));
  end
  if ~exist(fullfile(outputpath, subdirs{m}, subj_name), 'dir')
    mkdir(fullfile(outputpath, subdirs{m}, subj_name));
  end
    
end

%% specify the names of the MEG datasets
megfile = cell(6,1);
eventsfile = cell(6,1);
for run_nr = 1:6
  megfile{run_nr}    = fullfile(megpath,    sprintf('%s_ses-meg_task-facerecognition_run-%02d_proc-sss_meg.fif', subj_name, run_nr));
  eventsfile{run_nr} = fullfile(eventspath, sprintf('%s_ses-meg_task-facerecognition_run-%02d_events.tsv', subj_name, run_nr));  
end

%% specify the name of the anatomical MRI -> check whether this works on windows
mrifile = fullfile(mripath, sprintf('%s_ses-mri_acq-mprage_T1w.nii.gz', subj_name));
fidfile = strrep(mrifile, 'nii.gz', 'json');

subj = struct('id',subject,'name',subj_name,'mrifile',mrifile,'fidfile',fidfile,'outputpath',outputpath);
subj.megfile    = megfile;
subj.eventsfile = eventsfile;

%% other subject-specific information could also go here, especially if
% it follows from a manual assesment or analysis. Examples are
%  - bad channels
%  - bad data segments
%  - deviations from trigger codes
%  - anatomical information for coregistration

end