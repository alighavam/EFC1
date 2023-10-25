function ANA = efc1_subj(subjName,varargin)

% Handling the input arguments:
smoothing_win_length = 25; % window size is in ms
vararginoptions(varargin,{'smoothing_win_length'});

% setting paths:
usr_path = userpath;
usr_path = usr_path(1:end-17);

% subjName: name of the subject in the format of 'subj01', 'subj02', ...

% set file names:
datFileName = ['data/' subjName '/' 'efc1_' num2str(str2num(subjName(end-1:end))) '.dat'];   % input .dat file
outFileName = [usr_path '/Desktop/Projects/EFC1/analysis/efc1_' subjName '_raw.mat'];    % output file (saved in analysis folder)

% load .dat file:
D = dload(datFileName);

% container for the struct:
ANA = [];

oldBlock = -1;
% loop on trials:
for i = 1:length(D.BN)
    % load the mov file for each block:
    if (oldBlock ~= D.BN(i))
        fprintf("Loading the .mov file.\n")
        mov = movload(['data/' subjName '/' 'efc1_' num2str(str2num(subjName(end-1:end))) '_' num2str(D.BN(i),'%02d') '.mov']);
        oldBlock = D.BN(i);
    end
    fprintf('Block: %d , Trial: %d\n',D.BN(i),D.TN(i));
    C = efc1_trial(getrow(D,i),mov(D.TN(i)),smoothing_win_length);
    ANA=addstruct(ANA,C,'row','force');
end

save(outFileName,'-struct','ANA');









