function test_bug1808

% MEM 1gb
% WALLTIME 00:10:00
% DEPENDENCY ft_read_header ft_read_sens mne2grad
% DATA private

dataset = dccnpath('/project/3031000.02/test/bug1808/reduced.fif');

hdr  = ft_read_header(dataset);
grad = ft_read_sens(dataset);


