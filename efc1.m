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

% efc1_analyze('all_subj');

% temporary analysis:

% loading data
% analysisDir = '/Users/alighavam/Desktop/Projects/ExtFlexChord/efc1/analysis';
analysisDir = '/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1/analysis';  % iMac
cd(analysisDir)
matFiles = dir("*.mat");
data = cell(size(matFiles));
for i = 1:length(matFiles)
    data{i} = load(matFiles(i).name);
end

%% lineplots
close all;
clc;
% lineplot subplot
figure;
for i = 1:length(data)
    tmpData = data{i};
    idx = tmpData.RT~=0;
    subplot(3,2,i)
    lineplot(tmpData.BN(idx),tmpData.RT(idx)-600);
    xlabel("Block")
    ylabel("RT(ms)")
    title(sprintf("%s",matFiles(i).name(6:11)))
%     ylim([0,7000])
end

% lineplot with one plot
figure
colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
    [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
legNames = {};
for i = 1:length(data)
    tmpData = data{i};
    idx = tmpData.RT~=0;
    lineplot(tmpData.BN(idx),tmpData.RT(idx)-600,...
        'markercolor',colors(i,:),'linecolor',colors(i,:),'errorbars',{''});
    xlabel("Block")
    ylabel("RT(ms)")
    title("all subjects")
    hold on
    legNames{i} = matFiles(i).name(6:11);
end
legend(legNames)

%% Med RT
close all;
clc;

% visualizing median RTs
subNum = 1;
medRT = calcMedRT(data{subNum});
chordVec = generateAllChords();
chordVecSep = sepChordVec(chordVec);
corrMethod = 'spearman';

% randomSelection = chordVec(randperm(length(chordVec)));
% randomSelection = randomSelection(1:30);
% for i = 1:length(randomSelection)
%     tmpChord = randomSelection(i);
%     index = find([medRT{:}] == tmpChord);
%     tmpMedRT = medRT{index,2};
%     subplot(6,5,i)
%     scatter(1:length(tmpMedRT),tmpMedRT,'filled','k');
%     hold on
%     plot(1:length(tmpMedRT),tmpMedRT,'k','LineWidth',0.5)
%     ylabel("median RT")
%     xlabel("Block")
%     title(sprintf("subj0%d , %d",subNum,tmpChord))
%     ylim([0,10000])
% end

% correlation of median RT within participants
for i = 1:length(data)
    if (length(data{i}.BN) >= 2420)
        disp(['subj' num2str(data{i}.subNum(1))])
        medRT = calcMedRT(data{i});
        medRT = cell2mat(medRT);
        medRT = medRT(:,2:end);
        rho = corr(medRT,'type',corrMethod)
    end
end

% correlation of median RT across participants
lastSess = [];
for i = 1:length(data)
    if (length(data{i}.BN) >= 2420)
        disp(['subj' num2str(data{i}.subNum(1))])
        medRT = calcMedRT(data{i});
        medRT = cell2mat(medRT);
        medRT = medRT(:,2:end);
        lastSess = [lastSess , medRT(:,end)];
    end
end
disp("across subjects:")
rho = corr(lastSess,'type',corrMethod)

lastSess = [lastSess,mean(lastSess,2)];
disp("corr of subjects with global mean")
rho = corr(lastSess,'type',corrMethod);
rho(end,1:end-1)


%% Scatter plots within subject runs
close all;
clc;

chordVec = generateAllChords();
chordVecSep = sepChordVec(chordVec);
colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
    [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];

% scatter plots within subjects:
j = 1;
figure;
for i = 1:length(data)
    if (length(data{i}.BN) >= 2420)
        medRT = cell2mat(calcMedRT(data{i}));
        last2Runs = medRT(:,end-1:end);
        subplot(3,2,j)
        for numActiveFing = 1:size(chordVecSep,1)
            scatter(last2Runs(chordVecSep{numActiveFing,2},1),last2Runs(chordVecSep{numActiveFing,2},2),30,"MarkerFaceColor",colors(numActiveFing,:))
            hold on
        end
        legend(["activeFinger 1","activeFinger 2","activeFinger 3","activeFinger 4","activeFinger 5"])
        title(sprintf("last two runs MedRTs, %s",matFiles(i).name(6:11)))
        ylabel("Last Run, Med RT(ms)")
        xlabel("One Run Before Last, Med RT(ms)")
        j = j+1;
    end
end

% ranked in one plot within subjects
j = 1;
figure;
for i = 1:length(data)
    if (length(data{i}.BN) >= 2420)
        medRT = cell2mat(calcMedRT(data{i}));
        last2Runs = medRT(:,end-1:end);
        [~,i1] = sort(last2Runs(:,1));
        [~,i2] = sort(last2Runs(:,2));
        last2Runs_ranked = [i1,i2];
        subplot(3,2,j)
        for numActiveFing = 1:size(chordVecSep,1)
            scatter(last2Runs_ranked(chordVecSep{numActiveFing,2},1),last2Runs_ranked(chordVecSep{numActiveFing,2},2),30,"MarkerFaceColor",colors(numActiveFing,:))
            hold on
        end
        legend(["activeFinger 1","activeFinger 2","activeFinger 3","activeFinger 4","activeFinger 5"])
        title(sprintf("last two runs MedRTs ranked, %s",matFiles(i).name(6:11)))
        ylabel("Last Run, Med RT(ms)")
        xlabel("One Run Before Last, Med RT(ms)")
        j = j+1;
    end
end


%% scatter plots across subjects last runs:
close all;
clc;

chordVec = generateAllChords();
chordVecSep = sepChordVec(chordVec);
colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
    [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];

% Med RTs:
lastRuns = [];
for i = 1:length(data)
    if (length(data{i}.BN) >= 2420)
        medRT = cell2mat(calcMedRT(data{i}));
        lastRuns = [lastRuns medRT(:,end)];
    end
end

% figure
col1 = repelem(1:size(lastRuns,2),size(lastRuns,2));
col2 = repmat(1:5,1,size(lastRuns,2));
C = [col1',col2'];
C(C(:,1)==C(:,2),:) = [];
subplotCols = 2;
subplotRows = round((size(lastRuns,2)-1)/subplotCols);
for i = 1:size(lastRuns,2)
    figure;
    for j = 1:subplotRows*subplotCols
        subplot(subplotRows,subplotCols,j)
        for numActiveFing = 1:size(chordVecSep,1)
            scatter(lastRuns(chordVecSep{numActiveFing,2},C((i-1)*(size(lastRuns,2)-1)+j,1)),lastRuns(chordVecSep{numActiveFing,2},C((i-1)*(size(lastRuns,2)-1)+j,2)),...
                30,"MarkerFaceColor",colors(numActiveFing,:))
            hold on
        end
        title(sprintf("%s vs %s",matFiles(i).name(6:11),matFiles(C((i-1)*(size(lastRuns,2)-1)+j,2)).name(6:11)))
        xlabel(sprintf("%s medRT(ms)",matFiles(C((i-1)*(size(lastRuns,2)-1)+j,1)).name(6:11)))
        ylabel(sprintf("%s medRT(ms)",matFiles(C((i-1)*(size(lastRuns,2)-1)+j,2)).name(6:11)))
        legend(["activeFinger 1","activeFinger 2","activeFinger 3","activeFinger 4","activeFinger 5"])
    end
end


% Ranked Med RTs:
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


