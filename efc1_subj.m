function ANA = efc1_subj(subjName)
% subjName: name of the subject in the format of 'subj01', 'subj02', ...
addpath(genpath('/Users/aghavampour/Documents/MATLAB/dataframe-2016.1'),'-begin');

datFileName = ['data/' subjName '/' 'efc1_' num2str(str2num(subjName(end-1:end))) '.dat'];   % input .dat file
outFileName = ['/Users/aghavampour/Desktop/Projects/ExtFlexChord/efc1/analysis/efc1_' subjName '.mat'];    % output file (saved to analyse folder)

D = datload(datFileName);
ANA = [];

oldBlock = -1;
for i = trials
    if (oldBlock ~= D.BN(i))
        % load mov file for the block
        fprintf("Loading the .mov file.\n")
        mov = movload(['data/' subjName '/' 'efc1_' num2str(str2num(subjName(end-1:end))) '_' num2str(D.BN(i),'%02d') '.mov']);
        oldBlock = D.BN(i);
    end
    fprintf('Block: %d , Trial: %d\n',D.BN(i),D.TN(i));
    C = efc1_trial(getrow(D,i),mov(D.TN(i)));
    ANA=addstruct(ANA,C,'row','force');
end

save(outFileName,'-struct','ANA');









