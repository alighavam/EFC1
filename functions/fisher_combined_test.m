function p = fisher_combined_test(pi)

% number of samples:
k = length(pi);

% fisher z transform:
X2_2k = -2 * sum(log(pi));

% combined test;
p = chi2cdf(X2_2k,2*k,'upper');