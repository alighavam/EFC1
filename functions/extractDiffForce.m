function forces = extractDiffForce(data)

mov = data.mov;
forces = cell(size(mov));
for i = 1:length(mov)
    movTmp = mov{i};
    forces{i} = [movTmp(:,1) movTmp(:,3) movTmp(:,14:16) movTmp(:,17)*data.fGain4(1) movTmp(:,18)*data.fGain5(1)];
end