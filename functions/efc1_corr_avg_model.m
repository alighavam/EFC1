function rhoAvgModel = efc1_corr_avg_model(data,corrMethod)

medRTSubjects = [];
rhoAvgModel = cell(1,2);
for i = 1:size(data,1)
    if (length(data{i,1}.BN) >= 2420)
        medRT = calcMedRT(data{i,1});
        medRT = cell2mat(medRT);
        medRT = medRT(:,2:end);
        medRTSubjects = [medRTSubjects , medRT(:,end)];
        rhoAvgModel{1,2} = [rhoAvgModel{1,2} convertCharsToStrings(data{i,2})];
    end
end

for i = 1:size(medRTSubjects,2)
    idxMean = setdiff(1:size(medRTSubjects,2),i);   % excluding one subject
    avgModel = mean(medRTSubjects(:,idxMean),2);    % average median RT model
    rhoTmp = corr([medRTSubjects(:,i) , avgModel],'type',corrMethod);   % correlation of average model and excluded subject
    rhoAvgModel{1,1} = [rhoAvgModel{1,1} rhoTmp(1,2)];
end

