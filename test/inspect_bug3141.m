function inspect_bug3141

% WALLTIME 00:10:00
% MEM 1gb
% DEPENDENCY ft_defacemesh ft_defacevolume
% DATA public

[ftver, ftpath] = ft_version;
templatedir  = fullfile(ftpath, 'template');

%% anatomical mri

mri = ft_read_mri(dccnpath('/project/3031000.02/external/download/test/ctf/Subject01.mri'));

cfg = [];
defaced = ft_defacevolume(cfg, mri);

cfg = [];
ft_sourceplot(cfg, defaced);


%% head shape

headshape = ft_read_headshape(dccnpath('/project/3031000.02/external/download/test/ctf/Subject01.shape'));

cfg = [];
defaced = ft_defacemesh(cfg, headshape);

figure
ft_plot_mesh(defaced);

%% 3D grid source model

% this MATLAB file contains the variable sourcemodel
load(fullfile(templatedir, 'sourcemodel' , 'standard_sourcemodel3d4mm.mat'));

cfg = [];
defaced = ft_defacemesh(cfg, sourcemodel);

figure
ft_plot_mesh(defaced.pos(defaced.inside,:));

%% cortical sheet source model

sourcemodel = ft_read_headshape(fullfile(templatedir, 'sourcemodel', 'cortex_8196.surf.gii'));

cfg = [];
defaced = ft_defacemesh(cfg, sourcemodel);

figure
ft_plot_mesh(defaced);
camlight
lighting phong
