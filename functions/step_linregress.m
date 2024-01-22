function [B,STATS] = step_linregress(y, X)
% Description:
%       Linear regression on the models (design matrices) stored in cell X.
%       Models are fitted one by one in the order of the X and each model
%       is fitted on the residuals of the previous model.
%
% INPUT:
%       y: Explained var. A column vector.
%       X: a cell in the form of {X1, X2, X3, ...} of the design matrices.
%       Xi's number of rows should be size(y,1).
%
% OUTPUT:
%       B: Cocefficients. Length is the sum of number of columns of all Xi.
%       STATS: stats of the linear regression.

B = [];
STATS = [];

% loop on models:
res = y;
for i = 1:length(X)
    % regression on the residuals of the previous model fit, 
    % res = y - y_estimated:
    [B_tmp,~]=linregress(res,X{i},'intercept',0);
    B = [B ; B_tmp];
    % getting the residuals:
    res = y - X{i} * B_tmp;
end

STATS.R2 = 1 - sum(res.^2)/sum(y.^2);










