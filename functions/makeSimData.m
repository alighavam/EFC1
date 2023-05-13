function y = makeSimData(rowNum,colNum,option,params)

if (option == 'random')
    mu = params(1);
    var = params(2);
    y = mu + sqrt(var) * randn(rowNum,colNum);

elseif (option == 'model') % y_ijk = delta_j + gamma_ij + epsilon_ijk
    chordVecTmp = params{1}(:,1);
    subjVecTmp = params{1}(:,2);
    varDelta = params{2}(1);
    varGamma = params{2}(2);
    varEps = params{2}(3);

    vecDelta = sqrt(varDelta) * randn(rowNum,colNum);
    vecGamma = sqrt(varGamma) * randn(rowNum,colNum);
    vecEps = sqrt(varEps)*randn(rowNum,colNum);

    y = vecDelta + vecGamma + vecEps;
end
