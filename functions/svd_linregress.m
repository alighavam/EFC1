function [B,stats] = svd_linregress(y,X)

% svd decomposition of X:
[U,zeta,V] = svd(X);

% compact SVD of X, X=U1 zeta1 V1:
zeta1 = diag(zeta(zeta>1e-10));
U1 = U(:,1:size(zeta1,2));
V1 = V(:,1:size(zeta1,2));

% psuedo inverse of X:
X_cross = V1 * zeta1^-1 * U1';

% minimum norm(B) regression:
B = X_cross*y;
stats = -1;