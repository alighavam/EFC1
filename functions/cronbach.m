function alpha = cronbach(X)
% Description:
%       Cronbach's alpha calculation.
%       alpha = N*mean(cov) / (mean(var) * (N-1)*mean(cov))
%       
%       mean(cov) is the mean of all possible covariances. 
%       mean(var) is the mean of the variance of each partition.
%       N is the number of partitions (number of columns of X).
%       
% INPUT:
%       X: format should be 'number of observations * partitions'. 
%          partitions could be different sessions or different subjects.
%
%       Inspired from cronbachsalpha.m from dataframe toolbox by Jorn
%       Diedrichsen. Link1: https://www.diedrichsenlab.org/toolboxes/matlab_toolboxes.htm
%                    Link2: https://github.com/jdiedrichsen/dataframe/releases/tag/2016.1
%
%   alighavam79@gmail.com

% variance-covariance matrix:
% omitrows omits any rows of A containing one or more NaN values when
% computing the covariance:
C = cov(X,"omitrows"); 

% number of partitions:
N = size(X,2);

mean_cov = C .* (1-eye(N));
mean_cov = sum(mean_cov(:))/(N*(N-1));
mean_var = trace(C)/N;

alpha = N*mean_cov / (mean_var + (N-1) * mean_cov);