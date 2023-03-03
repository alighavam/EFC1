function varargout=efc1_analyze(what, data, varargin)

addpath(genpath('/Users/aghavampour/Documents/MATLAB/dataframe-2016.1'),'-begin');

%GLOBALS:
subjName = {'subj07'};

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
        efc1_RTvsRun(data,plotfcn);
    
    % =====================================================================
    case 'corr_within_subj_runs'
        corrMethod = 'pearson';    % default correlation method
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};   % setting 'plotfcn' option for lineplot()
        end    
        % correlation of median RT within subject runs
        rhoWithinSubject = efc1_corr_within_subj_runs(data,corrMethod);
        varargout{1} = rhoWithinSubject;
    
    % =====================================================================
    case 'corr_across_subj'
        corrMethod = 'pearson';    % default correlation method
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};   % setting 'plotfcn' option for lineplot()
        end
        % correlation of median RT across subjects
        rhoAcrossSubjects = efc1_corr_across_subj(data,corrMethod);
        varargout{1} = rhoAcrossSubjects;

    % =====================================================================
    case 'corr_avg_model'
        corrMethod = 'pearson';    % default correlation method
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};   % setting 'plotfcn' option for lineplot()
        end
        % correlation of median RT across subjects
        rhoAvgModel = efc1_corr_avg_model(data,corrMethod);
        varargout{1} = rhoAvgModel;
    
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



