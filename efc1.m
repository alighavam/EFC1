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
data = cell(length(matFiles),2);
for i = 1:length(matFiles)
    data{i,1} = load(matFiles(i).name);
    data{i,2} = matFiles(i).name(6:11);
end


%% analysis
clc;
clearvars -except data
close all;

% DATA PREP:
% efc1_analyze('all_subj'); % makes the .mat files from .dat and .mov of each subject

% ANALISYS:
% efc1_analyze('RT_vs_run',data,'plotfcn','median');
corrMethod = 'spearman';
rhoWithinSubject = efc1_analyze('corr_within_subj_runs',data,'corrMethod',corrMethod);
rhoAcrossSubjects = efc1_analyze('corr_across_subj',data,'corrMethod',corrMethod);
rhoAvgModel = efc1_analyze('corr_avg_model',data,'corrMethod',corrMethod);
% efc1_analyze('plot_scatter_within_subj',data,'transform_type','ranked')
efc1_analyze('plot_scatter_across_subj',data,'transform_type','ranked')







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

%% test github commit
zeros(1,100)
ones(1,100)

%% Features Correlation
close all;
clc;

chordVec = generateAllChords();
chordVecSep = sepChordVec(chordVec);

% features
numFeatures = 0;
f1 = zeros(length(chordVec),1); % num active fing
numFeatures = numFeatures+1;
for i = 1:length(chordVec)
    f1(i) = 5-sum(num2str(chordVec(i))=='9');
end

f2 = zeros(length(chordVec),1); % ring fing up
numFeatures = numFeatures+1;
for i = 1:length(chordVec)
    strChord = num2str(chordVec(i));
    if (strChord(4) == '1')
        f2(i) = 1;
    end
end

f3 = zeros(length(chordVec),1); % ring fing up, little up
numFeatures = numFeatures+1;
for i = 1:length(chordVec)
    strChord = num2str(chordVec(i));
    if (strChord(4) == '1' && strChord(5) == '1')
        f3(i) = 1;
    end
end

f4 = zeros(length(chordVec),1); % ring fing up, little down
numFeatures = numFeatures+1;
for i = 1:length(chordVec)
    strChord = num2str(chordVec(i));
    if (strChord(4) == '1' && strChord(5) == '2')
        f4(i) = 1;
    end
end

f5 = zeros(length(chordVec),1); % specific pattern
numFeatures = numFeatures+1;
for i = 1:length(chordVec)
    strChord = num2str(chordVec(i));
    if (strChord(4) == '1' && strChord(3) == '2' && strChord(5) == '2')
        f5(i) = 1;
    end
end

% correlation
vec = [];
for i = 1:length(data)
    if (length(data{i}.BN) >= 2420)
        medRT = cell2mat(calcMedRT(data{i}));
        vec = [vec , medRT(:,end)];
    end
end

vec = [vec f1 f2 f3 f4 f5];
fprintf("num active fingers:")
rho = corr(vec,'type','Pearson');
rho(end-numFeatures+1:end,1:end-numFeatures)


