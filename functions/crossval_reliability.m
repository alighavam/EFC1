function [R,R2] = crossval_reliability(X)
% Estimates the leave-one-out reliability of subjects/sessions/...
% a) Put 1 subject away. 
% b) Calculate the average of N-1 subjects. 
% c) Find the R and R2 of the group average and the left out subject. 
% d) Do this N times and each time leave a different subject out.
%
% Inputs:
%       X: an N by C matrix where C is the number of subjects/sessions and
%       N (rows) is the number of observations. Optionally, if your
%       observations are more 2-dimensional, X could be a C by 1 
%       cell array where each cell contains a matrix of observation for 
%       subjects.
%
% Outputs:
%       R: leave-one-out correlation
%       R2: leave-one-out R squared

is_cell = iscell(X);

if is_cell
    C = length(X);
else
    C = size(X,2);
end

R = zeros(C,1);
R2 = zeros(C,1);

for i = 1:C
    idx_in = setdiff(1:C,i);
    if is_cell
        avg = 0;
        % average of N-1 subejcts:
        for j = 1:length(idx_in)
            avg = avg + X{j}/length(idx_in);
        end
        R(i) = corr2(avg,X{i});
        R2(i) = mean(1 - sum((avg - X{i}).^2,1) ./ sum(X{i}.^2,1));
    else
        avg = mean(X(:,idx_in),2);
        R(i) = corr(avg,X(:,i));
        R2(i) = 1 - sum((avg - X(:,i)).^2) / sum(X(:,i).^2);
    end
end

