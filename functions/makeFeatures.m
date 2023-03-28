function features = makeFeatures(varargin)

chordVec = generateAllChords();
chordVecSep = sepChordVec(chordVec);

% FEATURES
% num active fingers - linear:
% column: 1
f1 = zeros(size(chordVec));
for i = 1:size(chordVecSep,1)
    f1(chordVecSep{i,2}) = i;
end

% each finger flexed or not (1 or 0):
% column: 5
f2 = zeros(size(chordVec,1),5);
for i = 1:size(chordVec,1)
    chord = num2str(chordVec(i));
    f2(i,:) = (chord == '2');
end

% each finger extended or not (1 or 0):
% column: 5
f3 = zeros(size(chordVec,1),5);
for i = 1:size(chordVec,1)
    chord = num2str(chordVec(i));
    f3(i,:) = (chord == '1');
end

% second level interactions of finger combinations:
% column: 40
f4Base = [f2,f3];
f4 = [];
for i = 1:size(f4Base,2)-1
    for j = i+1:size(f4Base,2)
        if (j ~= i+5)
            f4 = [f4, f4Base(:,i) .* f4Base(:,j)];
        end
    end
end

% num active fingers - one-hot:
% column: 5
f5 = zeros(size(chordVec,1),5);
for i = 1:size(chordVecSep,1)
    f5(chordVecSep{i,2},i) = 1;
end

% neighbour finger combinations:
% column: 16
f6 = zeros(size(chordVec,1),16);
neighbourChords = [11555,12555,21555,22555,...
                   51155,51255,52155,52255,...
                   55115,55125,55215,55225,...
                   55511,55512,55521,55522];
for i = 1:size(chordVec,1)
    chordTmp = num2str(chordVec(i));
    for j = 1:length(neighbourChords)
        if (sum(chordTmp == num2str(neighbourChords(j))) == 2)
            f6(i,j) = 1;
        end
    end
end


if (varargin{1} == "all")
    features = [f5,f2,f3,f4];
elseif (varargin{1} == "numActiveFing-linear")
    features = f1;
elseif (varargin{1} == "numActiveFing-oneHot")
    features = f5;
elseif (varargin{1} == "singleFingFlex")
    features = f2;
elseif (varargin{1} == "singleFingExt")
    features = f3;
elseif (varargin{1} == "singleFinger")
    features = [f2,f3];
elseif (varargin{1} == "numActive+singleFinger")
    features = [f1,f2,f3];
elseif (varargin{1} == "neighbourFingers")
    features = f6;
elseif (varargin{1} == "neighbourFingers+singleFinger")
    features = [f2,f3,f6];
elseif (varargin{1} == "2FingerCombinations")
    features = f4;
elseif (varargin{1} == "singleFinger+2FingerCombinations")
    features = [f2,f3,f4];
else
    error("makeFeature option " + varargin{1} + " does not exist.")
end



