function [highCeil,lowCeil] = calcNoiseCeiling(data,what,varargin)

onlyActiveFing = 0;
firstTrial = 2;
selectRun = -1;
durAfterActive = 200;
corrMethod = 'pearson';
excludeChord = [];

if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
    corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};
end
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
if (~isempty(find(strcmp(varargin,'excludeChord'),1)))
    excludeChord = varargin{find(strcmp(varargin,'excludeChord'),1)+1};
end


if (what == "meanTheta")
    thetaCell = efc1_analyze('thetaExp_vs_thetaStd',data,'durAfterActive',durAfterActive,'plotfcn',0,...
    'firstTrial',firstTrial,'onlyActiveFing',onlyActiveFing,'selectRun',selectRun);

    rho_theta_avgModel = efc1_analyze('corr_mean_theta_avg_model',data,'thetaCell',thetaCell,'onlyActiveFing',onlyActiveFing, ...
        'firstTrial',firstTrial,'corrMethod',corrMethod,'includeSubj',1);
    highCeil = mean(rho_theta_avgModel{1}); 
    rho_theta_avgModel = efc1_analyze('corr_mean_theta_avg_model',data,'thetaCell',thetaCell,'onlyActiveFing',onlyActiveFing, ...
        'firstTrial',firstTrial,'corrMethod',corrMethod,'includeSubj',0);
    lowCeil = mean(rho_theta_avgModel{1});
elseif (what == "medRT")
    rho_medRT_AvgModel = efc1_analyze('corr_medRT_avg_model',data,'corrMethod',corrMethod,...
        'excludeChord',excludeChord,'includeSubj',1);
    highCeil = mean(rho_medRT_AvgModel{1}); 
    rho_medRT_AvgModel = efc1_analyze('corr_medRT_avg_model',data,'corrMethod',corrMethod,...
        'excludeChord',excludeChord,'includeSubj',0);
    lowCeil = mean(rho_medRT_AvgModel{1});
elseif (what == "thetaBias")
    rho_bias_AvgModel = efc1_analyze('corr_bias_avg_model',data,'durAfterActive',durAfterActive,'selectRun',selectRun,...
                                'firstTrial',firstTrial,'includeSubj',1,'corrMethod',corrMethod);
    highCeil = mean(rho_bias_AvgModel{1}); 
    rho_bias_AvgModel = efc1_analyze('corr_bias_avg_model',data,'durAfterActive',durAfterActive,'selectRun',selectRun,...
                                'firstTrial',firstTrial,'includeSubj',0,'corrMethod',corrMethod);
   lowCeil = mean(rho_bias_AvgModel{1}); 
elseif (what == "meanDev")
    rho_meanDev_avgModel = efc1_analyze('corr_meanDev_avg_model',data,'selectRun',selectRun,'corrMethod',corrMethod,...
                                    'includeSubj',1);
    highCeil = mean(rho_meanDev_avgModel{1}); 
    rho_meanDev_avgModel = efc1_analyze('corr_meanDev_avg_model',data,'selectRun',selectRun,'corrMethod',corrMethod,...
                                    'includeSubj',0);
    lowCeil = mean(rho_meanDev_avgModel{1}); 
end




