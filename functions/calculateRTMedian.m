function [medianRT] = calculateRTMedian(dat)
% Ali Ghavampour 2023 - alighavam79@gmail.com
% This function calculates median reaction time of the chords.
% medianRT:
%   1st column = chordID
%   2nd column = median of the first 5 executions
%   3rd column = median of the second 5 executions
%   4th column = median of all 10 executions together
% note: note that it is not guaranteed that we have 5 executions in each
% block because of the subject errors.

chordVec = generateAllChords(); % vector of all chords
nChords = length(chordVec);     % number of chords

medianRT = zeros(size(chordVec,1),3);
medianRT(:,1) = chordVec;

for i = 1:nChords
    tmpChord = chordVec(i);
    RTs = dat.RT(dat.chordID == tmpChord);  % RT of all trials
    RT1 = RTs(1:5);                         % RT of first block
    RT1(RT1==0) = [];                       % removing the planning error trials
    RT2 = RTs(6:end);                       % RT of second block
    RT2(RT2==0) = [];                       % removing the planning error trials
    allRTs = RTs;
    allRTs(allRTs==0) = [];
    if (isempty(RT1))                       % If all of the trials failed
        med1 = 0;                           % zero indicates that all trials had planning error
    else
        med1 = median(RT1);                 % median of first block
    end
    if (isempty(RT2))                       % If all of the trials failed
        med2 = 0;                           % zero indicates that all trials had planning error
    else
        med2 = median(RT2);                 % median of second block
    end
    if (isempty(allRTs))                    % If all of the trials failed
        med3 = 0;                           % zero indicates that all trials had planning error
    else
        med3 = median(allRTs);              % median of all trials
    end
    medianRT(i,2) = med1;
    medianRT(i,3) = med2;
    medianRT(i,4) = med3;
end




























