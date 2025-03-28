function test_bug1894

% MEM 1gb
% WALLTIME 00:10:00
% DEPENDENCY ft_singleplotTFR ft_daattype_freq ft_datatype_sens ft_chantype
% DATA private

load(dccnpath('/project/3031000.02/test/bug1894.mat'));

cfg = [];
ft_multiplotTFR (cfg, freq);
ft_singleplotTFR(cfg, freq);
ft_topoplotTFR  (cfg, freq);

ft_datatype_sens(freq.grad);
