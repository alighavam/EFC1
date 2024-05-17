function [C, X, Y, COND, SN] = get_sem(y, subj_vec, part_vec, cond_vec)
% alighavam79@gmail.com - Diedrichsen and Pruszynski lab 2024.
% Description:
%       Estimates the sem across subjects for each condition in the
%       cond_vec within each partition in part_vec. Here is an example of
%       using this function with a dataframe:
%       get_sem(df.data, df.sn, df.sess, df.conditions)
%       where df is the dataframe. sn is the subject number' field. sess is
%       session. conditions is the conditions field. 
%       You can also manually create a cond_vec, subj_vec, and part_vec for 
%       any vecrtical vector y. Just note that length of them should match 
%       length of y.
%       
% INPUTs:
%       y: The input data. Nx1 vector.
%
%       subj_vec: vector of integers that specifies subejcts, subj_vec(i) 
%                 specifies which subject the data point y(i) is from.
%
%       part_vec: Nx1 vector of integers that specifies partitions 
%                 (sessions, runs, etc). Similar to subj_vec.
%
%       cond_vec: Nx1 vector of inegers that specifies conditions. Similar
%                 to subj_vec
%
% OUTPUTs:
%       C: dataframe with fields {cond, partitions, y, sem}. sem field is
%          the sem across subject for cond(i) and parititions(i). y(i) is
%          the avg of the data across subjects in each cond and partition.
%
%       Y: Vector of within subject average in each partition and 
%          condition.
%
%       X: The partition vector corresponding to Y. X(i) is the partition
%          that Y(i) is coming from.
%
%       COND: The condition vector corresponding to Y. COND(i) is the
%             condition Y(i) is coming from.
%
%       SN: subject vector corresponding to Y.

subjects = unique(subj_vec);
partitions = unique(part_vec);
conds = unique(cond_vec);

C = [];
X = [];
Y = [];
COND = [];
SN = [];

cnt = 1;
% loop on each partition. In EFC project, loop on sessions:
for i = 1:length(partitions)
    % loop on conditions. In EFC project, loop on num_fingers:
    for j = 1:length(conds)
        val = zeros(length(subjects),1);
        for k = 1:length(subjects)
            % average of data points y in each partition and condition 
            % within subjects:
            val(k) = mean(y(subj_vec==subjects(k) & part_vec==partitions(i) & cond_vec==conds(j)),'omitmissing');
        end
        % storing the values and estimating sem across subjects:
        C.cond(cnt,1) = conds(j);
        C.partitions(cnt,1) = partitions(i);
        C.y(cnt,1) = mean(val,'omitmissing');
        C.sem(cnt,1) = std(val,'omitmissing')/sqrt(sum(~isnan(val)));
        
        % subject data average within subjects:
        Y = [Y ; val];
        X = [X ; partitions(i)*ones(length(val),1)];
        COND = [COND ; conds(j)*ones(length(val),1)];
        SN = [SN ; subjects];

        cnt = cnt+1;
    end
end
