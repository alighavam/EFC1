%% Loading and initialization
clear;
close all;
clc;

% iMac
cd('/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1');
addpath('/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1/functions');
addpath('/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1')
addpath(genpath('/Users/aghavampour/Documents/MATLAB/dataframe-2016.1'),'-begin');

% macbook
% cd('/Users/alighavam/Desktop/Projects/ExtFlexChord/efc1');
% addpath('/Users/alighavam/Desktop/Projects/ExtFlexChord/efc1/functions');
% addpath('/Users/alighavam/Desktop/Projects/ExtFlexChord/efc1')
% addpath(genpath('/Users/alighavam/Documents/MATLAB/dataframe-2016.1'),'-begin')

% temporary analysis:

% loading data
% analysisDir = '/Users/alighavam/Desktop/Projects/ExtFlexChord/efc1/analysis';
analysisDir = '/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1/analysis';  % iMac
cd(analysisDir)
matFiles = dir("*.mat");
data = {};
cnt = 1;
for i = 1:length(matFiles)
    tmp = load(matFiles(i).name);
    if (length(tmp.BN) >= 2420 && ~strcmp(matFiles(i).name(6:11),'subj03'))         % more than or equal to 24 runs
        data{cnt,1} = tmp;
        data{cnt,2} = matFiles(i).name(6:11);
        cnt = cnt + 1;
    end
end

% temporary fix for the ongoing data recording
dataTmp = [];
for i = 1:size(data,1)
    if (length(unique(data{i,1}.BN)) >= 37 && length(unique(data{i,1}.BN)) <= 47)   % if data was not complete
        for j = 1:length(data{i,1}.BN)
            if (data{i,1}.BN(j) <= 36)
                dataTmp = addstruct(dataTmp,getrow(data{i,1},j),'row','force');
            end
        end
        data{i,1} = dataTmp;
    end
end

% temporary RT correction:
for i = 1:size(data,1)  % loop on subjects
    for i_t = 1:length(data{i,1}.BN)  % loop on trials
        if (data{i,1}.trialErrorType(i_t) == 1)     % errorType: '1'->planning error , '2'->exec error
            data{i,1}.RT(i_t) = 0;
        end
    end
end

% setting the RT type before any analysis:
RTtype = 'full'; % RT type

if (strcmp(RTtype,'full'))
    disp('RT type = full')
end
if (strcmp(RTtype,'firstRT'))
    disp('RT type = firstRT')
    for i = 1:size(data,1)  % loop on subjects
        disp(i)
        for i_t = 1:length(data{i,1}.BN)  % loop on trials
            [firstRT,~] = getSeparateRT(getrow(data{i,1},i_t));
            data{i,1}.RT(i_t) = firstRT+600;
        end
    end
end
if (strcmp(RTtype,'execRT'))
    disp('RT type = execRT')
    for i = 1:size(data,1)  % loop on subjects
        disp(i)
        for i_t = 1:length(data{i,1}.BN)  % loop on trials
            [~,execRT] = getSeparateRT(getrow(data{i,1},i_t));
            data{i,1}.RT(i_t) = execRT+600;
        end
    end
end


%% analysis
clc;
clearvars -except data
close all;

% global params:
corrMethod = 'pearson';
includeSubjAvgModel = 0;

% theta calc params:
onlyActiveFing = 0;
firstTrial = 2;
selectRun = -1;
durAfterActive = 200;
clim = [0,1];

% medRT params:
excludeChord = [];

% ====DATA PREP====
% efc1_analyze('all_subj'); % makes the .mat files from .dat and .mov of each subject

% ====ANALISYS====
% efc1_analyze('RT_vs_run',data,'plotfcn','median');

rho_medRT_WithinSubject = efc1_analyze('corr_within_subj_runs',data,'corrMethod',corrMethod,'excludeChord',excludeChord);

rho_medRT_acrossSubj = efc1_analyze('corr_across_subj',data,'plotfcn',1,'clim',clim,'corrMethod',corrMethod,'excludeChord',excludeChord);

rho_medRT_AvgModel = efc1_analyze('corr_medRT_avg_model',data,'corrMethod',corrMethod,'excludeChord',excludeChord,'includeSubj',includeSubjAvgModel);

thetaCell = efc1_analyze('thetaExp_vs_thetaStd',data,'durAfterActive',durAfterActive,'plotfcn',0,...
    'firstTrial',firstTrial,'onlyActiveFing',onlyActiveFing,'selectRun',selectRun);

rho_theta_acrossSubj = efc1_analyze('corr_mean_theta_across_subj',data,'thetaCell',thetaCell,'onlyActiveFing',onlyActiveFing, ...
    'firstTrial',firstTrial,'corrMethod',corrMethod,'plotfcn',1,'clim',clim);

rho_theta_avgModel = efc1_analyze('corr_mean_theta_avg_model',data,'thetaCell',thetaCell,'onlyActiveFing',onlyActiveFing, ...
    'firstTrial',firstTrial,'corrMethod',corrMethod,'includeSubj',includeSubjAvgModel);

% [rho_OLS_medRT, crossValModels_medRT, singleSubjModel_medRT] = efc1_analyze('reg_OLS_medRT',data,...
%     'regSubjNum',0,'excludeChord',excludeChord,'corrMethod',corrMethod);

% [rho_OLS_meanTheta, crossValModels_meanTheta, singleSubjModel_meanTheta] = efc1_analyze('reg_OLS_meanTheta',data,...
%     thetaCell,'regSubjNum',0,'corrMethod',corrMethod,'onlyActiveFing',onlyActiveFing,'firstTrial',firstTrial);

% efc1_analyze('plot_scatter_within_subj',data,'transform_type','ranked')

% efc1_analyze('plot_scatter_across_subj',data,'transform_type','no_transform')

% efc1_analyze('meanTheta_scatter_across_subj',data,thetaCell,'onlyActiveFing',onlyActiveFing,'firstTrial',firstTrial



% ====EXTRA PLOTS====
figure; % avgModel correlations comparison between medRT and meanTheta
hold all
scatter(1:length(rho_theta_avgModel{1}),rho_theta_avgModel{1},40,'k','filled','HandleVisibility','off')
plot(1:length(rho_theta_avgModel{1}),rho_theta_avgModel{1},'k','LineWidth',0.2)
scatter(1:length(rho_medRT_AvgModel{1}),rho_medRT_AvgModel{1},40,'r','filled','HandleVisibility','off')
plot(1:length(rho_medRT_AvgModel{1}),rho_medRT_AvgModel{1},'r','LineWidth',0.2)
title("correlation avg model")
xlabel("subj excluded")
ylabel("correlation of avg with excluded subj")
legend("meanTheta","medRT")
ylim([0,1])






%% ========================================================================
%% TEMPORARY CODES AND ANALYSIS FROM HERE !<UNDER CONSTRUCTION>!


%% Mean Deviation
clc
clearvars -except data
close all

% Params:
durAfterActive = 200;   % 200 ms after first active finger passes threshold
selectRun = -1;         % the 12 runs to select data from

forceData = cell(size(data));
for i = 1:size(data,1)
    forceData{i,1} = extractDiffForce(data(1,:));
    forceData{i,2} = data{i,2};
end

meanDCell = cell(size(data,1),2);
for subj = 1:size(data,1)
    chordVec = generateAllChords();                 % make all chords
    subjForceData = forceData{subj,1};
    subjData = data{subj,1};
    meanDCell{subj,2} = data{subj,2};
    meanDCell{subj,1} = zeros(size(chordVec,1),6);  % 6 = 1(chordID) + 5(number of repetitions for that chord)
    vecBN = unique(subjData.BN);
    for i = 1:length(chordVec)
        meanDCell{subj,1}(i,1) = chordVec(i);      % first columns: chordID
        if (selectRun == -1)    % selecting the last 12 runs
            trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > vecBN(end-12));
        elseif (selectRun == 1) % selecting the first 12 runs
            trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN < 13);
        elseif (selectRun == 2)
            trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > 12 & subjData.BN < 25);
        elseif (selectRun == 3)
            trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > 24 & subjData.BN < 37);
            iTmp = find(subjData.BN > 24 & subjData.BN < 37);
            if (isempty(iTmp))
                error("Error with <selectRun> option , " + data{subj,2} + " does not have block number " + num2str(selectRun))
            end
        else
            error("selectRun " + num2str(selectRun) + "does not exist. Possible choices are 1,2,3 and -1.")
        end

        if (~isempty(trialIdx))
            chordTmp = num2str(chordVec(i));
            for trial_i = 1:length(trialIdx)
                forceTmp = [];
                tVec = subjForceData{trialIdx(trial_i)}(:,2);   % time vector in trial
                tGoCue = subjData.planTime(trialIdx(trial_i));
                fGainVec = [subjData.fGain1(trialIdx(trial_i)) subjData.fGain2(trialIdx(trial_i)) subjData.fGain3(trialIdx(trial_i)) subjData.fGain4(trialIdx(trial_i)) subjData.fGain5(trialIdx(trial_i))];
                for j = 1:5     % thresholded force of the fingers after "Go Cue"
                    if (chordTmp(j) == '1') % extension
                        forceTmp = [forceTmp (fGainVec(j)*subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                    elseif (chordTmp(j) == '2') % flexion
                        forceTmp = [forceTmp (fGainVec(j)*subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)))]; 
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
                    forceSelceted = [forceSelceted subjForceData{trialIdx(trial_i)}(idxStart:idxStart+round(durAfterActive/2),2+j)];
                end
                
                tempDiff = zeros(size(forceSelceted,1),1);
%                 straightLineTrajectory = 
                for t = 1:size(forceSelceted,1)

%                     projection = 
                    tempDiff(t) = forceSelceted(t,:) - projection;
                end


                forceVec = mean(forceSelceted,1);  % average of finger forces from idxStart to idxStart+durAfterActive
                idealVec = double(chordTmp~='9');
                for j = 1:5
                    if (chordTmp(j) == '2')
                        idealVec(j) = -1;
                    end
                end
                if (onlyActiveFing) % if only wanted to find the angle between active fingers
                    forceVec(idealVec==0) = [];
                    idealVec(idealVec==0) = [];
                end
                thetaCellSubj{i,2} = [thetaCellSubj{i,2} vectorAngle(forceVec,idealVec)];
            end
        else
            meanDCell{subj,1}(i,2:end) = 0;
        end 
    end
    thetaCell{subj,1} = thetaCellSubj;
end





%% Model Testing - meanTheta
clc;
close all;
clearvars -except data


% global params:
corrMethod = 'pearson';
includeSubjAvgModel = 0;

% theta calc params:
onlyActiveFing = 0;
firstTrial = 2;
selectRun = -1;
durAfterActive = 200;

% medRT params:
excludeChord = [];

dataName = "meanTheta";
featureCell = {"numActiveFing-linear","numActiveFing-oneHot","singleFinger","singleFingExt","singleFingFlex",...
    "neighbourFingers","2FingerCombinations","neighbourFingers+singleFinger","singleFinger+2FingerCombinations","all"};

efc1_analyze('modelTesting',data,'dataName',dataName,'featureCell',featureCell,'corrMethod',corrMethod,'onlyActiveFing',onlyActiveFing,...
            'firstTrial',firstTrial,'selectRun',selectRun,'durAfterActive',durAfterActive,'excludeChord',excludeChord);



%% thetaMean avg over numFingerActive

runVec = [1,2,3,-1];
colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
    [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
figure;
for j = 1:4
    thetaCell = efc1_analyze('thetaExp_vs_thetaStd',data,'durAfterActive',durAfterActive,'plotfcn',0,...
    'firstTrial',firstTrial,'onlyActiveFing',onlyActiveFing,'selectRun',runVec(j));
    [thetaMean,thetaStd] = meanTheta(thetaCell,firstTrial);
    chordVec = generateAllChords();
    chordVecSep = sepChordVec(chordVec);
    xVec = [];
    yVec = [];
    for i = 1:size(chordVecSep,1)
        xTmp = repmat(i,size(thetaMean,2)*length(chordVecSep{i,2}),1);
        yTmp = thetaMean(chordVecSep{i,2},:);
        yTmp = yTmp(:);
        xVec = [xVec;xTmp];
        yVec = [yVec;yTmp];
    end
    xVec(isnan(yVec)) = [];
    yVec(isnan(yVec)) = [];
    lineplot(xVec,yVec,'linecolor',colors(j,:));
    title("meanTheta across subjects")
    xlabel("num Finger Active")
    ylabel("meanTheta (degree)")
    hold on
end

%% median RT over numActiveFinger + mean theta over numActiveFinger
close all;
clc;

chordVec = generateAllChords();
chordVecSep = sepChordVec(chordVec);
colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
    [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];

activeVec = zeros(length(chordVec),1);
for i = 1:size(chordVecSep,1)
    activeVec(chordVecSep{i,2}) = i;
end

for i = 1:size(data,1)
    if (length(data{i,1}.BN) >= 2420)
        medRT = cell2mat(calcMedRT(data{i,1},[]));
        lineplot(activeVec,medRT(:,end),'linecolor',colors(i,:),'errorbars',{''});
        legNames{i} = data{i,2};
        hold on
    end
end
legend(legNames,'Location','northwest')
xlabel("num active fingers")
ylabel("average medRT")

% mean theta over numActiveFinger:
chordVec = generateAllChords();
chordVecSep = sepChordVec(chordVec);
colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
    [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
firstTrial = 2;

activeVec = zeros(length(chordVec),1);
for i = 1:size(chordVecSep,1)
    activeVec(chordVecSep{i,2}) = i;
end

thetaMean = zeros(242,size(thetaCell,1));
thetaStd = zeros(242,size(thetaCell,1));
for subj = 1:size(thetaCell,1)
    for j = 11:size(thetaMean,1)
        thetaMean(j,subj) = mean(thetaCell{subj,1}{j,2}(firstTrial:end));
        thetaStd(j,subj) = std(thetaCell{subj,1}{j,2}(firstTrial:end));
    end
end

figure;
for i = 1:size(thetaMean,2)
    lineplot(activeVec,thetaMean(:,i),'linecolor',colors(i,:),'errorbars',{''});
    legNames{i} = data{i,2};
    hold on
end
legend(legNames,'Location','northwest')
xlabel("num active fingers")
ylabel("mean theta")




%% Linear Regression (OLS) - Mean Theta 
clc;
close all;

chordVec = generateAllChords();
chordVecSep = sepChordVec(chordVec);

% features
% num active fingers - continuous:
f1 = zeros(size(chordVec));
for i = 1:size(chordVecSep,1)
    f1(chordVecSep{i,2}) = i;
end
% num active fingers - one hot:
% f1 = zeros(size(chordVec,1),5);
% for i = 1:size(chordVecSep,1)
%     f1(chordVecSep{i,2},i) = 1;
% end

% each finger flexed or not:
f2 = zeros(size(chordVec,1),5);
for i = 1:size(chordVec,1)
    chord = num2str(chordVec(i));
    f2(i,:) = (chord == '2');
end

% each finger extended or not:
f3 = zeros(size(chordVec,1),5);
for i = 1:size(chordVec,1)
    chord = num2str(chordVec(i));
    f3(i,:) = (chord == '1');
end

% second level interactions of finger combinations:
f4Base = [f2,f3];
f4 = [];
for i = 1:size(f4Base,2)-1
    for j = i+1:size(f4Base,2)
        f4 = [f4, f4Base(:,i) .* f4Base(:,j)];
    end
end

firstTrial = 2;

activeVec = zeros(length(chordVec),1);
for i = 1:size(chordVecSep,1)
    activeVec(chordVecSep{i,2}) = i;
end

thetaMean = zeros(242,size(thetaCell,1));
thetaStd = zeros(242,size(thetaCell,1));
for subj = 1:size(thetaCell,1)
    for j = 11:size(thetaMean,1)
        thetaMean(j,subj) = mean(thetaCell{subj,1}{j,2}(firstTrial:end));
        thetaStd(j,subj) = std(thetaCell{subj,1}{j,2}(firstTrial:end));
    end
end

% linear regression for one subj:
features = [f1,f2,f3,f4];
if (onlyActiveFing)
    thetaMean(1:10,:) = [];
    features(1:10,:) = [];
end
[i,~] = find(isnan(thetaMean));
thetaMean(i,:) = [];
features(i,:) = [];

subj = 1;
estimated = thetaMean(:,subj);  
mdl = fitlm(features,estimated)

% cross validated linear regression:
fullFeatures = repmat(features,size(data,1)-1,1);
rho_OLS_meanTheta = cell(1,2);
for i = 1:size(data,1)
    fprintf("\n")
    idx = setdiff(1:size(data,1),i);
    estimated = []; 
    for j = idx
        estimated = [estimated ; thetaMean(:,j)];
    end
    fprintf('%s out:\n',data{i,2})
    mdl = fitlm(fullFeatures,estimated)

    % testing model:
    pred = predict(mdl,features);
    meanThetaOut = thetaMean(:,i);
    
    corrTmp = corr(meanThetaOut,pred,'type',corrMethod);
    rho_OLS_meanTheta{2}(1,i) = convertCharsToStrings(data{i,2});
    rho_OLS_meanTheta{1}(1,i) = corrTmp;
end




%% analysis tmp
clc;
clearvars -except data
close all;

forceData = cell(size(data));
for i = 1:size(data,1)
    forceData{i,1} = extractDiffForce(data{i,1});
    forceData{i,2} = data{i,2};
end


%% visualize force data - examples
clc;
close all;
clearvars -except data forceData

subj = 1;
trial = 3977;
sigTmp = forceData{subj,1}{trial};
fGain4 = data{subj,1}.fGain4(trial);
fGain5 = data{subj,1}.fGain5(trial);
plot(sigTmp(:,2),[sigTmp(:,3:5),fGain4*sigTmp(:,6),fGain5*sigTmp(:,7)])
xline(500,'r','LineWidth',1.5)
hold on
plot([sigTmp(1,2) sigTmp(end,2)],[data{subj,1}.baselineTopThresh data{subj,1}.baselineTopThresh],'k')
hold on
plot([sigTmp(1,2) sigTmp(end,2)],-[data{subj,1}.baselineTopThresh data{subj,1}.baselineTopThresh],'k')
legend({"1","2","3","4","5"})















