%% Loading and initialization
clear;
close all;
clc;

% iMac
% cd('/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1');
% addpath('/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1/functions');
% addpath('/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1')
% addpath(genpath('/Users/aghavampour/Documents/MATLAB/dataframe-2016.1'),'-begin');

% macbook
cd('/Users/alighavam/Desktop/Projects/ExtFlexChord/efc1');
addpath('/Users/alighavam/Desktop/Projects/ExtFlexChord/efc1/functions');
addpath('/Users/alighavam/Desktop/Projects/ExtFlexChord/efc1')
addpath(genpath('/Users/alighavam/Documents/MATLAB/dataframe-2016.1'),'-begin')

% temporary analysis:

% loading data
analysisDir = '/Users/alighavam/Desktop/Projects/ExtFlexChord/efc1/analysis';
% analysisDir = '/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1/analysis';  % iMac
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

% parameters:
onlyActiveFing = 1;
fisrtTrial = 2;
corrMethod = 'pearson';
selectRun = -1;
durAfterActive = 200;

% ====DATA PREP====
% efc1_analyze('all_subj'); % makes the .mat files from .dat and .mov of each subject


% ====ANALISYS====
% efc1_analyze('RT_vs_run',data,'plotfcn','median');

rhoWithinSubject = efc1_analyze('corr_within_subj_runs',data,'corrMethod',corrMethod,'excludeChord',[1]);

rhoAcrossSubjects = efc1_analyze('corr_across_subj',data,'plotfcn',1,'clim',[0,1],'corrMethod',corrMethod,'excludeChord',[1]);

rhoAvgModel = efc1_analyze('corr_avg_model',data,'corrMethod',corrMethod,'excludeChord',[1]);

thetaCell = efc1_analyze('thetaExp_vs_thetaStd',data,'durAfterActive',200,'plotfcn',0,...
    'firstTrial',fisrtTrial,'onlyActiveFing',onlyActiveFing,'selectRun',selectRun);

rho_theta = efc1_analyze('corr_mean_theta_across_subj',data,'thetaCell',thetaCell,'onlyActiveFing',onlyActiveFing, ...
    'firstTrial',fisrtTrial,'corrMethod',corrMethod,'plotfcn',1,'clim',[0,1]);

rho_theta_avgModel = efc1_analyze('corr_mean_theta_avg_model',data,'thetaCell',thetaCell,'onlyActiveFing',onlyActiveFing, ...
    'firstTrial',fisrtTrial,'corrMethod',corrMethod);

% efc1_analyze('plot_scatter_within_subj',data,'transform_type','ranked')

% efc1_analyze('plot_scatter_across_subj',data,'transform_type','ranked')


% ====EXTRA PLOTS====
figure;
hold all
scatter(1:length(rho_theta_avgModel{1}),rho_theta_avgModel{1},40,'k','filled','HandleVisibility','off')
plot(1:length(rho_theta_avgModel{1}),rho_theta_avgModel{1},'k','LineWidth',0.2)
scatter(1:length(rhoAvgModel{1}),rhoAvgModel{1},40,'r','filled','HandleVisibility','off')
plot(1:length(rhoAvgModel{1}),rhoAvgModel{1},'r','LineWidth',0.2)
title("correlation avg model")
xlabel("subj excluded")
ylabel("correlation of avg with excluded subj")
legend("meanTheta","medRT")
ylim([0,1])


%% Scatter plots ranked separate numActiveFing
close all;
clc;

chordVec = generateAllChords();
chordVecSep = sepChordVec(chordVec);
colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
    [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];

% Ranked Med RTs across subjects:
lastRuns_ranked = [];
for i = 1:length(data)
    if (length(data{i}.BN) >= 2420)
        medRT = cell2mat(calcMedRT(data{i}));
        [~,idx] = sort(medRT(:,end));
        lastRuns_ranked = [lastRuns_ranked idx];
    end
end

% figure
col1 = repelem(1:size(lastRuns_ranked,2),size(lastRuns_ranked,2));
col2 = repmat(1:5,1,size(lastRuns_ranked,2));
C = [col1',col2'];
C(C(:,1)==C(:,2),:) = [];
subplotCols = 2;
subplotRows = round((size(lastRuns_ranked,2)-1)/subplotCols);
for i = 1:size(lastRuns_ranked,2)
    figure;
    for j = 1:subplotRows*subplotCols
        subplot(subplotRows,subplotCols,j)
        for numActiveFing = 1:size(chordVecSep,1)
            scatter(lastRuns_ranked(chordVecSep{numActiveFing,2},C((i-1)*(size(lastRuns_ranked,2)-1)+j,1)),lastRuns_ranked(chordVecSep{numActiveFing,2},C((i-1)*(size(lastRuns,2)-1)+j,2)),...
                30,"MarkerFaceColor",colors(numActiveFing,:))
            hold on
        end
        title(sprintf("%s vs %s , ranked medRT",matFiles(i).name(6:11),matFiles(C((i-1)*(size(lastRuns_ranked,2)-1)+j,2)).name(6:11)))
        xlabel(sprintf("%s medRT(ms)",matFiles(C((i-1)*(size(lastRuns_ranked,2)-1)+j,1)).name(6:11)))
        ylabel(sprintf("%s medRT(ms)",matFiles(C((i-1)*(size(lastRuns_ranked,2)-1)+j,2)).name(6:11)))
        legend(["activeFinger 1","activeFinger 2","activeFinger 3","activeFinger 4","activeFinger 5"])
    end
end


%% median RT over numActiveFinger
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

%% mean theta over numActiveFinger
close all;
clc;

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

for i = 1:size(thetaMean,2)
    lineplot(activeVec,thetaMean(:,i),'linecolor',colors(i,:),'errorbars',{''});
    legNames{i} = data{i,2};
    hold on
end
legend(legNames,'Location','northwest')
xlabel("num active fingers")
ylabel("mean theta")


%% Linear Regression (OLS) - Med RT
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

% linear regression for one subj:
subj = 1;
features = [f1,f2,f3,f4];
medRT = cell2mat(calcMedRT(data{subj,1},[]));
estimated = medRT(:,end);
mdl = fitlm(features,estimated)


% cross validated linear regression:
fullFeatures = [repmat(f1,size(data,1)-1,1),repmat(f2,size(data,1)-1,1),repmat(f3,size(data,1)-1,1),repmat(f4,size(data,1)-1,1)];
rho_OLS_medRT = cell(1,2);
for i = 1:size(data,1)
    fprintf("\n")
    idx = setdiff(1:size(data,1),i);
    estimated = []; 
    for j = idx
        tmpMedRT = cell2mat(calcMedRT(data{j,1},[]));
        estimated = [estimated ; tmpMedRT(:,end)];
    end
    fprintf('%s out:\n',data{i,2})
    mdl = fitlm(fullFeatures,estimated)

    % testing model:
    pred = predict(mdl,features);
    medRTOut = cell2mat(calcMedRT(data{i,1},[]));
    medRTOut = medRTOut(:,end);
    
    corrTmp = corr(medRTOut,pred,'type',corrMethod);
    rho_OLS_medRT{2}(1,i) = convertCharsToStrings(data{i,2});
    rho_OLS_medRT{1}(1,i) = corrTmp;
end


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

%%
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















