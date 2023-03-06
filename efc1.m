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

% temporary RT correction:
for i = 1:size(data,1)  % loop on subjects
    for i_t = 1:length(data{i,1}.BN)  % loop on trials
        if (data{i,1}.trialErrorType(i_t) == 2)
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

% DATA PREP:
% efc1_analyze('all_subj'); % makes the .mat files from .dat and .mov of each subject

% ANALISYS:
% efc1_analyze('RT_vs_run',data,'plotfcn','median');
corrMethod = 'pearson';
rhoWithinSubject = efc1_analyze('corr_within_subj_runs',data,'corrMethod',corrMethod);
rhoAcrossSubjects = efc1_analyze('corr_across_subj',data,'corrMethod',corrMethod);
rhoAvgModel = efc1_analyze('corr_avg_model',data,'corrMethod',corrMethod);
% efc1_analyze('plot_scatter_within_subj',data,'transform_type','ranked')
% efc1_analyze('plot_scatter_across_subj',data,'transform_type','ranked')


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

for i = 1:length(data)
    if (length(data{i}.BN) >= 2420)
        medRT = cell2mat(calcMedRT(data{i}));
        lineplot(activeVec,medRT(:,end),'linecolor',colors(i,:),'errorbars',{''})
        legNames{i} = matFiles(i).name(6:11);
        hold on
    end
end
legend(legNames)
xlabel("num active fingers")
ylabel("average medRT")


%% Features Correlation
clc;
clearvars -except data
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
features = [f1,f2,f3,f4];
medRT = cell2mat(calcMedRT(data{1,1}));
estimated = medRT(:,end);
mdl = fitlm(features,estimated)

% cross validated linear regression:
fullFeatures = [repmat(f1,size(data,1)-1,1),repmat(f2,size(data,1)-1,1),repmat(f3,size(data,1)-1,1),repmat(f4,size(data,1)-1,1)];
for i = 1:size(data,1)
    fprintf("\n")
    idx = setdiff(1:size(data,1),i);
    estimated = []; 
    for j = idx
        tmpMedRT = cell2mat(calcMedRT(data{j,1}));
        estimated = [estimated ; tmpMedRT(:,end)];
    end
    fprintf('subj %s out:\n',num2str(i))
    mdl = fitlm(fullFeatures,estimated)
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

%%
clc;
close all;
clearvars -except data forceData

sigTmp = forceData{1,1}{1};
plot(sigTmp(:,2),sigTmp(:,3:end))
legend({"1","2","3","4","5"})

% [firstRT,execRT] = getSeparateRT(getrow(data{1,1},1));






