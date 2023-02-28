function medRT = calcMedRT(subjData)


data = subjData;
chordVec = generateAllChords();  % all chords
medRT = cell(length(chordVec),2);   % each chord will be seen 4 times
for i = 1:length(chordVec)
    medRT{i,1} = chordVec(i);
    chordIdx = find(data.chordID == chordVec(i));
    if (~isempty(chordIdx))
        tmpRT = data.RT(chordIdx)-600;
        if (length(find(tmpRT==0)) ~= length(tmpRT))
            tmpMed = [];
            for j = 1:length(tmpRT)/5
                tmp = tmpRT((j-1)*5+1:j*5);
                tmp(tmp==0) = [];
                if (~isempty(tmp))
                    tmpMed = [tmpMed median(tmp)];
                else
                    tmpMed = [tmpMed 0];
                end
            end
            medRT{i,2} = tmpMed;
        else
            medRT{i,2} = [];
        end
    else
        medRT{i,2} = [];
    end
    
    
end
