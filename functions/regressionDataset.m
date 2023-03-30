function dataset = regressionDataset(data,what,varargin)

onlyActiveFing = 0;
firstTrial = 2;
selectRun = -1;
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
end











