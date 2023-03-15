function rhoAcrossSubjects = efc1_corr_across_subj(data,corrMethod,excludeVec)

medRTSubjects = [];
rhoAcrossSubjects = cell(1,2);
for i = 1:size(data,1)
    if (length(data{i,1}.BN) >= 2420)
        medRT = calcMedRT(data{i,1},excludeVec);
        medRT = cell2mat(medRT);
        medRT = medRT(:,2:end);
        medRTSubjects = [medRTSubjects , medRT(:,end)];
        rhoAcrossSubjects{1,2} = [rhoAcrossSubjects{1,2} convertCharsToStrings(data{i,2})];
    end
end
rhoAcrossSubjects{1,1} = corr(medRTSubjects,'type',corrMethod);