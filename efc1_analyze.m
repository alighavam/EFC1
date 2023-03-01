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
                    last2Runs_cell{j} = last2Runs;
                elseif (strcmp(dataTransform,'ranked'))
                    [~,idx1] = sort(last2Runs(:,1));
                    [~,idx2] = sort(last2Runs(:,2));
                    last2Runs_ranked = [idx1,idx2];
                    last2Runs_cell{j} = last2Runs_ranked;
                end
                j = j+1;
            end
        end
        
        
        figure;
        for i = 1:size(data,1)
            if (length(data{i,1}.BN) >= 2420)
                medRT = cell2mat(calcMedRT(data{i,1}));
                last2Runs = medRT(:,end-1:end);
                subplot(3,2,j)
                for numActiveFing = 1:size(chordVecSep,1)
                    scatter(last2Runs(chordVecSep{numActiveFing,2},1),last2Runs(chordVecSep{numActiveFing,2},2),30,"MarkerFaceColor",colors(numActiveFing,:))
                    hold on
                end
                legend(["activeFinger 1","activeFinger 2","activeFinger 3","activeFinger 4","activeFinger 5"])
                title(sprintf("last two runs MedRTs, %s",data{i,2}))
                ylabel("Last Run, Med RT(ms)")
                xlabel("One Run Before Last, Med RT(ms)")
                j = j+1;
            end
        end



    otherwise
        error('The analysis you entered does not exist!')
end



