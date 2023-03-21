function varargout=efc1_analyze(what, data, varargin)

addpath(genpath('/Users/aghavampour/Documents/MATLAB/dataframe-2016.1'),'-begin');

%GLOBALS:
subjName = {'subj09'};

switch (what)
    % =====================================================================
    case 'all_subj'     % create .mat data files for subjects   
        for s = 1:length(subjName)
            efc1_subj(subjName{s},0);
        end
    
    % =====================================================================
    case 'RT_vs_run'    % varargin options: 'plotfcn',{'mean' or 'median'} default is 'mean'
        % lineplot subplot for each subj
        plotfcn = 'mean';
        if (~isempty(find(strcmp(varargin,'plotfcn'),1)))
            plotfcn = varargin{find(strcmp(varargin,'plotfcn'),1)+1};   % setting 'plotfcn' option for lineplot()
        end
        efc1_RTvs Run(data,plotfcn);
    
    % =====================================================================
    case 'corr_within_subj_runs'
        corrMethod = 'pearson';     % default correlation method
        excludeVec = [];            % default exclude chord vector. Not excluding any chords by default.
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};     % setting 'plotfcn' option for lineplot()
        end   
        if (~isempty(find(strcmp(varargin,'excludeChord'),1)))
            excludeVec = varargin{find(strcmp(varargin,'excludeChord'),1)+1};   % setting 'excludeChord' option for calcMedRT
        end  
        % correlation of median RT within subject runs
        rhoWithinSubject = efc1_corr_within_subj_runs(data,corrMethod,excludeVec);
        varargout{1} = rhoWithinSubject;
    
    % =====================================================================
    case 'corr_across_subj'
        corrMethod = 'pearson';     % default correlation method
        excludeVec = [];            % default exclude chord vector. Not excluding any chords by default.
        plotfcn = 0;                % default is not to plot
        clim = [0,1];               % default for colorbar limit
        if (~isempty(find(strcmp(varargin,'plotfcn'),1)))
            plotfcn = varargin{find(strcmp(varargin,'plotfcn'),1)+1};           % setting 'plotfcn' option
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};     % setting 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'excludeChord'),1)))
            excludeVec = varargin{find(strcmp(varargin,'excludeChord'),1)+1};   % setting 'excludeChord' option for calcMedRT
        end  
        if (~isempty(find(strcmp(varargin,'clim'),1)))
            clim = varargin{find(strcmp(varargin,'clim'),1)+1};                 % setting 'colorbar' option
        end
        % correlation of median RT across subjects
        rhoAcrossSubjects = efc1_corr_across_subj(data,corrMethod,excludeVec);
        varargout{1} = rhoAcrossSubjects;
        if (plotfcn)
            figure;
            if (~isempty(clim))
                imagesc(rhoAcrossSubjects{1},clim)
            else
                imagesc(rhoAcrossSubjects{1})
            end
            colorbar
            title(sprintf("corr medRT across subjects - corrMethod: %s",corrMethod))
            xlabel("subj")
            ylabel("subj")
        end

    % =====================================================================
    case 'corr_avg_model'
        corrMethod = 'pearson';     % default correlation method
        excludeVec = [];            % default exclude chord vector. Not excluding any chords by default.
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};     % setting 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'excludeChord'),1)))
            excludeVec = varargin{find(strcmp(varargin,'excludeChord'),1)+1};   % setting 'excludeChord' option for calcMedRT
        end
        % correlation of median RT across subjects
        rhoAvgModel = efc1_corr_avg_model(data,corrMethod,excludeVec);
        varargout{1} = rhoAvgModel;

    % =====================================================================
    case 'thetaExp_vs_thetaStd'
        durAfterActive = 200;   % default duration after first finger passed the baseline threshld in ms
        plotfcn = 1;            % default is to plot
        firstTrial = 2;         % default is 2 , The first trial of the chord is usually very different from others which impacts the variance a lot. This is an option to ignore the first trial if wanted.
        onlyActiveFing = 0;     % default is 0 , option to caclculate the angle only for active fingers
        selectRun = -1;         % default run to do the analysis is the last run. you can select run 1,2,3 or -1(last)
        if (~isempty(find(strcmp(varargin,'durAfterActive'),1)))
            durAfterActive = varargin{find(strcmp(varargin,'durAfterActive'),1)+1};     % setting 'durAfterActive' option
        end
        if (~isempty(find(strcmp(varargin,'plotfcn'),1)))
            plotfcn = varargin{find(strcmp(varargin,'plotfcn'),1)+1};                   % setting 'plotfcn' option
        end
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};             % setting 'firstTrial' option
        end
        if (~isempty(find(strcmp(varargin,'onlyActiveFing'),1)))    
            onlyActiveFing = varargin{find(strcmp(varargin,'onlyActiveFing'),1)+1};     % setting 'onlyActiveFing' option
        end
        if (~isempty(find(strcmp(varargin,'selectRun'),1)))    
            selectRun = varargin{find(strcmp(varargin,'selectRun'),1)+1};          % setting 'selectRun' option
        end
        
        forceData = cell(size(data));
        for i = 1:size(data,1)
            forceData{i,1} = extractDiffForce(data{i,1});
            forceData{i,2} = data{i,2};
        end
        
        thetaCell = cell(size(data));
        for subj = 1:size(data,1)
            thetaCell{subj,2} = data{subj,2};
            chordVec = generateAllChords();  % all chords
            subjData = data{subj,1};
            uniqueBN = [0 ; unique(subjData.BN)];
            idxBN = find(mod(uniqueBN,12)==0)-1;
            idxBN(1) = 1;
            subjForceData = forceData{subj,1};
            thetaCellSubj = cell(length(chordVec),2);
            for i = 1:length(chordVec)
                thetaCellSubj{i,1} = chordVec(i);
                if (selectRun == -1)
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > uniqueBN(idxBN(end-1)+1) & subjData.BN <= uniqueBN(idxBN(end)+1));
                elseif (selectRun > length(idxBN)-1)
                    error("Error with <selectRun> option , " + data{subj,2} + " does not have run number " + num2str(selectRun))
                elseif (selectRun == 1)
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > uniqueBN(idxBN(selectRun)) & subjData.BN <= uniqueBN(idxBN(selectRun+1)+1));
                else
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > uniqueBN(idxBN(selectRun)+1) & subjData.BN <= uniqueBN(idxBN(selectRun+1)+1));
                end
                
%                 fprintf("%s\n",data{subj,2})
%                 fprintf("trialIdx: %d\n",trialIdx)

                if (~isempty(trialIdx))
                    chordTmp = num2str(chordVec(i));
                    for trial_i = 1:length(trialIdx)
                        forceTmp = [];
                        tVec = subjForceData{trialIdx(trial_i)}(:,2); % time vector in trial
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
                        idxStart = find(tVec==tGoCue)+sortIdx(1)-1; % index that the first finger passes the baseline threhold after "Go Cue"
                        
                        forceSelceted = [];
                        for j = 1:5     % getting the force from idxStart to idxStart+durAfterActive
                            forceSelceted = [forceSelceted subjForceData{trialIdx(trial_i)}(idxStart:idxStart+round(durAfterActive/2),2+j)];
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
                    thetaCellSubj{i,2} = [];
                end 
            end
            thetaCell{subj,1} = thetaCellSubj;
        end
        varargout{1} = thetaCell;

        if (plotfcn)
            % visualizing thetaCell
            chordVecSep = sepChordVec(chordVec);
            colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
                [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
            for subj = 1:size(thetaCell,1)
                thetaCellSubj = thetaCell{subj,1};
                expVec = zeros(size(thetaCellSubj,1),1);
                stdVec = zeros(size(thetaCellSubj,1),1);
                for i = 1:size(thetaCellSubj,1)
                    expVec(i) = mean(thetaCellSubj{i,2}(firstTrial:end));
                    stdVec(i) = std(thetaCellSubj{i,2}(firstTrial:end));
                end
                
                figure;
                for numActiveFing = 1:size(chordVecSep,1)
                    scatter(stdVec(chordVecSep{numActiveFing,2}),expVec(chordVecSep{numActiveFing,2}),...
                        30,"MarkerFaceColor",colors(numActiveFing,:))
                    hold on
                end
                xlabel("std theta (degree)")
                ylabel("mean theta (degree)")
                title(sprintf("%s",thetaCell{subj,2}))
                legend({"1","2","3","4","5"})
            end
        end
    
    % =====================================================================
    case 'corr_mean_theta_across_subj'
        onlyActiveFing = 1;     % default value
        firstTrial = 2;         % default value
        corrMethod = 'pearson'; % default corr method
        plotfcn = 0;            % default is not to plot
        clim = [0,1];           % default for colorbar limit
        if (isempty(find(strcmp(varargin,'thetaCell'),1)))   
            error("thetaCell not found. You should input thetaCell for this analysis")
        end
        if (~isempty(find(strcmp(varargin,'thetaCell'),1)))    
            thetaCell = varargin{find(strcmp(varargin,'thetaCell'),1)+1};           % inputting the 'thetaCell'
        end
        if (~isempty(find(strcmp(varargin,'onlyActiveFing'),1)))    
            onlyActiveFing = varargin{find(strcmp(varargin,'onlyActiveFing'),1)+1}; % setting the 'onlyActiveFing' option - should be the same as the option used for 'thetaExp_vs_thetaStd'
        end
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))    
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};         % setting the 'firstTrial' option - should be the same as the option used for 'thetaExp_vs_thetaStd'
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))    
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};         % setting the 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'plotfcn'),1)))    
            plotfcn = varargin{find(strcmp(varargin,'plotfcn'),1)+1};               % setting the 'plotfcn' option
        end
        if (~isempty(find(strcmp(varargin,'clim'),1)))    
            clim = varargin{find(strcmp(varargin,'clim'),1)+1};                     % setting the 'clim' option
        end
        
        rho = cell(1,2);
        thetaMean = zeros(242,size(thetaCell,1));
        thetaStd = zeros(242,size(thetaCell,1));
        for subj = 1:size(thetaCell,1)
            for j = 11:size(thetaMean,1)
                thetaMean(j,subj) = mean(thetaCell{subj,1}{j,2}(firstTrial:end));
                thetaStd(j,subj) = std(thetaCell{subj,1}{j,2}(firstTrial:end));
            end
            rho{1,2} = [rho{1,2} convertCharsToStrings(data{subj,2})];
        end

        if (onlyActiveFing)
            thetaMean(1:10,:) = [];
        end
        [i,~] = find(isnan(thetaMean));
        thetaMean(i,:) = [];
        
        rho{1,1} = corr(thetaMean,'type',corrMethod);
        varargout{1} = rho;

        if (plotfcn)
            figure;
            if (~isempty(clim))
                imagesc(rho{1},clim)
            else
                imagesc(rho{1})
            end
            colorbar
            title(sprintf("corr meanTheta across subj - corrMethod: %s",corrMethod))
            xlabel("subj")
            ylabel("subj")
        end
    
    % =====================================================================
    case 'corr_mean_theta_avg_model'
        onlyActiveFing = 1;     % default value
        firstTrial = 2;         % default value
        corrMethod = 'pearson'; % default corr method
        if (isempty(find(strcmp(varargin,'thetaCell'),1)))   
            error("thetaCell not found. You should input thetaCell for this analysis")
        end
        if (~isempty(find(strcmp(varargin,'thetaCell'),1)))    
            thetaCell = varargin{find(strcmp(varargin,'thetaCell'),1)+1};           % inputting the 'thetaCell'
        end
        if (~isempty(find(strcmp(varargin,'onlyActiveFing'),1)))    
            onlyActiveFing = varargin{find(strcmp(varargin,'onlyActiveFing'),1)+1}; % setting the 'onlyActiveFing' option - should be the same as the option used for 'thetaExp_vs_thetaStd'
        end
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))    
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};         % setting the 'firstTrial' option - should be the same as the option used for 'thetaExp_vs_thetaStd'
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))    
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};         % setting the 'corrMethod' option
        end

        thetaMean = zeros(242,size(thetaCell,1));
        thetaStd = zeros(242,size(thetaCell,1));
        for subj = 1:size(thetaCell,1)
            for j = 11:size(thetaMean,1)
                thetaMean(j,subj) = mean(thetaCell{subj,1}{j,2}(firstTrial:end));
                thetaStd(j,subj) = std(thetaCell{subj,1}{j,2}(firstTrial:end));
            end
            % rhoAvg{1,2} = [rhoAvg{1,2} convertCharsToStrings(data{subj,2})];
        end
        
        if (onlyActiveFing)
            thetaMean(1:10,:) = [];
        end
        [i,~] = find(isnan(thetaMean));
        thetaMean(i,:) = [];
        
        rhoAvg = cell(1,2);
        for i = 1:size(thetaMean,2)
            idxSelect = setdiff(1:size(thetaMean,2),i);                 % excluding subj i from avg calculation
            tmpThetaMeanMat = thetaMean(:,idxSelect);
            tmpAvg = mean(tmpThetaMeanMat,2);                           % calculating avg of thetaMean for subjects other than subj i
            corrTmp = corr(tmpAvg,thetaMean(:,i),'type',corrMethod);    % correlation of avg model with excluded subj
            rhoAvg{1,1} = [rhoAvg{1,1} corrTmp];
            rhoAvg{1,2} = [rhoAvg{1,2} convertCharsToStrings(data{i,2})];
        end
        
        varargout{1} = rhoAvg;

    % =====================================================================
    case 'plot_scatter_within_subj'
        dataTransform = 'no_transform'; % default data transform type
        if (~isempty(find(strcmp(varargin,'transform_type'),1)))
            dataTransform = varargin{find(strcmp(varargin,'transform_type'),1)+1};   % setting 'transform_type' option
        end
        chordVec = generateAllChords();
        chordVecSep = sepChordVec(chordVec);
        colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
            [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
        
        j = 1;
        last2Runs_cell = {};
        for i = 1:size(data,1)
            if (length(data{i,1}.BN) >= 2420)
                medRT = cell2mat(calcMedRT(data{i,1}));
                last2Runs = medRT(:,end-1:end);
                if (strcmp(dataTransform,'no_transform'))
                    last2Runs_cell{j,1} = last2Runs;
                elseif (strcmp(dataTransform,'ranked'))
                    [~,idx1] = sort(last2Runs(:,1));
                    [~,idx2] = sort(last2Runs(:,2));
                    last2Runs_ranked = [idx1,idx2];
                    last2Runs_cell{j,1} = last2Runs_ranked;
                end
                last2Runs_cell{j,2} = data{i,2};
                j = j+1;
            end
        end
        
        figure;
        for i = 1:size(last2Runs_cell,1)
            last2Runs = last2Runs_cell{i,1};
            subplot(3,2,i)
            for numActiveFing = 1:size(chordVecSep,1)
                scatter(last2Runs(chordVecSep{numActiveFing,2},1),last2Runs(chordVecSep{numActiveFing,2},2),30,"MarkerFaceColor",colors(numActiveFing,:))
                hold on
            end
            legend(["activeFinger 1","activeFinger 2","activeFinger 3","activeFinger 4","activeFinger 5"])
            title(sprintf("last two runs MedRTs, %s",last2Runs_cell{i,2}))
            ylabel("Last Run, Med RT(ms)")
            xlabel("One Run Before Last, Med RT(ms)")
            axis equal
            maxLim = max(max(last2Runs_cell{i,1}(:,1)),max(last2Runs_cell{i,1}(:,2)));
            xlim([0,maxLim])
            ylim([0,maxLim])
        end
    
    % =====================================================================
    case 'plot_scatter_across_subj'
        dataTransform = 'no_transform'; % default data transform type
        if (~isempty(find(strcmp(varargin,'transform_type'),1)))
            dataTransform = varargin{find(strcmp(varargin,'transform_type'),1)+1};   % setting 'transform_type' option
        end
        chordVec = generateAllChords();
        chordVecSep = sepChordVec(chordVec);
        colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
            [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
        
        % Med RTs:
        lastRuns = {};
        k = 1;  % index for last runs.
        for i = 1:size(data,1)
            if (length(data{i,1}.BN) >= 2420)
                medRT = cell2mat(calcMedRT(data{i,1}));
                if (strcmp(dataTransform,'no_transform'))   % not transform option
                    lastRuns{k,1} = medRT(:,end);
                elseif (strcmp(dataTransform,'ranked'))     % rank transform option
                    [~,idx] = sort(medRT(:,end));
                    lastRuns{k,1} = idx;
                end
                lastRuns{k,2} = data{i,2};
                k = k+1;
            end
        end
        
        % plotting each subject vs all others
        subplotCols = 2;
        subplotRows = round((size(lastRuns,1)-1)/subplotCols);
        for i = 1:size(lastRuns,1)
            figure;
            yDataIdx = setdiff(1:size(lastRuns,1),i);   % subjects other than subject i
            subplotIdx = 1:subplotRows*subplotCols;
            k = 1;  % index for subplotIdx
            for j = yDataIdx
                subplot(subplotRows,subplotCols,subplotIdx(k))
                for numActiveFing = 1:size(chordVecSep,1)
                    scatter(lastRuns{i,1}(chordVecSep{numActiveFing,2}),lastRuns{j,1}(chordVecSep{numActiveFing,2}),...
                        30,"MarkerFaceColor",colors(numActiveFing,:))
                    hold on
                end
                title(sprintf("subjects last run scatter"))
                xlabel(sprintf("%s medRT(ms)",lastRuns{i,2}))
                ylabel(sprintf("%s medRT(ms)",lastRuns{j,2}))
                legend(["activeFinger 1","activeFinger 2","activeFinger 3","activeFinger 4","activeFinger 5"])
                axis equal
                maxLim = max(max(lastRuns{i,1}),max(lastRuns{j,1}));
                xlim([0,maxLim])
                ylim([0,maxLim])
                k = k+1;
            end
        end


    otherwise
        error('The analysis you entered does not exist!')
end



