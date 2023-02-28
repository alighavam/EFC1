function out = mergeSessionsMov(mov)
% Ali Ghavampour 2023 - alighavam79@gmail.com
% This function merges all of the sessions in the 1xn mov cell into one
% session

out = {};
for i = 1:length(mov)
    out = [out,mov{i}];
end