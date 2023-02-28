function [dataset,dat,mov,chordVec,medianRTMat] = init(subjectName)
% Ali Ghavampour 2023 - alighavam79@gmail.com
% This code loads all the required variables for the analysis

dataset = load(sprintf("efc1_dataset_"+subjectName));
dataset = dataset.dataset;
dat = dataset.dat;
mov = dataset.mov;
mov = mergeSessionsMov(mov);                        % merging all sessions for ease of use
chordVec = generateAllChords();                     % vector of all chords
medianRTMat = calculateRTMedian(dat);               % median reaction time of all chords
