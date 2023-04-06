function dataset = regressionDataset(data,what,varargin)

onlyActiveFing = 0;
firstTrial = 2;
selectRun = -2;
durAfterActive = 200;

if (~isempty(find(strcmp(varargin,'onlyActiveFing'),1)))
    onlyActiveFing = varargin{find(strcmp(varargin,'onlyActiveFing'),1)+1};
end
if (~isempty(find(strcmp(varargin,'firstTrial'),1)))
    firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};
end
if (~isempty(find(strcmp(varargin,'selectRun'),1)))
    selectRun = varargin{find(strcmp(varargin,'selectRun'),1)+1};
end
if (~isempty(find(strcmp(varargin,'durAfterActive'),1)))
    durAfterActive = varargin{find(strcmp(varargin,'durAfterActive'),1)+1};
end

if (what == "meanTheta")    % make dataset for meanTheta
    thetaCell = efc1_analyze('thetaExp_vs_thetaStd',data,'durAfterActive',durAfterActive,'plotfcn',0,...
    'firstTrial',firstTrial,'onlyActiveFing',onlyActiveFing,'selectRun',selectRun);
    [thetaMean,~] = meanTheta(thetaCell,firstTrial);
    dataset = thetaMean;
elseif (what == "medRT")
    chordVec = generateAllChords();
    dataset = zeros(size(chordVec,1),size(data,1));
    for i = 1:size(data,1)
        medRT = calcMedRT(data{i,1},[]);
        medRT = medRT(:,2);
        medRT = cell2mat(medRT);
        medRT = medRT(:,end);
        dataset(:,i) = medRT;
    end
elseif (what == "thetaBias")
    biasVarCell = efc1_analyze('theta_bias',data,'durAfterActive',durAfterActive,'selectRun',selectRun,...
                            'firstTrial',firstTrial);
    biasMat = [biasVarCell{:,1}];
    biasMat(:,1:2:end)=[];
    biasMat = cell2mat(biasMat);
    biasMat(:,2:2:end)=[];
    dataset = biasMat;
elseif (what == "meanDev")
    [meanDevCell,~] = efc1_analyze('meanDev',data,'selectRun',selectRun,...
                                                    'plotfcn',0,'clim',[]);
    tmpMeanDev = [meanDevCell{:,1}];
    tmpMeanDev(:,1:2:end) = [];
    avgMeanDev = cellfun(@(x) mean(x,'all'),tmpMeanDev);
    dataset = avgMeanDev;
else
    error("dataName %s does not exist.",what)
end












