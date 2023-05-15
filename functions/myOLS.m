function [beta,SSR,SST] = myOLS(y,X)

beta = (X' * X)^-1 * X' * y;
SSR = trace(beta'*X'*X*beta);
SST = trace(y'*y);