function varargout=efc1_analyze(what, varargin)

addpath('functions/')

% setting paths:
usr_path = userpath;
usr_path = usr_path(1:end-17);
project_path = fullfile(usr_path, 'Desktop', 'Projects', 'EFC1');

% colors:
colors_red = [[255, 219, 219] ; [255, 146, 146] ; [255, 73, 73] ; [255, 0, 0] ; [182, 0, 0]]/255;
colors_gray = ['#d3d3d3' ; '#b9b9b9' ; '#868686' ; '#6d6d6d' ; '#535353'];
colors_blue = ['#dbecff' ; '#a8d1ff' ; '#429bff' ; '#0f80ff' ; '#0067db'];
colors_cyan = ['#adecee' ; '#83e2e5' ; '#2ecfd4' ; '#23a8ac' ; '#1b7e81'];
colors_random = ['#773344' ; '#E3B5A4' ; '#83A0A0' ; '#0B0014' ; '#D44D5C'];

colors_blue = hex2rgb(colors_blue);
colors_gray = hex2rgb(colors_gray);
colors_random = hex2rgb(colors_random);

% figure properties:
my_font.xlabel = 10;
my_font.ylabel = 10;
my_font.title = 11;
my_font.tick_label = 8;
my_font.legend = 8;

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
    
    case 'make_all_dataframe'
        % Calculate RT, MT, Mean Deviation for each trial of each subejct
        % and create a struct without the mov signals and save it as a
        % single struct called efc1_all.mat
        
        % input arguments:
        percent_after_RT = 15; % percentage of movement after RT.
        vararginoptions(varargin,{'percent_after_RT'});

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
            v_dev_tmp = zeros(length(tmp_data.BN),5);
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
                    % calculate initial deviation vector from ideal trajectory:
                    v_dev_tmp(j,:) = calculate_dev_vector(tmp_mov{j}, tmp_data.chordID(j), ...
                                                          tmp_data.baselineTopThresh(j), tmp_data.RT(j), percent_after_RT, ...
                                                          tmp_data.fGain1(j), tmp_data.fGain2(j), tmp_data.fGain3(j), ...
                                                          tmp_data.fGain4(j), tmp_data.fGain5(j));
                
                % if trial was incorrect:
                else
                    % mean dev:
                    mean_dev_tmp(j) = -1;
                    rt_tmp(j) = -1;
                    mt_tmp(j) = -1;
                    v_dev_tmp(j,:) = -1*ones(1,size(v_dev_tmp,2));
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
            tmp_data.MD = mean_dev_tmp;
            tmp_data.v_dev1 = v_dev_tmp(:,1);
            tmp_data.v_dev2 = v_dev_tmp(:,2);
            tmp_data.v_dev3 = v_dev_tmp(:,3);
            tmp_data.v_dev4 = v_dev_tmp(:,4);
            tmp_data.v_dev5 = v_dev_tmp(:,5);

            sess = (tmp_data.BN<=12) + 2*(tmp_data.BN>=13 & tmp_data.BN<=24) + 3*(tmp_data.BN>=25 & tmp_data.BN<=36) + 4*(tmp_data.BN>=37 & tmp_data.BN<=48);
            tmp_data.sess = sess;
            
            % adding subject data to ANA:
            ANA=addstruct(ANA,tmp_data,'row','force');
        end
        % adding number of active fingers:
        ANA.num_fingers = get_num_active_fingers(ANA.chordID);

        dsave(fullfile(usr_path,'Desktop','Projects','EFC1','analysis','efc1_all.tsv'),ANA);
    
    case 'make_chord_dataframe'
        % fields:
        % sn, sess, chordID, num_trials, num_fingers, MD, MT, RT, MD_std, MT_std, RT_std  

        % IMPORTANT: If new subjects are added, you should run
        % subject_routine and make_all_dataframe before running this
        % function.

        % load trial dataframe:
        data = dload(fullfile(project_path, 'analysis', 'efc1_all.tsv'));
        subjects = unique(data.sn);
        chords = generateAllChords;
        n = get_num_active_fingers(chords);
        sess = unique(data.sess);

        % container to hold the dataframe:
        ANA = [];
        % loop on subjects:
        for i = 1:length(subjects)
            tmp = [];
            % loop on sess:
            cnt = 1;
            for j = 1:length(sess)
                % loop on chords:
                for k = 1:length(chords)
                    tmp.sn(cnt,1) = subjects(i);
                    tmp.sess(cnt,1) = sess(j);
                    tmp.chordID(cnt,1) = chords(k);
                    
                    row = data.sn==subjects(i) & data.sess==sess(j) & data.chordID==chords(k) & data.trialCorr==1;
                    tmp.num_trials(cnt,1) = sum(row);
                    tmp.accuracy(cnt,1) = sum(row)/5;
                    tmp.num_fingers(cnt,1) = n(k);
                    tmp.MD(cnt,1) = mean(data.MD(row));
                    tmp.MT(cnt,1) = mean(data.MT(row));
                    tmp.RT(cnt,1) = mean(data.RT(row));
                    tmp.MD_std(cnt,1) = std(data.MD(row));
                    tmp.MT_std(cnt,1) = std(data.MT(row));
                    tmp.RT_std(cnt,1) = std(data.RT(row));
                    
                    cnt = cnt+1;
                end
            end
            ANA = addstruct(ANA,tmp,'row','force');
        end
        dsave(fullfile(project_path,'analysis','efc1_chord.tsv'),ANA);

    case 'subject_chords_accuracy'
        chords = generateAllChords;
        data = dload(fullfile(project_path, 'analysis', 'efc1_chord.tsv'));
        sess = data.sess;
        
        subjects = unique(data.sn);
        
        C = [];
        for i = 1:length(subjects)
            % loop on chords:
            acc_tmp = zeros(size(chords));
            for j = 1:length(chords)
                % averaging accuracies across sess 1 and 2:
                acc_tmp(j) = mean(data.accuracy(data.sn==subjects(i) & data.chordID==chords(j) & data.sess<=2));
            end

            % The most undoable chords of subject in the first 
            % two sessions: 
            [acc,idx] = sort(acc_tmp);

            % the most undoable chord:
            hard_chord = chords(idx(1));
            
            C.sn(i,1) = subjects(i);
            C.chordID(i,1) = hard_chord;
            % Accuracies:
            C.acc_diff_s01(i,1) = data.accuracy(data.sn==subjects(i) & data.sess==1 & data.chordID==hard_chord);
            C.acc_diff_s02(i,1) = data.accuracy(data.sn==subjects(i) & data.sess==2 & data.chordID==hard_chord);
            C.acc_diff_s03(i,1) = data.accuracy(data.sn==subjects(i) & data.sess==3 & data.chordID==hard_chord);
            C.acc_diff_s04(i,1) = data.accuracy(data.sn==subjects(i) & data.sess==4 & data.chordID==hard_chord);
            C.acc_avg_s01(i,1) = mean(data.accuracy(data.sn==subjects(i) & data.sess==1));
            C.acc_avg_s02(i,1) = mean(data.accuracy(data.sn==subjects(i) & data.sess==2));
            C.acc_avg_s03(i,1) = mean(data.accuracy(data.sn==subjects(i) & data.sess==3));
            C.acc_avg_s04(i,1) = mean(data.accuracy(data.sn==subjects(i) & data.sess==4));
        end

        % % plot:
        % subjects = unique(C.sn);
        % for i = 1:length(subjects)
        %     fig = figure();
        %     fontsize(fig, my_font.tick_label, 'points')
        %     scatter(ones(length(C.acc_diff_s01(C.sn==subjects(i)))), C.acc_diff_s01(C.sn==subjects(i)), 40, 'k', 'filled')
        %     hold on
        %     scatter(2*ones(length(C.acc_diff_s02(C.sn==subjects(i)))), C.acc_diff_s02(C.sn==subjects(i)), 40, 'k', 'filled')
        %     scatter(3*ones(length(C.acc_diff_s03(C.sn==subjects(i)))), C.acc_diff_s03(C.sn==subjects(i)), 40, 'k', 'filled')
        %     scatter(4*ones(length(C.acc_diff_s04(C.sn==subjects(i)))), C.acc_diff_s04(C.sn==subjects(i)), 40, 'k', 'filled')
        %     drawline(5,'dir','horz','color',[0.7,0.7,0.7])
        %     plot(1:4, ...
        %         [C.acc_diff_s01(C.sn==subjects(i))' ; C.acc_diff_s02(C.sn==subjects(i))' ; C.acc_diff_s03(C.sn==subjects(i))' ; C.acc_diff_s04(C.sn==subjects(i))'] ...
        %         ,'Color',[0 0 0],'LineWidth',1.5)
        %     ylim([0 1.2])
        %     xticks([1 2 3 4])
        %     yticks([0 0.5 1])
        %     title(['subj ' num2str(subjects(i))],'FontSize',my_font.title)
        %     ylabel('num correct executions','FontSize',my_font.ylabel)
        %     xlabel('sess','FontSize',my_font.xlabel)
        % end

        % plot:
        avg_diff = [mean(C.acc_diff_s01) ; mean(C.acc_diff_s02) ; mean(C.acc_diff_s03) ; mean(C.acc_diff_s04)];
        sem_diff = [std(C.acc_diff_s01) ; std(C.acc_diff_s02) ; std(C.acc_diff_s03) ; std(C.acc_diff_s04)]/sqrt(length(C.sn));
        avg_all = [mean(C.acc_avg_s01) ; mean(C.acc_avg_s02) ; mean(C.acc_avg_s03) ; mean(C.acc_avg_s04)];
        sem_all = [std(C.acc_avg_s01) ; std(C.acc_avg_s02) ; std(C.acc_avg_s03) ; std(C.acc_avg_s04)]/sqrt(length(C.sn));
        
        fig = figure('Units','centimeters', 'Position',[15 15 5 5]);
        fontsize(fig, my_font.tick_label, 'points')
        drawline(1,'dir','horz','color',[0.7 0.7 0.7],'lim',[0 5]); hold on;
        
        errorbar(1:4,avg_diff,sem_diff,'LineStyle','none','CapSize',0,'Color',colors_blue(5,:)); 
        plot(1:4,avg_diff,'Color',colors_blue(5,:),'LineWidth',2)
        scatter(1:4,avg_diff,30,'MarkerFaceColor',colors_blue(5,:),'MarkerEdgeColor',colors_blue(5,:));

        % errorbar(1:4,avg_all,sem_all,'LineStyle','none','CapSize',0,'Color',colors_blue(2,:)); 
        plot(1:4,avg_all,'Color',[colors_blue(2,:), 0.6],'LineWidth',3)
        % scatter(1:4,avg_all,30,'MarkerFaceColor',colors_blue(2,:),'MarkerEdgeColor',colors_blue(2,:),'MarkerEdgeAlpha',0,'MarkerFaceAlpha',0.4);
        
        lgd = legend({'','','most challenging','','all 242'});
        legend boxoff
        fontsize(lgd,6,'points')

        ylim([0,1.2])
        xlim([0.8,4.2])
        h = gca;
        h.YAxis.TickValues = 0:0.5:1;
        h.XAxis.TickValues = 1:4;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('sess','FontSize',my_font.xlabel)
        ylabel('accuracy','FontSize',my_font.tick_label)
        box off
        
        varargout{1} = C;
        

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

    case 'behavior_reliability_v2'
        vararginoptions(varargin,{'blocks'})
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_all.tsv'));
        sess = (data.BN<=12) + 2*(data.BN>=13 & data.BN<=24) + 3*(data.BN>=25 & data.BN<=36) + 4*(data.BN>=37 & data.BN<=48);
        
        subjects = unique(data.sn);

        % extracting avg mean dev of all subjects:
        C = [];
        for sn = 1:length(subjects)
            tmp = [];
            % all possible chords:
            chords = generateAllChords();
            
            % get the behavior data for all sessions and chords:
            cnt = 1;
            for j = 1:length(unique(sess))
                for i = 1:length(chords)
                    tmp.sn(cnt,1) = subjects(sn);
                    tmp.chordID(cnt,1) = chords(i);
                    tmp.num_fingers(cnt,1) = get_num_active_fingers(chords(i));
                    tmp.sess(cnt,1) = j;
                    
                    row = data.sn==subjects(sn) & sess==j & data.chordID==chords(i) & data.trialCorr==1;
                    tmp.mean_dev(cnt,1) = mean(data.mean_dev(row));
                    tmp.RT(cnt,1) = median(data.RT(row));
                    tmp.MT(cnt,1) = median(data.MT(row));
                    cnt = cnt+1;
                end
            end

            % concatenating subjects:
            C = addstruct(C,tmp,'row','force');
        end

        % getting the values in matrix format
        MD = zeros(length(chords)*length(unique(sess)),length(sn));
        RT = zeros(length(chords)*length(unique(sess)),length(sn));
        MT = zeros(length(chords)*length(unique(sess)),length(sn));
        sess_reduced = kron([1;2;3;4],ones(length(chords),1));
        for sn = 1:length(subjects)
            MD(:,sn) = C.mean_dev(C.sn==subjects(sn));
            RT(:,sn) = C.RT(C.sn==subjects(sn));
            MT(:,sn) = C.MT(C.sn==subjects(sn));
        end

        % num active fingers:
        n = C.num_fingers(C.sn==1);

        % corr behavior leave-one-out:
        corr_struct = [];

        % loop on number of fingers:
        for i = 1:length(unique(n))
            tmp = [];
            % loop on subjs:
            for sn = 1:length(subjects)
                tmp.num_fingers(sn,1) = i;
                tmp.sn(sn,1) = subjects(sn);
                

                % simple across session correlation within subj:
                row01 = C.num_fingers==i & C.sn==subjects(sn) & C.sess==3;
                row02 = C.num_fingers==i & C.sn==subjects(sn) & C.sess==4;
                [r,p] = corrcoef(C.mean_dev(row01),C.mean_dev(row02));
                tmp.MD_within(sn,1) = r(2);

                [r,p] = corrcoef(C.MT(row01),C.MT(row02));
                tmp.MT_within(sn,1) = r(2);

                [r,p] = corrcoef(C.RT(row01),C.RT(row02));
                tmp.RT_within(sn,1) = r(2);


                % cronbach's alpha within subj:
                alpha = cronbach([C.mean_dev(row01), C.mean_dev(row02)]);
                tmp.MD_within_alpha(sn,1) = alpha;

                alpha = cronbach([C.MT(row01), C.MT(row02)]);
                tmp.MT_within_alpha(sn,1) = alpha;

                alpha = cronbach([C.RT(row01), C.RT(row02)]);
                tmp.RT_within_alpha(sn,1) = alpha;


                % avg sess , leave-one-out:
                x = mean([MD(n==i & sess_reduced==3,sn),MD(n==i & sess_reduced==4,sn)],2,"omitnan");
                y = mean([MD(n==i & sess_reduced==3,setdiff(1:length(subjects),sn)),MD(n==i & sess_reduced==4,setdiff(1:length(subjects),sn))],2,"omitnan");
                [r,p] = corrcoef(x,y);
                tmp.MD_across_avg(sn,1) = r(2);

                x = mean([MT(n==i & sess_reduced==3,sn),MT(n==i & sess_reduced==4,sn)],2,"omitnan");
                y = mean([MT(n==i & sess_reduced==3,setdiff(1:length(subjects),sn)),MT(n==i & sess_reduced==4,setdiff(1:length(subjects),sn))],2,"omitnan");
                [r,p] = corrcoef(x,y);
                tmp.MT_across_avg(sn,1) = r(2);

                x = mean([RT(n==i & sess_reduced==3,sn),RT(n==i & sess_reduced==4,sn)],2,"omitnan");
                y = mean([RT(n==i & sess_reduced==3,setdiff(1:length(subjects),sn)),RT(n==i & sess_reduced==4,setdiff(1:length(subjects),sn))],2,"omitnan");
                [r,p] = corrcoef(x,y);
                tmp.RT_across_avg(sn,1) = r(2);


                % cat sess , leave-one-out:
                x = MD(n==i & sess_reduced>=3,sn);
                y = mean(MD(n==i & sess_reduced>=3,setdiff(1:length(subjects),sn)),2,"omitnan");
                [r,p] = corrcoef(x,y);
                tmp.MD_across_cat(sn,1) = r(2);

                x = MT(n==i & sess_reduced>=3,sn);
                y = mean(MT(n==i & sess_reduced>=3,setdiff(1:length(subjects),sn)),2,"omitnan");
                [r,p] = corrcoef(x,y);
                tmp.MT_across_cat(sn,1) = r(2);

                x = RT(n==i & sess_reduced>=3,sn);
                y = mean(RT(n==i & sess_reduced>=3,setdiff(1:length(subjects),sn)),2,"omitnan");
                [r,p] = corrcoef(x,y);
                tmp.RT_across_cat(sn,1) = r(2);


                % avg sess cronbach , leave-one-out:
                x = mean([MD(n==i & sess_reduced==3,sn),MD(n==i & sess_reduced==4,sn)],2,"omitnan");
                y = mean([MD(n==i & sess_reduced==3,setdiff(1:length(subjects),sn)),MD(n==i & sess_reduced==4,setdiff(1:length(subjects),sn))],2,"omitnan");
                alpha = cronbach([x,y]);
                tmp.MD_avg_alpha(sn,1) = alpha;

                x = mean([MT(n==i & sess_reduced==3,sn),MT(n==i & sess_reduced==4,sn)],2,"omitnan");
                y = mean([MT(n==i & sess_reduced==3,setdiff(1:length(subjects),sn)),MT(n==i & sess_reduced==4,setdiff(1:length(subjects),sn))],2,"omitnan");
                alpha = cronbach([x,y]);
                tmp.MT_avg_alpha(sn,1) = alpha;

                x = mean([RT(n==i & sess_reduced==3,sn),RT(n==i & sess_reduced==4,sn)],2,"omitnan");
                y = mean([RT(n==i & sess_reduced==3,setdiff(1:length(subjects),sn)),RT(n==i & sess_reduced==4,setdiff(1:length(subjects),sn))],2,"omitnan");
                alpha = cronbach([x,y]);
                tmp.RT_avg_alpha(sn,1) = alpha;

                % cat sess cronbach , leave-one-out:
                x = MD(n==i & sess_reduced>=3,sn);
                y = mean(MD(n==i & sess_reduced>=3,setdiff(1:length(subjects),sn)),2,"omitnan");
                alpha = cronbach([x,y]);
                tmp.MD_across_cat(sn,1) = alpha;

                x = MT(n==i & sess_reduced>=3,sn);
                y = mean(MT(n==i & sess_reduced>=3,setdiff(1:length(subjects),sn)),2,"omitnan");
                alpha = cronbach([x,y]);
                tmp.MT_across_cat(sn,1) = alpha;

                x = RT(n==i & sess_reduced>=3,sn);
                y = mean(RT(n==i & sess_reduced>=3,setdiff(1:length(subjects),sn)),2,"omitnan");
                alpha = cronbach([x,y]);
                tmp.RT_across_cat(sn,1) = alpha;
                
            end
            corr_struct = addstruct(corr_struct,tmp,'row','force');
        end

        % corr across for all chords:
        [~,corr_all] = efc1_analyze('selected_chords_reliability','chords',generateAllChords,'plot_option',0);
        
        % plots:
        fig = figure();
        fontsize(fig,my_font.tick_label,'points')
        lineplot(corr_struct.num_fingers,corr_struct.MD_within_alpha, 'markertype','o','markersize',8,'markercolor',[0 0.4470 0.7410],'markerfill',[0 0.4470 0.7410],'linecolor',[0.8588 0.9451 1.0000],'linewidth',2,'errorbars','');
        hold on
        lineplot(corr_struct.num_fingers,corr_struct.MD_across_cat, 'markertype','s','markersize',8,'markercolor',[0.8500 0.3250 0.0980],'markerfill',[0.8500 0.3250 0.0980],'linecolor',[0.9843 0.9059 0.8706],'linewidth',2,'errorbars','');
        drawline(mean(corr_all.MD),'dir','horz','color',[0.7 0.7 0.7])
        legend('within subjects','across subjects')
        legend boxoff
        title(sprintf('MD Reliability'),'FontSize',my_font.title)
        xlabel('num fingers','FontSize',my_font.xlabel)
        ylabel('rho leave-one-out','FontSize',my_font.ylabel)
        ylim([0,1])
        h = gca;
        h.YAxis.TickValues = linspace(h.YAxis.TickValues(1), h.YAxis.TickValues(end), 6);

        varargout{1} = C;
        varargout{2} = corr_struct;

    case 'behavior_trends'
        measure = 'MD';
        vararginoptions(varargin,{'measure'})

        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));

        % getting the values of measure:
        values = eval(['data.' measure]);
        
        [sem_subj, X_subj, Y_subj, ~] = get_sem(values, data.sn, data.sess, data.num_fingers);
        
        % PLOTS:
        figure;
        ax1 = axes('Units','centimeters', 'Position', [2 2 4.8 5],'Box','off');
        % ax1.PositionConstraint = "innerposition";
        % axes(ax1);
        for i = 1:5
            errorbar(sem_subj.partitions(sem_subj.cond==i),sem_subj.y(sem_subj.cond==i),sem_subj.sem(sem_subj.cond==i),'LineStyle','none','Color',colors_blue(i,:),'CapSize',0); hold on;
            lineplot(data.sess(data.num_fingers==i & ~isnan(values)),values(data.num_fingers==i & ~isnan(values)),'markertype','o','markersize',3.5,'markerfill',colors_blue(i,:),'markercolor',colors_blue(i,:),'linecolor',colors_blue(i,:),'linewidth',1.5,'errorbars','');
        end
        
        % lgd = legend({'','n=1','','n=2','','n=3','','n=4','','n=5'});
        % legend boxoff
        % fontsize(lgd,6,'points')
        ylim([0.5 2.6])
        % ylim([0 2600])
        % ylim([140 420])
        xlim([0.8 4.2])
        xlabel('session','FontSize',my_font.xlabel)
        % ylabel([measure ,' [ms]'],'FontSize',my_font.tick_label)
        ylabel([measure],'FontSize',my_font.tick_label)
        h = gca;
        h.YTick = linspace(h.YTick(1),h.YTick(end),3);
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        fontname("Arial")
        
        % doing stats:
        idx_exlude_nans = ~isnan(values);
        stats = rm_anova2(values(idx_exlude_nans),data.sn(idx_exlude_nans),data.sess(idx_exlude_nans),data.num_fingers(idx_exlude_nans),{'sess','num_fingers'});
        varargout{1} = stats;
        

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
        % EFC EMG Pilot 1:
        chords = [19999,91999,99199,99919,99991,29999,92999,99299,99929,99992,...
                  11912,22921,21911,12922,12191,21292,19121,29212,12112,21221,21121,21121,12212,11212,22121,21211,21122]';
        % Sheena:
        % chords = [99922,99292,92992,92929,92922,92292,29992,29929,29922,29299,29292,29229,22929,22299]';
        measure = 'MD';
        subjects = [];
        vararginoptions(varargin,{'measure','chords','subjects'})

        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));

        % rows for selected chords:
        row = arrayfun(@(x) ~isempty(intersect(x,chords)), data.chordID);
        data = getrow(data,row);

        if isempty(subjects)
            subjects = unique(data.sn);
        else
            row = arrayfun(@(x) ~isempty(intersect(x,subjects)), data.sn);
            data = getrow(data,row);
        end

        % getting the values of measure:
        values = eval(['data.' measure]);

        cond_vec = data.num_fingers;
        cond_vec(cond_vec>1) = 2;
        [sem_subj, X_subj, Y_subj, COND] = get_sem(values, data.sn, data.sess, cond_vec);

        x = [];
        y = [];
        n = [];
        conditions = unique(cond_vec);
        cnt = 1;
        for i = 1:length(subjects)
            for j = 1:length(unique(data.sess))
                for k = 1:length(conditions)
                    x(cnt,1) = j;
                    y(cnt,1) = mean(values(data.sess==j & data.sn==subjects(i) & cond_vec==conditions(k)),'omitmissing');
                    n(cnt,1) = conditions(k);
                    cnt = cnt+1;
                end
            end
        end

        % avg trend acorss sessions:
        fig = figure('Position', [500 500 190 200]);
        fontsize(fig, my_font.tick_label, 'points')
        
        errorbar(sem_subj.partitions(sem_subj.cond==1),sem_subj.y(sem_subj.cond==1),sem_subj.sem(sem_subj.cond==1),'LineStyle','none','Color',colors_blue(2,:)); hold on;
        lineplot(x(n==conditions(1)),y(n==conditions(1)),'markertype','o','markersize',5,'markerfill',colors_blue(2,:),'markercolor',colors_blue(2,:),'linecolor',colors_blue(2,:),'linewidth',2,'errorbars','');
        hold on

        errorbar(sem_subj.partitions(sem_subj.cond==2),sem_subj.y(sem_subj.cond==2),sem_subj.sem(sem_subj.cond==2),'LineStyle','none','Color',colors_blue(5,:))
        lineplot(x(n==conditions(2)),y(n==conditions(2)),'markertype','o','markersize',5,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',2,'errorbars','');
        
        % scatter(X_subj(COND==1),Y_subj(COND==1),10,'MarkerEdgeColor',colors_blue(1,:),'MarkerFaceColor',colors_blue(1,:))
        % scatter(X_subj(COND==2),Y_subj(COND==2),10,'MarkerEdgeColor',colors_blue(5,:),'MarkerFaceColor',colors_blue(5,:))

        legend('','single finger','','chord');
        legend boxoff
        xlabel('sess','FontSize',my_font.xlabel)
        ylabel([replace(measure,'_',' ')],'FontSize',my_font.title)
        % title([replace(measure,'_',' ')],'FontSize',my_font.title)
        % ylim([0.2 2.7])
        % ylim([0 3500])
        ylim([0 500])
        h = gca;
        h.YTick = linspace(h.YTick(1),h.YTick(end),5);

    case 'var_decomp_overall'
        chords = generateAllChords;
        measure = 'MD';
        centered = 1;
        vararginoptions(varargin,{'chords','measure','centered'})

        data = dload(fullfile(project_path, 'analysis', 'efc1_chord.tsv'));

        % getting the values of measure:
        values = eval(['data.' measure]);

        % reliability estimation:
        [v_g, v_gs, v_gse] = reliability_var(values(data.sess>=3), data.sn(data.sess>=3), data.sess(data.sess>=3), 'centered', centered);

        % plot:
        fig = figure('Units','centimeters','Position',[30 30 6 7]);
        fontsize(fig, my_font.tick_label, "points")
        bar(1,1,'FaceColor','flat','EdgeColor',[1,1,1],'LineWidth',1,'CData',[0.8 0.8 0.8])
        hold on
        bar(1,1-(v_gs-v_g)/v_gse,'FaceColor','flat','EdgeColor',[1,1,1],'LineWidth',1,'CData',[36, 168, 255]/255)
        bar(1,v_g/v_gse,'FaceColor','flat','EdgeColor',[1,1,1],'LineWidth',1,'CData',[238, 146, 106]/255)
        drawline(1,'dir','horz','color',[0.7 0.7 0.7])
        drawline(0,'dir','horz','color',[0.7 0.7 0.7])
        box off;
        h = gca;
        h.YTick = [];
        % h.XTick = [];
        title([measure ' Reliability'],'FontSize',my_font.title)
        xlabel('All Chords','FontSize',my_font.xlabel)
        % legend('global','subject','noise')
        % legend boxoff
        ylim([-0.1,1.2])


    case 'var_decomp_nfingers'
        chords = generateAllChords;
        measure = 'MD';
        centered = 1;
        vararginoptions(varargin,{'chords','measure','centered'})

        data = dload(fullfile(project_path, 'analysis', 'efc1_chord.tsv'));

        % getting the values of measure:
        values = eval(['data.' measure]);

        % exclude nan values - subjects may have missed all 5 reps:
        % exclude_

        % reliability estimation:
        [v_g, v_gs, v_gse] = reliability_var(values(data.sess>=3), data.sn(data.sess>=3), data.sess(data.sess>=3), ...
            'cond_vec', data.num_fingers(data.sess>=3), 'centered', centered);
        
        % plot:
        y = [];
        figure;
        ax1 = axes('Units','centimeters', 'Position', [2 2 4.8 5],'Box','off');
        for i = 1:length(unique(data.num_fingers))
            y(i,:) = [v_g{i}/v_gse{i} (v_gs{i}-v_g{i})/v_gse{i} (v_gse{i}-v_gs{i})/v_gse{i}];
            b = bar(i,y(i,:),'stacked','FaceColor','flat');
            b(1).CData = [238, 146, 106]/255;   % global var
            b(2).CData = [36, 168, 255]/255;  % subj var
            b(3).CData = [0.8 0.8 0.8];  % noise var
            b(1).EdgeColor = [1 1 1];
            b(2).EdgeColor = [1 1 1];
            b(3).EdgeColor = [1 1 1];
            b(1).LineWidth = 1;
            b(2).LineWidth = 1;
            b(3).LineWidth = 1;
            hold on
        end
        drawline(1,'dir','horz','color',[0.7 0.7 0.7])
        drawline(0,'dir','horz','color',[0.7 0.7 0.7])
        set(gca, 'XTick', 1:5);
        h = gca;
        h.YTick = 0:0.2:1;
        box off;
        title([measure ' Reliability'],'FontSize',my_font.title)
        xlabel('num fingers','FontSize',my_font.xlabel)
        ylabel('percent variance','FontSize',my_font.ylabel)
        legend('global','subject','noise')
        legend boxoff
        ylim([-0.1,1.2])

        varargout{1} = [v_g, v_gs, v_gse];
        
    case 'repetition_effect'
        chords = generateAllChords;
        measure = 'MD';
        vararginoptions(varargin,{'chords','measure'})
        
        data = dload(fullfile(project_path, 'analysis', 'efc1_all.tsv'));

        % getting the values of measure:
        values = eval(['data.' measure]);
        values(values==-1) = NaN;
        
        % putting trials in rows:
        n_fing = reshape(data.num_fingers,5,[]); 
        sess = reshape(data.sess,5,[]); 
        values = reshape(values,5,[]);
        subj = reshape(data.sn,5,[]);
        repetitions = 5;

        % getting averages within each session and n_fing:
        n_fing = n_fing(1,:);
        sess = sess(1,:);
        subj = subj(1,:);
        C = [];
        % loop on n_fing:
        cnt = 1;
        for i = 1:length(unique(n_fing))
            % loop on sess:
            for j = 1:length(unique(sess))
                % selecting the data for each session and finger group
                values_tmp = values(:, n_fing==i & sess==j);
                C.value(cnt,:) = mean(values_tmp,2,'omitmissing')';

                % estimating the standard errors:
                for k = 1:repetitions
                    [sem_tmp, ~, ~, ~] = get_sem( values_tmp(k,:)', subj(n_fing==i & sess==j)', ones(length(values_tmp(k,:)),1), ones(length(values_tmp(k,:)),1) );
                    C.sem(cnt,k) = sem_tmp.sem;
                end
                C.num_fingers(cnt,1) = i;
                C.sess(cnt,1) = j;
                cnt = cnt+1;
            end
        end

        % Estimating the benefit from sess1 to sess4:
        subj_unique = unique(subj);
        benefit = [];
        cnt = 1;
        for i = 2:length(unique(n_fing))
            for sn = 1:length(subj_unique)
                % selecting the data for each subj:
                values_tmp01 = mean(values(:, n_fing==i & sess==1 & subj==subj_unique(sn)), 2, 'omitmissing');
                values_tmp04 = mean(values(:, n_fing==i & sess==4 & subj==subj_unique(sn)), 2, 'omitmissing');
                benefit.benefit(cnt,:) = (values_tmp01 - values_tmp04)';
                benefit.benefit_rep1(cnt,1) = benefit.benefit(cnt,1);
                benefit.benefit_rep2_5(cnt,1) = mean(benefit.benefit(cnt,2:end));
                benefit.sn(cnt,1) = subj_unique(sn);
                benefit.num_fingers(cnt,1) = i;
                cnt = cnt+1;
            end
        end

        % PLOT - repetition trends:
        figure;
        ax1 = axes('Units','centimeters', 'Position', [2 2 4.8 5],'Box','off');
        offset_size = 5;
        x_offset = 0:offset_size:5*(length(unique(C.sess))-1);
        for i = 1:length(unique(C.num_fingers))
            for j = 1:length(unique(C.sess))
                plot((1:5)+x_offset(j), C.value(C.num_fingers==i & C.sess==j, :),'Color',colors_blue(i,:),'LineWidth',1); hold on;
                errorbar((1:5)+x_offset(j), C.value(C.num_fingers==i & C.sess==j, :), C.sem(C.num_fingers==i & C.sess==j, :), 'CapSize', 0, 'Color', colors_blue(i,:));
                scatter((1:5)+x_offset(j), C.value(C.num_fingers==i & C.sess==j, :), 10,'MarkerFaceColor',colors_blue(i,:),'MarkerEdgeColor',colors_blue(i,:))
            end
        end
        box off
        h = gca;
        % h.YTick = 100:150:600; % RT
        % h.YTick = 0:1000:3000; % MT
        h.YTick = 0.5:1:2.5; % MD
        h.XTick = 5*(1:length(unique(C.sess))) - 2;
        xlabel('session','FontSize',my_font.xlabel)
        h.XTickLabel = {'1','2','3','4'};
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        % ylabel(measure,'FontSize',my_font.ylabel)
        ylim([0.3, 2.8]) % MD
        % ylim([80, 650]) % RT
        % ylim([0, 3200]) % MT
        xlim([0,21])
        % title('Repetition Effect','FontSize',my_font.title)
        fontname("Arial")

        varargout{1} = C;
        varargout{2} = benefit;
        
        
    case 'model_testing_avg_values'
        % handling input args:
        blocks = [25,48];
        model_names = {'n_trans','n_fing','additive','n_fing+n_trans','n_fing+additive','n_trans+additive','n_fing+n_trans+additive','n_fing+n_trans+neighbour','n_fing+n_trans+additive+neighbour'};
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

        % loop on subjects and regression with leave-one-out:
        results = [];
        for i = 1:length(subjects)
            fprintf('running for subj %d/%d out...\n',i,length(subjects))

            % container for regression results:
            tmp = [];

            % loop on models:
            for j = 1:length(model_names)
                
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

                % storing the regression results:
                tmp.model_name{j,1} = model_names{j};
                tmp.model_num(j,1) = j;
                tmp.sn_out(j,1) = subjects(i);
                tmp.B{j,1} = B;
                tmp.stats{j,1} = STATS;

                % estimating the model performance:
                % r:
                [r,p] = corrcoef(y_pred,y_test);
                tmp.r_test(j,1) = r(2);
                tmp.p_value(j,1) = p(2);
                % r squared:
                tmp.r2_test(j,1) = 1 - sum((y_pred-y_test).^2) / sum((y_test-mean(y_test)).^2);
                
                % estimating model performance within chord groups:
                for k = 1:5
                    % r:
                    [r,p] = corrcoef(y_pred(n==k),y_test(n==k));
                    % if the model was num_fingers, then calculating r give
                    % nan as the denominator is 0 (which is the var of
                    % y_pred):
                    if strcmp(model_names{j},'n_fing')
                        r = [0 0 ; 0 0];
                        p = [0 0 ; 0 0];
                    end
                    eval(['tmp.r_test_n' num2str(k) '(j,1) = r(2);']);
                    eval(['tmp.p_value_n' num2str(k) '(j,1) = p(2);']);

                    % r squared:
                    tmp_r2 = 1 - sum((y_pred(n==k)-y_test(n==k)).^2) / sum((y_test(n==k)-mean(y_test(n==k))).^2);
                    eval(['tmp.r2_test_n' num2str(k) '(j,1) = tmp_r2;']);
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

        % all chords noise ceiling -> leave one out correlation:
        [~,corr_struct] = efc1_analyze('selected_chords_reliability','blocks',blocks,'chords',chords,'plot_option',0);
        if (strcmp(measure,'mean_dev'))
            noise_ceil = mean(corr_struct.MD);
        elseif (strcmp(measure,'MT'))
            noise_ceil = mean(corr_struct.MT);
        else
            noise_ceil = mean(corr_struct.RT);
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

        % plotting overall model performance:
        fig = figure('Position',[500 500 450 400]);
        fontsize(fig,my_font.tick_label,"points")
        lineplot(results.model_num, results.r_test ,'markersize', 8, 'markerfill', colors_blue(5,:), 'markercolor', colors_blue(5,:), 'linecolor', colors_blue(1,:), 'linewidth', 2, 'errorbars', '');
        hold on;
        scatter(results.model_num, results.r_test, 5, 'MarkerFaceColor', colors_blue(2,:), 'MarkerEdgeColor', colors_blue(2,:));
        drawline(noise_ceil,'dir','horz','color',[0.7 0.7 0.7])
        xticklabels(cellfun(@(x) replace(x,'_',' '),model_names,'uniformoutput',false))
        ax = gca(fig);
        ax.XAxis.FontSize = my_font.xlabel;
        ax.YAxis.TickValues = linspace(0, 1, 6);
        ylabel('rho model','FontSize',my_font.ylabel)
        title(['rho with ' replace(measure,'_',' ')], 'FontSize', my_font.title)
        ylim([0,1])

        % plotting model performance within finger groups:
        for i = 2:5
            x = results.model_num;
            y = eval(['results.r_test_n' num2str(i)]);
            z = model_names;
            z(2) = [];
            y(x==2) = [];
            x(x==2) = [];
            x(x>2) = x(x>2)-1;
            % all chords noise ceiling -> leave one out correlation:
            [~,corr_struct] = efc1_analyze('selected_chords_reliability','blocks',blocks,'chords',chords(n==i),'plot_option',0);
            if (strcmp(measure,'mean_dev'))
                noise_ceil = mean(corr_struct.MD);
            elseif (strcmp(measure,'MT'))
                noise_ceil = mean(corr_struct.MT);
            else
                noise_ceil = mean(corr_struct.RT);
            end
            fig = figure('Position',[500 500 400 400]);
            fontsize(fig,my_font.tick_label,"points")
            lineplot(x, y,'markersize', 8, 'markerfill', colors_blue(5,:), 'markercolor', colors_blue(5,:), 'linecolor', colors_blue(1,:), 'linewidth', 2, 'errorbars', '');
            hold on;
            scatter(x, y, 5, 'MarkerFaceColor', colors_blue(2,:), 'MarkerEdgeColor', colors_blue(2,:));
            drawline(noise_ceil,'dir','horz','color',[0.7 0.7 0.7])
            xticklabels(cellfun(@(x) replace(x,'_',' '),z,'uniformoutput',false))
            ylabel('rho','FontSize',my_font.ylabel)
            title(sprintf('num fingers = %d',i),'FontSize',my_font.title)
            ylim([0,1])
        end

        varargout{1} = results;
        varargout{2} = H_across_models;
        varargout{3} = H_model_ceil;

    case 'model_testing_stepwise'
        % handling input args:
        sess = [3 4];
        model_names = {'n_fing','n_fing+n_trans','n_fing+additive','n_fing+2fing_nonadj','n_fing+2fing_adj','n_fing+2fing','n_fing+additive+2fing_adj'};
        chords = generateAllChords;
        measure = 'MD';
        vararginoptions(varargin,{'model_names','sess','chords','measure'})
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        subjects = unique(data.sn);
        n = get_num_active_fingers(chords);

        % getting the values of 'measure':
        values_tmp = eval(['data.' measure]);

        % loop on subjects to make averaged session data:
        for i = 1:length(subjects)
            for j = 1:length(chords)
                values(j,i) = mean(values_tmp(data.chordID==chords(j) & data.sn==subjects(i) & data.sess>=sess(1) & data.sess<=sess(2)));
            end
        end

        % loop on subjects and regression with leave-one-out:
        results = [];
        for i = 1:length(subjects)
            fprintf('running for subj %d/%d out...\n',i,length(subjects))

            % container for regression results:
            tmp = [];

            % loop on models:
            for j = 1:length(model_names)
                names = strsplit(model_names{j},'+');
                
                % making design matrix:
                X = [];
                X{1} = repmat(make_design_matrix(chords,names{1}),length(subjects)-1,1);
                if (length(names)>=2)
                    tmp_model = join(names(2:end),'+');
                    X{2} = repmat(make_design_matrix(chords,tmp_model{1}),length(subjects)-1,1);
                end
                % for k = 1:length(names)
                %     X{k} = repmat(make_design_matrix(chords,names{k}),length(subjects)-1,1);
                % end
                
                % train linear model on subject-out data:
                y = values(:,setdiff(1:length(subjects),i));
                y = y(:);

                % regression:
                [B,STATS] = step_linregress(y, X);
                
                % test model on subject data:
                X_test = make_design_matrix(chords,model_names{j});
                y_pred = X_test*B;
                y_test = values(:,i);

                % storing the regression results:
                tmp.model_name{j,1} = model_names{j};
                tmp.model_num(j,1) = j;
                tmp.sn_out(j,1) = subjects(i);
                tmp.B{j,1} = B;
                tmp.STATS{j,1} = STATS;

                % estimating the model performance:
                % r:
                [r,p] = corrcoef(y_pred,y_test);
                tmp.r_test(j,1) = r(2);
                tmp.p_value(j,1) = p(2);
                % r squared:
                tmp.r2_test(j,1) = 1 - sum((y_pred-y_test).^2) / sum((y_test-mean(y_test)).^2);
                
                % estimating model performance within chord groups:
                for k = 1:5
                    % r:
                    [r,p] = corrcoef(y_pred(n==k),y_test(n==k));
                    % if the model was num_fingers, then calculating r give
                    % nan as the denominator is 0 (which is the var of
                    % y_pred):
                    if strcmp(model_names{j},'n_fing')
                        r = [0 0 ; 0 0];
                        p = [0 0 ; 0 0];
                    end
                    eval(['tmp.r_test_n' num2str(k) '(j,1) = r(2);']);
                    eval(['tmp.p_value_n' num2str(k) '(j,1) = p(2);']);

                    % r squared:
                    tmp_r2 = 1 - sum((y_pred(n==k)-y_test(n==k)).^2) / sum((y_test(n==k)-mean(y_test(n==k))).^2);
                    eval(['tmp.r2_test_n' num2str(k) '(j,1) = tmp_r2;']);
                end
            end
            
            results = addstruct(results,tmp,'row','force');
        end
        
        % all chords noise ceiling -> leave one out correlation:
        [~,corr_struct] = efc1_analyze('selected_chords_reliability','blocks', [(sess(1)-1)*12+1 sess(2)*12],'chords',chords,'plot_option',0);
        if (strcmp(measure,'MD'))
            noise_ceil = mean(corr_struct.MD);
        elseif (strcmp(measure,'MT'))
            noise_ceil = mean(corr_struct.MT);
        else
            noise_ceil = mean(corr_struct.RT);
        end

        % plotting overall model performance:
        fig = figure('Position',[500 500 450 400]);
        fontsize(fig,my_font.tick_label,"points")
        lineplot(results.model_num, results.r_test ,'markersize', 8, 'markerfill', colors_blue(5,:), 'markercolor', colors_blue(5,:), 'linecolor', colors_blue(1,:), 'linewidth', 2, 'errorbars', '');
        hold on;
        scatter(results.model_num, results.r_test, 5, 'MarkerFaceColor', colors_blue(2,:), 'MarkerEdgeColor', colors_blue(2,:));
        drawline(noise_ceil,'dir','horz','color',[0.7 0.7 0.7])
        xticklabels(cellfun(@(x) replace(x,'_',' '),model_names,'uniformoutput',false))
        ax = gca(fig);
        ax.XAxis.FontSize = my_font.xlabel;
        ax.YAxis.TickValues = linspace(0, 1, 6);
        ylabel('rho model','FontSize',my_font.ylabel)
        title(['rho with ' replace(measure,'_',' ')], 'FontSize', my_font.title)
        ylim([0,1])

        % plotting model performance within finger groups:
        for i = 1:5
            x = results.model_num;
            y = eval(['results.r_test_n' num2str(i)]);

            % chords noise ceiling -> leave one out correlation:
            [~,corr_struct] = efc1_analyze('selected_chords_reliability','blocks',[(sess(1)-1)*12+1 sess(2)*12],'chords',chords(n==i),'plot_option',0);
            if (strcmp(measure,'MD'))
                noise_ceil = mean(corr_struct.MD);
            elseif (strcmp(measure,'MT'))
                noise_ceil = mean(corr_struct.MT);
            else
                noise_ceil = mean(corr_struct.RT);
            end

            fig = figure('Position',[500 500 400 400]);
            fontsize(fig,my_font.tick_label,"points")
            lineplot(x, y,'markersize', 8, 'markerfill', colors_blue(5,:), 'markercolor', colors_blue(5,:), 'linecolor', colors_blue(1,:), 'linewidth', 2, 'errorbars', '');
            hold on;
            scatter(x, y, 5, 'MarkerFaceColor', colors_blue(2,:), 'MarkerEdgeColor', colors_blue(2,:));
            drawline(noise_ceil,'dir','horz','color',[0.7 0.7 0.7])
            xticklabels(cellfun(@(x) replace(x,'_',' '),model_names,'uniformoutput',false))
            ylabel('rho','FontSize',my_font.ylabel)
            title(sprintf('num fingers = %d',i),'FontSize',my_font.title)
            ylim([0,1])
        end
        
        varargout{1} = results;


    case 'model_observation'
        % handling input args:
        blocks = [25,48];
        model_names = {'n_fing','n_trans','n_fing+n_trans','additive','n_fing+additive','n_fing+n_trans+additive','neighbour','2fing'};
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
        [~,corr_struct] = efc1_analyze('selected_chords_reliability','blocks',blocks,'chords',chords,'plot_option',0);
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
                    % y_test = y_test-mean(y_test);
                end

                % storing the regression results:
                tmp.model_name{j,1} = model_names{j};
                tmp.model_num(j,1) = j;
                tmp.sn_out(j,1) = subjects(i);
                tmp.B{j,1} = B;
                tmp.stats{j,1} = STATS;
                tmp.pred{j,1} = y_pred;
                tmp.y{j,1} = y_test;

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

        % plots:
        figure;
        for i = 1:length(model_names)
            subplot(1,length(model_names),i)
            pred = cell2mat(results.pred(results.model_num==i)');
            lineplot(n,pred);
            title(replace(model_names{i},'_',' '))
            xlabel('n fingers')
            ylabel(['predicted ' replace(measure,'_',' ')])
        end
    
        figure;
        for i = 1:length(model_names)
            subplot(1,length(model_names),i)
            pred = cell2mat(results.pred(results.model_num==i)');
            y = cell2mat(results.y(results.model_num==i)');
            for j = 1:length(unique(n))
                scatter(pred(n==j,1),y(n==j,1),40,colors_random(j,:),'filled')
                hold on
            end
            title(replace(model_names{i},'_',' '))
            xlabel([replace(measure,'_',' ') ' predicted'])
            ylabel(replace(measure,'_',' '))
        end

        varargout{1} = results;


    case 'model_observation_stepwise'
        % handling input args:
        sess = [3 4];
        model_names = {'n_fing','n_fing+n_trans','n_fing+additive','n_fing+additive+additive','n_fing+additive+n_trans','n_fing+additive+2fing_nonadj','n_fing+additive+2fing_adj','n_fing+additive+2fing'};
        chords = generateAllChords;
        measure = 'MD';
        vararginoptions(varargin,{'model_names','sess','chords','measure'})
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
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
        [~,corr_struct] = efc1_analyze('selected_chords_reliability','blocks',blocks,'chords',chords,'plot_option',0);
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
                    % y_test = y_test-mean(y_test);
                end

                % storing the regression results:
                tmp.model_name{j,1} = model_names{j};
                tmp.model_num(j,1) = j;
                tmp.sn_out(j,1) = subjects(i);
                tmp.B{j,1} = B;
                tmp.stats{j,1} = STATS;
                tmp.pred{j,1} = y_pred;
                tmp.y{j,1} = y_test;

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

        % plots:
        figure;
        for i = 1:length(model_names)
            subplot(1,length(model_names),i)
            pred = cell2mat(results.pred(results.model_num==i)');
            lineplot(n,pred);
            title(replace(model_names{i},'_',' '))
            xlabel('n fingers')
            ylabel(['predicted ' replace(measure,'_',' ')])
        end
    
        figure;
        for i = 1:length(model_names)
            subplot(1,length(model_names),i)
            pred = cell2mat(results.pred(results.model_num==i)');
            y = cell2mat(results.y(results.model_num==i)');
            for j = 1:length(unique(n))
                scatter(pred(n==j,1),y(n==j,1),40,colors_random(j,:),'filled')
                hold on
            end
            title(replace(model_names{i},'_',' '))
            xlabel([replace(measure,'_',' ') ' predicted'])
            ylabel(replace(measure,'_',' '))
        end

        varargout{1} = results;
    
    
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
    

    case 'initial_deviation'
        % chords = generateAllChords;

        data = dload(fullfile(project_path, 'analysis', 'efc1_all.tsv'));
        data = getrow(data, data.trialCorr==1 & data.sess>=3 & data.v_dev1~=-1 & data.num_fingers>=1);
        subjects = unique(data.sn);

        chords = unique(data.chordID);
        
        % Building the regressors and y:
        X1 = zeros(length(data.BN),length(chords));
        X2 = zeros(length(data.BN),length(chords)*length(subjects));
        y = zeros(length(data.BN),5);
        for i = 1:length(data.BN)
            chord_idx = chords==data.chordID(i);
            X1(i,chord_idx) = 1;
            X2(i,(find(subjects==data.sn(i))-1)*length(chords)+find(chord_idx)) = 1;
            y(i,1) = data.v_dev1(i);
            y(i,2) = data.v_dev2(i);
            y(i,3) = data.v_dev3(i);
            y(i,4) = data.v_dev4(i);
            y(i,5) = data.v_dev5(i);
        end

        trial_label = zeros(length(data.BN),1);
        for i = 1:length(subjects)
            for j = 1:length(chords)
                idx = data.sn==subjects(i) & data.chordID==chords(j);
                trial_label(idx) = 1:sum(idx);
            end
        end
        
        labels = [data.sn,data.chordID,trial_label];

        % ====== Regresison:
        [beta,SSR,SST] = myOLS(y,{X1,X2},labels,'shuffle_trial_crossVal');

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
        % y = makeSimData(size(y,1),5,'random',[0,1]);
        % 
        % % ====== Regresison:
        % [beta,SSR,SST] = myOLS(y,{X1,X2},labels,'shuffle_trial_crossVal');
        % 
        % % var explained:
        % chordVar = mean(SSR(:,1)./SST) * 100;
        % subjVar = mean((SSR(:,2) - SSR(:,1))./SST) * 100;
        % trialVar = 100 - (chordVar + subjVar);
        % fprintf("Sim Noisy data:\nChord = %.4f , Chord-Subj = %.4f , Trial = %.4f\n\n\n",chordVar,subjVar,trialVar);

        % pie chart:
        % figure;
        % pie([chordVar,subjVar,trialVar],{'chord','chord-subj','trial-noise'});
        % title(sprintf('Simulation , Random noise'))

        % Model simulation
        % varChord = 5;
        % varSubj = 3;
        % varEps = 1;
        % total = varChord + varSubj + varEps;
        % y = makeSimData(size(y,1),5,'model',{{X1,X2},[varChord,varSubj,varEps]});

        % ====== Regresison:
        % [beta,SSR,SST] = myOLS(y,{X1,X2},labels,'shuffle_trial_crossVal');
        % 
        % % var explained:
        % chordVar = mean(SSR(:,1)./SST) * 100;
        % subjVar = mean((SSR(:,2) - SSR(:,1))./SST) * 100;
        % trialVar = 100 - (chordVar + subjVar);
        % fprintf("Sim Model data:\nChord = %.4f , Chord-Subj = %.4f , Trial = %.4f\n",chordVar,subjVar,trialVar);
        % fprintf("Theoretical Partiotions:\nChord = %.4f , Chord-Subj = %.4f , Trial = %.4f\n\n\n",varChord/total*100,varSubj/total*100,varEps/total*100);

        % pie chart:
        % figure;
        % pie([chordVar,subjVar,trialVar],{'chord','chord-subj','trial-noise'});
        % title(sprintf('Simulation , chord=%.2f , chord-subj=%.2f , noise=%.2f',varChord/total*100,varSubj/total*100,varEps/total*100))

        norm_y = vecnorm(y');
        figure; lineplot(data.sess,norm_y');
        figure; lineplot(data.BN,norm_y');
        figure; scatter(data.MD,norm_y,5,'filled');
        
    case 'visual_complexity'
        chords = generateAllChords;
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        
        symmetries = get_chord_symmetry(chords);
        sess = unique(data.sess);
        subj = unique(data.sn);
        
        C = [];
        cnt = 1;
        for k = 1:length(subj)
            for i = 1:length(sess)
                for j = 1:length(symmetries.chord)
                    C.sn(cnt,1) = subj(k);
                    C.sess(cnt,1) = sess(i);

                    % calculate difference of values of chord symmetries:
                    row = data.sess==sess(i) & data.sn==subj(k);
                    RT_vec = [data.RT(row & data.chordID==symmetries.chord(j)),...
                              data.RT(row & data.chordID==symmetries.chord_vs(j))];
                              % data.RT(row & data.chordID==symmetries.chord_hs(j)),...
                              % data.RT(row & data.chordID==symmetries.chord_vhs(j))];

                    MT_vec = [data.MT(row & data.chordID==symmetries.chord(j)),...
                              data.MT(row & data.chordID==symmetries.chord_vs(j))];
                              % data.MT(row & data.chordID==symmetries.chord_hs(j)),...
                              % data.MT(row & data.chordID==symmetries.chord_vhs(j))];

                    MD_vec = [data.MD(row & data.chordID==symmetries.chord(j)),...
                              data.MD(row & data.chordID==symmetries.chord_vs(j))];
                              % data.MD(row & data.chordID==symmetries.chord_hs(j)),...
                              % data.MD(row & data.chordID==symmetries.chord_vhs(j))];
    
                    subtract_RT = subtract_arr_elements(RT_vec);
                    subtract_MT = subtract_arr_elements(MT_vec);
                    subtract_MD = subtract_arr_elements(MD_vec);
                    
                    % storing the values:
                    C.RT_diff(cnt,:) = subtract_RT;
                    C.MT_diff(cnt,:) = subtract_MT;
                    C.MD_diff(cnt,:) = subtract_MD;
                    cnt = cnt+1;
                end
            end
        end
        
        % PLOT:
        rt = C.RT_diff(C.sess>=3,:);
        rt = rt(:);
        rt(rt==0) = [];
        rt(isnan(rt)) = [];

        mt = C.MT_diff(C.sess>=3,:);
        mt = mt(:);
        mt(mt==0) = [];
        mt(isnan(mt)) = [];

        md = C.MD_diff(C.sess>=3,:);
        md = md(:);
        md(md==0) = [];
        md(isnan(md)) = [];
        
        figure;
        subplot(1,3,1)
        histogram(rt,31);
        subplot(1,3,2)
        histogram(mt,31);
        subplot(1,3,3)
        histogram(md,31);
        
        [t,p]=ttest(rt,[],2,'onesample')
        [t,p]=ttest(mt,[],2,'onesample')
        [t,p]=ttest(md,[],2,'onesample')
        
        figure;
        errorbar(1:3,[mean(rt),mean(mt),mean(md)],[std(rt)/sqrt(length(rt)),mean(mt)/sqrt(length(mt)),mean(md)/sqrt(length(md))]); hold on;
        scatter(1:3,[mean(rt),mean(mt),mean(md)],20,'filled');
        


        varargout{1} = C;


    otherwise
        error('The analysis you entered does not exist!')
end



