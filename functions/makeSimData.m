function y = makeSimData(rowNum,colNum,option,params)

if (strcmp(option,'random'))
    mu = params(1);
    var = params(2);
    y = mu + sqrt(var) * randn(rowNum,colNum);

elseif (strcmp(option,'model')) % y_ijk = delta_j + gamma_ij + epsilon_ijk
    X1 = params{1}{1};
    X2 = params{1}{2};
    [~,ic_x1] = find(X1);
    [~,ic_x2] = find(X2);

    varChord = params{2}(1);
    varSubj = params{2}(2);
    varEps = params{2}(3);
    
    vecChord = sqrt(varChord) * randn(242,colNum);
    vecSubj = sqrt(varSubj) * randn(242*6,colNum);
    vecEps = sqrt(varEps)*randn(rowNum,colNum);

    y = vecEps;

    for i = 1:size(y,1)
        y(i,:) = y(i,:) + vecChord(ic_x1(i),:) + vecSubj(ic_x2(i),:);
    end
end
