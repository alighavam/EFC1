function forces = extractDiffForce(data)

mov = data{1}.mov;
forces = cell(size(mov));
for i = 1:length(mov)
    movTmp = mov{i};
    forces{i} = [movTmp(:,1) movTmp(:,3) movTmp(:,14:18)];
end