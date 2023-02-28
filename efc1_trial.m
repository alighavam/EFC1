function C = efc1_trial(row,mov)

addpath(genpath('/Users/aghavampour/Documents/MATLAB/dataframe-2016.1'),'-begin');

C = [];
if (row.trialPoint==0)
    row.RT = 10000;   % correction for execution error trials
end
C = addstruct(C,row,'row','force');
C.mov = mov;