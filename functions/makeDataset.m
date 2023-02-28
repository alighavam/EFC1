function makeDataset(subjectName,option)
% Ali Ghavampour 2022 - alighavam79@gmail.com
% Reading .mov and .dat file and making a struct from those files. The .mov
% and .dat files are turned into tables for ease of use.

% Loading packages 
if (option == "iMac")
    path(path,genpath('/Users/aghavampour/Documents/MATLAB/dataframe-2016.1'));
    cd(sprintf("/Users/aghavampour/Desktop/ExtFlexChord/data/"+subjectName+"/"));
elseif (option == "macbookPro")
    path(path,genpath('/Users/alighavam/Documents/MATLAB/dataframe-2016.1'));
    cd(sprintf("/Users/alighavam/Desktop/ExtFlexChord/data/"+subjectName+"/"));
end

% Loading data
filesDat = dir('*.dat');
filesMov = dir('*.mov');
dat = datload(filesDat(1).name);
dataMov = {1,length(filesMov)};
disp("Loading mov files. This might take a few minutes.")
for i = 1:length(filesMov)
    fprintf("loading session "+num2str(i)+"...\n");
    dataMov{i} = movload(filesMov(i).name);
end

% Changing RT of execution error trials from 0 to 10s:
trialErrorTypeTmp = dat.trialErrorType;
execErrorIdx = find(trialErrorTypeTmp == 2);
dat.RT(execErrorIdx) = 10000;

% Making a cell of all sessions: 
% Each session contains tables of each trial made from .mov files
movCell = {1,length(dataMov)};
for i = 1:length(dataMov)
    tmpMov = dataMov{i};
    for j = 1:length(tmpMov)
        tmpMov{j} = array2table(tmpMov{j});
        tmpMov{j}.Properties.VariableNames = {'state' 'timeReal' 'time' 'extForce1' 'extForce2' 'extForce3' 'extForce4' 'extForce5' ...
            'flxForce1' 'flxForce2' 'flxForce3' 'flxForce4' 'flxForce5' ...
            'diffForce1' 'diffForce2' 'diffForce3' 'diffForce4' 'diffForce5' ...
            'visForce1' 'visForce2' 'visForce3' 'visForce4' 'visForce5'};
    end
    movCell{i} = tmpMov;
end

% Making a table of .dat file:
dat = struct2table(dat);

dataset = struct('dat',[],'mov',[]);
dataset.dat = dat;
dataset.mov = movCell;

if (option == "iMac")
    cd("/Users/aghavampour/Desktop/ExtFlexChord/data");
    save(sprintf("efc1_dataset_"+subjectName),"dataset");
    cd("/Users/aghavampour/Desktop/ExtFlexChord");
    fprintf("Dataset created\n");
elseif (option == "macbookPro")
    cd("/Users/alighavam/Desktop/ExtFlexChord/data");
    save(sprintf("efc1_dataset_"+subjectName),"dataset");
    cd("/Users/alighavam/Desktop/ExtFlexChord");
    fprintf("Dataset created\n");
end




