function C = efc1_trial(row)

% container for the trial data:
C = [];

% in case of execution error, set the RT to 10000ms. This was an old problem
% with the experiment code where RT of execution error was saved as 10 not
% 10000 and here is a post-fix for the subjects that were recorded with the
% old code:
if (row.trialErrorType==2)
    row.RT = 10000;   % correction for execution error trials
end

C = addstruct(C,row,'row','force');
