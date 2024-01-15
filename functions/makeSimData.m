function y = makeSimData(rowNum,colNum,option,params)

if (strcmp(option,'random'))
    mu = params(1);
    var = params(2);
    y = mu + sqrt(var) * randn(rowNum,colNum);

elseif (strcmp(option,'model')) % y_ijk = delta_j + gamma_ij + epsilon_ijk
    X1 = params{1}{1};
    X2 = params{1}{2};
    [ir_x1,ic_x1] = find(X1);
    [ir_x2,ic_x2] = find(X2);

    varChord = params{2}(1);
    varSubj = params{2}(2);
    varEps = params{2}(3);
    
    vecChord = sqrt(varChord) * randn(242,colNum);
    vecSubj = repelem(sqrt(varSubj) * randn(9,colNum),242,1);
    vecEps = sqrt(varEps)*randn(rowNum,colNum);
    
    y = vecEps;

    for i = 1:size(y,1)
        y(ir_x1(i),:) = y(ir_x1(i),:) + vecChord(ic_x1(i),:);
        y(ir_x2(i),:) = y(ir_x2(i),:) + vecSubj(ic_x2(i),:);
    end
end
