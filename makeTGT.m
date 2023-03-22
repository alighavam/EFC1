%% Ali Ghavampour 2022
% This code makes .tgt files for the ExtFlexChord experiment

%% Behavioral experiment target files
% tgt files for the experiment containing all chords.
clear;
clc;
close all;

% Loading packages 
% iMac
path(path,genpath('/Users/aghavampour/Documents/MATLAB'));
% Macbook Pro
% path(path,genpath('/Users/alighavam/Documents/MATLAB'));

% Loading functions
% iMac
addpath('/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1/functions');
cd("/Users/aghavampour/Desktop/Projects/ExtFlexChord/EFC1");
% Macbook Pro
% addpath('/Users/alighavam/Desktop/ExtFlexChord/functions');
% cd("/Users/alighavam/Desktop/ExtFlexChord/");

% experiment parameters
subNum = 9;                        % subject number - dont forget to change this for each subject!!!!!!
nSessions = 24;
option = "fullCounterBalanced";    % option for makeChord function

nMaxTrials = 40;        % number of maximum trials per session
nChunks = 2;            % number of chunks for each chord
nRepetition = 5;        % number of repetition of each chord in each chunk
planTime = 500;         % planTime column in .tgt file
execMaxTime = 10000;    % execMaxTime column in .tgt file
feedbackTime = 800;     % feedBackTime column in .tgt file
iti = 200;              % iti column of .tgt file
columnNames = {'subNum','chordID','planTime','execMaxTime','feedbackTime','iti'};

% making chords:
chords_set1 = makeChord(nMaxTrials,nChunks,nRepetition,nSessions,option);
chords_set2 = makeChord(nMaxTrials,nChunks,nRepetition,nSessions,option);

% making .tgt files
% set 1:
targetStruct = struct(columnNames{1},[],columnNames{2},[],columnNames{3},[],columnNames{4},[],columnNames{5},[],columnNames{6},[]);
cd(sprintf("target/%s",option)) % change path to target folder
nSessions = size(chords_set1,2);
for i = 1:nSessions
    trialNum = length(chords_set1{i});
    targetStruct.subNum = repmat([subNum],trialNum,1);
    targetStruct.chordID = chords_set1{i};
    targetStruct.planTime = repmat([planTime],trialNum,1);
    targetStruct.execMaxTime = repmat([execMaxTime],trialNum,1);
    targetStruct.feedbackTime = repmat([feedbackTime],trialNum,1);
    targetStruct.iti = repmat([iti],trialNum,1);
    datsave(sprintf("efc1_subj0%s_set1_run%s.tgt",num2str(subNum),num2str(i)),targetStruct);
end
% set 2:
targetStruct = struct(columnNames{1},[],columnNames{2},[],columnNames{3},[],columnNames{4},[],columnNames{5},[],columnNames{6},[]);
nSessions = size(chords_set2,2);
for i = 1:nSessions
    trialNum = length(chords_set2{i});
    targetStruct.subNum = repmat([subNum],trialNum,1);
    targetStruct.chordID = chords_set2{i};
    targetStruct.planTime = repmat([planTime],trialNum,1);
    targetStruct.execMaxTime = repmat([execMaxTime],trialNum,1);
    targetStruct.feedbackTime = repmat([feedbackTime],trialNum,1);
    targetStruct.iti = repmat([iti],trialNum,1);
    datsave(sprintf("efc1_subj0%s_set2_run%s.tgt",num2str(subNum),num2str(i)),targetStruct);
end
disp("target file created")
cd('..')
cd('..')


















