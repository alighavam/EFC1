function [R,R2] = crossval_reliability(X,varargin)
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
%       VARARGIN:
%
%       'split': Ues this in case you want to input dataframe formatted
%       data to this function.
%       if split is not empty, the function assumes that X is a
%       T by 1 vertical vector consisting of the concatenated data. Now
%       vector 'split' is also a T by 1 vector separating rows of X into
%       different splits. Remember that the number of values must be equal
%       across splits. splits could be subjects in case you want to
%       calculate the reliability of a measure across subjects.
%       As an example, X could be a 36 by 1 vector where split is a vector
%       [ones(12,1) ; 2*ones(12,1) ; 3*ones(12,1)] denoting that the 
%       first 12 rows are data of subject 1 and the second 12 rows are 
%       data for subject 2 and so on.
%
%
% Outputs:
%       R: leave-one-out correlation
%       R2: leave-one-out R squared
split = [];
vararginoptions(varargin,{'split'})

if ~isempty(split)
    part = unique(split);
    C = length(part);
    R = zeros(C,1);
    R2 = zeros(C,1);
    for i = 1:C
        % put split i out:
        out_data = X(split==part(i));
        
        % average the included data:
        avg_in = zeros(length(out_data),1);
        part_in = part(part ~= part(i));
        for j = 1:C-1
            avg_in = avg_in + X(split==part_in(j))/(C-1);
        end

        % calculate correlation of the current fold:
        R(i) = corr(avg_in,out_data);
        R2(i) = 1 - sum((avg_in - out_data).^2) / sum(out_data.^2);
    end
else
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
end

