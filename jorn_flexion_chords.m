
ANA = [];
rename = [345, 145, 234, 123, 124, 134, 125, 245, 235, 135];
jorn_chords = [99222,29922,92229,22299,22929,29229,22992,92922,92292,29292];

data_mean_dev = calc_mean_dev(data);

for i = 1:size(data_mean_dev,1)
    tmp = data_mean_dev{i,1};

    [idx_select, ~] = find(tmp.chordID == jorn_chords);
    idx_select = sort(idx_select);
    tmp = getrow(tmp,idx_select);

    RT_tmp = tmp.RT;

    % making an new field. This field will be filled later:
    tmp.MT = tmp.RT;

    disp(i)
    for i_t = 1:length(tmp.BN)  % loop on trials
        [RT,MT] = getSeparateRT(getrow(tmp,i_t));
        tmp.RT(i_t) = RT;
        tmp.MT(i_t) = MT;
    end
    
    tmp.success_time = RT_tmp;
    tmp = rmfield(tmp,{'mov','trialPoint'});

    for j = 1:length(tmp.BN)
        ANA = addstruct(ANA,getrow(tmp,j),'row','force');
    end
end

for i = 1:length(jorn_chords)
    [idx,~] = find(ANA.chordID == jorn_chords(i));
    ANA.chordID(idx) = rename(i);
end

dsave('jorn_data.tsv',ANA)


%% Functions:

function data = calc_mean_dev(data)
    forceData = cell(size(data));
    for i = 1:size(data,1)
        forceData{i,1} = extractDiffForce(data{i,1});
        forceData{i,2} = data{i,2};
    end
    meanDevCell = cell(size(data,1),2);
    
    for subj = 1:size(data,1)
        data{subj,1}.mean_dev = zeros(length(data{subj,1}.BN),1);
        chordVec = generateAllChords();                 % make all chords
        subjForceData = forceData{subj,1};
        subjData = data{subj,1};
        meanDevCell{subj,2} = data{subj,2};
        vecBN = unique(subjData.BN);
        meanDevCellSubj = cell(length(chordVec),2);
        for i = 1:length(chordVec)
            
            meanDevCellSubj{i,1} = chordVec(i);      % first columns: chordID
            
            trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1);
            
            if (~isempty(trialIdx))
                chordTmp = num2str(chordVec(i));
                meanDevTmp = zeros(length(trialIdx),1);
                for trial_i = 1:length(trialIdx)
                    forceTmp = [];
                    tVec = subjForceData{trialIdx(trial_i)}(:,2);   % time vector in trial
                    tGoCue = subjData.planTime(trialIdx(trial_i));
                    fGainVec = [subjData.fGain1(trialIdx(trial_i)) subjData.fGain2(trialIdx(trial_i)) subjData.fGain3(trialIdx(trial_i)) subjData.fGain4(trialIdx(trial_i)) subjData.fGain5(trialIdx(trial_i))];
                    for j = 1:5     % thresholded force of the fingers after "Go Cue"
                        if (chordTmp(j) == '1') % extension
                            forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                            if (isempty(find(forceTmp(:,end),1)))
                                forceTmp(:,end) = [];
                            end
                        elseif (chordTmp(j) == '2') % flexion
                            forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                            if (isempty(find(forceTmp(:,end),1)))
                                forceTmp(:,end) = [];
                            end
                        elseif (chordTmp(j) == '9') % finger should be relaxed
                            forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)) ...
                                | subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                            if (isempty(find(forceTmp(:,end),1)))
                                forceTmp(:,end) = [];
                            end
                        end
                    end
                    
                    if (isempty(find(forceTmp,1)))  % if no fingers moved out of threshold, go to next trial
                        disp("empty forceTmp")
                        continue
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
                    data{subj,1}.mean_dev(trialIdx(trial_i)) = meanDevTmp(trial_i);
                end
                meanDevCellSubj{i,2} = meanDevTmp;
            else
                meanDevCellSubj{i,2} = [];
            end 
        end
        meanDevCell{subj,1} = meanDevCellSubj;
        
    end
end    

