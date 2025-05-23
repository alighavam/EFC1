function [chordVec, chordVecSep] = generateAllChords()
% Ali Ghavampour 2023 - alighavam79@gmail.com
% This function generates all of the possible chords

combPool = {[1,9,9,9,9] % All the possible combinations of flex-ext-relax. All permutations of each combination makes all possible chords.
            [2,9,9,9,9]
            [1,1,9,9,9]
            [1,2,9,9,9]
            [2,2,9,9,9]
            [1,1,1,9,9]
            [1,1,2,9,9]
            [1,2,2,9,9]
            [2,2,2,9,9]
            [1,1,1,1,9]
            [1,1,1,2,9]
            [1,1,2,2,9]
            [1,2,2,2,9]
            [2,2,2,2,9]
            [1,1,1,1,1]
            [1,1,1,1,2]
            [1,1,1,2,2]
            [1,1,2,2,2]
            [1,2,2,2,2]
            [2,2,2,2,2]};

chordMat = [9,9,9,9,9];     % chords are saved in this matrix (243x5).
chordVec = [];              % we should turn the 243x5 matrix into a 243x1 string vector for the .tgt files.

% making a 243x13 matrix of all the possible chords:
for iComb = 1:size(combPool,1)
    chordTmpMat = perms(combPool{iComb});
    chordMat = [chordMat ; unique(chordTmpMat,'rows')]; 
end

% change the matrix into a vector -> each row of matrix will become an
% element of the new vector:
chordMat = num2str(chordMat);
for i = 1:size(chordMat,1)
    tmp = chordMat(i,:);
    idxTmp = strfind(tmp,' ');
    tmp(idxTmp) = [];
    tmp = str2double(tmp);
    chordVec = [chordVec;tmp]; 
end
chordVec = chordVec(2:end); % chordVec contains all the possible unique chords other than 99999 (size:242x1) which is all fingers relaxed.


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

