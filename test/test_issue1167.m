function test_issue1167

% MEM 1gb
% WALLTIME 00:10:00
% DEPENDENCY edf2fieldtrip
% DATA no

filename = {'ma0844az_1-1+.edf';
            'test_generator.edf';
            'test_generator_2.edf'};
          
for k = 1:3
  data{k} = edf2fieldtrip(dccnpath(fullfile('/project/3031000.02/test/original/eeg/edf', filename{k})));
end
