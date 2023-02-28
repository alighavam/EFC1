function [chords] = makeChord(nMaxTrials,nChunk,nRepetition,nSessions,option)
% Ali Ghavampour 2022 - alighavam79@gmail.com
% Generating chords for the extensionFlexionChord experiment
% This function generates the chord column of the target files (.tgt) 
% for the ExtFlexChord experiment.

% ==========================================
% fingers: 1)thumb 2)index 3)middle 4)ring 5)little
% chord ID guide:
% '9' means finger should stay relaxed in the baseline zone.
% '1' means finger should extend.
% '2' means finger should flex.
% example: '91299' means extension of index, flexion of middle and all
% other fingers (thumb,ring,little) relaxed. 
% ==========================================

%   ========== HowToUse ====================
%   nMaxTrials : maximum number of trials in each session
%   nChunk: number of chunks for each chord
%   nRepetition: number of repetition of each chord in each chunk
%   option: select an option. refer to the code for details.

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

if (option == "fullShuffle")
    % =====================================================================
    % This option randomly shuffles the chunks across sessions. There is no
    % guarantee that you will see the same chord again in the same session
    % =====================================================================
    chordVec = repelem(chordVec,nChunk);                        % making chunk roots of chords
    chordVec = chordVec(randperm(length(chordVec)));            % shuffling the chunks

    % dividing chords into some sessions with less than nMaxTrials number 
    % of trials:
    nMaxChunks = floor(nMaxTrials/nRepetition);                 % max chunks allowed in each session
    idx = 1:nMaxChunks:length(chordVec);                        % indexes for the sessions generation loop
    chords = cell(1,length(idx));                               % cell to hold sessions

    % generating sessions chunks:
    for i = 1:length(idx)-1
        chords{i} = chordVec(idx(i):idx(i+1)-1);                % selecting 'nMaxChunks' chunks
        chords{i} = repelem(chords{i},nRepetition);             % repeating each chord in each chunk for nRepetiotions
    end
    chords{i+1} = chordVec(idx(i+1):end);
    chords{i+1} = repelem(chords{i+1},nRepetition);             % repeating each chord in each chunk for nRepetiotions

elseif (option == "chunkShuffle")
    chordVec = chordVec(randperm(length(chordVec)));            % shuffling the chords

    % dividing chords into some sessions with less than nMaxTrials number 
    % of trials:
    nChunksAllowed = floor(nMaxTrials/nRepetition/nChunk);      % maximum number of chunks allowed to be in each session - each chunks contains 'nRepetition' trials
    idx = 1:nChunksAllowed:length(chordVec);                    % indexes for the sessions generation loop
    chords = {1,length(idx)};                                   % cell to hold sessions

    % generating sessions chunks:
    for i = 1:length(idx)-1
        chords{i} = chordVec(idx(i):idx(i+1)-1);
        chords{i} = repelem(chords{i},nChunk);                  % repeating each chord in each session for nChunk times.
        chords{i} = chords{i}(randperm(length(chords{i})), :);  % shuffling chunk roots
        chords{i} = repelem(chords{i},nRepetition);             % repeating each chord for nRepetiotions
    end
    chords{i+1} = chordVec(idx(i+1):end);
    chords{i+1} = repelem(chords{i+1},nChunk);                  % repeating each chord in each session for nChunk times.
    chords{i+1} = chords{i+1}(randperm(length(chords{i+1})));   % shuffling chunk roots
    chords{i+1} = repelem(chords{i+1},nRepetition);             % repeating each chord for nRepetiotions

elseif (option == "HalfHalf")
    % =====================================================================
    % This option creates nSessions, seperates each session in two halves 
    % and shuffels the chord chunks in each half.
    % =====================================================================
    chordVec = chordVec(randperm(length(chordVec)));            % shuffling the chords
    chords = cell(1,nSessions);                                 % cell to hold sessions

    idx = 1:floor(length(chordVec)/nSessions):length(chordVec);
    idx(end) = length(chordVec)+1;                              % index for selecting chords from chordVec
    
    % generating sessions:
    for i = 1:nSessions-1
        tmp = chordVec(idx(i):idx(i+1)-1);                      % selecting chords
        half1 = tmp(randperm(length(tmp)));                     % making first half
        half1 = repelem(half1,nRepetition);                     % repeating chords
        half2 = tmp(randperm(length(tmp)));                     % making second half
        half2 = repelem(half2,nRepetition);                     % repeating chords
        chords{i} = [half1 ; half2];
    end
    tmp = chordVec(idx(end-1):idx(end)-1);                      % selecting chords
    half1 = tmp(randperm(length(tmp)));                         % making first half
    half1 = repelem(half1,nRepetition);                         % repeating chords
    half2 = tmp(randperm(length(tmp)));                         % making second half
    half2 = repelem(half2,nRepetition);                         % repeating chords
    chords{nSessions} = [half1 ; half2];
    
elseif (option == "fullCounterBalanced")
    % =====================================================================
    % Say we have n sessions (n should be even). all 242 chords are seen in
    % each n/2 sessions. Each chord is also repeated nRepetition times in a 
    % row in each half.
    % =====================================================================
    if (mod(nSessions,2) == 0)  % check if nSessions is even
        chords = cell(1,nSessions);                                 % cell to hold sessions
        numChordsSelect = floor(length(chordVec)/(nSessions/2));
        numChordsSelectLast = length(chordVec) - floor(length(chordVec)/(nSessions/2)) * (nSessions/2-1);

        % first n/2 sessions
        chordVec = chordVec(randperm(length(chordVec)));            % shuffling the chords
        for i = 1:nSessions/2-1
            tmpChords = chordVec((i-1)*numChordsSelect+1:i*numChordsSelect);
            chords{i} = repelem(tmpChords,nRepetition);
        end
        tmpChords = chordVec(i*numChordsSelect+1:i*numChordsSelect+numChordsSelectLast);
        chords{nSessions/2} = repelem(tmpChords,nRepetition);

        % second n/2 sessions
        chordVec = chordVec(randperm(length(chordVec)));            % shuffling the chords
        for i = 1:nSessions/2-1
            tmpChords = chordVec((i-1)*numChordsSelect+1:i*numChordsSelect);
            chords{i+nSessions/2} = repelem(tmpChords,nRepetition);
        end
        tmpChords = chordVec(i*numChordsSelect+1:i*numChordsSelect+numChordsSelectLast);
        chords{nSessions} = repelem(tmpChords,nRepetition);
        
        
    else  % if nSessions is not even:
        error(sprintf("For ""fullCounterBalanced"" option, nSessions must be an even number."))
    end


else
    error(sprintf("Option does not exist. Options: ""fullShuffle""  ""chunkShuffle"" ""HalfHalf"" ""fullCounterBalanced"" \nrefer to makeChord.m for more details"))
end







