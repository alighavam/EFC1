function [c_g, c_gs] = reliability_corr(Y, subj_vec, part_vec, varargin)
% alighavam79@gmail.com
%
% Description:
%       variance decomposition on dataset. Say the multi-channel data
%       y_ij follow the following format:
%               y_ij = g + s_i + e_ij
%       i, being the subject number and j, the partition/session number.
%
%       Assuming a) g, s_i, e_ij are mutually independent b) e_ij and s_i
%       are i.i.d, we can estimate the term variances as follows:
%       
%       Across subjects:
%       v_g = E[y_ij, y_kl]
%       Within subject, Across run:
%       v_g + v_s = E[y_ij, y_ik]
%       Within observation/partition:
%       v_g + v_s + v_e = E[y_ij, y_ij]
%
%       To develop estimators for these quantities we replace the 
%       Expectation with the mean over all possible pairings.
%
% INPUT:
%       Y: Data vector/matrix vertically concatenated for subjects and
%       partitions. In case of using dataframe this would be C.data.
%
%       subj_vec: column vector of subject numbers. In case of using
%       dataframe this would be C.sn
%
%       part_vec: column vector of partition numbers. Partitions could be
%       sessions/blocks/runs within a subject. In case of using dataframe
%       this would be something like C.sess/C.partition/...
%
%       varargin: 
%       'cond_vec': column vector of condition numbers. If a cond_vec is
%       inputted, the reliability is calculated separately for different
%       conditions. The output v_g, v_gs, v_gse will be in form of a cell
%       array containing the estimations for different conditions in each
%       cell.
%
%       'centered': 1 or 0. If 1, centers the data within observation y_ij 
%       before variance decomposition.
%
% OUTPUT:
%       v_g: estimated across subject variance (global effect).
%       v_gs: estimated (Within subject, Across run) variance.
%       v_gse: estimated (Within observation) variance.
%
%
% HOW TO USE: 
% % Here is an example of how to use the function.
% % Experiment: Play with the value of n to see how it effects the estimation
% % of the variance portions.
%
% % number of data points in each partition:
% n = 30;
% 
% % global effect:
% g = normrnd(0, 2, n, 1);   
% % subject 1 effect:
% s1 = normrnd(0, 1, n, 1);  
% % subejct 2 effect:
% s2 = normrnd(0, 1, n, 1);  
% 
% % subject 1 data:
% x1 = [g + s1 + normrnd(0,0.3,n,1) ; g + s1 + normrnd(0,0.3,n,1)];
% % subject 2 data:
% x2 = [g + s2 + normrnd(0,0.3,n,1) ; g + s2 + normrnd(0,0.3,n,1)];
% 
% Y = [x1 ; x2];
% subj_vec = kron([1;2],ones(2*n,1));
% part_vec = kron([1;2;1;2],ones(n,1));
% 
% [v_g, v_gs, v_gse] = reliability_var(Y, subj_vec, part_vec);
% 
% % theoretical var decomp:
% fprintf('Theoretical:\nvar_g = %.4f , var_s = %.4f , var_e = %.4f\n',4/(4+1+0.09),1/(4+1+0.09),0.09/(4+1+0.09))
% 
% % estimated:
% fprintf('Estimated:\nvar_g = %.4f , var_s = %.4f , var_e = %.4f\n\n',v_g/v_gse,(v_gs-v_g)/v_gse,(v_gse-v_gs)/v_gse)  

% check for nans:
if sum(isnan(Y),'all')~=0
    warning('Input data contains nan elements')
end


% handling input arguments:
cond_vec = ones(size(subj_vec));
vararginoptions(varargin,{'cond_vec'})

subjects = unique(subj_vec);
partitions = unique(part_vec);
conds = unique(cond_vec);

% estimating c_g and c_s:
c_g = 0;
c_gs = 0;
if length(conds)>1
    c_g = cell(length(conds),1);
    c_gs = cell(length(conds),1);
    for i = 1:length(conds)
        c_g{i} = 0;
        c_gs{i} = 0;
    end
end

% container for subj data:
subj_data = {};

% loop on conditions:
for k = 1:length(conds)
    % loop on subjects:
    for i = 1:length(subjects)
        % matrix to hold subject data:
        A = [];
        % loop on partitions:
        for j = 1:length(partitions)
            % getting the data for subj i , partition j:
            part_data = Y(subj_vec==subjects(i) & part_vec==partitions(j) & cond_vec==conds(k),:);
    
            % adding the partition data to A:
            A = [A, part_data(:)];
        end
        % storing subject data:
        subj_data{i,k} = A;
    
        % correlation matrix of subject data:
        B = corr(A);
        B = cronbach(A);
    
        % number of partitions:
        N = size(A,2);

        % sum of off-diagonal elems corr(y_ij,y_ik):
        % mean_corr = B .* (1-eye(N));
        % mean_corr = sum(mean_corr(:))/(N*(N-1));
        tmp_c_gs = B/length(subjects);

        if length(conds)>1
            c_gs{k} = c_gs{k} + tmp_c_gs;
        else
            c_gs = c_gs + tmp_c_gs;
        end
    end
end
    
% estimating c_g:
c_g = 0;
if length(conds)>1
    c_g = cell(length(conds),1);
    for i = 1:length(conds)
        c_g{i} = 0;
    end
end

N = length(subjects);


% avg of partitions:
subj_data_avg = cellfun(@(x) mean(x,2), subj_data, 'UniformOutput', false);
for k = 1:length(conds)
    for i = 1:N
        % subj i out data:
        tmp_subj_out = subj_data_avg(setdiff(1:N,i),k);
        avg_out = mean([tmp_subj_out{:}],2);
        
        % subj i data:
        avg_in = subj_data_avg{i,k};
        
        % correlation:
        tmp_c_g = corr(avg_in,avg_out)/N;

        if length(conds)>1
            c_g{k} = c_g{k} + tmp_c_g;
        else
            c_g = c_g + tmp_c_g;
        end

    end
end



