function varargout=efc1_analyze(what, varargin)

addpath(genpath('/Users/aghavampour/Documents/MATLAB/dataframe-2016.1'),'-begin');
behavDir='/Users/aghavampour/Desktop/Projects/ExtFlexChord/efc1/analysis';

%GLOBALS:
subjName = {'subj07'};

switch (what)
    case 'all_subj'     % create .mat data files for subjects   
        for s = 1:length(subjName)
            efc1_subj(subjName{s},0);
        end
    
    
    otherwise
        error('The analysis you entered does not exist!')
end
