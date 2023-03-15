function rhoWithinSubject = efc1_corr_within_subj_runs(data,corrMethod,excludeVec)

rhoWithinSubject = cell(size(data,1),2);
for i = 1:size(data,1)
    rho = 0;
    if (length(data{i,1}.BN) >= 2420)
        medRT = calcMedRT(data{i,1},excludeVec);
        medRT = cell2mat(medRT);
        medRT = medRT(:,2:end);
        rho = corr(medRT,'type',corrMethod);
    end
    rhoWithinSubject{i,1} = rho;
    rhoWithinSubject{i,2} = data{i,2};
end