function chordVecSep = sepChordVec(chordVec)

% separating chords based on number of active fingers
chordVecSep = cell(5,2);
for i = 1:length(chordVec)
    if (sum(num2str(chordVec(i))=='9')==4)
        chordVecSep{1,1} = [chordVecSep{1,1} chordVec(i)];
        chordVecSep{1,2} = [chordVecSep{1,2} i];
    elseif (sum(num2str(chordVec(i))=='9')==3)
        chordVecSep{2,1} = [chordVecSep{2,1} chordVec(i)];
        chordVecSep{2,2} = [chordVecSep{2,2} i];
    elseif (sum(num2str(chordVec(i))=='9')==2)
        chordVecSep{3,1} = [chordVecSep{3,1} chordVec(i)];
        chordVecSep{3,2} = [chordVecSep{3,2} i];
    elseif (sum(num2str(chordVec(i))=='9')==1)
        chordVecSep{4,1} = [chordVecSep{4,1} chordVec(i)];
        chordVecSep{4,2} = [chordVecSep{4,2} i];
    elseif (sum(num2str(chordVec(i))=='9')==0)
        chordVecSep{5,1} = [chordVecSep{5,1} chordVec(i)];
        chordVecSep{5,2} = [chordVecSep{5,2} i];
    end
end

