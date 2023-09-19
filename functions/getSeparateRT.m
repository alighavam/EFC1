function [firstRT,execRT] = getSeparateRT(row)

chordID = num2str(row.chordID);
flexThreshold = row.flexBotThresh;
extThreshold = row.extBotThresh;
RT = row.RT-600;

if (row.trialErrorType == 1)   % planning error trials
    firstRT = 0;
    execRT = 0;
    return
elseif (row.trialErrorType == 2)    % unsuccessful chord execution 
    firstRT = 10000;
    execRT = 10000;
    return
elseif (sum(chordID=='1' | chordID=='2')==1)    % one finger flexion or extension
    firstRT = RT;
    execRT = RT;
    return
end

forces = extractDiffForce(row);
forces = forces{1};
forces(:,2+4) = forces(:,2+4)*row.fGain4;
forces(:,2+5) = forces(:,2+5)*row.fGain5;
thresholdedForce = [];
for i = 1:5 % loop on fingers
    fingerState = chordID(i);
    if (strcmp(fingerState,'1'))   % if finger was not relaxed
        forceTmp = forces(:,i+2);
        forceTmp = forceTmp >= extThreshold;
        thresholdedForce = [thresholdedForce , forceTmp];
    elseif (strcmp(fingerState,'2'))
        forceTmp = forces(:,i+2);
        forceTmp = forceTmp <= flexThreshold;
        thresholdedForce = [thresholdedForce , forceTmp];
    end
end

for i = 1:size(thresholdedForce,2)
    tmpIdx(i) = find(thresholdedForce(:,i),1);
end

[~,sortIdx] = sort(tmpIdx);

% finding firstRT time
firstRT = find(thresholdedForce(:,sortIdx(1)) & thresholdedForce(:,sortIdx(2)),1);
firstRT = forces(firstRT,2) - forces(find(forces(:,1)==3,1),2);
execRT = RT - firstRT;




