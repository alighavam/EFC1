function mean_dev = calculate_mean_dev(mov, chordID, force_threshold)
% Description: 
%       Calculated mean deviation for the trial. 
%
% INPUTS:
%       bluh
%
% OUTPUTS:
%       bluh

% container for thresholded force data:
forceTmp = [];

% time vector of the force signals:
tVec = mov(:,3);

% time of Go Cue, first time when state variable becomes 3:
tGoCue = mov(find(mov(:,1)==3,1),3);

% Turning chordID into a char array:
chordID = num2str(chordID);

% Gain applied to the fingers:
fGainVec = [fGain1 fGain2 fGain3 fGain4 fGain5];

% thresholding force of the fingers after "Go Cue" to find the first time
% a finger goes out of the baseline zone:
% Looping through fingers:
for j = 1:5
    % if instructed movement was extension:
    if (chordID(j) == '1')
        % adding the thresholded force signal to the forceTmp:
        forceTmp = [forceTmp (mov(tVec>=tGoCue,13+j)*fGainVec(j) > force_threshold)]; 

    % if instructed movement was flexion:
    elseif (chordTmp(j) == '2')
        forceTmp = [forceTmp (mov(tVec>=tGoCue,13+j)*fGainVec(j) < -force_threshold)];

    % if finger should be relaxed:
    elseif (chordTmp(j) == '9') % finger should be relaxed
        forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)) ...
            | subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
        if (isempty(find(forceTmp(:,end),1)))
            forceTmp(:,end) = [];
        end
    end
end


tmpIdx = [];
for k = 1:size(forceTmp,2)
    tmpIdx(k) = find(forceTmp(:,k),1);
end
[sortIdx,~] = sort(tmpIdx); % sortIdx(1) is the first index after "Go Cue" that the first finger crossed the baseline thresh
idxStart = find(tVec==tGoCue)+sortIdx(1)-1; % index that the first active finger passes the baseline threshold after "Go Cue"
forceSelceted = [];
durAfterActive = subjData.RT(trialIdx(trial_i))-600;    % select the force from movement initiation until the correct state is formed
% durAfterActive = 200;   % select the force from movement initiation until 200ms later
for j = 1:5     % getting the force from idxStart to idxStart+durAfterActive
    forceSelceted = [forceSelceted subjForceData{trialIdx(trial_i)}(idxStart:find(tVec==tGoCue)+round(durAfterActive/2),2+j)];
end

tempDiff = zeros(size(forceSelceted,1),1);
c = forceSelceted(end,:)-forceSelceted(1,:);
for t = 1:size(forceSelceted,1) % iterating on time points
    projection = (c * forceSelceted(t,:)' / norm(c)^2)*c;
    tempDiff(t) = norm(forceSelceted(t,:) - projection);
end
meanDevTmp(trial_i) = sum(tempDiff) / size(forceSelceted,1);


