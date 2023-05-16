function [beta,SSR,SST] = myOLS(y,X,labels,option)

switch option
    case 'regular'  % regular regression without any cross validationt
        y = y-repmat(mean(y,1),size(y,1),1);    % mean centering the data (necessary for the matrix calculation of SSR)
        beta = (X' * X)^-1 * X' * y;    % estimated beta with OLS
        SSR = trace(beta'*(X'*X)*beta); % sum of squared regression
        SST = trace(y'*y);  % sum of squared total

    case 'shuffle_trial_crossVal'   % shuffles trials and does cross-validated regression
        numCrossVal = 5;

        X1 = X(:,1:242);
        X2 = X(:,243:end);
        
        trialID = labels(:,3);
        chordID = labels(:,2);
        subjID = labels(:,1);

        subjUnique = unique(subjID);
        chordUnique = unique(chordID);
        
        beta = cell(numCrossVal,1);
        SSR = zeros(numCrossVal,2);
        SST = zeros(numCrossVal,1);
        for n = 1:numCrossVal
            y_shuffled = y;
            for subj = 1:length(subjUnique)
                for i = 1:length(chordUnique)
                    tmpTrialsIdx = subjID == subjUnique(subj) & chordID == chordUnique(i);
                    y_tmp = y(tmpTrialsIdx,:);  % selecting all the trials for each chord of each subject
                    y_shuffled(tmpTrialsIdx,:) = y_tmp(randperm(size(y_tmp,1)),:);  % shuffling the trials (rows) and putting instead of original data
                end
            end
    
            % now we have y_shuffled which is a trial-shuffled version of y.
            % Seperating the data into training and validation sets:
            y_train = y_shuffled(trialID>=1 & trialID<=5 , :);
            y_train = y_train-repmat(mean(y_train,1),size(y_train,1),1); 
            X1_train = X1(trialID>=1 & trialID<=5 , :);
            X2_train = X2(trialID>=1 & trialID<=5 , :);

            y_val = y_shuffled(~(trialID>=1 & trialID<=5) , :);
            y_val = y_val-repmat(mean(y_val,1),size(y_val,1),1);
            X1_val = X1(~(trialID>=1 & trialID<=5) , :);
            X2_val = X2(~(trialID>=1 & trialID<=5) , :); 
            
            % Linear regression on the training set: 
            beta1 = (X1_train' * X1_train)^-1 * X1_train' * y_train;
            beta2 = (X2_train' * X2_train)^-1 * X2_train' * y_train;
            
            % testing on the validation data
            pred_X1 = X1_val * beta1;
            pred_X2 = X2_val * beta2;

            SSR_pred_X1 = sum(sum(pred_X1.^2,1));
            SSR_pred_X2 = sum(sum(pred_X2.^2,1));
            SST_tmp = sum(sum(y_val.^2,1));

            SSR(n,1) = SSR_pred_X1;
            SSR(n,2) = SSR_pred_X2;
            SST(n) = SST_tmp;
        end

    case 'subj_crossVal'   % cross validated regression across subjects
        X1 = X(:,1:242);
        X2 = X(:,243:end);
        
        trialID = labels(:,3);
        chordID = labels(:,2);
        subjID = labels(:,1);

        subjUnique = unique(subjID);
        chordUnique = unique(chordID);
        
        beta = cell(numCrossVal,1);
        SSR = zeros(numCrossVal,2);
        SST = zeros(numCrossVal,1);

        for subj = 1:length(subjUnique)
            y_tmp = 
        end


end

