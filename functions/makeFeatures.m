function features = makeFeatures(varargin)

chordVec = generateAllChords();
chordVecSep = sepChordVec(chordVec);

% FEATURES
% num active fingers - continuous:
% column: 1
f1 = zeros(size(chordVec));
for i = 1:size(chordVecSep,1)
    f1(chordVecSep{i,2}) = i;
end

% each finger flexed or not (1 or 0):
% column: 2:6
f2 = zeros(size(chordVec,1),5);
for i = 1:size(chordVec,1)
    chord = num2str(chordVec(i));
    f2(i,:) = (chord == '2');
end

% each finger extended or not (1 or 0):
% column: 7:11
f3 = zeros(size(chordVec,1),5);
for i = 1:size(chordVec,1)
    chord = num2str(chordVec(i));
    f3(i,:) = (chord == '1');
end

% second level interactions of finger combinations:
% column: 12:56
f4Base = [f2,f3];
f4 = [];
for i = 1:size(f4Base,2)-1
    for j = i+1:size(f4Base,2)
        f4 = [f4, f4Base(:,i) .* f4Base(:,j)];
    end
end

features = [f1,f2,f3,f4];
if (varargin{1} == "numActiveFing")
    features = f1;
elseif (varargin{1} == "singleFingFlex")
    features = f2;
elseif (varargin{1} == "singleFingExt")
    features = f3;
elseif (varargin{1} == "singleFinger")
    features = [f2,f3];
elseif (varargin{1} == "numActive+singleFinger")
    features = [f1,f2,f3];
else
    error("makeFeature option " + varargin{1} + " does not exist.")
end



