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

% temporary fix:
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
selectRun = -2;
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

biasVarCell = efc1_analyze('theta_bias',data,'durAfterActive',durAfterActive,'selectRun',selectRun,...
                            'firstTrial',firstTrial,'plotfcn',0);

[meanDevCell,rho_meanDev_acrossSubj] = efc1_analyze('meanDev',data,'selectRun',selectRun,...
                                                    'corrMethod',corrMethod,'plotfcn',0,'clim',clim);

rho_meanDev_avgModel = efc1_analyze('corr_meanDev_avg_model',data,'selectRun',selectRun,'corrMethod',corrMethod,...
                                    'includeSubj',includeSubjAvgModel);

% [rho_OLS_medRT, crossValModels_medRT, singleSubjModel_medRT] = efc1_analyze('reg_OLS_medRT',data,...
%     'regSubjNum',0,'excludeChord',excludeChord,'corrMethod',corrMethod);

% [rho_OLS_meanTheta, crossValModels_meanTheta, singleSubjModel_meanTheta] = efc1_analyze('reg_OLS_meanTheta',data,...
%     thetaCell,'regSubjNum',0,'corrMethod',corrMethod,'onlyActiveFing',onlyActiveFing,'firstTrial',firstTrial);

% efc1_analyze('plot_scatter_within_subj',data,'transform_type','ranked')

% efc1_analyze('plot_scatter_across_subj',data,'transform_type','no_transform')

% efc1_analyze('meanTheta_scatter_across_subj',data,thetaCell,'onlyActiveFing',onlyActiveFing,'firstTrial',firstTrial





%% ========================================================================
%% TEMPORARY CODES AND ANALYSIS FROM HERE !<UNDER CONSTRUCTION>!
%% ========================================================================



%% Model Testing
clc;
close all;
clearvars -except data

% global params:
dataName = "meanDev";
corrMethod = 'pearson';
includeSubjAvgModel = 0;

% theta calc params:
onlyActiveFing = 0;
firstTrial = 2;
selectRun = -2;
durAfterActive = 200;

% medRT params:
excludeChord = [];


featureCell = {"singleFingExt","numActiveFing-oneHot","singleFinger",...
    "neighbourFingers+singleFinger","singleFinger+2FingerCombinations","all"};

efc1_analyze('modelTesting',data,'dataName',dataName,'featureCell',featureCell,'corrMethod',corrMethod,'onlyActiveFing',onlyActiveFing,...
            'firstTrial',firstTrial,'selectRun',selectRun,'durAfterActive',durAfterActive,'excludeChord',excludeChord);



%% thetaMean avg vs numFingerActive

runVec = [1,2,3,-1];
colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
    [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
figure;
for j = 1:4
    thetaCell = efc1_analyze('thetaExp_vs_thetaStd',data,'durAfterActive',durAfterActive,'plotfcn',0,...
    'firstTrial',firstTrial,'onlyActiveFing',onlyActiveFing,'selectRun',runVec(j));
    [thetaMean,~] = meanTheta(thetaCell,firstTrial);
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


%% bias vs numFingerActive

runVec = [1,2,3,-1];
colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
    [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
figure;
for j = 1:4
    biasVarCell = efc1_analyze('theta_bias',data,'durAfterActive',durAfterActive,'selectRun',runVec(j),...
                            'firstTrial',firstTrial);
    biasMat = [biasVarCell{:,1}];
    biasMat(:,1:2:end)=[];
    % in some runs, for some of the chords we get [] for biasVar. 
    % Fixing for that here:
    emptyCells = cellfun(@isempty,biasMat);
    [row,col] = find(emptyCells);
    biasMat(row,:) = [];
    biasMat = cell2mat(biasMat);
    biasMat(:,2:2:end)=[];

    chordVec = generateAllChords();
    chordVec(row,:) = [];
    chordVecSep = sepChordVec(chordVec);

    xVec = [];
    yVec = [];
    for i = 1:size(chordVecSep,1)
        xTmp = repmat(i,size(biasMat,2)*length(chordVecSep{i,2}),1);
        yTmp = biasMat(chordVecSep{i,2},:);
        yTmp = yTmp(:);
        xVec = [xVec;xTmp];
        yVec = [yVec;yTmp];
    end
    xVec(isnan(yVec)) = [];
    yVec(isnan(yVec)) = [];
    lineplot(xVec,yVec,'linecolor',colors(j,:));
    title("biasTheta")
    xlabel("num Finger Active")
    ylabel("biasTheta (degree)")
    hold on
end

%% MeanDev vs numFingerActive

runVec = [1,2,3,-1];
colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
    [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];


figure;
for j = 1:4
    meanDev = regressionDataset(data,'meanDev','selectRun',runVec(j),'plotfcn',0);

    chordVec = generateAllChords();
    chordVecSep = sepChordVec(chordVec);

    xVec = [];
    yVec = [];
    for i = 1:size(chordVecSep,1)
        xTmp = repmat(i,size(meanDev,2)*length(chordVecSep{i,2}),1);
        yTmp = meanDev(chordVecSep{i,2},:);
        yTmp = yTmp(:);
        xVec = [xVec;xTmp];
        yVec = [yVec;yTmp];
    end
    xVec(isnan(yVec)) = [];
    yVec(isnan(yVec)) = [];
    lineplot(xVec,yVec,'linecolor',colors(j,:));
    title("MeanDev")
    xlabel("num Finger Active")
    ylabel("Avg MeanDev")
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


















%% Correlations of measures
clc;
close all;
clearvars -except data

% global params:
corrMethod = 'pearson';
includeSubjAvgModel = 0;

% theta calc params:
onlyActiveFing = 0;
firstTrial = 2;
selectRun = -2;
durAfterActive = 200;

% medRT params:
excludeChord = [];


medRT = regressionDataset(data,"medRT",'onlyActiveFing',onlyActiveFing,...
            'firstTrial',firstTrial,'selectRun',selectRun,'durAfterActive',durAfterActive);


meanTheta = regressionDataset(data,"meanTheta",'onlyActiveFing',onlyActiveFing,...
            'firstTrial',firstTrial,'selectRun',selectRun,'durAfterActive',durAfterActive);

thetaBias = regressionDataset(data,"thetaBias",'onlyActiveFing',onlyActiveFing,...
            'firstTrial',firstTrial,'selectRun',selectRun,'durAfterActive',durAfterActive);

meanDev = regressionDataset(data,"meanDev",'onlyActiveFing',onlyActiveFing,...
            'firstTrial',firstTrial,'selectRun',selectRun,'durAfterActive',durAfterActive);


mat = [medRT,meanTheta,thetaBias,meanDev];
rho = corr(mat,'type',corrMethod);

figure;
imagesc(rho)
hold on
line([0.50,24.5], [6.50,6.50], 'Color', 'k','LineWidth',2);
line([0.50,24.5], [12.5,12.5], 'Color', 'k','LineWidth',2);
line([0.50,24.5], [18.5,18.5], 'Color', 'k','LineWidth',2);
line([6.50,6.50], [0.50,24.5], 'Color', 'k','LineWidth',2);
line([12.5,12.5], [0.50,24.5], 'Color', 'k','LineWidth',2);
line([18.5,18.5], [0.50,24.5], 'Color', 'k','LineWidth',2);
xticks([1:24])
yticks([1:24])
xticklabels([1:6,1:6,1:6,1:6])
yticklabels([1:6,1:6,1:6,1:6])
colorbar
title(sprintf("measures correlations (left to right: medRT , meanTheta , theta bias , meanDev)"))
xlabel("subject num")
ylabel("subject num")

















