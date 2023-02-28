function ANA = efc1_subj(subjName,fig,block,trial)
% subjName: name of the subject in the format of 'subj01', 'subj02', ...
addpath(genpath('/Users/aghavampour/Documents/MATLAB/dataframe-2016.1'),'-begin');

if (nargin<2)
    fig = 0;
end
datFileName = ['data/' subjName '/' 'efc1_' num2str(str2num(subjName(end-1:end))) '.dat'];   % input .dat file
outFileName = ['/Users/aghavampour/Desktop/Projects/ExtFlexChord/efc1/analysis/efc1_' subjName '.mat'];    % output file (saved to analyse folder)

D = datload(datFileName);
ANA = [];

% define the trials we want to analyze
if (nargin<3)
    trials = 1:length(D.BN);
elseif (nargin<4)
    trials = [find(D.BN==block)];
else
    idxEnd = find(D.BN==block);
    trials = find(D.BN==block & D.TN==trial):idxEnd(end);
end

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









