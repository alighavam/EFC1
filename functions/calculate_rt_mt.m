function [rt,mt,first_finger] = calculate_rt_mt(mov, chordID, force_threshold, completion_time, fGain1, fGain2, fGain3, fGain4, fGain5)
% Description: 
%       Calculate rt and mt of the trial.
%
% INPUTS:
%       mov: the matrix that contains the mov data of the trial
%
%       chordID: ID of the chord. e.g. 12999 -> extension thumb, flexion
%       inedx, others relaxed.
%       
%       force_threshold: the force threshold of the baseline zone. 
%       
%       completion_time: Time from t=0 until the end of the execution phase
%
%       fGain<1 to 5>: Gains that was applied on the finger forces. These
%       are software gains. 
%
% OUTPUTS:
%       rt (ms): reaction time, defined as the time from the go cue to the time
%       the first finger goes out of the baseline zone.
%       
%       mt (ms): time from rt until reaching the holding state.

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
active_fingers = [];
% Looping through fingers:
for j = 1:5
    % if instructed movement was extension:
    if (chordID(j) == '1')
        % Here it is assumed that if finger is instructed to extend, the
        % reaction time only makes sense when finger moves towards the
        % instructed state:
        forceTmp = [forceTmp (mov(tVec>=tGoCue,13+j)*fGainVec(j) > force_threshold)];
        
        % Save the active finger:
        active_fingers = [active_fingers j];

        % just as a sanity check that the finger has gone out of the 
        % baseline if instructed:
        if (isempty(find(forceTmp(:,end),1)))
            error('Mean Dev calculation error: Finger %d instructed to extend but does not look like it did. ChordID: %s',...
                j,chordID)
        end

    % if instructed movement was flexion:
    elseif (chordID(j) == '2')
        % Here it is assumed that if finger is instructed to extend, the
        % reaction time only counts when finger moves towards the
        % instructed state:
        forceTmp = [forceTmp (mov(tVec>=tGoCue,13+j)*fGainVec(j) < -force_threshold)];

        % Save the active finger:
        active_fingers = [active_fingers j];
        
        % just as a sanity check that the finger has gone out of the 
        % baseline if instructed:
        if (isempty(find(forceTmp(:,end),1)))
            error('Mean Dev calculation error: Finger %d instructed to flex but does not look like it did. ChordID: %s',...
                j,chordID)
        end

    % if finger should be relaxed:
    elseif (chordID(j) == '9')
        % If the finger should have been relaxed, we assume that if the
        % finger goes out of the baseline zone -both from extension and
        % flexion- it counts as RT:
        forceTmp = [forceTmp (mov(tVec>=tGoCue,13+j)*fGainVec(j) < -force_threshold | mov(tVec>=tGoCue,13+j)*fGainVec(j) > force_threshold)]; 
        
        % Save the active finger:
        active_fingers = [active_fingers j];

        % If finger never left the baseline zone as it should have, remove
        % the thresholded signal because it is all 0:
        if (isempty(find(forceTmp(:,end),1)))
            forceTmp(:,end) = [];
            active_fingers(end) = [];
        end
    end
end

% find the first index where each finger moved out of the baseline:
tmpIdx = [];
for k = 1:size(forceTmp,2)
    tmpIdx(k) = find(forceTmp(:,k),1);
end

% Finding the earliest time that a finger went out of the baseline, 
% sortIdx(1) is the first index after "Go Cue" that the first finger 
% crossed the baseline threshold:
[sortIdx,~] = sort(tmpIdx);

% the finger that moved out of baseline:
first_finger = active_fingers(find(tmpIdx == sortIdx(1),1));
if (length(find(tmpIdx == sortIdx(1))) > 1)
    
end

% reaction time, from tGoCue until the first finger goes out of baseline:
rt = sortIdx(1)/500 * 1000; % 500Hz is the fs

% movement time:
mt = completion_time - rt - 600;

% check if rt and mt make sense:
if (rt <= 0 || isnan(rt))
    warning(['calc_rt_mt: The calculated rt is %.2f. The value of rt should not ' ...
        'be negative or 0 if the trial is correct and everything is saved correctly.'],rt)
end

if (mt <= 0 || mt > completion_time - 600)
    warning(['calc_rt_mt: The calculated rt is %.2f. The value of mt should not ' ...
        'be negative or 0 if the trial is correct and everything is saved correctly.'],mt)
end



