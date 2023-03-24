function [thetaMean,thetaStd] = meanTheta(thetaCell,firstTrial)

thetaMean = zeros(242,size(thetaCell,1));
thetaStd = zeros(242,size(thetaCell,1));
for subj = 1:size(thetaCell,1)
    for j = 1:size(thetaMean,1)
        thetaMean(j,subj) = mean(thetaCell{subj,1}{j,2}(firstTrial:end));
        thetaStd(j,subj) = std(thetaCell{subj,1}{j,2}(firstTrial:end));
    end
end