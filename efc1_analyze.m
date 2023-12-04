function varargout=efc1_analyze(what, varargin)

addpath('functions/')

% setting paths:
usr_path = userpath;
usr_path = usr_path(1:end-17);
project_path = fullfile(usr_path, 'Desktop', 'Projects', 'EFC1');

% colors:
colors = [[0.4660, 0.6740, 0.1880] ; [0.3010, 0.7450, 0.9330] ; [0.9290, 0.6940, 0.1250] ; [0.8500, 0.3250, 0.0980] ; [0.4940, 0.1840, 0.5560]];

switch (what)
    case 'subject_routine'
        % handling input arguments:
        subject_name = 'subj01';
        smoothing_win_length = 25;
        vararginoptions(varargin,{'subject_name','smoothing_win_length'});
        
        % if a cell containing multiple subjects was given:
        if (iscell(subject_name))
            for i = 1:length(subject_name)
                efc1_subj(subject_name{i},'smoothing_win_length',smoothing_win_length)
            end
        % if a single subject as a char was given:
        else
            efc1_subj(subject_name,'smoothing_win_length',smoothing_win_length);
        end
    
    case 'make_analysis_data'
        % Calculate RT, MT, Mean Deviation for each trial of each subejct
        % and create a struct without the mov signals and save it as a
        % single struct called efc1_all.mat
        
        % getting subject files:
        files = dir(fullfile(usr_path, 'Desktop', 'Projects', 'EFC1', 'analysis', 'efc1_*_raw.tsv'));
        movFiles = dir(fullfile(usr_path, 'Desktop', 'Projects', 'EFC1', 'analysis', 'efc1_*_mov.mat'));
        
        % container to hold all subjects' data:
        ANA = [];
        
        % looping through subjects' data:
        for i = 1:length({files(:).name})
            % load subject data:
            tmp_data = dload(fullfile(files(i).folder, files(i).name));
            tmp_mov = load(fullfile(movFiles(i).folder, movFiles(i).name));
            tmp_mov = tmp_mov.MOV_struct;
            
            mean_dev_tmp = zeros(length(tmp_data.BN),1);
            rt_tmp = zeros(length(tmp_data.BN),1);
            mt_tmp = zeros(size(rt_tmp));
            first_finger_tmp = zeros(size(rt_tmp));
            % loop through trials:
            for j = 1:length(tmp_data.BN)
                % if trial was correct:
                if (tmp_data.trialCorr(j) == 1)
                    % calculate and store mean dev:
                    mean_dev_tmp(j) = calculate_mean_dev(tmp_mov{j}, tmp_data.chordID(j), ...
                                                         tmp_data.baselineTopThresh(j), tmp_data.RT(j), ...
                                                         tmp_data.fGain1(j), tmp_data.fGain2(j), tmp_data.fGain3(j), ...
                                                         tmp_data.fGain4(j), tmp_data.fGain5(j));
                    % calculate and stor rt and mt:
                    [rt_tmp(j),mt_tmp(j),first_finger_tmp(j)] = calculate_rt_mt(tmp_mov{j}, tmp_data.chordID(j), ...
                                                                tmp_data.baselineTopThresh(j), tmp_data.RT(j), ...
                                                                tmp_data.fGain1(j), tmp_data.fGain2(j), tmp_data.fGain3(j), ...
                                                                tmp_data.fGain4(j), tmp_data.fGain5(j));
                
                % if trial was incorrect:
                else
                    % mean dev:
                    mean_dev_tmp(j) = -1;
                    rt_tmp(j) = -1;
                    mt_tmp(j) = -1;
                    first_finger_tmp(j) = -1;
                end
            end
            
            % removing unnecessary fields:
            tmp_data = rmfield(tmp_data,'RT');
            tmp_data = rmfield(tmp_data,'trialPoint');

            % adding the calculated parameters to the subject struct:
            tmp_data.RT = rt_tmp;
            tmp_data.MT = mt_tmp;
            tmp_data.first_finger = first_finger_tmp;
            tmp_data.mean_dev = mean_dev_tmp;
            
            % adding subject data to ANA:
            ANA=addstruct(ANA,tmp_data,'row','force');
        end
        % adding number of active fingers:
        ANA.num_fingers = get_num_active_fingers(ANA.chordID);

        dsave(fullfile(usr_path,'Desktop','Projects','EFC1','analysis','efc1_all.tsv'),ANA);
    

    case 'behavior_reliability'
        blocks = [25 48];
        vararginoptions(varargin,{'blocks'})
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_all.tsv'));
        
        subjects = unique(data.sn);

        % extracting avg mean dev of all subjects:
        C = [];
        for sn = 1:length(subjects)
            tmp = [];
            % all possible chords:
            chords = generateAllChords();

            for i = 1:length(chords)
                tmp.sn(i,1) = subjects(sn);
                tmp.chordID(i,1) = chords(i);
                tmp.num_fingers(i,1) = get_num_active_fingers(chords(i));

                row = data.sn==subjects(sn) & data.BN>=blocks(1) & data.BN<=blocks(2) & data.chordID==chords(i) & data.trialCorr==1;
                tmp.mean_dev(i,1) = mean(data.mean_dev(row));
                tmp.RT(i,1) = median(data.RT(row));
                tmp.MT(i,1) = median(data.MT(row));
            end

            % concatenating subjects:
            C = addstruct(C,tmp,'row','force');
        end

        % getting the values in matrix format
        MD = zeros(length(chords),length(sn));
        RT = zeros(length(chords),length(sn));
        MT = zeros(length(chords),length(sn));
        for sn = 1:length(subjects)
            MD(:,sn) = C.mean_dev(C.sn==subjects(sn));
            RT(:,sn) = C.RT(C.sn==subjects(sn));
            MT(:,sn) = C.MT(C.sn==subjects(sn));
        end
        
        % num active fingers:
        n = C.num_fingers(C.sn==1);

        % corr behavior leave-one-out:
        corr_MD = [];
        corr_MT = [];
        corr_RT = [];
        
        corr_struct = [];
        for i = 1:length(unique(n))
            tmp = [];
            for sn = 1:length(subjects)
                tmp.num_fingers(sn,1) = i;

                [r,p] = corrcoef(MD(n==i,sn),mean(MD(n==i,subjects~=subjects(sn)),2));
                tmp.MD(sn,1) = r(2);
                tmp.MD_p(sn,1) = p(2);

                [r,p] = corrcoef(MT(n==i,sn),mean(MT(n==i,subjects~=subjects(sn)),2));
                tmp.MT(sn,1) = r(2);
                tmp.MT_p(sn,1) = p(2);

                [r,p] = corrcoef(RT(n==i,sn),mean(RT(n==i,subjects~=subjects(sn)),2));
                tmp.RT(sn,1) = r(2);
                tmp.RT_p(sn,1) = p(2);
            end
            corr_struct = addstruct(corr_struct,tmp,'row','force');
        end
        
        % plots:
        figure;
        subplot(1,3,1)
        lineplot(corr_struct.num_fingers,corr_struct.MD, 'markertype','o','markersize',5,'linecolor',[1 1 1]);
        title(sprintf('MD reliability , block %d to %d',blocks(1),blocks(2)))
        xlabel('num fingers')
        ylabel('corr leave one out subj')
        ylim([0,1])

        subplot(1,3,2)
        lineplot(corr_struct.num_fingers,corr_struct.MT,'markertype','o','markersize',5,'linecolor',[1 1 1]);
        title(sprintf('MT reliability , block %d to %d',blocks(1),blocks(2)))
        xlabel('num fingers')
        ylabel('corr leave one out subj')
        ylim([0,1])

        subplot(1,3,3)
        lineplot(corr_struct.num_fingers,corr_struct.RT,'markertype','o','markersize',5,'linecolor',[1 1 1]);
        title(sprintf('RT reliability , block %d to %d',blocks(1),blocks(2)))
        xlabel('num fingers')
        ylabel('corr leave one out subj')
        ylim([0,1])

        varargout{1} = C;
        varargout{2} = corr_struct;

    case 'behavior_trends'
        measure = 'mean_dev';
        vararginoptions(varargin,{'measure'})

        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_all.tsv'));

        % getting the values of measure:
        values = eval(['data.' measure]);

        sess = (data.BN<=12) + 2*(data.BN>=13 & data.BN<=24) + 3*(data.BN>=25 & data.BN<=36) + 4*(data.BN>=37 & data.BN<=48);

        % colors:
        colors = [[0.4660, 0.6740, 0.1880] ; [0.3010, 0.7450, 0.9330] ; [0.9290, 0.6940, 0.1250] ; [0.8500, 0.3250, 0.0980] ; [0.4940, 0.1840, 0.5560]];

        % avg trend acorss sessions:
        figure;
        lineplot(sess(data.trialCorr==1 & data.num_fingers==1),values(data.trialCorr==1 & data.num_fingers==1),'linecolor',colors(1,:));hold on;
        lineplot(sess(data.trialCorr==1 & data.num_fingers==2),values(data.trialCorr==1 & data.num_fingers==2),'linecolor',colors(2,:));
        lineplot(sess(data.trialCorr==1 & data.num_fingers==3),values(data.trialCorr==1 & data.num_fingers==3),'linecolor',colors(3,:));
        lineplot(sess(data.trialCorr==1 & data.num_fingers==4),values(data.trialCorr==1 & data.num_fingers==4),'linecolor',colors(4,:));
        lineplot(sess(data.trialCorr==1 & data.num_fingers==5),values(data.trialCorr==1 & data.num_fingers==5),'linecolor',colors(5,:));
        xlabel('session')
        ylabel(['avg ' measure(measure~='_') ' across subj'])
        
        % significance test of differences across num fingers:
        H_num_fingers = [];
        for i = 1:4
            tmp = [];
            for j = 1:4
                tmp.sess(j,1) = i;
                [~, tmp.p(j,1)] = ttest2(values(sess==i & data.trialCorr==1 & data.num_fingers==j),values(sess==i & data.trialCorr==1 & data.num_fingers==j+1));
            end
            H_num_fingers = addstruct(H_num_fingers,tmp,'row','force');
        end

        % significance test of differences across sessions:
        H_sess = [];
        for i = 1:5
            tmp = [];
            for j = 1:3
                tmp.num_fingers(j,1) = i;
                [~, tmp.p(j,1)] = ttest2(values(sess==j & data.trialCorr==1 & data.num_fingers==i),values(sess==j+1 & data.trialCorr==1 & data.num_fingers==i));
            end
            H_sess = addstruct(H_sess,tmp,'row','force');
        end

        % avg trends across blocks:
        figure;
        lineplot(data.BN(data.trialCorr==1 & data.num_fingers==1),values(data.trialCorr==1 & data.num_fingers==1),'linecolor',[0.4660, 0.6740, 0.1880]);hold on;
        lineplot(data.BN(data.trialCorr==1 & data.num_fingers==2),values(data.trialCorr==1 & data.num_fingers==2),'linecolor',[0.3010, 0.7450, 0.9330]);
        lineplot(data.BN(data.trialCorr==1 & data.num_fingers==3),values(data.trialCorr==1 & data.num_fingers==3),'linecolor',[0.9290, 0.6940, 0.1250]);
        lineplot(data.BN(data.trialCorr==1 & data.num_fingers==4),values(data.trialCorr==1 & data.num_fingers==4),'linecolor',[0.8500, 0.3250, 0.0980]);
        lineplot(data.BN(data.trialCorr==1 & data.num_fingers==5),values(data.trialCorr==1 & data.num_fingers==5),'linecolor',[0.4940, 0.1840, 0.5560]);
        xlabel('Block')
        ylabel(['avg ' measure(measure~='_') ' across subj'])
        

        varargout{1} = H_num_fingers;
        varargout{2} = H_sess;

    case 'selected_chords_reliability'
        % handling input args:
        blocks = [25, 48];
        % check reliability for these chords:
        chords = [11912,22921,21911,12922,12191,21292,19121,29212,12112,21221,21121,21121,12212,11212,22121,21211,21122]';
        plot_option = 1;
        vararginoptions(varargin,{'blocks','chords','plot_option'})
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_all.tsv'));
        
        subjects = unique(data.sn);

        % extracting avg mean dev of all subjects:
        C = [];
        % loop on subjs:
        for sn = 1:length(subjects)
            % container for subjects:
            tmp = [];
            % loop on chords:
            for i = 1:length(chords)
                tmp.sn(i,1) = subjects(sn);
                tmp.chordID(i,1) = chords(i);
                tmp.num_fingers(i,1) = get_num_active_fingers(chords(i));

                row = data.sn==subjects(sn) & data.BN>=blocks(1) & data.BN<=blocks(2) & data.chordID==chords(i) & data.trialCorr==1;
                tmp.mean_dev(i,1) = mean(data.mean_dev(row));
                tmp.RT(i,1) = median(data.RT(row));
                tmp.MT(i,1) = median(data.MT(row));
            end

            % concatenating subjects:
            C = addstruct(C,tmp,'row','force');
        end

        % getting the values in matrix format
        MD = zeros(length(chords),length(sn));
        RT = zeros(length(chords),length(sn));
        MT = zeros(length(chords),length(sn));
        for sn = 1:length(subjects)
            MD(:,sn) = C.mean_dev(C.sn==subjects(sn));
            RT(:,sn) = C.RT(C.sn==subjects(sn));
            MT(:,sn) = C.MT(C.sn==subjects(sn));
        end
        
        % calculating correlations leave_one_out:
        corr_struct = [];
        for sn = 1:length(subjects)
            [r,p] = corrcoef(MD(:,sn),mean(MD(:,subjects~=subjects(sn)),2));
            corr_struct.MD(sn,1) = r(2);
            corr_struct.MD_p(sn,1) = p(2);

            [r,p] = corrcoef(MT(:,sn),mean(MT(:,subjects~=subjects(sn)),2));
            corr_struct.MT(sn,1) = r(2);
            corr_struct.MT_p(sn,1) = p(2);

            [r,p] = corrcoef(RT(:,sn),mean(RT(:,subjects~=subjects(sn)),2));
            corr_struct.RT(sn,1) = r(2);
            corr_struct.RT_p(sn,1) = p(2);
        end
        
        % calculating correlations subejct to subject:
        [r_MD,p_MD] = corrcoef(MD);
        [r_MT,p_MT] = corrcoef(MT);
        [r_RT,p_RT] = corrcoef(RT);
        
        if plot_option
            % figures:
            figure;
            subplot(1,3,1)
            bar(1,mean(corr_struct.MD))
            hold on
            scatter(ones(length(subjects),1),corr_struct.MD,20,'k','filled');
            title(sprintf('MD reliability , block %d to %d',blocks(1),blocks(2)))
            ylabel('corr leave one out subj')
            ylim([-1,1])
    
            subplot(1,3,2)
            bar(1,mean(corr_struct.MT))
            hold on
            scatter(ones(length(subjects),1),corr_struct.MT,20,'k','filled');
            title(sprintf('MT reliability , block %d to %d',blocks(1),blocks(2)))
            ylabel('corr leave one out subj')
            ylim([-1,1])
    
            subplot(1,3,3)
            bar(1,mean(corr_struct.RT))
            hold on
            scatter(ones(length(subjects),1),corr_struct.RT,20,'k','filled');
            title(sprintf('RT reliability , block %d to %d',blocks(1),blocks(2)))
            ylabel('corr leave one out subj')
            ylim([-1,1])
            
            % subject-subject figures;
            figure; imagesc(r_MD); title('MD , subject-subject correlation')
            colorbar
            caxis([-1 1])
    
            figure; imagesc(r_MT); title('MT , subject-subject correlation')
            colorbar
            caxis([-1 1])
            
            figure; imagesc(r_RT); title('RT , subject-subject correlation')
            colorbar
            caxis([-1 1])
        end

        varargout{1} = C;
        varargout{2} = corr_struct;

    case 'selected_chord_trends'
        % handling input args:
        % check reliability for these chords:
        chords = [11912,22921,21911,12922,12191,21292,19121,29212,12112,21221,21121,21121,12212,11212,22121,21211,21122]';
        measure = 'mean_dev';
        vararginoptions(varargin,{'measure','chords'})

        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_all.tsv'));

        % getting the values of measure:
        values = eval(['data.' measure]);

        sess = (data.BN<=12) + 2*(data.BN>=13 & data.BN<=24) + 3*(data.BN>=25 & data.BN<=36) + 4*(data.BN>=37 & data.BN<=48);

        % colors:
        colors = [[0.4660, 0.6740, 0.1880] ; [0.3010, 0.7450, 0.9330] ; [0.9290, 0.6940, 0.1250] ; [0.8500, 0.3250, 0.0980] ; [0.4940, 0.1840, 0.5560]];
        
        % rows for selected chords:
        row = arrayfun(@(x) ~isempty(intersect(x,chords)), data.chordID);

        % avg trend acorss sessions:
        figure;
        lineplot(sess(data.trialCorr==1 & data.num_fingers==1 & row),values(data.trialCorr==1 & data.num_fingers==1 & row),'linecolor',colors(1,:));hold on;
        lineplot(sess(data.trialCorr==1 & data.num_fingers==2 & row),values(data.trialCorr==1 & data.num_fingers==2 & row),'linecolor',colors(2,:));
        lineplot(sess(data.trialCorr==1 & data.num_fingers==3 & row),values(data.trialCorr==1 & data.num_fingers==3 & row),'linecolor',colors(3,:));
        lineplot(sess(data.trialCorr==1 & data.num_fingers==4 & row),values(data.trialCorr==1 & data.num_fingers==4 & row),'linecolor',colors(4,:));
        lineplot(sess(data.trialCorr==1 & data.num_fingers==5 & row),values(data.trialCorr==1 & data.num_fingers==5 & row),'linecolor',colors(5,:));
        xlabel('session')
        ylabel(['avg ' measure(measure~='_') ' across subj'])
        xlim([0.7,4.3])
        
        % significance test of differences across num fingers:
        H_num_fingers = [];
        for i = 1:4
            tmp = [];
            for j = 1:4
                tmp.sess(j,1) = i;
                [~, tmp.p(j,1)] = ttest2(values(sess==i & data.trialCorr==1 & data.num_fingers==j & row),values(sess==i & data.trialCorr==1 & data.num_fingers==j+1 & row));
            end
            H_num_fingers = addstruct(H_num_fingers,tmp,'row','force');
        end

        % significance test of differences across sessions:
        H_sess = [];
        for i = 1:5
            tmp = [];
            for j = 1:3
                tmp.num_fingers(j,1) = i;
                [~, tmp.p(j,1)] = ttest2(values(sess==j & data.trialCorr==1 & data.num_fingers==i & row),values(sess==j+1 & data.trialCorr==1 & data.num_fingers==i & row));
            end
            H_sess = addstruct(H_sess,tmp,'row','force');
        end

        % avg trends across blocks:
        figure;
        lineplot(data.BN(data.trialCorr==1 & data.num_fingers==1 & row),values(data.trialCorr==1 & data.num_fingers==1 & row),'linecolor',[0.4660, 0.6740, 0.1880]);hold on;
        lineplot(data.BN(data.trialCorr==1 & data.num_fingers==2 & row),values(data.trialCorr==1 & data.num_fingers==2 & row),'linecolor',[0.3010, 0.7450, 0.9330]);
        lineplot(data.BN(data.trialCorr==1 & data.num_fingers==3 & row),values(data.trialCorr==1 & data.num_fingers==3 & row),'linecolor',[0.9290, 0.6940, 0.1250]);
        lineplot(data.BN(data.trialCorr==1 & data.num_fingers==4 & row),values(data.trialCorr==1 & data.num_fingers==4 & row),'linecolor',[0.8500, 0.3250, 0.0980]);
        lineplot(data.BN(data.trialCorr==1 & data.num_fingers==5 & row),values(data.trialCorr==1 & data.num_fingers==5 & row),'linecolor',[0.4940, 0.1840, 0.5560]);
        xlabel('Block')
        ylabel(['avg ' measure(measure~='_') ' across subj'])
        
        varargout{1} = H_num_fingers;
        varargout{2} = H_sess;

    case 'model_testing'
        % handling input args:
        blocks = [25,48];
        model_names = {'extension','num_fingers','single_finger','single_finger+neighbour_fingers','single_finger+two_finger_interactions'};
        chords = generateAllChords;
        measure = 'mean_dev';
        remove_mean = 0;
        vararginoptions(varargin,{'model_names','blocks','chords','measure','remove_mean'})
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_all.tsv'));
        subjects = unique(data.sn);

        % getting the values of measure:
        values = eval(['data.' measure]);

        % noise ceiling calculation:
        [~,corr_struct] = efc1_analyze('selected_chord_reliability','blocks',blocks,'chords',chords,'plot_option',0);
        noise_ceil = mean(corr_struct.MD);

        % loop on subjects and regression with leave-one-out:
        results = [];
        for i = 1:length(subjects)
            fprintf('running for subj %d/%d out...\n',i,length(subjects))
            % container for regression results:
            tmp = [];

            % loop on models:
            for j = 1:length(model_names)
                % making design matrix:
                X = make_design_matrix(data.chordID(data.sn~=subjects(i) & data.trialCorr==1 & data.BN>=blocks(1) & data.BN<=blocks(2)),model_names{j});
                
                % train linear model on subject-out data:
                y = values(data.sn~=subjects(i) & data.trialCorr==1 & data.BN>=blocks(1) & data.BN<=blocks(2));
                
                if remove_mean
                    y = y - mean(y);
                end
                [B,STATS]=linregress(y,X,'intercept',0,'contrast',eye(size(X,2)));
                
                
                % test model on subject data:
                X_test = make_design_matrix(data.chordID(data.sn==subjects(i) & data.trialCorr==1 & data.BN>=blocks(1) & data.BN<=blocks(2)),model_names{j});
                % X_test = [ones(size(X_test,1),1) X_test];
                y_pred = X_test*B;
                y_test = values(data.sn==subjects(i) & data.trialCorr==1 & data.BN>=blocks(1) & data.BN<=blocks(2));

                if remove_mean
                    y_test = y_test-mean(y_test);
                end

                [r,p] = corrcoef(y_pred,y_test);

                % storing the regression results:
                tmp.model_name{j,1} = model_names{j};
                tmp.model_num(j,1) = j;
                tmp.sn_out(j,1) = subjects(i);
                tmp.B{j,1} = B;
                tmp.stats{j,1} = STATS;
                tmp.r_test(j,1) = r(2);
                tmp.p_value(j,1) = p(2);
            end
            
            results = addstruct(results,tmp,'row','force');
        end

        % hypohtesis testing between models:
        H_across_models = [];
        for i = 1:length(model_names)-1
            tmp = [];
            for j = i+1:length(model_names)
                sample01 = results.r_test(results.model_num==i);
                sample02 = results.r_test(results.model_num==j);
                [t,p] = ttest(sample01,sample02,2,'paired');

                tmp.model01{j,1} = model_names{i};
                tmp.model02{j,1} = model_names{j};
                tmp.t(j,1) = t;
                tmp.p_value(j,1) = p;
            end
            H_across_models = addstruct(H_across_models,tmp,'row','force');
        end
        
        % plotting:
        figure;
        lineplot(results.model_num, results.r_test ,'markersize', 5);
        hold on;
        scatter(results.model_num, results.r_test, 10, 'r', 'filled');
        drawline(noise_ceil,'dir','horz')
        xticklabels(cellfun(@(x) replace(x,'_',' '),model_names,'uniformoutput',false))
        ylabel('rho')
        ylim([0,1])

        varargout{1} = results;
        varargout{2} = H_across_models;
        
    case 'model_testing_avg_values'
        % handling input args:
        blocks = [25,48];
        model_names = {'extension','num_fingers','single_finger','single_finger+neighbour_fingers','single_finger+two_finger_interactions'};
        chords = generateAllChords;
        measure = 'mean_dev';
        remove_mean = 0;
        vararginoptions(varargin,{'model_names','blocks','chords','measure','remove_mean'})
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_all.tsv'));
        subjects = unique(data.sn);

        % getting the values of measure:
        values_tmp = eval(['data.' measure]);

        n = get_num_active_fingers(chords);

        % avg trials of subjects:
        for i = 1:length(subjects)
            for j = 1:length(chords)
                values(j,i) = mean(values_tmp(data.chordID==chords(j) & data.sn==subjects(i) & data.trialCorr==1 & data.BN>=blocks(1) & data.BN<=blocks(2)));
            end
        end

        % noise ceiling calculation:
        [~,corr_struct] = efc1_analyze('selected_chord_reliability','blocks',blocks,'chords',chords,'plot_option',0);
        noise_ceil = mean(corr_struct.MD);

        % loop on subjects and regression with leave-one-out:
        results = [];
        for i = 1:length(subjects)
            % container for regression results:
            tmp = [];

            % loop on models:
            for j = 1:length(model_names)
                fprintf('running for subj %d/%d out , model: %s\n',i,length(subjects),model_names{j})
                % making design matrix:
                X = make_design_matrix(chords,model_names{j});
                X = repmat(X,length(subjects)-1,1);
                
                % train linear model on subject-out data:
                y = values(:,setdiff(1:length(subjects),i));
                y = y(:);
                
                if remove_mean
                    % removing sample mean:
                    y = y - mean(y);
                end

                % regression:
                [B,STATS]=linregress(y,X,'intercept',0,'contrast',eye(size(X,2)));
                
                % test model on subject data:
                X_test = make_design_matrix(chords,model_names{j});
                y_pred = X_test*B;
                y_test = values(:,i);

                if remove_mean
                    y_test = y_test-mean(y_test);
                end

                % storing the regression results:
                tmp.model_name{j,1} = model_names{j};
                tmp.model_num(j,1) = j;
                tmp.sn_out(j,1) = subjects(i);
                tmp.B{j,1} = B;
                tmp.stats{j,1} = STATS;

                [r,p] = corrcoef(y_pred,y_test);
                tmp.r_test(j,1) = r(2);
                tmp.p_value(j,1) = p(2);

                for k = 1:5
                    [r,p] = corrcoef(y_pred(n==k),y_test(n==k));
                    eval(['tmp.r_test_n' num2str(k) '(j,1) = r(2);']);
                    eval(['tmp.p_value_n' num2str(k) '(j,1) = p(2);']);
                end
            end
            
            results = addstruct(results,tmp,'row','force');
        end

        % hypothesis testing between models:
        H_across_models = [];
        for i = 1:length(model_names)-1
            tmp = [];
            for j = i+1:length(model_names)
                sample01 = results.r_test(results.model_num==i);
                sample02 = results.r_test(results.model_num==j);
                [t,p] = ttest(sample01,sample02,2,'paired');

                tmp.model01{j,1} = model_names{i};
                tmp.model02{j,1} = model_names{j};
                tmp.t(j,1) = t;
                tmp.p_value(j,1) = p;
            end
            H_across_models = addstruct(H_across_models,tmp,'row','force');
        end

        % hypothesis testing between models and ceiling:
        H_model_ceil = [];
        for i = 1:length(model_names)
            sample01 = results.r_test(results.model_num==i);
            sample02 = corr_struct.MD;
            [t,p] = ttest(sample01,sample02,2,'paired');

            H_model_ceil.model01{i,1} = model_names{i};
            H_model_ceil.t(i,1) = t;
            H_model_ceil.p_value(i,1) = p;
        end
        
        % plotting:
        figure;
        lineplot(results.model_num, results.r_test ,'markersize', 5);
        hold on;
        scatter(results.model_num, results.r_test, 10, 'r', 'filled');
        drawline(noise_ceil,'dir','horz')
        xticklabels(cellfun(@(x) replace(x,'_',' '),model_names,'uniformoutput',false))
        ylabel('rho')
        ylim([0,1])

        for i = 1:5
            % noise ceiling calculation:
            [~,corr_struct] = efc1_analyze('selected_chord_reliability','blocks',blocks,'chords',chords(n==i),'plot_option',0);
            noise_ceil = mean(corr_struct.MD);

            figure;
            lineplot(results.model_num, eval(['results.r_test_n' num2str(i)]), 'markersize', 5);
            hold on;
            scatter(results.model_num, eval(['results.r_test_n' num2str(i)]), 10, 'r', 'filled');
            drawline(noise_ceil,'dir','horz')
            xticklabels(cellfun(@(x) replace(x,'_',' '),model_names,'uniformoutput',false))
            ylabel('rho')
            title(sprintf('num fingers = %d',i))
            ylim([0,1])
        end


        varargout{1} = results;
        varargout{2} = H_across_models;
        varargout{3} = H_model_ceil;


    case 'RT_vs_run'    % varargin options: 'plotfcn',{'mean' or 'median'} default is 'mean'
        % lineplot subplot for each subj
        plotfcn = 'mean';
        if (~isempty(find(strcmp(varargin,'plotfcn'),1)))
            plotfcn = varargin{find(strcmp(varargin,'plotfcn'),1)+1};   % setting 'plotfcn' option for lineplot()
        end
        efc1_RTvsRun(data,plotfcn);
    
    % =====================================================================

    
    case 'corr_medRT_avg_model'
        corrMethod = 'pearson';     % default correlation method
        excludeVec = [];            % default exclude chord vector. Not excluding any chords by default.
        includeSubj = 0;            % default is not to include each subj in the avg calculation
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};     % setting 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'excludeChord'),1)))
            excludeVec = varargin{find(strcmp(varargin,'excludeChord'),1)+1};   % setting 'excludeChord' option for calcMedRT
        end
        if (~isempty(find(strcmp(varargin,'includeSubj'),1)))    
            includeSubj = varargin{find(strcmp(varargin,'includeSubj'),1)+1};   % setting the 'includeSubj' option
        end

        % correlation of median RT across subjects
        rhoAvgModel = efc1_corr_avg_model(data,corrMethod,excludeVec,includeSubj);
        varargout{1} = rhoAvgModel;

    % =====================================================================
    case 'thetaExp_vs_thetaStd'
        durAfterActive = 200;   % default duration after first finger passed the baseline threshld in ms
        plotfcn = 1;            % default is to plot
        firstTrial = 2;         % default is 2 , The first trial of the chord is usually very different from others which impacts the variance a lot. This is an option to ignore the first trial if wanted.
        onlyActiveFing = 0;     % default is 0 , option to caclculate the angle only for active fingers
        selectRun = -1;         % default run to do the analysis is the last run. you can select run 1,2,3 or -1(last)
        if (~isempty(find(strcmp(varargin,'durAfterActive'),1)))
            durAfterActive = varargin{find(strcmp(varargin,'durAfterActive'),1)+1};     % setting 'durAfterActive' option
        end
        if (~isempty(find(strcmp(varargin,'plotfcn'),1)))
            plotfcn = varargin{find(strcmp(varargin,'plotfcn'),1)+1};                   % setting 'plotfcn' option
        end
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};             % setting 'firstTrial' option
        end
        if (~isempty(find(strcmp(varargin,'onlyActiveFing'),1)))    
            onlyActiveFing = varargin{find(strcmp(varargin,'onlyActiveFing'),1)+1};     % setting 'onlyActiveFing' option
        end
        if (~isempty(find(strcmp(varargin,'selectRun'),1)))    
            selectRun = varargin{find(strcmp(varargin,'selectRun'),1)+1};          % setting 'selectRun' option
        end
        holdTime = 600;
        
        forceData = cell(size(data));   % extracting the force signals for each subj
        for i = 1:size(data,1)
            forceData{i,1} = extractDiffForce(data{i,1});
            forceData{i,2} = data{i,2};
        end
        
        thetaCell = cell(size(data));
        for subj = 1:size(data,1)
            thetaCell{subj,2} = data{subj,2};
            chordVec = generateAllChords();  % all chords
            subjData = data{subj,1};
%             uniqueBN = [0 ; unique(subjData.BN)];
%             idxBN = find(mod(uniqueBN,12)==0)-1;
%             idxBN(1) = 1;
            subjForceData = forceData{subj,1};
            thetaCellSubj = cell(length(chordVec),2);
            vecBN = unique(subjData.BN);
            for i = 1:length(chordVec)
                thetaCellSubj{i,1} = chordVec(i);
%                 if (selectRun == -1)
%                     trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > uniqueBN(idxBN(end-1)+1) & subjData.BN <= uniqueBN(idxBN(end)+1));
%                 elseif (selectRun > length(idxBN)-1)
%                     error("Error with <selectRun> option , " + data{subj,2} + " does not have run number " + num2str(selectRun))
%                 elseif (selectRun == 1)
%                     trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > uniqueBN(idxBN(selectRun)) & subjData.BN <= uniqueBN(idxBN(selectRun+1)+1));
%                 else
%                     trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > uniqueBN(idxBN(selectRun)+1) & subjData.BN <= uniqueBN(idxBN(selectRun+1)+1));
%                 end

                if (selectRun == -1)        % selecting the last 12 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > vecBN(end-12));
                elseif (selectRun == -2)    % selectign the last 24 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > vecBN(end-24));
                elseif (selectRun == 1)     % selecting the first 12 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN < 13);
                elseif (selectRun == 2)
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > 12 & subjData.BN < 25);
                elseif (selectRun == 3)
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > 24 & subjData.BN < 37);
                    iTmp = find(subjData.BN > 24 & subjData.BN < 37);
                    if (isempty(iTmp))
                        error("Error with <selectRun> option , " + data{subj,2} + " does not have block number " + num2str(selectRun))
                    end
                else
                    error("selectRun " + num2str(selectRun) + "does not exist. Possible choices are 1,2,3 and -1.")
                end

                if (~isempty(trialIdx))
                    chordTmp = num2str(chordVec(i));
                    for trial_i = 1:length(trialIdx)
                        forceTrial = subjForceData{trialIdx(trial_i)};
                        baselineIdx = forceTrial(:,1) == 2;
                        execIdx = find(forceTrial(:,1) == 3);
                        execIdx = execIdx(end-holdTime/2:end);
                        
                        avgBaselineForce = mean(forceTrial(baselineIdx,3:7),1);
                        avgExecForce = mean(forceTrial(execIdx,3:7),1);
                        idealVec = avgExecForce - avgBaselineForce;

                        forceTmp = [];
                        tVec = subjForceData{trialIdx(trial_i)}(:,2); % time vector in trial
                        tGoCue = subjData.planTime(trialIdx(trial_i));
                        fGainVec = [subjData.fGain1(trialIdx(trial_i)) subjData.fGain2(trialIdx(trial_i)) subjData.fGain3(trialIdx(trial_i)) subjData.fGain4(trialIdx(trial_i)) subjData.fGain5(trialIdx(trial_i))];
                        for j = 1:5     % thresholded force of the fingers after "Go Cue"
                            if (chordTmp(j) == '1') % extension
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            elseif (chordTmp(j) == '2') % flexion
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            elseif (chordTmp(j) == '9') % finger should be relaxed
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)) ...
                                    | subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            end
                        end
                        if (isempty(find(forceTmp,1)))  % if no fingers moved out of threshold, go to next trial
                            disp("empty")
                            continue
                        end
            
                        tmpIdx = [];
                        for k = 1:size(forceTmp,2)
                            tmpIdx(k) = find(forceTmp(:,k),1);
                        end
                        [sortIdx,~] = sort(tmpIdx); % sortIdx(1) is the first index after "Go Cue" that the first finger crossed the baseline thresh
                        idxStart = find(tVec==tGoCue)+sortIdx(1)-1; % index that the first finger passes the baseline threhold after "Go Cue"
                        
                        forceSelceted = [];
                        for j = 1:5     % getting the force from idxStart to idxStart+durAfterActive
                            forceSelceted = [forceSelceted subjForceData{trialIdx(trial_i)}(idxStart:idxStart+round(durAfterActive/2),2+j)];
                        end
                        forceVec = mean(forceSelceted,1);  % average of finger forces from idxStart to idxStart+durAfterActive
%                         idealVec = double(chordTmp~='9');
%                         for j = 1:5
%                             if (chordTmp(j) == '2')
%                                 idealVec(j) = -1;
%                             end
%                         end
                        thetaCellSubj{i,2} = [thetaCellSubj{i,2} vectorAngle(forceVec,idealVec)];
                    end
                else
                    thetaCellSubj{i,2} = [];
                end 
            end
            thetaCell{subj,1} = thetaCellSubj;
        end
        varargout{1} = thetaCell;

        if (plotfcn)
            % visualizing thetaCell
            chordVecSep = sepChordVec(chordVec);
            colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
                [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
            for subj = 1:size(thetaCell,1)
                thetaCellSubj = thetaCell{subj,1};
                expVec = zeros(size(thetaCellSubj,1),1);
                stdVec = zeros(size(thetaCellSubj,1),1);
                for i = 1:size(thetaCellSubj,1)
                    expVec(i) = mean(thetaCellSubj{i,2}(firstTrial:end));
                    stdVec(i) = std(thetaCellSubj{i,2}(firstTrial:end));
                end
                
                figure;
                for numActiveFing = 1:size(chordVecSep,1)
                    scatter(stdVec(chordVecSep{numActiveFing,2}),expVec(chordVecSep{numActiveFing,2}),...
                        30,"MarkerFaceColor",colors(numActiveFing,:))
                    hold on
                end
                xlabel("std theta (degree)")
                ylabel("mean theta (degree)")
                title(sprintf("%s",thetaCell{subj,2}))
                legend({"1","2","3","4","5"})
                ylim([0,90])
                xlim([0,60])
            end
        end
    
    % =====================================================================
    case 'corr_mean_theta_across_subj'
        onlyActiveFing = 1;     % default value
        firstTrial = 2;         % default value
        corrMethod = 'pearson'; % default corr method
        plotfcn = 0;            % default is not to plot
        clim = [0,1];           % default for colorbar limit
        if (isempty(find(strcmp(varargin,'thetaCell'),1)))   
            error("thetaCell not found. You should input thetaCell for this analysis")
        end
        if (~isempty(find(strcmp(varargin,'thetaCell'),1)))    
            thetaCell = varargin{find(strcmp(varargin,'thetaCell'),1)+1};           % inputting the 'thetaCell'
        end
        if (~isempty(find(strcmp(varargin,'onlyActiveFing'),1)))    
            onlyActiveFing = varargin{find(strcmp(varargin,'onlyActiveFing'),1)+1}; % setting the 'onlyActiveFing' option - should be the same as the option used for 'thetaExp_vs_thetaStd'
        end
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))    
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};         % setting the 'firstTrial' option - should be the same as the option used for 'thetaExp_vs_thetaStd'
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))    
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};         % setting the 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'plotfcn'),1)))    
            plotfcn = varargin{find(strcmp(varargin,'plotfcn'),1)+1};               % setting the 'plotfcn' option
        end
        if (~isempty(find(strcmp(varargin,'clim'),1)))    
            clim = varargin{find(strcmp(varargin,'clim'),1)+1};                     % setting the 'clim' option
        end
        
        rho = cell(1,2);
        thetaMean = zeros(242,size(thetaCell,1));
        thetaStd = zeros(242,size(thetaCell,1));
        for subj = 1:size(thetaCell,1)
            for j = 1:size(thetaMean,1)
                thetaMean(j,subj) = mean(thetaCell{subj,1}{j,2}(firstTrial:end));
                thetaStd(j,subj) = std(thetaCell{subj,1}{j,2}(firstTrial:end));
            end
            rho{1,2} = [rho{1,2} convertCharsToStrings(data{subj,2})];
        end

        if (onlyActiveFing)
            thetaMean(1:10,:) = [];
        end
        [i,~] = find(isnan(thetaMean));
        thetaMean(i,:) = [];
        
        rho{1,1} = corr(thetaMean,'type',corrMethod);
        varargout{1} = rho;

        if (plotfcn)
            figure;
            if (~isempty(clim))
                imagesc(rho{1},clim)
            else
                imagesc(rho{1})
            end
            colorbar
            title(sprintf("corr meanTheta across subj - corrMethod: %s",corrMethod))
            xlabel("subj")
            ylabel("subj")
        end
    
    % =====================================================================
    case 'corr_mean_theta_avg_model'
        onlyActiveFing = 1;     % default value
        firstTrial = 2;         % default value
        corrMethod = 'pearson'; % default corr method
        includeSubj = 0;        % default is not to include subj in avg
        if (isempty(find(strcmp(varargin,'thetaCell'),1)))   
            error("thetaCell not found. You should input thetaCell for this analysis")
        end
        if (~isempty(find(strcmp(varargin,'thetaCell'),1)))    
            thetaCell = varargin{find(strcmp(varargin,'thetaCell'),1)+1};           % inputting the 'thetaCell'
        end
        if (~isempty(find(strcmp(varargin,'onlyActiveFing'),1)))    
            onlyActiveFing = varargin{find(strcmp(varargin,'onlyActiveFing'),1)+1}; % setting the 'onlyActiveFing' option - should be the same as the option used for 'thetaExp_vs_thetaStd'
        end
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))    
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};         % setting the 'firstTrial' option - should be the same as the option used for 'thetaExp_vs_thetaStd'
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))    
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};         % setting the 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'includeSubj'),1)))    
            includeSubj = varargin{find(strcmp(varargin,'includeSubj'),1)+1};       % setting the 'includeSubj' option
        end

        thetaMean = zeros(242,size(thetaCell,1));
        thetaStd = zeros(242,size(thetaCell,1));
        for subj = 1:size(thetaCell,1)
            for j = 1:size(thetaMean,1)
                thetaMean(j,subj) = mean(thetaCell{subj,1}{j,2}(firstTrial:end));
                thetaStd(j,subj) = std(thetaCell{subj,1}{j,2}(firstTrial:end));
            end
            % rhoAvg{1,2} = [rhoAvg{1,2} convertCharsToStrings(data{subj,2})];
        end
        
        if (onlyActiveFing)
            thetaMean(1:10,:) = [];
        end
        [i,~] = find(isnan(thetaMean));
        thetaMean(i,:) = [];
        
        rhoAvg = cell(1,2);
        if (~includeSubj)    % if we do not include each subject in the avg model -> lower noise ceiling
            for i = 1:size(thetaMean,2)
                idxSelect = setdiff(1:size(thetaMean,2),i);                   % excluding subj i from avg calculation
                tmpThetaMeanMat = thetaMean(:,idxSelect);
                avgModel = mean(tmpThetaMeanMat,2);                           % calculating avg of thetaMean for subjects other than subj i
                corrTmp = corr(avgModel,thetaMean(:,i),'type',corrMethod);    % correlation of avg model with excluded subj
                rhoAvg{1,1} = [rhoAvg{1,1} corrTmp];
                rhoAvg{1,2} = [rhoAvg{1,2} convertCharsToStrings(data{i,2})];
            end
        else                % if we include all subjects in the avg model -> higher noise ceiling
            avgModel = mean(thetaMean,2);    
            for i = 1:size(thetaMean,2)
                corrTmp = corr(avgModel,thetaMean(:,i),'type',corrMethod);    % correlation of avg model with each subj
                rhoAvg{1,1} = [rhoAvg{1,1} corrTmp];
                rhoAvg{1,2} = [rhoAvg{1,2} convertCharsToStrings(data{i,2})];
            end
        end

        varargout{1} = rhoAvg;

    % =====================================================================
    case 'plot_scatter_within_subj'
        dataTransform = 'no_transform'; % default data transform type
        if (~isempty(find(strcmp(varargin,'transform_type'),1)))
            dataTransform = varargin{find(strcmp(varargin,'transform_type'),1)+1};   % setting 'transform_type' option
        end
        chordVec = generateAllChords();
        chordVecSep = sepChordVec(chordVec);
        colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
            [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
        
        j = 1;
        last2Runs_cell = {};
        for i = 1:size(data,1)
            if (length(data{i,1}.BN) >= 2420)
                medRT = cell2mat(calcMedRT(data{i,1},[]));
                last2Runs = medRT(:,end-1:end);
                if (strcmp(dataTransform,'no_transform'))
                    last2Runs_cell{j,1} = last2Runs;
                elseif (strcmp(dataTransform,'ranked'))
                    [~,idx1] = sort(last2Runs(:,1));
                    [~,idx2] = sort(last2Runs(:,2));
                    last2Runs_ranked = [idx1,idx2];
                    last2Runs_cell{j,1} = last2Runs_ranked;
                end
                last2Runs_cell{j,2} = data{i,2};
                j = j+1;
            end
        end
        
        figure;
        for i = 1:size(last2Runs_cell,1)
            last2Runs = last2Runs_cell{i,1};
            subplot(3,2,i)
            for numActiveFing = 1:size(chordVecSep,1)
                scatter(last2Runs(chordVecSep{numActiveFing,2},1),last2Runs(chordVecSep{numActiveFing,2},2),30,"MarkerFaceColor",colors(numActiveFing,:))
                hold on
            end
            legend(["activeFinger 1","activeFinger 2","activeFinger 3","activeFinger 4","activeFinger 5"])
            title(sprintf("last two runs MedRTs, %s",last2Runs_cell{i,2}))
            ylabel("Last Run, Med RT(ms)")
            xlabel("One Run Before Last, Med RT(ms)")
            axis equal
            maxLim = max(max(last2Runs_cell{i,1}(:,1)),max(last2Runs_cell{i,1}(:,2)));
            xlim([0,maxLim])
            ylim([0,maxLim])
        end
    
    % =====================================================================
    case 'plot_scatter_across_subj'
        dataTransform = 'no_transform'; % default data transform type
        if (~isempty(find(strcmp(varargin,'transform_type'),1)))
            dataTransform = varargin{find(strcmp(varargin,'transform_type'),1)+1};   % setting 'transform_type' option
        end
        chordVec = generateAllChords();
        chordVecSep = sepChordVec(chordVec);
        colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
            [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
        
        % Med RTs:
        lastRuns = {};
        k = 1;  % index for last runs.
        for i = 1:size(data,1)
            if (length(data{i,1}.BN) >= 2420)
                medRT = cell2mat(calcMedRT(data{i,1},[]));
                if (strcmp(dataTransform,'no_transform'))   % not transform option
                    lastRuns{k,1} = medRT(:,end);
                elseif (strcmp(dataTransform,'ranked'))     % rank transform option
                    [~,idx] = sort(medRT(:,end));
                    lastRuns{k,1} = idx;
                end
                lastRuns{k,2} = data{i,2};
                k = k+1;
            end
        end
        
        % plotting each subject vs all others
        subplotCols = 2;
        subplotRows = round((size(lastRuns,1)-1)/subplotCols);
        for i = 1:size(lastRuns,1)
            figure;
            yDataIdx = setdiff(1:size(lastRuns,1),i);   % subjects other than subject i
            subplotIdx = 1:subplotRows*subplotCols;
            k = 1;  % index for subplotIdx
            for j = yDataIdx
                subplot(subplotRows,subplotCols,subplotIdx(k))
                for numActiveFing = 1:size(chordVecSep,1)
                    scatter(lastRuns{i,1}(chordVecSep{numActiveFing,2}),lastRuns{j,1}(chordVecSep{numActiveFing,2}),...
                        30,"MarkerFaceColor",colors(numActiveFing,:))
                    hold on
                end
                title(sprintf("subjects last run scatter"))
                xlabel(sprintf("%s medRT(ms)",lastRuns{i,2}))
                ylabel(sprintf("%s medRT(ms)",lastRuns{j,2}))
                legend(["activeFinger 1","activeFinger 2","activeFinger 3","activeFinger 4","activeFinger 5"])
                axis equal
                maxLim = max(max(lastRuns{i,1}),max(lastRuns{j,1}));
                xlim([0,maxLim])
                ylim([0,maxLim])
                k = k+1;
            end
        end
    
    % =====================================================================
    case 'reg_OLS_medRT'
        regSubjNum = 0;         % default is not to do single subject regression model
        corrMethod = 'pearson'; % default corrMethod is pearson
        excludeChord = [];      % default is not to exclude any subjects
        if (~isempty(find(strcmp(varargin,'regSubjNum'),1)))
            regSubjNum = varargin{find(strcmp(varargin,'regSubjNum'),1)+1};     % setting 'regSubjNum' option
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};     % setting 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'excludeChord'),1)))
            excludeChord = varargin{find(strcmp(varargin,'excludeChord'),1)+1}; % setting 'excludeChord' option
        end

        chordVec = generateAllChords();
        chordVecSep = sepChordVec(chordVec);
        if (~isempty(excludeChord))
            idxRemove = [];
            for i = 1:length(excludeChord)
                idxRemove = [idxRemove chordVecSep{excludeChord(i),2}];
            end
        else
            idxRemove = [];
        end

        % FEATURES:
        % num active fingers - continuous:
        f1 = zeros(size(chordVec));
        for i = 1:size(chordVecSep,1)
            f1(chordVecSep{i,2}) = i;
        end
        f1(idxRemove,:) = [];
        
        % each finger flexed or not:
        f2 = zeros(size(chordVec,1),5);
        for i = 1:size(chordVec,1)
            chord = num2str(chordVec(i));
            f2(i,:) = (chord == '2');
        end
        f2(idxRemove,:) = [];
        
        
        % each finger extended or not:
        f3 = zeros(size(chordVec,1),5);
        for i = 1:size(chordVec,1)
            chord = num2str(chordVec(i));
            f3(i,:) = (chord == '1');
        end
        f3(idxRemove,:) = [];
        
        % second level interactions of finger combinations:
        f4Base = [f2,f3];
        f4 = [];
        for i = 1:size(f4Base,2)-1
            for j = i+1:size(f4Base,2)
                f4 = [f4, f4Base(:,i) .* f4Base(:,j)];
            end
        end

        % linear regression for one subj:
        features = [f1,f2,f3,f4];
        if (regSubjNum ~= 0)
            singleSubjModel = cell(1,2);
            medRT = cell2mat(calcMedRT(data{regSubjNum,1},excludeChord));
            estimated = medRT(:,end);
            fprintf("============= medRT regression for %s =============\n",data{regSubjNum,2})
            mdl = fitlm(features,estimated)
            fprintf("==========================================================================================\n\n")
            singleSubjModel{1} = mdl;
            singleSubjModel{2} = sprintf("regression for %s",data{regSubjNum,2});
            varargout{3} = singleSubjModel;
        else
            varargout{3} = "no single subj reg";
        end
        
        % cross validated linear regression:
        fullFeatures = [repmat(f1,size(data,1)-1,1),repmat(f2,size(data,1)-1,1),repmat(f3,size(data,1)-1,1),repmat(f4,size(data,1)-1,1)];
        rho_OLS_medRT = cell(1,2);
        crossValModel = cell(size(data,1),2);
        for i = 1:size(data,1)
            idx = setdiff(1:size(data,1),i);    % excluding one subj from the model fitting process
            estimated = [];                     % the estimated values for the regression
            for j = idx
                tmpMedRT = cell2mat(calcMedRT(data{j,1},excludeChord));
                estimated = [estimated ; tmpMedRT(:,end)];
            end
            fprintf('============= medRT regression with excluded subject: %s =============\n',data{i,2})
            mdl = fitlm(fullFeatures,estimated) % linear regression with OLS
            fprintf('==========================================================================================\n\n')
            crossValModel{i,1} = mdl;
            crossValModel{i,2} = sprintf("excluded subj: %s",data{i,2});
            
            % testing the model:
            pred = predict(mdl,features);   % model fitted values
            medRTOut = cell2mat(calcMedRT(data{i,1},excludeChord));   % medRT of all runs of the excluded subject
            medRTOut = medRTOut(:,end); % medRT of the lastRun of excluded subject
            
            corrTmp = corr(medRTOut,pred,'type',corrMethod);    % correlation of model fit with the excluded subj medRT
            rho_OLS_medRT{2}(1,i) = convertCharsToStrings(data{i,2});
            rho_OLS_medRT{1}(1,i) = corrTmp;
        end
        varargout{2} = crossValModel;
        varargout{1} = rho_OLS_medRT;

    % =====================================================================
    case 'reg_OLS_meanTheta'
        regSubjNum = 0;         % default is not to do single subject regression model
        corrMethod = 'pearson'; % default corrMethod is pearson
        onlyActiveFing = 1;     % default onlyActiveFinger is turned on
        firstTrial = 2;         % default is firstTrial is 2
        thetaCell = varargin{1};
        if (~isempty(find(strcmp(varargin,'regSubjNum'),1)))
            regSubjNum = varargin{find(strcmp(varargin,'regSubjNum'),1)+1};             % setting 'regSubjNum' option
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};             % setting 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'onlyActiveFing'),1)))
            onlyActiveFing = varargin{find(strcmp(varargin,'onlyActiveFing'),1)+1};     % setting 'onlyActiveFing' option
        end
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};             % setting 'onlyActiveFing' option
        end

        chordVec = generateAllChords();
        chordVecSep = sepChordVec(chordVec);
        
        % FEATURES
        % num active fingers - continuous:
        f1 = zeros(size(chordVec));
        for i = 1:size(chordVecSep,1)
            f1(chordVecSep{i,2}) = i;
        end
        
        % each finger flexed or not:
        f2 = zeros(size(chordVec,1),5);
        for i = 1:size(chordVec,1)
            chord = num2str(chordVec(i));
            f2(i,:) = (chord == '2');
        end
        
        % each finger extended or not:
        f3 = zeros(size(chordVec,1),5);
        for i = 1:size(chordVec,1)
            chord = num2str(chordVec(i));
            f3(i,:) = (chord == '1');
        end
        
        % second level interactions of finger combinations:
        f4Base = [f2,f3];
        f4 = [];
        for i = 1:size(f4Base,2)-1
            for j = i+1:size(f4Base,2)
                f4 = [f4, f4Base(:,i) .* f4Base(:,j)];
            end
        end

        activeVec = zeros(length(chordVec),1);
        for i = 1:size(chordVecSep,1)
            activeVec(chordVecSep{i,2}) = i;
        end
        
        thetaMean = zeros(242,size(thetaCell,1));
        thetaStd = zeros(242,size(thetaCell,1));
        for subj = 1:size(thetaCell,1)
            for j = 1:size(thetaMean,1)
                thetaMean(j,subj) = mean(thetaCell{subj,1}{j,2}(firstTrial:end));
                thetaStd(j,subj) = std(thetaCell{subj,1}{j,2}(firstTrial:end));
            end
        end
        
        % linear regression for one subj:
        features = [f1,f2,f3,f4];
        if (onlyActiveFing)
            thetaMean(1:10,:) = [];
            features(1:10,:) = [];
        end
        [i,~] = find(isnan(thetaMean));
        thetaMean(i,:) = [];
        features(i,:) = [];
        
        if (regSubjNum ~= 0)
            estimated = thetaMean(:,regSubjNum);  
            singleSubjModel = cell(1,2);
            fprintf("============= meanTheta regression for %s =============\n",data{regSubjNum,2})
            mdl = fitlm(features,estimated)
            fprintf("==========================================================================================\n\n")
            singleSubjModel{1} = mdl;
            singleSubjModel{2} = sprintf("regression for %s",data{regSubjNum,2});
            varargout{3} = singleSubjModel;
        else
            varargout{3} = "no single subj reg";
        end
        

        % cross validated linear regression:
        fullFeatures = repmat(features,size(data,1)-1,1);
        rho_OLS_meanTheta = cell(1,2);
        crossValModel = cell(size(data,1),2);
        for i = 1:size(data,1)
            idx = setdiff(1:size(data,1),i);
            estimated = []; 
            for j = idx
                estimated = [estimated ; thetaMean(:,j)];
            end
            fprintf('============= meanTheta regression with excluded subject: %s =============\n',data{i,2})
            mdl = fitlm(fullFeatures,estimated)
            fprintf('==========================================================================================\n\n')
            crossValModel{i,1} = mdl;
            crossValModel{i,2} = sprintf("excluded subj: %s",data{i,2});

            % testing model:
            pred = predict(mdl,features);
            meanThetaOut = thetaMean(:,i);
            
            corrTmp = corr(meanThetaOut,pred,'type',corrMethod);
            rho_OLS_meanTheta{2}(1,i) = convertCharsToStrings(data{i,2});
            rho_OLS_meanTheta{1}(1,i) = corrTmp;
        end
        varargout{2} = crossValModel;
        varargout{1} = rho_OLS_meanTheta;

    % =====================================================================
    case 'meanTheta_scatter_across_subj'
        onlyActiveFing = 1;     % default onlyActiveFinger is turned on
        firstTrial = 2;         % default is firstTrial is 2
        thetaCell = varargin{1};
        if (~isempty(find(strcmp(varargin,'onlyActiveFing'),1)))
            onlyActiveFing = varargin{find(strcmp(varargin,'onlyActiveFing'),1)+1};     % setting 'onlyActiveFing' option
        end
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};             % setting 'onlyActiveFing' option
        end
        
        thetaMean = zeros(242,size(thetaCell,1));
        thetaStd = zeros(242,size(thetaCell,1));
        for subj = 1:size(thetaCell,1)
            for j = 1:size(thetaMean,1)
                thetaMean(j,subj) = mean(thetaCell{subj,1}{j,2}(firstTrial:end));
                thetaStd(j,subj) = std(thetaCell{subj,1}{j,2}(firstTrial:end));
            end
            % rhoAvg{1,2} = [rhoAvg{1,2} convertCharsToStrings(data{subj,2})];
        end

        if (onlyActiveFing)
            thetaMean(1:10,:) = 0;
        end
        [i,~] = find(isnan(thetaMean));
        thetaMean(i,:) = [];
        
        % plotting
        chordVec = generateAllChords();
        chordVecSep = sepChordVec(chordVec);
        colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
            [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
        rowNum = 3;
        colNum = ceil(nchoosek(size(data,1),2)/rowNum);
        figure;
        k = 1;
        for i = 1:size(data,1)
            for j = i+1:size(data,1)
                subplot(rowNum,colNum,k)
                for numActiveFing = 1:size(chordVecSep,1)
                    scatter(thetaMean(chordVecSep{numActiveFing,2},i),thetaMean(chordVecSep{numActiveFing,2},j),30,"MarkerFaceColor",colors(numActiveFing,:))
                    hold on
                end
                xlabel(sprintf("%s meanTheta",data{i,2}))
                ylabel(sprintf("%s meanTheta",data{j,2}))
                legend(["1","2","3","4","5"])
                k = k+1;
            end
        end
        

    % =====================================================================
    case 'OLS'
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};             % setting 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'dataset'),1)))                               % setting 'dataset' option
            dataset = varargin{find(strcmp(varargin,'dataset'),1)+1};                   
            if (~isempty(find(isnan(dataset),1)))
                error("you have NaN in your dataset. Please handle them before giving to this function")
            end
        else
            error('dataset not inputted to the function.')
        end
        if (~isempty(find(strcmp(varargin,'features'),1)))                              % setting 'features' option
            features = varargin{find(strcmp(varargin,'features'),1)+1};                   
            if (size(features,1) ~= size(dataset,1))
                error("dataset and features must have the same number of rows.")
            end
        else
            error('features not inputted to the function.')
        end
        
        % cross validated linear regression:
        fullFeatures = repmat(features,size(data,1)-1,1);
        rho_OLS = zeros(1,size(data,1));
        models = cell(size(data,1),2);
        for i = 1:size(data,1)
            idx = setdiff(1:size(data,1),i);    % excluding one subject from the analysis
            estimated = [];
            for j = idx
                estimated = [estimated ; dataset(:,j)];
            end
%             fprintf('============= OLS linear regression with excluded subject: %s =============\n',data{i,2})
            mdl = fitlm(fullFeatures,estimated);
%             fprintf('==========================================================================================\n\n')
            models{i,1} = mdl;
            models{i,2} = sprintf("excluded subj: %s",data{i,2});

            % testing model:
            pred = predict(mdl,features);
            dataOut = dataset(:,i);
            
            corrTmp = corr(dataOut,pred,'type',corrMethod);
            rho_OLS(1,i) = corrTmp;
        end
        varargout{2} = models;
        varargout{1} = rho_OLS;
        
    
    
    case 'modelTesting'
        dataName = "meanDev";
        featureCell = {"numActiveFing-linear","numActiveFing-oneHot","singleFinger","singleFingExt","singleFingFlex",...
            "neighbourFingers","2FingerCombinations","singleFinger+2FingerCombinations","neighbourFingers+singleFinger","all"};

        if (~isempty(find(strcmp(varargin,'dataName'),1)))
            dataName = varargin{find(strcmp(varargin,'dataName'),1)+1};   % setting 'dataName' option
        end
        if (~isempty(find(strcmp(varargin,'featureCell'),1)))
            featureCell = varargin{find(strcmp(varargin,'featureCell'),1)+1};   % setting 'featureCell' option
        end
        if (~isempty(find(strcmp(varargin,'onlyActiveFing'),1)))
            onlyActiveFing = varargin{find(strcmp(varargin,'onlyActiveFing'),1)+1};
        else
            error("parameter error: you should input onlyActiveFing parameter")
        end
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};
        else
            error("parameter error: you should input firstTrial parameter")
        end
        if (~isempty(find(strcmp(varargin,'selectRun'),1)))
            selectRun = varargin{find(strcmp(varargin,'selectRun'),1)+1}; 
        else
            error("parameter error: you should input selectRun parameter")
        end
        if (~isempty(find(strcmp(varargin,'durAfterActive'),1)))
            durAfterActive = varargin{find(strcmp(varargin,'durAfterActive'),1)+1};
        else
            error("parameter error: you should input durAfterActive parameter")
        end
        if (~isempty(find(strcmp(varargin,'excludeChord'),1)))
            excludeChord = varargin{find(strcmp(varargin,'excludeChord'),1)+1};
        else
            error("parameter error: you should input excludeChord parameter")
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};
        else
            error("parameter error: you should input corrMethod parameter")
        end

        fprintf("Running model evaluation for %s\n\n",dataName);
        
        dataset = regressionDataset(data,dataName,'onlyActiveFing',onlyActiveFing,...
            'firstTrial',firstTrial,'selectRun',selectRun,'durAfterActive',durAfterActive);
        [highCeil,lowCeil] = calcNoiseCeiling(data,dataName,'onlyActiveFing',onlyActiveFing,...
            'firstTrial',firstTrial,'selectRun',selectRun,'durAfterActive',durAfterActive,'excludeChord',excludeChord);
        
        % regression:
        models_save = cell(size(featureCell,2),1);
        rho_OLS = [];
        for i = 1:length(featureCell)
            features = makeFeatures(featureCell{i});
            [rho_OLS(i,:), models_save{i}] = efc1_analyze('OLS',data,'dataset',dataset,'features',features,'corrMethod',corrMethod);
        end
        
        modelCorrAvg = zeros(size(rho_OLS,1),1);
        modelCorrSem = zeros(size(rho_OLS,1),1);
        for i = 1:size(rho_OLS,1)
            modelCorrAvg(i) = mean(rho_OLS(i,:));
            modelCorrSem(i) = std(rho_OLS(i,:))/sqrt(length(rho_OLS(i,:)));
        end
        
        
        % Plot model performance
        figure;
        hold all
        x = 1:length(modelCorrAvg);
        h = bar(x,diag(modelCorrAvg),'stacked','BarWidth',0.6);
%         set(h(1),'facecolor',[1,0,0])
%         set(h(2),'facecolor',[0,1,0])
%         set(h(3),'facecolor',[0,0,1])
        errorbar(x,modelCorrAvg,modelCorrSem,"LineStyle","none",'Color','k')
%         yline(lowCeil,'linewidth',2)
        yline(highCeil,'linewidth',3)
        ylim([0,1])
        xticks(x)
        xticklabels(featureCell)
        title(sprintf("Eplaining the %s",dataName))
        ylabel("Crossvalidated Correlation")
        
        % beta value maps - single + 2finger
        model = models_save{find(string(featureCell) == "singleFinger+2FingerCombinations")};
        betaMatCell = cell(size(model,1),1);
        pValCell = cell(size(model,1),1);
        for n = 1:size(model,1)
            betaMat = zeros(10,10);
            pValMat = zeros(10,10);
            modelTmp = model{n,1};
            beta = modelTmp.Coefficients;
            pVal = table2array(beta(:,4));
            beta = table2array(beta(:,1));
            beta(1) = [];
            pVal(1) = [];
            
        %     beta = [zeros(10,1);beta];
        
            singleFingerBeta = beta(1:10);
            singleFinger_pVal = pVal(1:10);
            cnt_single = 1;
            twoFingerBeta = beta(11:end);
            twoFinger_pVal = pVal(11:end);
            cnt_two = 1;
            for i = 1:size(betaMat,1)
                for j = i:size(betaMat,2)
                    if (i==j)
                        betaMat(i,j) = singleFingerBeta(cnt_single);
                        pValMat(i,j) = singleFinger_pVal(cnt_single);
                        cnt_single = cnt_single+1;
                    elseif (j ~= i+5)
                        betaMat(i,j) = twoFingerBeta(cnt_two);
                        betaMat(j,i) = twoFingerBeta(cnt_two);
                        pValMat(i,j) = twoFinger_pVal(cnt_two);
                        pValMat(j,i) = twoFinger_pVal(cnt_two);
                        cnt_two = cnt_two+1;
                    end
                end
            end
            betaMatCell{n} = betaMat;
            pValCell{n} = pValMat;
        end
        
        betaMat = zeros(10,10);
        for i = 1:size(betaMatCell,1)
            betaMat = betaMat + betaMatCell{i};
        end
        betaMat = betaMat/size(betaMatCell,1);
        figure;
        imagesc(betaMat)
        hold on
        line([0.5,10.5], [5.5,5.5], 'Color', 'k','LineWidth',2);
        line([5.5,5.5], [0.5,10.5], 'Color', 'k','LineWidth',2);
        xticklabels([1:5,1:5])
        yticklabels([1:5,1:5])
        colorbar
        title(sprintf("beta values , %s",dataName))
        xlabel("digit")
        ylabel("digit")
    
    % =====================================================================
    case 'theta_bias'
        durAfterActive = 200;   % default duration after first finger passed the baseline threshld in ms
        plotfcn = 0;            % default is to plot
        firstTrial = 2;         % default is 2 , The first trial of the chord is usually very different from others which impacts the variance a lot. This is an option to ignore the first trial if wanted.
        selectRun = -2;         % default run to do the analysis is the last run. you can select run 1,2,3 or -1(last)
        if (~isempty(find(strcmp(varargin,'durAfterActive'),1)))
            durAfterActive = varargin{find(strcmp(varargin,'durAfterActive'),1)+1};     % setting 'durAfterActive' option
        end
        if (~isempty(find(strcmp(varargin,'plotfcn'),1)))
            plotfcn = varargin{find(strcmp(varargin,'plotfcn'),1)+1};                   % setting 'plotfcn' option
        end
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};             % setting 'firstTrial' option
        end
        if (~isempty(find(strcmp(varargin,'selectRun'),1)))    
            selectRun = varargin{find(strcmp(varargin,'selectRun'),1)+1};               % setting 'selectRun' option
        end
        holdTime = 600;
        
        forceData = cell(size(data));   % extracting the force signals for each subj
        for i = 1:size(data,1)
            forceData{i,1} = extractDiffForce(data{i,1});
            forceData{i,2} = data{i,2};
        end

        outCell = cell(size(data));
        for subj = 1:size(data,1)
            outCell{subj,2} = data{subj,2};
            chordVec = generateAllChords();  % all chords
            subjData = data{subj,1};
            subjForceData = forceData{subj,1};
            outCellSubj = cell(length(chordVec),2);
            vecBN = unique(subjData.BN);
            for i = 1:length(chordVec)
                outCellSubj{i,1} = chordVec(i);

                if (selectRun == -1)        % selecting the last 12 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > vecBN(end-12));
                elseif (selectRun == -2)    % selectign the last 24 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > vecBN(end-24));
                elseif (selectRun == 1)     % selecting the first 12 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN < 13);
                elseif (selectRun == 2)
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > 12 & subjData.BN < 25);
                elseif (selectRun == 3)
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > 24 & subjData.BN < 37);
                    iTmp = find(subjData.BN > 24 & subjData.BN < 37,1);
                    if (isempty(iTmp))
                        error("Error with <selectRun> option , " + data{subj,2} + " does not have block number " + num2str(selectRun))
                    end
                else
                    error("selectRun " + num2str(selectRun) + "does not exist. Possible choices are 1,2,3 and -1.")
                end

                if (firstTrial == 2)
                    if (selectRun ~= -2)
                        if (length(trialIdx) == 5)
                            trialIdx(1) = [];
                        end
                    elseif (selectRun == -2)
                        if (length(trialIdx) == 10)
                            trialIdx(6) = [];
                            trialIdx(1) = [];
                        end
                    end
                end

                if (~isempty(trialIdx))
                    chordTmp = num2str(chordVec(i));
%                     idealVec = double(chordTmp~='9');
%                     for j = 1:5
%                         if (chordTmp(j) == '2')
%                             idealVec(j) = -1;
%                         end
%                     end
                    forceVec_i_holder = [];
                    idealVec = zeros(1,5);
                    for trial_i = 1:length(trialIdx)
                        forceTrial = subjForceData{trialIdx(trial_i)};
                        baselineIdx = forceTrial(:,1) == 2;
                        execIdx = find(forceTrial(:,1) == 3);
                        execIdx = execIdx(end-holdTime/2:end); % 2ms is sampling frequency hence the holdTime/2
                        
                        avgBaselineForce = mean(forceTrial(baselineIdx,3:7),1);
                        avgExecForce = mean(forceTrial(execIdx,3:7),1);
                        idealVec = idealVec + (avgExecForce - avgBaselineForce)/length(trialIdx);

                        forceTmp = [];
                        tVec = subjForceData{trialIdx(trial_i)}(:,2); % time vector in trial
                        tGoCue = subjData.planTime(trialIdx(trial_i));
                        for j = 1:5     % thresholded force of the fingers after "Go Cue"
                            if (chordTmp(j) == '1') % extension
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            elseif (chordTmp(j) == '2') % flexion
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            elseif (chordTmp(j) == '9') % finger should be relaxed
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)) ...
                                    | subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            end
                        end
                        if (isempty(find(forceTmp,1)))  % if no fingers moved out of threshold, go to next trial
                            disp("empty")
                            continue
                        end
            
                        tmpIdx = [];
                        for k = 1:size(forceTmp,2)
                            tmpIdx(k) = find(forceTmp(:,k),1);
                        end
                        [sortIdx,~] = sort(tmpIdx); % sortIdx(1) is the first index after "Go Cue" that the first finger crossed the baseline thresh
                        idxStart = find(tVec==tGoCue)+sortIdx(1)-1; % index that the first finger passes the baseline threhold after "Go Cue"
                        
                        forceSelceted = [];
                        for j = 1:5     % getting the force from idxStart to idxStart+durAfterActive
                            forceSelceted = [forceSelceted subjForceData{trialIdx(trial_i)}(idxStart:idxStart+round(durAfterActive/2),2+j)];
                        end
                        forceVec_i = mean(forceSelceted,1)';  % average of finger forces in the first {durAfterActive} ms
                        forceVec_i_holder = [forceVec_i_holder forceVec_i];
                    end
                    forceVec_avg = mean(forceVec_i_holder,2);   % average of force vectors across trials -> vec_avg
                    thetaTmp = zeros(size(forceVec_i_holder,2),1);
                    for j = size(forceVec_i_holder,2) % going through all the forces
                        thetaTmp(i) = vectorAngle(forceVec_avg,forceVec_i_holder(:,j)); % Angle(vec_avg,vec_i)
                    end
                    outCellSubj{i,2}(1) = vectorAngle(forceVec_avg,idealVec);   % bias = Angle(vec_avg,vec_ideal);
                    outCellSubj{i,2}(2) = var(thetaTmp);                        % var = var{Angle(vec_i,vec_avg)}
                else
                    outCellSubj{i,2} = [];
                end 
            end
            outCell{subj,1} = outCellSubj;
        end
        varargout{1} = outCell;

        if (plotfcn)    % plotting
            biasVarCell = outCell;
            chordVec = generateAllChords();
            chordVecSep = sepChordVec(chordVec);
            colors = [[0 0.4470 0.7410];[0.8500 0.3250 0.0980];[0.9290 0.6940 0.1250];[0.4940 0.1840 0.5560];...
                [0.4660 0.6740 0.1880];[0.3010 0.7450 0.9330];[0.6350 0.0780 0.1840]];
            for subj = 1:size(biasVarCell,1)
                bias_var = biasVarCell{subj};
                emptyCells = cellfun(@isempty,bias_var);
                [row,col] = find(emptyCells);
                bias_var = cell2mat(bias_var(:,2));
            
                chordVec = generateAllChords();
                chordVec(row,:) = [];
                chordVecSep = sepChordVec(chordVec);
                figure;
                for numActiveFing = 1:size(chordVecSep,1)
                    scatter(sqrt(bias_var(chordVecSep{numActiveFing,2},2)),bias_var(chordVecSep{numActiveFing,2},1),30,"MarkerFaceColor",colors(numActiveFing,:))
                    hold on
                end
                xlabel("std theta (degree)")
                ylabel("bias (degree)")
                title(sprintf("%s",biasVarCell{subj,2}))
                legend({"1","2","3","4","5"})
                ylim([0,100])
                xlim([0,20])
            end
        end

    % =====================================================================
    case 'corr_bias_avg_model'
        firstTrial = 2;         % default value
        corrMethod = 'pearson'; % default corr method
        includeSubj = 0;        % default is not to include subj in avg
        if (~isempty(find(strcmp(varargin,'firstTrial'),1)))    
            firstTrial = varargin{find(strcmp(varargin,'firstTrial'),1)+1};         % setting the 'firstTrial' option - should be the same as the option used for 'thetaExp_vs_thetaStd'
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))    
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};         % setting the 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'includeSubj'),1)))    
            includeSubj = varargin{find(strcmp(varargin,'includeSubj'),1)+1};       % setting the 'includeSubj' option
        end
        if (~isempty(find(strcmp(varargin,'durAfterActive'),1)))    
            durAfterActive = varargin{find(strcmp(varargin,'durAfterActive'),1)+1};       % setting the 'durAfterActive' option
        end
        if (~isempty(find(strcmp(varargin,'selectRun'),1)))    
            selectRun = varargin{find(strcmp(varargin,'selectRun'),1)+1};       % setting the 'selectRun' option
        end


        biasVarCell = efc1_analyze('theta_bias',data,'durAfterActive',durAfterActive,'selectRun',selectRun,...
                            'firstTrial',firstTrial);
        biasMat = [biasVarCell{:,1}];
        biasMat(:,1:2:end)=[];
        biasMat = cell2mat(biasMat);
        biasMat(:,2:2:end)=[];
        
        rhoAvg = cell(1,2);
        if (~includeSubj)    % if we do not include each subject in the avg model -> lower noise ceiling
            for i = 1:size(biasMat,2)
                idxSelect = setdiff(1:size(biasMat,2),i);                       % excluding subj i from avg calculation
                tmpThetaMeanMat = biasMat(:,idxSelect);
                avgModel = mean(tmpThetaMeanMat,2);                             % calculating avg of thetaMean for subjects other than subj i
                corrTmp = corr(avgModel,biasMat(:,i),'type',corrMethod);        % correlation of avg model with excluded subj
                rhoAvg{1,1} = [rhoAvg{1,1} corrTmp];
                rhoAvg{1,2} = [rhoAvg{1,2} convertCharsToStrings(data{i,2})];
            end
        else                % if we include all subjects in the avg model -> higher noise ceiling
            avgModel = mean(biasMat,2);    
            for i = 1:size(biasMat,2)
                corrTmp = corr(avgModel,biasMat(:,i),'type',corrMethod);      % correlation of avg model with each subj
                rhoAvg{1,1} = [rhoAvg{1,1} corrTmp];
                rhoAvg{1,2} = [rhoAvg{1,2} convertCharsToStrings(data{i,2})];
            end
        end

        varargout{1} = rhoAvg;
    
    % =====================================================================
    case 'meanDev'
        selectRun = -2;         % the blocks to select data from
        clim = [];
        corrMethod = 'pearson';
        plotfcn = 0;
        if (~isempty(find(strcmp(varargin,'selectRun'),1)))    
            selectRun = varargin{find(strcmp(varargin,'selectRun'),1)+1};               % setting the 'selectRun' option
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))    
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};             % setting the 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'plotfcn'),1)))    
            plotfcn = varargin{find(strcmp(varargin,'plotfcn'),1)+1};               % setting the 'plotfcn' option
        end
        if (~isempty(find(strcmp(varargin,'clim'),1)))    
            clim = varargin{find(strcmp(varargin,'clim'),1)+1};                     % setting the 'clim' option
        end
        
        forceData = cell(size(data));
        for i = 1:size(data,1)
            forceData{i,1} = extractDiffForce(data{i,1});
            forceData{i,2} = data{i,2};
        end
        meanDevCell = cell(size(data,1),2);
        
        for subj = 1:size(data,1)
            chordVec = generateAllChords();                 % make all chords
            subjForceData = forceData{subj,1};
            subjData = data{subj,1};
            meanDevCell{subj,2} = data{subj,2};
            vecBN = unique(subjData.BN);
            meanDevCellSubj = cell(length(chordVec),2);
            for i = 1:length(chordVec)
                
                meanDevCellSubj{i,1} = chordVec(i);      % first columns: chordID
                
                if (selectRun == -1)        % selecting the last 12 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > vecBN(end-12));
                elseif (selectRun == -2)    % selectign the last 24 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > vecBN(end-24));
                elseif (selectRun == 1)     % selecting the first 12 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN < 13);
                elseif (selectRun == 2)
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > 12 & subjData.BN < 25);
                elseif (selectRun == 3)
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType == 0 & subjData.BN > 24 & subjData.BN < 37);
                    iTmp = find(subjData.BN > 24 & subjData.BN < 37,1);
                    if (isempty(iTmp))
                        error("Error with <selectRun> option , " + data{subj,2} + " does not have block number " + num2str(selectRun))
                    end
                else
                    error("selectRun " + num2str(selectRun) + "does not exist. Possible choices are 1,2,3 and -1.")
                end
                
                if (~isempty(trialIdx))
                    chordTmp = num2str(chordVec(i));
                    meanDevTmp = zeros(length(trialIdx),1);
                    for trial_i = 1:length(trialIdx)
                        forceTmp = [];
                        tVec = subjForceData{trialIdx(trial_i)}(:,2);   % time vector in trial
                        tGoCue = subjData.planTime(trialIdx(trial_i));
                        fGainVec = [subjData.fGain1(trialIdx(trial_i)) subjData.fGain2(trialIdx(trial_i)) subjData.fGain3(trialIdx(trial_i)) subjData.fGain4(trialIdx(trial_i)) subjData.fGain5(trialIdx(trial_i))];
                        for j = 1:5     % thresholded force of the fingers after "Go Cue"
                            if (chordTmp(j) == '1') % extension
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            elseif (chordTmp(j) == '2') % flexion
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            elseif (chordTmp(j) == '9') % finger should be relaxed
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)) ...
                                    | subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            end
                        end
                        
                        if (isempty(find(forceTmp,1)))  % if no fingers moved out of threshold, go to next trial
                            disp("empty forceTmp")
                            continue
                        end
                        
                        tmpIdx = [];
                        for k = 1:size(forceTmp,2)
                            tmpIdx(k) = find(forceTmp(:,k),1);
                        end
                        [sortIdx,~] = sort(tmpIdx); % sortIdx(1) is the first index after "Go Cue" that the first finger crossed the baseline thresh
                        idxStart = find(tVec==tGoCue)+sortIdx(1)-1; % index that the first active finger passes the baseline threshold after "Go Cue"
                        forceSelceted = [];
                        durAfterActive = subjData.RT(trialIdx(trial_i))-600;    % select the force from movement initiation until the correct state is formed
                        % durAfterActive = 200;   % select the force from movement initiation until 200ms later
                        for j = 1:5     % getting the force from idxStart to idxStart+durAfterActive
                            forceSelceted = [forceSelceted subjForceData{trialIdx(trial_i)}(idxStart:find(tVec==tGoCue)+round(durAfterActive/2),2+j)];
                        end
                        
                        tempDiff = zeros(size(forceSelceted,1),1);
                        c = forceSelceted(end,:)-forceSelceted(1,:);
                        for t = 1:size(forceSelceted,1) % iterating on time points
                            projection = (c * forceSelceted(t,:)' / norm(c)^2)*c;
                            tempDiff(t) = norm(forceSelceted(t,:) - projection);
                        end
                        meanDevTmp(trial_i) = sum(tempDiff) / size(forceSelceted,1);
                    end
                    meanDevCellSubj{i,2} = meanDevTmp;
                else
                    meanDevCellSubj{i,2} = [];
                end 
            end
            meanDevCell{subj,1} = meanDevCellSubj;
            
        end
        
        varargout{1} = meanDevCell;
        tmpMeanDev = [meanDevCell{:,1}];
        tmpMeanDev(:,1:2:end) = [];
        
        
        avgMeanDev = cellfun(@(x) mean(x,'all'),tmpMeanDev);
        corrMeanDev = cell(1,2);
        corrMeanDev{2} = cellfun(@(x) convertCharsToStrings(x),data(:,2));
        corrMeanDev{1} = corr(avgMeanDev,'type',corrMethod);
        varargout{2} = corrMeanDev;

        if (plotfcn)
            figure;
            if (~isempty(clim))
                imagesc(corrMeanDev{1},clim)
            else
                imagesc(corrMeanDev{1})
            end
            colorbar
            title(sprintf("corr meanDev across subj - corrMethod: %s",corrMethod))
            xlabel("subj")
            ylabel("subj")
        end
        

    % =====================================================================
    case 'corr_meanDev_avg_model'
        selectRun = -2;
        corrMethod = 'pearson';
        includeSubj = 0;
        if (~isempty(find(strcmp(varargin,'selectRun'),1)))    
            selectRun = varargin{find(strcmp(varargin,'selectRun'),1)+1};           % setting the 'selectRun' option - should be the same as the option used for 'thetaExp_vs_thetaStd'
        end
        if (~isempty(find(strcmp(varargin,'corrMethod'),1)))    
            corrMethod = varargin{find(strcmp(varargin,'corrMethod'),1)+1};         % setting the 'corrMethod' option
        end
        if (~isempty(find(strcmp(varargin,'includeSubj'),1)))    
            includeSubj = varargin{find(strcmp(varargin,'includeSubj'),1)+1};       % setting the 'includeSubj' option
        end
        
        meanDev = regressionDataset(data,'meanDev','selectRun',selectRun,'plotfcn',0);
        
        rhoAvg = cell(1,2);
        if (~includeSubj)    % if we do not include each subject in the avg model -> lower noise ceiling
            for i = 1:size(meanDev,2)
                idxSelect = setdiff(1:size(meanDev,2),i);                       % excluding subj i from avg calculation
                tmpMeanDev = meanDev(:,idxSelect);
                avgModel = mean(tmpMeanDev,2);                                  % calculating avg of meanDev for subjects other than subj i
                corrTmp = corr(avgModel,meanDev(:,i),'type',corrMethod);        % correlation of avg model with excluded subj
                rhoAvg{1,1} = [rhoAvg{1,1} corrTmp];
                rhoAvg{1,2} = [rhoAvg{1,2} convertCharsToStrings(data{i,2})];
            end
        else                % if we include all subjects in the avg model -> higher noise ceiling
            avgModel = mean(meanDev,2);    
            for i = 1:size(meanDev,2)
                corrTmp = corr(avgModel,meanDev(:,i),'type',corrMethod);      % correlation of avg model with each subj
                rhoAvg{1,1} = [rhoAvg{1,1} corrTmp];
                rhoAvg{1,2} = [rhoAvg{1,2} convertCharsToStrings(data{i,2})];
            end
        end

        varargout{1} = rhoAvg;

    case 'variance_partition'
        selectRun = -2;
        holdTime = 600;
        baseLineForceOption = 0;    % if '0', then the baseline force will be considerred [0,0,0,0,0]. If not,
                                    % baseline force will be considerred the avg
                                    % force during baseline duration.
        durAfterActive = 200;

        % setting the input options
        if (~isempty(find(strcmp(varargin,'selectRun'),1)))    
            selectRun = varargin{find(strcmp(varargin,'selectRun'),1)+1};
        end
        if (~isempty(find(strcmp(varargin,'durAfterActive'),1)))    
            durAfterActive = varargin{find(strcmp(varargin,'durAfterActive'),1)+1};
        end
        if (~isempty(find(strcmp(varargin,'baseLineForceOption'),1)))    
            baseLineForceOption = varargin{find(strcmp(varargin,'baseLineForceOption'),1)+1};
        end
        


        forceData = cell(size(data));   % extracting the force signals for each subj
        for i = 1:size(data,1)
            forceData{i,1} = extractDiffForce(data{i,1});
            forceData{i,2} = data{i,2};
        end
        
        outCell = cell(size(data));
        for subj = 1:size(data,1)
            outCell{subj,2} = data{subj,2};
            chordVec = generateAllChords();  % all chords
            subjData = data{subj,1};
            subjForceData = forceData{subj,1};
            outCellSubj = cell(length(chordVec),2);
            vecBN = unique(subjData.BN);
            for i = 1:length(chordVec)
                outCellSubj{i,2} = chordVec(i);
                outCellSubj{i,1} = cell(1,3);
        
                if (selectRun == -1)        % selecting the last 12 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > vecBN(end-12));
                elseif (selectRun == -2)    % selectign the last 24 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > vecBN(end-24));
                elseif (selectRun == 1)     % selecting the first 12 runs
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN < 13);
                elseif (selectRun == 2)
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > 12 & subjData.BN < 25);
                elseif (selectRun == 3)
                    trialIdx = find(subjData.chordID == chordVec(i) & subjData.trialErrorType ~= 1 & subjData.BN > 24 & subjData.BN < 37);
                    iTmp = find(subjData.BN > 24 & subjData.BN < 37,1);
                    if (isempty(iTmp))
                        error("Error with <selectRun> option , " + data{subj,2} + " does not have block number " + num2str(selectRun))
                    end
                else
                    error("selectRun " + num2str(selectRun) + "does not exist. Possible choices are 1,2,3,-1 and -2.")
                end
        
                
                if (~isempty(trialIdx))
                    chordTmp = num2str(chordVec(i));
                    forceVec_i_holder = [];
                    idealVec = zeros(1,5);
                    for trial_i = 1:length(trialIdx)
                        forceTrial = subjForceData{trialIdx(trial_i)};
                        baselineIdx = forceTrial(:,1) == 2;
                        execIdx = find(forceTrial(:,1) == 3);
                        execIdx = execIdx(end-holdTime/2:end); % 2ms is sampling frequency hence the holdTime/2
                        
                        avgBaselineForce = mean(forceTrial(baselineIdx,3:7),1);
                        if (baseLineForceOption == 0)
                            avgBaselineForce = zeros(1,5);
                        end
                        avgExecForce = mean(forceTrial(execIdx,3:7),1);
                        idealVec = idealVec + (avgExecForce - avgBaselineForce)/length(trialIdx);
        
                        forceTmp = [];
                        tVec = subjForceData{trialIdx(trial_i)}(:,2); % time vector in trial
                        tGoCue = subjData.planTime(trialIdx(trial_i));
                        for j = 1:5     % thresholded force of the fingers after "Go Cue"
                            if (chordTmp(j) == '1') % extension
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            elseif (chordTmp(j) == '2') % flexion
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            elseif (chordTmp(j) == '9') % finger should be relaxed
                                forceTmp = [forceTmp (subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) < -subjData.baselineTopThresh(trialIdx(trial_i)) ...
                                    | subjForceData{trialIdx(trial_i)}(tVec>=tGoCue,2+j) > subjData.baselineTopThresh(trialIdx(trial_i)))]; 
                                if (isempty(find(forceTmp(:,end),1)))
                                    forceTmp(:,end) = [];
                                end
                            end
                        end
                        if (isempty(find(forceTmp,1)))  % if no fingers moved out of threshold, go to next trial
                            disp("empty trial")
                            continue
                        end
            
                        tmpIdx = [];
                        for k = 1:size(forceTmp,2)
                            tmpIdx(k) = find(forceTmp(:,k),1);
                        end
                        [sortIdx,~] = sort(tmpIdx); % sortIdx(1) is the first index after "Go Cue" that the first finger crossed the baseline thresh
                        idxStart = find(tVec==tGoCue)+sortIdx(1)-1; % index that the first finger passes the baseline threhold after "Go Cue"
                        %idxStart = idxStart - idxStartShift;
        
                        forceSelceted = [];
                        for j = 1:5     % getting the force from idxStart to idxStart+durAfterActive
                            forceSelceted = [forceSelceted subjForceData{trialIdx(trial_i)}(idxStart:idxStart+round(durAfterActive/2),2+j)];
                        end
                        forceVec_i = mean(forceSelceted,1);  % average of finger forces in the first {durAfterActive} ms
                        forceVec_i_holder = [forceVec_i_holder ; forceVec_i/norm(forceVec_i)];
                    end
        
                    outCellSubj{i,1}{1} = forceVec_i_holder;
                    outCellSubj{i,1}{2} = repmat(idealVec/norm(idealVec),size(forceVec_i_holder,1),1);
                    outCellSubj{i,1}{3} = [ones(size(forceVec_i_holder,1),1)*i (1:size(forceVec_i_holder,1))'];
                else
                    outCellSubj{i,1} = [];
                end 
            end
            outCell{subj,1} = outCellSubj;
        end
        
        % Making regressors:
        y = [];     % dependent variable -> N by 5 matrix
        X1 = [];    % chord -> N by 242 matrix
        X2 = [];    % chord and subj -> N by 242*6 matrix
        labels = [];
        chordIDVec = [];
        for subj = 1:size(outCell,1)
            tmp = outCell{subj,1};
            forceVec = [tmp{:,1}]';
            idealVec = forceVec(2:3:end);
            tmpChord = forceVec(3:3:end);
            forceVec = forceVec(1:3:end);
            idealVec = vertcat(idealVec{:});
            forceVec = vertcat(forceVec{:});
            tmpChord = vertcat(tmpChord{:});
            labels = [labels ; [subj*ones(size(tmpChord,1),1),tmpChord]];
            tmpChord = tmpChord(:,1);
            X1_tmp = zeros(size(tmpChord,1),242);
            X2_tmp = zeros(size(tmpChord,1),242*6);
            val = unique(tmpChord);
            
            for i = 1:length(val)
                X1_tmp(tmpChord==val(i),val(i)) = 1;
                X2_tmp(tmpChord==val(i),(subj-1)*242+val(i)) = 1;
            end
            chordIDVec = [chordIDVec ; tmpChord];
            X1 = [X1 ; X1_tmp];
            X2 = [X2 ; X2_tmp];
            y = [y;idealVec-forceVec]; 
        end
        
        % mean cetnering the dependent variable (for simpler matrix calculations):
        y = y - repmat(mean(y,1),size(y,1),1);
        
        % ====== Regresison:
        [beta,SSR,SST] = myOLS(y,[X1,X2],labels,'shuffle_trial_crossVal');
        
        % var explained:
        chordVar = mean(SSR(:,1)./SST) * 100;
        subjVar = mean((SSR(:,2) - SSR(:,1))./SST) * 100;
        trialVar = 100 - (chordVar + subjVar);
        fprintf("var partitioning:\nChord = %.4f , Chord-Subj = %.4f , Trial = %.4f\n\n\n",chordVar,subjVar,trialVar);
        
        % pie chart:
        figure;
        pie([chordVar,subjVar,trialVar],{'chord','chord-subj','trial-noise'});
        title(sprintf('Variance Partitioning'))
        
        
        % Simulations ===============================================
        % random noise simulation
        y = makeSimData(size(y,1),5,'random',[0,1]);
        
        % ====== Regresison:
        [beta,SSR,SST] = myOLS(y,[X1,X2],labels,'shuffle_trial_crossVal');
        
        % var explained:
        chordVar = mean(SSR(:,1)./SST) * 100;
        subjVar = mean((SSR(:,2) - SSR(:,1))./SST) * 100;
        trialVar = 100 - (chordVar + subjVar);
        fprintf("Sim Noisy data:\nChord = %.4f , Chord-Subj = %.4f , Trial = %.4f\n\n\n",chordVar,subjVar,trialVar);
        
        % pie chart:
        figure;
        pie([chordVar,subjVar,trialVar],{'chord','chord-subj','trial-noise'});
        title(sprintf('Simulation , Random noise'))
        
        
        % Model simulation
        varChord = 5;
        varSubj = 3;
        varEps = 1;
        total = varChord + varSubj + varEps;
        y = makeSimData(size(y,1),5,'model',{{X1,X2},[varChord,varSubj,varEps]});
        
        % ====== Regresison:
        [beta,SSR,SST] = myOLS(y,[X1,X2],labels,'shuffle_trial_crossVal');
        
        % var explained:
        chordVar = mean(SSR(:,1)./SST) * 100;
        subjVar = mean((SSR(:,2) - SSR(:,1))./SST) * 100;
        trialVar = 100 - (chordVar + subjVar);
        fprintf("Sim Model data:\nChord = %.4f , Chord-Subj = %.4f , Trial = %.4f\n",chordVar,subjVar,trialVar);
        fprintf("Theoretical Partiotions:\nChord = %.4f , Chord-Subj = %.4f , Trial = %.4f\n\n\n",varChord/total*100,varSubj/total*100,varEps/total*100);
        
        % pie chart:
        figure;
        pie([chordVar,subjVar,trialVar],{'chord','chord-subj','trial-noise'});
        title(sprintf('Simulation , chord=%.2f , chord-subj=%.2f , noise=%.2f',varChord/total*100,varSubj/total*100,varEps/total*100))

    
    otherwise
        error('The analysis you entered does not exist!')
end



