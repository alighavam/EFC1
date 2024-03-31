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
colors_green = ['#9bdbb1' ; '#3aa35f' ; '#3aa35f' ; '#2d7d49' ; '#1f5833'];
colors_cyan = ['#adecee' ; '#83e2e5' ; '#2ecfd4' ; '#23a8ac' ; '#1b7e81'];
colors_random = ['#773344' ; '#E3B5A4' ; '#83A0A0' ; '#0B0014' ; '#D44D5C'];

colors_blue = hex2rgb(colors_blue);
colors_green = hex2rgb(colors_green);
colors_cyan = hex2rgb(colors_cyan);
colors_gray = hex2rgb(colors_gray);
colors_random = hex2rgb(colors_random);

colors_measures = [colors_red(3,:) ; colors_cyan(3,:) ; colors_blue(5,:)];

% figure properties:
my_font.xlabel = 10;
my_font.ylabel = 10;
my_font.title = 11;
my_font.tick_label = 8;
my_font.legend = 8;
my_font.conf_tick_label = 32;
my_font.conf_label = 36;
my_font.conf_legend = 32;
my_font.conf_title = 36;

% conference fig settings:
conf.err_width = 3;
conf.line_width = 8;
conf.marker_size = 350;
conf.horz_line_width = 6;
conf.axis_width = 3;

switch (what)
    case 'subject_routine'
        % handling input arguments:
        subject_name = 'subj01';
        smoothing_win_length = 30;
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
            
            diff_force_f1 = zeros(length(tmp_data.BN),1);
            diff_force_f2 = zeros(length(tmp_data.BN),1);
            diff_force_f3 = zeros(length(tmp_data.BN),1);
            diff_force_f4 = zeros(length(tmp_data.BN),1);
            diff_force_f5 = zeros(length(tmp_data.BN),1);

            force_f1 = zeros(length(tmp_data.BN),1);
            force_f2 = zeros(length(tmp_data.BN),1);
            force_f3 = zeros(length(tmp_data.BN),1);
            force_f4 = zeros(length(tmp_data.BN),1);
            force_f5 = zeros(length(tmp_data.BN),1);
            force_e1 = zeros(length(tmp_data.BN),1);
            force_e2 = zeros(length(tmp_data.BN),1);
            force_e3 = zeros(length(tmp_data.BN),1);
            force_e4 = zeros(length(tmp_data.BN),1);
            force_e5 = zeros(length(tmp_data.BN),1);
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
                    
                    % average force:
                    idx_completion = find(tmp_mov{j}(:,1)==3);
                    idx_completion = idx_completion(end);
                    diff_force_f1(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,14));
                    diff_force_f2(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,15));
                    diff_force_f3(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,16));
                    diff_force_f4(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,17));
                    diff_force_f5(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,18));

                    force_f1(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,9));
                    force_f2(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,10));
                    force_f3(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,11));
                    force_f4(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,12));
                    force_f5(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,13));
                    force_e1(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,4));
                    force_e2(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,5));
                    force_e3(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,6));
                    force_e4(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,7));
                    force_e5(j) = mean(tmp_mov{j}(idx_completion-299:idx_completion,8));
                
                % if trial was incorrect:
                else
                    diff_force_f1(j) = -1;
                    diff_force_f2(j) = -1;
                    diff_force_f3(j) = -1;
                    diff_force_f4(j) = -1;
                    diff_force_f5(j) = -1;

                    force_f1(j) = -1;
                    force_f2(j) = -1;
                    force_f3(j) = -1;
                    force_f4(j) = -1;
                    force_f5(j) = -1;
                    force_e1(j) = -1;
                    force_e2(j) = -1;
                    force_e3(j) = -1;
                    force_e4(j) = -1;
                    force_e5(j) = -1;

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

            tmp_data.diff_force_f1 = diff_force_f1;
            tmp_data.diff_force_f2 = diff_force_f2;
            tmp_data.diff_force_f3 = diff_force_f3;
            tmp_data.diff_force_f4 = diff_force_f4;
            tmp_data.diff_force_f5 = diff_force_f5;

            tmp_data.force_f1 = force_f1;
            tmp_data.force_f2 = force_f2;
            tmp_data.force_f3 = force_f3;
            tmp_data.force_f4 = force_f4;
            tmp_data.force_f5 = force_f5;
            tmp_data.force_e1 = force_e1;
            tmp_data.force_e2 = force_e2;
            tmp_data.force_e3 = force_e3;
            tmp_data.force_e4 = force_e4;
            tmp_data.force_e5 = force_e5;
            
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
        
        % handling input args:
        exclude_1st_rep = 0;
        out_file_name = 'efc1_chord.tsv';
        vararginoptions(varargin,{'exclude_1st_rep','out_file_name'})

        % load trial dataframe:
        data = dload(fullfile(project_path, 'analysis', 'efc1_all.tsv'));
        if exclude_1st_rep
            tmp_idx = mod(data.TN,5);
            % removing 1st rep from data:
            data = getrow(data,tmp_idx~=1);
        end

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

                    tmp.diff_force_f1(cnt,1) = mean(data.diff_force_f1(row));
                    tmp.diff_force_f2(cnt,1) = mean(data.diff_force_f2(row));
                    tmp.diff_force_f3(cnt,1) = mean(data.diff_force_f3(row));
                    tmp.diff_force_f4(cnt,1) = mean(data.diff_force_f4(row));
                    tmp.diff_force_f5(cnt,1) = mean(data.diff_force_f5(row));

                    tmp.force_f1(cnt,1) = mean(data.force_f1(row));
                    tmp.force_f2(cnt,1) = mean(data.force_f2(row));
                    tmp.force_f3(cnt,1) = mean(data.force_f3(row));
                    tmp.force_f4(cnt,1) = mean(data.force_f4(row));
                    tmp.force_f5(cnt,1) = mean(data.force_f5(row));
                    tmp.force_e1(cnt,1) = mean(data.force_e1(row));
                    tmp.force_e2(cnt,1) = mean(data.force_e2(row));
                    tmp.force_e3(cnt,1) = mean(data.force_e3(row));
                    tmp.force_e4(cnt,1) = mean(data.force_e4(row));
                    tmp.force_e5(cnt,1) = mean(data.force_e5(row));
                    
                    cnt = cnt+1;
                end
            end
            ANA = addstruct(ANA,tmp,'row','force');
        end
        dsave(fullfile(project_path,'analysis',out_file_name),ANA);

    case 'subject_chords_accuracy'
        conference_fig = 0;
        vararginoptions(varargin,{'conference_fig'})

        chords = generateAllChords;
        data = dload(fullfile(project_path, 'analysis', 'efc1_chord.tsv'));
        subjects = unique(data.sn);
        
        C = [];
        for i = 1:length(subjects)
            % loop on chords:
            acc_tmp = zeros(size(chords));
            for j = 1:length(chords)
                % accuracy of chords:
                acc_tmp(j) = mean(data.accuracy(data.sn==subjects(i) & data.chordID==chords(j)));
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
        
        if ~conference_fig
            fig = figure('Units','centimeters', 'Position',[15 15 5 5]);
            fontsize(fig, my_font.tick_label, 'points')
            drawline(1,'dir','horz','color',[0.7 0.7 0.7],'lim',[0 5]); hold on;
            
            errorbar(1:4,avg_diff,sem_diff,'LineStyle','none','CapSize',0,'Color',colors_blue(5,:)); 
            plot(1:4,avg_diff,'Color',colors_blue(5,:),'LineWidth',2)
            scatter(1:4,avg_diff,30,'MarkerFaceColor',colors_blue(5,:),'MarkerEdgeColor',colors_blue(5,:));
    
            errorbar(1:4,avg_all,sem_all,'LineStyle','none','CapSize',0,'Color',colors_blue(2,:)); 
            plot(1:4,avg_all,'Color',[colors_blue(2,:), 0.6],'LineWidth',3)
            % scatter(1:4,avg_all,30,'MarkerFaceColor',colors_blue(2,:),'MarkerEdgeColor',colors_blue(2,:),'MarkerEdgeAlpha',0,'MarkerFaceAlpha',0.4);
            
            lgd = legend({'','','most challenging','','','all 242'});
            legend boxoff
            fontsize(lgd,6,'points')
    
            ylim([0,1.2])
            xlim([0.8,4.2])
            h = gca;
            h.YAxis.TickValues = 0:0.5:1;
            h.XAxis.TickValues = 1:4;
            h.XAxis.FontSize = my_font.tick_label;
            h.YAxis.FontSize = my_font.tick_label;
            xlabel('days','FontSize',my_font.xlabel)
            ylabel('accuracy','FontSize',my_font.tick_label)
            box off
            fontname("Arial")
        else
            fig = figure('Units','centimeters', 'Position',[15 15 25 15]);
            fontsize(fig, my_font.conf_tick_label, 'points')
            drawline(1,'dir','horz','color',[0.85 0.85 0.85],'lim',[0 5],'linewidth',conf.horz_line_width,'linestyle',':'); hold on;
            
            errorbar(1:4,avg_diff,sem_diff,'LineStyle','none','CapSize',0,'Color',colors_blue(5,:),'LineWidth',conf.err_width); 
            plot(1:4,avg_diff,'Color',colors_blue(5,:),'LineWidth',conf.line_width)
            scatter(1:4,avg_diff,conf.marker_size,'MarkerFaceColor',colors_blue(5,:),'MarkerEdgeColor',colors_blue(5,:));
            
            errorbar(1:4,avg_all,sem_all,'LineStyle','none','CapSize',0,'Color',colors_blue(2,:),'LineWidth',conf.err_width); 
            plot(1:4,avg_all,'Color',[colors_blue(2,:), 0.6],'LineWidth',conf.line_width)
            % scatter(1:4,avg_all,30,'MarkerFaceColor',colors_blue(2,:),'MarkerEdgeColor',colors_blue(2,:),'MarkerEdgeAlpha',0,'MarkerFaceAlpha',0.4);
            
            lgd = legend({'','','Most Challenging Chords','','','All 242 Chords'});
            legend boxoff
            fontsize(lgd,my_font.conf_legend,'points')
            
            ylim([0,1.2])
            xlim([0.8,4.2])
            h = gca;
            h.YAxis.TickValues = 0:0.5:1;
            h.XAxis.TickValues = 1:4;
            h.XAxis.FontSize = my_font.conf_tick_label;
            h.YAxis.FontSize = my_font.conf_tick_label;
            h.LineWidth = conf.axis_width;
            xlabel('days','FontSize',my_font.conf_label)
            ylabel('accuracy','FontSize',my_font.conf_label)
            box off
            fontname("Arial")
        end
        
        varargout{1} = C;
        

    case 'corr_reliability_nfingers'
        chords = generateAllChords;
        measure = 'MD';
        vararginoptions(varargin,{'chords','measure'})

        data = dload(fullfile(project_path, 'analysis', 'efc1_chord.tsv'));

        % getting the values of measure:
        values = eval(['data.' measure]);

        % remove nan values - subjects may have missed all 5 reps:
        nan_idx = isnan(values);
        values(nan_idx) = 0;

        % reliability estimation:
        [c_g, c_gs] = reliability_corr(values(data.sess>=3), data.sn(data.sess>=3), data.sess(data.sess>=3), ...
            'cond_vec', data.num_fingers(data.sess>=3));
        
        % % plot:
        % y = [];
        % figure;
        % ax1 = axes('Units','centimeters', 'Position', [2 2 4.8 5],'Box','off');
        % for i = 1:length(unique(data.num_fingers))
        %     y(i,:) = [c_g{i}/c_gse{i} (c_gs{i}-c_g{i})/c_gse{i} (c_gse{i}-c_gs{i})/c_gse{i}];
        %     b = bar(i,y(i,:),'stacked','FaceColor','flat');
        %     b(1).CData = [238, 146, 106]/255;   % global var
        %     b(2).CData = [36, 168, 255]/255;  % subj var
        %     b(3).CData = [0.8 0.8 0.8];  % noise var
        %     b(1).EdgeColor = [1 1 1];
        %     b(2).EdgeColor = [1 1 1];
        %     b(3).EdgeColor = [1 1 1];
        %     b(1).LineWidth = 1;
        %     b(2).LineWidth = 1;
        %     b(3).LineWidth = 1;
        %     hold on
        % end
        % drawline(1,'dir','horz','color',[0.7 0.7 0.7])
        % drawline(0,'dir','horz','color',[0.7 0.7 0.7])
        % set(gca, 'XTick', 1:5);
        % h = gca;
        % h.YTick = 0:0.2:1;
        % box off;
        % title([measure ' Reliability'],'FontSize',my_font.title)
        % xlabel('num fingers','FontSize',my_font.xlabel)
        % ylabel('correlation','FontSize',my_font.ylabel)
        % legend('global','subject','noise')
        % legend boxoff
        % ylim([-0.1,1.2])
        % 
        % varargout{1} = [c_g, c_gs, c_gse];

    

    case 'behavior_trends'
        measure = 'MD';
        conference_fig = 0;
        vararginoptions(varargin,{'measure','conference_fig'})

        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        subj = unique(data.sn);

        % getting the values of measure:
        values = eval(['data.' measure]);
        
        % calaculating avg improvement from sess 1 to 4:
        C = [];
        for i = 1:length(subj)
            C.sn(i,1) = subj(i);

            % sess 1 and 4 data:
            val1 = mean(values(data.sn==subj(i) & data.sess==1),'omitmissing');
            val4 = mean(values(data.sn==subj(i) & data.sess==4),'omitmissing');

            C.perc_improvement(i,1) = (val1-val4)/val1;
        end
        
        [sem_subj, X_subj, Y_subj, ~] = get_sem(values, data.sn, data.sess, data.num_fingers);
        
        % PLOTS:
        if ~conference_fig
            figure;
            ax1 = axes('Units', 'centimeters', 'Position', [2 2 4.8 5],'Box','off');
            ax1.PositionConstraint = "innerposition";
            axes(ax1);
            for i = 1:5
                errorbar(sem_subj.partitions(sem_subj.cond==i),sem_subj.y(sem_subj.cond==i),sem_subj.sem(sem_subj.cond==i),'LineStyle','none','Color',colors_blue(i,:),'CapSize',0,'LineWidth',1); hold on;
                lineplot(data.sess(data.num_fingers==i & ~isnan(values)),values(data.num_fingers==i & ~isnan(values)),'markertype','o','markersize',3.5,'markerfill',colors_blue(i,:),'markercolor',colors_blue(i,:),'linecolor',colors_blue(i,:),'linewidth',1.5,'errorbars','');
            end
            
            % all avg:
            % [sem_subj, X_subj, Y_subj, ~] = get_sem(values, data.sn, data.sess, ones(size(data.sess)));
            % errorbar(sem_subj.partitions,sem_subj.y,sem_subj.sem,'LineStyle','none','Color',colors_blue(5,:),'CapSize',0); hold on;
            % lineplot(data.sess(~isnan(values)),values(~isnan(values)),'markertype','o','markersize',3.5,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',1.5,'errorbars','');
    
            lgd = legend({'','n=1','','n=2','','n=3','','n=4','','n=5'});
            legend boxoff
            fontsize(lgd,6,'points')
            if measure=='MD'
                ylim([0.5 2.7])
            elseif measure=='RT'
                ylim([150 450])
            elseif measure=='MT'
                ylim([0 2600])
            end
            xlim([0.8 4.2])
            xlabel('days','FontSize',my_font.xlabel)
            ylabel([measure ,' [ms]'],'FontSize',my_font.tick_label)
            % ylabel([measure],'FontSize',my_font.tick_label)
            h = gca;
            h.YTick = linspace(h.YTick(1),h.YTick(end),3);
            h.XAxis.FontSize = my_font.tick_label;
            h.YAxis.FontSize = my_font.tick_label;
            fontname("Arial")
        else
            % figure;
            % ax1 = axes('Units', 'centimeters', 'Position', [0 0 25 25],'Box','off');
            % ax1.PositionConstraint = "innerposition";
            % axes(ax1);
            fig = figure('Units','centimeters', 'Position',[15 15 25 20]);
            for i = 1:5
                errorbar(sem_subj.partitions(sem_subj.cond==i),sem_subj.y(sem_subj.cond==i),sem_subj.sem(sem_subj.cond==i),'LineStyle','none','Color',colors_blue(i,:),'CapSize',0,'LineWidth',conf.err_width); hold on;
                lineplot(data.sess(data.num_fingers==i & ~isnan(values)),values(data.num_fingers==i & ~isnan(values)),'markertype','o','markersize',12,'markerfill',colors_blue(i,:),'markercolor',colors_blue(i,:),'linecolor',colors_blue(i,:),'linewidth',6,'errorbars','');
            end
            
            % all avg:
            % [sem_subj, X_subj, Y_subj, ~] = get_sem(values, data.sn, data.sess, ones(size(data.sess)));
            % errorbar(sem_subj.partitions,sem_subj.y,sem_subj.sem,'LineStyle','none','Color',colors_blue(5,:),'CapSize',0); hold on;
            % lineplot(data.sess(~isnan(values)),values(~isnan(values)),'markertype','o','markersize',3.5,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',1.5,'errorbars','');
    
            lgd = legend({'','n=1','','n=2','','n=3','','n=4','','n=5'});
            legend boxoff
            fontsize(lgd,my_font.conf_legend,'points')
            if measure=='MD'
                ylim([0.5 2.7])
            elseif measure=='RT'
                ylim([150 450])
            elseif measure=='MT'
                ylim([0 2600])
            end
            xlim([0.8 4.2])
            xlabel('days','FontSize',my_font.conf_label)
            ylabel([measure ,' [ms]'],'FontSize',my_font.conf_label)
            % ylabel([measure],'FontSize',my_font.tick_label)
            h = gca;
            h.YTick = linspace(h.YTick(1),h.YTick(end),3);
            h.XAxis.FontSize = my_font.conf_tick_label;
            h.YAxis.FontSize = my_font.conf_tick_label;
            h.LineWidth = conf.axis_width;
            fontname("Arial")
        end
        
        % doing stats:
        idx_exlude_nans = ~isnan(values);
        stats = rm_anova2(values(idx_exlude_nans),data.sn(idx_exlude_nans),data.sess(idx_exlude_nans),data.num_fingers(idx_exlude_nans),{'sess','num_fingers'});
        % T = MANOVA2rp(data.sn(idx_exlude_nans),[data.sess(idx_exlude_nans),data.num_fingers(idx_exlude_nans)],values(idx_exlude_nans));
        
        % percent improvement:
        fprintf('%s improvement from sess 1 to 4:\n    %.4f%% +- %.4f SEM\n',measure, mean(C.perc_improvement)*100, 100*std(C.perc_improvement)/sqrt(length(C.perc_improvement)))
        
        varargout{1} = stats;
        varargout{2} = C;
        
    case 'similarity_of_measures'
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        subj = unique(data.sn);
        sess = unique(data.sess);

        C = [];
        C_total = [];
        cnt = 1;
        for i = 1:length(subj)
            for j = 1:length(sess)
                % correlation without separating num fingers:
                row = data.sn==subj(i) & data.sess==sess(j);
                C_tmp.sn = subj(j);
                C_tmp.sess = sess(j);
                C_tmp.rt_mt = corr(data.RT(row),data.MT(row),'rows','complete');
                C_tmp.rt_md = corr(data.RT(row),data.MD(row),'rows','complete');
                C_tmp.mt_md = corr(data.MT(row),data.MD(row),'rows','complete');
                C_total = addstruct(C_total,C_tmp,'row',1);

                % loop on number of fingers:
                for n = 1:5
                    row = data.sn==subj(i) & data.sess==sess(j) & data.num_fingers==n;
                    % getting the data for each session:
                    rt = data.RT(row);
                    mt = data.MT(row);
                    md = data.MD(row);

                    % correlation of measures within subj:
                    C.sn(cnt,1) = subj(i);
                    C.sess(cnt,1) = sess(j);
                    C.num_fingers(cnt,1) = n;
                    C.rt_mt(cnt,1) = corr(rt,mt,'rows','complete');
                    C.rt_md(cnt,1) = corr(rt,md,'rows','complete');
                    C.mt_md(cnt,1) = corr(mt,md,'rows','complete');
                    cnt = cnt+1;
                end
            end
        end

        % printing values of total corr:
        C_rt_mt = get_sem(C_total.rt_mt, C_total.sn, ones(size(C_total.sn)), ones(size(C_total.sn)));
        C_rt_md = get_sem(C_total.rt_md, C_total.sn, ones(size(C_total.sn)), ones(size(C_total.sn)));
        C_mt_md = get_sem(C_total.mt_md, C_total.sn, ones(size(C_total.sn)), ones(size(C_total.sn)));
        fprintf('total corr(rt,mt) = %.4f\n',C_rt_mt.y);
        fprintf('total corr(rt,md) = %.4f\n',C_rt_md.y);
        fprintf('total corr(mt,md) = %.4f\n',C_mt_md.y);
    
        % getting the summary of data:
        C_rt_mt = get_sem(C.rt_mt, C.sn, ones(size(C.sn)), C.num_fingers);
        C_rt_md = get_sem(C.rt_md, C.sn, ones(size(C.sn)), C.num_fingers);
        C_mt_md = get_sem(C.mt_md, C.sn, ones(size(C.sn)), C.num_fingers);

        C_rt_mt.y
        mean(C_rt_mt.y)
        C_rt_md.y
        mean(C_rt_md.y)
        C_mt_md.y
        mean(C_mt_md.y)

        % PLOT - corr vs num_fingers:
        figure;
        ax1 = axes('Units', 'centimeters', 'Position', [2 2 4.8 5],'Box','off');
        
        drawline(0,'dir','horz','color',[0.7 0.7 0.7],'lim',[0,6]); hold on;

        % plot(1:5, C_rt_mt.y, 'Color', (colors_measures(1,:)+colors_measures(2,:))/2, 'LineWidth', 2);
        % errorbar(1:5, C_rt_mt.y, C_rt_mt.sem, 'LineStyle', 'none', 'CapSize', 0, 'Color', (colors_measures(1,:)+colors_measures(2,:))/2);
        % scatter(1:5, C_rt_mt.y, 15, 'MarkerFaceColor', (colors_measures(1,:)+colors_measures(2,:))/2, 'MarkerEdgeColor', (colors_measures(1,:)+colors_measures(2,:))/2); hold on;

        plot(1:5, C_rt_md.y, 'Color', (colors_measures(1,:)+colors_measures(3,:))/2, 'LineWidth', 2);
        errorbar(1:5, C_rt_md.y, C_rt_md.sem, 'LineStyle', 'none', 'CapSize', 0, 'Color', (colors_measures(1,:)+colors_measures(3,:))/2);
        scatter(1:5, C_rt_md.y, 15, 'MarkerFaceColor', (colors_measures(1,:)+colors_measures(3,:))/2, 'MarkerEdgeColor', (colors_measures(1,:)+colors_measures(3,:))/2);

        % plot(1:5, C_mt_md.y, 'Color', (colors_measures(2,:)+colors_measures(3,:))/2, 'LineWidth', 2);
        % errorbar(1:5, C_mt_md.y, C_mt_md.sem, 'LineStyle', 'none', 'CapSize', 0, 'Color', (colors_measures(2,:)+colors_measures(3,:))/2);
        % scatter(1:5, C_mt_md.y, 15, 'MarkerFaceColor', (colors_measures(2,:)+colors_measures(3,:))/2, 'MarkerEdgeColor', (colors_measures(2,:)+colors_measures(3,:))/2);
        
        % lgd = legend({'','r_{RT,MT}','','','r_{RT,MD}','','','r_{MT,MD}','',''});
        % legend boxoff
        % fontsize(lgd,6,'points')

        ylim([-0.1,1.05])
        xlim([0 6])
        xlabel('finger count','FontSize',my_font.xlabel)
        ylabel('correlation','FontSize',my_font.tick_label)
        h = gca;
        h.YTick = 0:0.25:1;
        h.XTick = 1:5;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        fontname("Arial")

        varargout{1} = C;



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
                tmp.MD(i,1) = mean(data.MD(row));
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
            MD(:,sn) = C.MD(C.sn==subjects(sn));
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
        conference_fig = 0;
        vararginoptions(varargin,{'measure','chords','subjects','conference_fig'})

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
        % cond_vec(cond_vec>1) = 2;
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

        if ~conference_fig
            % avg trend acorss sessions:
            fig = figure('Position', [500 500 190 200]);
            fontsize(fig, my_font.tick_label, 'points')
            
            errorbar(sem_subj.partitions(sem_subj.cond==1),sem_subj.y(sem_subj.cond==1),sem_subj.sem(sem_subj.cond==1),'LineStyle','none','Color',colors_blue(2,:)); hold on;
            lineplot(x(n==conditions(1)),y(n==conditions(1)),'markertype','o','markersize',5,'markerfill',colors_blue(2,:),'markercolor',colors_blue(2,:),'linecolor',colors_blue(2,:),'linewidth',2,'errorbars','');
            hold on
    
            errorbar(sem_subj.partitions(sem_subj.cond==3),sem_subj.y(sem_subj.cond==3),sem_subj.sem(sem_subj.cond==3),'LineStyle','none','Color',colors_blue(3,:))
            lineplot(x(n==conditions(2)),y(n==conditions(2)),'markertype','o','markersize',5,'markerfill',colors_blue(3,:),'markercolor',colors_blue(3,:),'linecolor',colors_blue(3,:),'linewidth',2,'errorbars','');
    
            errorbar(sem_subj.partitions(sem_subj.cond==5),sem_subj.y(sem_subj.cond==5),sem_subj.sem(sem_subj.cond==5),'LineStyle','none','Color',colors_blue(5,:))
            lineplot(x(n==conditions(3)),y(n==conditions(3)),'markertype','o','markersize',5,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',2,'errorbars','');
            
            % scatter(X_subj(COND==1),Y_subj(COND==1),10,'MarkerEdgeColor',colors_blue(1,:),'MarkerFaceColor',colors_blue(1,:))
            % scatter(X_subj(COND==2),Y_subj(COND==2),10,'MarkerEdgeColor',colors_blue(5,:),'MarkerFaceColor',colors_blue(5,:))
    
            legend('','single finger','','chord 3f','','chord 5f');
            legend boxoff
            xlabel('sess','FontSize',my_font.xlabel)
            ylabel([replace(measure,'_',' ')],'FontSize',my_font.title)
            % title([replace(measure,'_',' ')],'FontSize',my_font.title)
            % ylim([0.2 2.7])
            % ylim([0 3500])
            ylim([0 500])
            h = gca;
            h.YTick = linspace(h.YTick(1),h.YTick(end),5);
        else
            % avg trend acorss sessions:
            fig = figure('Units','centimeters', 'Position',[15 15 25 20]);
            fontsize(fig, my_font.conf_tick_label, 'points')
            
            errorbar(sem_subj.partitions(sem_subj.cond==1),sem_subj.y(sem_subj.cond==1),sem_subj.sem(sem_subj.cond==1),'LineStyle','none','Color',colors_blue(2,:),'LineWidth',conf.err_width); hold on;
            lineplot(x(n==conditions(1)),y(n==conditions(1)),'markertype','o','markersize',12,'markerfill',colors_blue(2,:),'markercolor',colors_blue(2,:),'linecolor',colors_blue(2,:),'linewidth',6,'errorbars','');
            hold on
    
            errorbar(sem_subj.partitions(sem_subj.cond==3),sem_subj.y(sem_subj.cond==3),sem_subj.sem(sem_subj.cond==3),'LineStyle','none','Color',colors_blue(3,:),'LineWidth',conf.err_width)
            lineplot(x(n==conditions(2)),y(n==conditions(2)),'markertype','o','markersize',12,'markerfill',colors_blue(3,:),'markercolor',colors_blue(3,:),'linecolor',colors_blue(3,:),'linewidth',6,'errorbars','');
    
            errorbar(sem_subj.partitions(sem_subj.cond==5),sem_subj.y(sem_subj.cond==5),sem_subj.sem(sem_subj.cond==5),'LineStyle','none','Color',colors_blue(5,:),'LineWidth',conf.err_width)
            lineplot(x(n==conditions(3)),y(n==conditions(3)),'markertype','o','markersize',12,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',6,'errorbars','');
            
            % scatter(X_subj(COND==1),Y_subj(COND==1),10,'MarkerEdgeColor',colors_blue(1,:),'MarkerFaceColor',colors_blue(1,:))
            % scatter(X_subj(COND==2),Y_subj(COND==2),10,'MarkerEdgeColor',colors_blue(5,:),'MarkerFaceColor',colors_blue(5,:))
            xlim([0.8 4.2])

            lgd = legend('','1-finger','','3-finger','','5-finger');
            legend boxoff
            fontsize(lgd,my_font.conf_legend,'points')
            xlabel('days','FontSize',my_font.conf_label)
            ylabel([measure ,' [ms]'],'FontSize',my_font.conf_label)

            if measure=='MD'
                ylim([0.2 2.7])
            elseif measure=='RT'
                 ylim([150 450])
            elseif measure=='MT'
                ylim([0 3500])
            end
            h = gca;
            h.YTick = linspace(h.YTick(1),h.YTick(end),3);
            h.XAxis.FontSize = my_font.conf_tick_label;
            h.YAxis.FontSize = my_font.conf_tick_label;
            h.LineWidth = conf.axis_width;
            fontname("Arial")
        end


    case 'var_reliability_overall'
        chords = generateAllChords;
        measure = 'MD';
        centered = 1;
        vararginoptions(varargin,{'chords','measure','centered'})

        data = dload(fullfile(project_path, 'analysis', 'efc1_chord.tsv'));

        % getting the values of measure:
        values = eval(['data.' measure]);

        % remove nan values - subjects may have missed all 5 reps:
        nan_idx = isnan(values);
        values(nan_idx) = 0;

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


    case 'var_reliability_nfingers'
        chords = generateAllChords;
        measure = 'MD';
        centered = 1;
        vararginoptions(varargin,{'chords','measure','centered'})

        data = dload(fullfile(project_path, 'analysis', 'efc1_chord.tsv'));

        % getting the values of measure:
        values = eval(['data.' measure]);

        % remove nan values - subjects may have missed all 5 reps:
        nan_idx = isnan(values);
        values(nan_idx) = 0;
        
        % reliability estimation:
        [v_g, v_gs, v_gse] = reliability_var(values(data.sess>=3), data.sn(data.sess>=3), data.sess(data.sess>=3), ...
            'cond_vec', data.num_fingers(data.sess>=3), 'centered', centered);
        
        % plot:
        y = [];
        figure;
        ax1 = axes('Units','centimeters', 'Position', [2 2 4 4],'Box','off');
        for i = 1:length(unique(data.num_fingers))
            y(i,:) = [v_g{i}/v_gse{i} (v_gs{i}-v_g{i})/v_gse{i} (v_gse{i}-v_gs{i})/v_gse{i}];
            b = bar(i,y(i,:),'stacked','FaceColor','flat','BarWidth',0.8);
            b(1).CData = colors_blue(5,:);   % global var
            b(2).CData = colors_red(3,:);  % subj var
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
        % drawline(0,'dir','horz','color',[0.7 0.7 0.7])
        set(gca, 'XTick', 1:5);
        h = gca;
        h.YTick = 0:0.2:1;
        box off;
        % title([measure ' Reliability'],'FontSize',my_font.title)
        xlabel('finger count','FontSize',my_font.xlabel)
        ylabel('percent variance','FontSize',my_font.ylabel)
        % lgd = legend('global','subject','noise');
        % legend boxoff
        % fontsize(lgd,6,'points')
        ylim([0,1.1])
        xlim([0.3,5.7])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        fontname("Arial")

        varargout{1} = [v_g, v_gs, v_gse];
        
    case 'repetition_effect'
        chords = generateAllChords;
        measure = 'MD';
        subj_selection = [];
        vararginoptions(varargin,{'chords','measure','subj_selection'})
        
        data = dload(fullfile(project_path, 'analysis', 'efc1_all.tsv'));
        data = getrow(data,ismember(data.chordID,chords));
        if ~isempty(subj_selection)
            data = getrow(data,ismember(data.sn,subj_selection));
        end

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
        n_fing_unique = unique(n_fing);
        sess = sess(1,:);
        subj = subj(1,:);
        subj_unique = unique(subj);
        C = [];
        % loop on n_fing:
        cnt = 1;
        for i = 1:length(n_fing_unique)
            % loop on sess:
            for j = 1:length(unique(sess))
                for sn = 1:length(subj_unique)
                    C.num_fingers(cnt,1) = n_fing_unique(i);
                    C.sess(cnt,1) = j;
                    C.sn(cnt,1) = subj_unique(sn);

                    % selecting the data for each session, finger group and
                    % subject:
                    values_tmp = values(:, subj==subj_unique(sn) & n_fing==n_fing_unique(i) & sess==j);
                    C.value_subj(cnt,:) = mean(values_tmp,2,'omitmissing')';

                    % averaging the values across subjects:
                    values_tmp = values(:, n_fing==n_fing_unique(i) & sess==j);
                    C.value(cnt,:) = mean(values_tmp,2,'omitmissing')';
                    
                    % estimating the standard errors:
                    for k = 1:repetitions
                        [sem_tmp, ~, ~, ~] = get_sem( values_tmp(k,:)', subj(n_fing==n_fing_unique(i) & sess==j)', ones(length(values_tmp(k,:)),1), ones(length(values_tmp(k,:)),1) );
                        C.sem(cnt,k) = sem_tmp.sem;
                    end
                    cnt = cnt+1;
                end
            end
        end
        
        % stats, improvement from rep1 to avg of rep2-5:
        stats = [];
        rep_improvement = [];
        for sn = 1:length(subj_unique)
            % values across repetitions for subj sn:
            tmp = C.value_subj(C.sn==subj_unique(sn),:);
            % difference of values from 1st rep to average of rep 2 to 5:
            diff_rep = tmp(:,1) - mean(tmp(:,2:5),2);
            rep_improvement = [rep_improvement ; mean(diff_rep,1)];
        end
        % onesample t-test on rep_improvement:
        % size(rep_improvement)
        [t,p] = ttest(rep_improvement,[],1,'onesample');
        stats.name(1,1) = {'improvement from rep1 to avg of rep2-5'};
        stats.t(1,1) = t;
        stats.p(1,1) = p;
        stats

        % stats, imporovement from rep 2 to 5. rm_anova:
        tmp_data = C.value_subj;
        % removing rep 1:
        tmp_data(:,1) = [];
        % repetitions:
        rep = kron(2:5,ones(size(tmp_data,1),1));
        % subj:
        sn = repmat(C.sn,[1,4]);
        % vectorizing:
        tmp_data = tmp_data(:);
        rep = rep(:);
        sn = sn(:);
        % rm_anova:
        T = MANOVArp(sn,rep,tmp_data);

        % Improvement of measure from sess1 to sess4:
        B = [];
        cnt = 1;
        
        % calculating the benefits within subjects:
        for i = 1:length(subj_unique)
            avg_improvement = 0;
            for j = 1:length(n_fing_unique)
                value_sess1 = C.value_subj(C.sn==subj_unique(i) & C.num_fingers==n_fing_unique(j) & C.sess==1,:);
                value_sess4 = C.value_subj(C.sn==subj_unique(i) & C.num_fingers==n_fing_unique(j) & C.sess==4,:);
                avg_improvement = avg_improvement + (value_sess1 - value_sess4) ./ value_sess1 * 100 /length(subj_unique);
            end
            B.sn(cnt,1) = subj_unique(i);
            % percent improvement:
            B.benefit(cnt,:) = avg_improvement;
            cnt = cnt+1;
        end

        % PLOT - repetition trends across sessions:
        figure;
        ax1 = axes('Units', 'centimeters', 'Position', [2 2 4.8 5],'Box','off');
        offset_size = 5;
        x_offset = 0:offset_size:5*(length(unique(C.sess))-1);
        num_fingers_unique = unique(C.num_fingers);
        for i = 1:length(num_fingers_unique)
            for j = 1:length(unique(C.sess))
                plot((1:5)+x_offset(j), mean(C.value(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1),'Color',colors_blue(num_fingers_unique(i),:),'LineWidth',1); hold on;
                errorbar((1:5)+x_offset(j), mean(C.value(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1), mean(C.sem(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1), 'CapSize', 0, 'Color', colors_blue(num_fingers_unique(i),:));
                scatter((1:5)+x_offset(j), mean(C.value(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1), 10,'MarkerFaceColor',colors_blue(num_fingers_unique(i),:),'MarkerEdgeColor',colors_blue(num_fingers_unique(i),:))
            end
        end
        box off
        h = gca;
        h.YTick = 100:150:650; % RT
        % h.YTick = 0:1000:3000; % MT
        % h.YTick = 0.5:1:2.5; % MD
        h.XTick = 5*(1:length(unique(C.sess))) - 2;
        xlabel('session','FontSize',my_font.xlabel)
        h.XTickLabel = {'1','2','3','4'};
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        ylabel(measure,'FontSize',my_font.ylabel)
        % ylabel([measure ' [ms]'],'FontSize',my_font.ylabel)
        % ylim([0.3 3])
        % ylim([0 2600])
        ylim([0 650])
        xlim([0,21])
        % title('Repetition Effect','FontSize',my_font.title)
        fontname("Arial")

        varargout{1} = C;
        varargout{2} = B;

    case 'repetition_improvement'
        measure_cell = {};
        val_cell = {};
        [val_cell{1},measure_cell{1}] = efc1_analyze('repetition_effect','measure','RT');
        [val_cell{2},measure_cell{2}] = efc1_analyze('repetition_effect','measure','MT');
        [val_cell{3},measure_cell{3}] = efc1_analyze('repetition_effect','measure','MD');
        close all;
        clc;

        % PLOT - Improvement from sess1 to sess4:
        figure;
        ax1 = axes('Units', 'centimeters', 'Position', [2 2 4.8 5],'Box','off');
        
        drawline(0,'dir','horz','color',[0.7 0.7 0.7],'lim',[0,6]); hold on;
        for i = 1:3
            B = measure_cell{i};

            % getting subj averages and SEMs for each repetition:
            sem_1 = get_sem(B.benefit(:,1), B.sn, ones(size(B.sn)), ones(size(B.sn)));
            sem_2 = get_sem(B.benefit(:,2), B.sn, ones(size(B.sn)), ones(size(B.sn)));
            sem_3 = get_sem(B.benefit(:,3), B.sn, ones(size(B.sn)), ones(size(B.sn)));
            sem_4 = get_sem(B.benefit(:,4), B.sn, ones(size(B.sn)), ones(size(B.sn)));
            sem_5 = get_sem(B.benefit(:,5), B.sn, ones(size(B.sn)), ones(size(B.sn)));
            
            plot(1:5,[sem_1.y sem_2.y sem_3.y sem_4.y sem_5.y],'LineWidth',1,'Color',colors_measures(i,:));
            errorbar(1:5,[sem_1.y sem_2.y sem_3.y sem_4.y sem_5.y],[sem_1.sem sem_2.sem sem_3.sem sem_4.sem sem_5.sem],'CapSize',0,'Color',colors_measures(i,:)); 
            scatter(1:5,[sem_1.y sem_2.y sem_3.y sem_4.y sem_5.y],15,'filled','MarkerFaceColor',colors_measures(i,:),'MarkerEdgeColor',colors_measures(i,:))
        end
        box off
        h = gca;
        h.YTick = 0:25:100;
        h.XTick = 1:5;
        lgd = legend({'','RT','','','MT','','','MD','',''});
        legend boxoff
        fontsize(lgd,6,'points')
        xlabel('repetition','FontSize',my_font.xlabel)
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        ylabel('% Improvement day 1-4','FontSize',my_font.ylabel)
        ylim([-20, 55])
        xlim([0,6])
        % title('Repetition Effect','FontSize',my_font.title)
        fontname("Arial")

        % two-way rm_anova for (first repetition, session, num finger):
        for i = 1:3
            C = val_cell{i};
            fprintf("rm_anova for (first repetition, session, num finger):\n")
            stats = rm_anova2(C.value_subj(:,1),C.sn,C.sess,C.num_fingers,{'session','num_finger'})
        end

        % stats - ttest for benefit of repetition from sess1 to sess4:
        stats_benefit = [];
        cnt = 1;
        for i = 1:3
            B = measure_cell{i};

            % ttest for each repetition from 0:
            for j = 1:5
                [t,p] = ttest(B.benefit(:,j),[],1,'onesample');
                stats_benefit.measure(cnt,1) = i;
                stats_benefit.rep(cnt,1) = j;
                stats_benefit.t(cnt,1) = t;
                stats_benefit.p(cnt,1) = p;
                cnt = cnt+1;
            end
        end
        varargout{1} = stats_benefit;

        
    
    
    case 'model_testing'
        % handling input arguments:
        chords = generateAllChords;
        sess = [3,4];
        measure = 'MD';
        model_names = {'transition','additive','symmetries','additive+2fing_adj','additive+2fing'};
        vararginoptions(varargin,{'chords','sess','measure','model_names'})

        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        subj = unique(data.sn);
        n = get_num_active_fingers(chords);
        
        % getting the values of measure:
        values_tmp = eval(['data.' measure]);
        
        % getting the average of sessions for every subj:
        values = zeros(length(chords),length(subj));
        for i = 1:length(subj)
            % avg with considering nan values since subjects might have
            % missed all 5 repetitions in one session:
            values(:,i) = mean([values_tmp(data.sess==sess(1) & data.sn==subj(i)),values_tmp(data.sess==sess(2) & data.sn==subj(i))],2,'omitmissing');
        end
        
        % loop on num_fingers:
        C = [];
        for i = 1:5
            % loop on subjects and regression with leave-one-out:
            for sn = 1:length(subj)
                % values of 'not-out' subjects for chords with n=i , Nx1 vector:
                y_train = values(n==i,setdiff(1:length(subj),sn));
                y_train = y_train(:);

                % avg of 'out' subject:
                y_test = values(n==i,sn);

                % loop on models to be tested:
                for i_mdl = 1:length(model_names)
                    % getting design matrix for model:
                    X = make_design_matrix(repmat(chords(n==i),length(subj)-1,1),model_names{i_mdl});

                    % check design matrix's Rank:
                    is_full_rank = rank(X) == size(X,2);
                    
                    % training the model:
                    % [B,STATS] = linregress(y_train,X,'intercept',0);
                    [B,STATS] = svd_linregress(y_train,X);

                    % testing the model:
                    X_test = make_design_matrix(chords(n==i),model_names{i_mdl});
                    y_pred = X_test * B;
                    r = corr(y_pred,y_test);
                    SSR = sum((y_pred-y_test).^2);
                    SST = sum((y_test-mean(y_test)).^2);
                    r2 = 1 - SSR/SST;

                    % storing the results:
                    C_tmp.num_fingers = i;
                    C_tmp.sn_out = sn;
                    C_tmp.model = model_names(i_mdl);
                    C_tmp.is_full_rank = is_full_rank;
                    C_tmp.B = {B};
                    C_tmp.stats = {STATS};
                    C_tmp.r = r;
                    C_tmp.r2 = r2;

                    C = addstruct(C,C_tmp,'row',1);
                end
            end
        end

        % stats between models:
        stats = [];
        for num_f = 1:5
            for i = 1:length(model_names)-1
                r1 = C.r(C.num_fingers==num_f & strcmp(C.model,model_names{i}));
                for j = i+1:length(model_names)
                    r2 = C.r(C.num_fingers==num_f & strcmp(C.model,model_names{j}));
                    % paired t-test, one-tail r2>r1:
                    [t,p] = ttest(r2,r1,1,'paired');
                    tmp.num_fingers = num_f;
                    tmp.models = {model_names{i},model_names{j}};
                    tmp.t = t;
                    tmp.p = p;
                    stats = addstruct(stats,tmp,'row',1);
                end
            end
        end

        % PLOT - regression results:
        % loop on num fingers:
        for i = 2:5
            % getting noise ceiling:
            [~,corr_struct] = efc1_analyze('selected_chords_reliability','blocks',[(sess(1)-1)*12+1 sess(2)*12],'chords',chords(n==i),'plot_option',0);
            if (strcmp(measure,'MD'))
                noise_ceil = mean(corr_struct.MD);
            elseif (strcmp(measure,'MT'))
                noise_ceil = mean(corr_struct.MT);
            else
                noise_ceil = mean(corr_struct.RT);
            end

            figure;
            ax1 = axes('Units', 'centimeters', 'Position', [2 2 3.5 3],'Box','off');
            for j = 1:length(model_names)
                % getting cross validated r:
                r = C.r(C.num_fingers==i & strcmp(C.model,model_names{j}));
                
                r_avg(j) = mean(r);
                r_sem(j) = std(r)/sqrt(length(r));
            end
            drawline(noise_ceil,'dir','horz','color',[0.7 0.7 0.7],'lim',[0,length(model_names)+1],'linestyle',':'); hold on;
            plot(1:length(model_names),r_avg,'LineWidth',2,'Color',[0.1 0.1 0.1,0.1]);
            errorbar(1:length(model_names),r_avg,r_sem,'LineStyle','none','Color',[0.1 0.1 0.1],'CapSize',0)
            scatter(1:length(model_names),r_avg,20,'filled','MarkerFaceColor',[0.1 0.1 0.1],'MarkerEdgeColor',[0.1 0.1 0.1]);
            box off
            h = gca;
            h.YTick = 0:0.25:1;
            h.XTick = 1:length(model_names);
            % xlabel('model','FontSize',my_font.xlabel)
            h.XTickLabel = cellfun(@(x) replace(x,'_',' '),model_names,'uniformoutput',false);
            h.XAxis.FontSize = my_font.tick_label;
            h.YAxis.FontSize = my_font.tick_label;
            ylabel('r','FontSize',my_font.ylabel)
            ylim([0, 1.05])
            xlim([0.5,length(model_names)+0.5])
            title(['n = ',num2str(i)],'FontSize',my_font.tick_label)
            fontname("Arial")
        end
        
        varargout{1} = C;
        varargout{2} = stats;

    case 'model_testing_all'
        % handling input arguments:
        chords = generateAllChords;
        sess = [3,4];
        measure = 'MD';
        model_names = {'n_fing','n_fing+additive','n_fing+force_avg','n_fing+2fing','n_fing+force_2fing','n_fing+additive+2fing','n_fing+force_avg+force_2fing'};
        vararginoptions(varargin,{'chords','sess','measure','model_names'})
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        data = getrow(data,ismember(data.chordID,chords));
        chords = data.chordID(data.sn==1 & data.sess==1);
        subj = unique(data.sn);
        
        % getting the values of measure:
        values_tmp = eval(['data.' measure]);
        
        % getting the average of sessions for every subj:
        values = zeros(length(chords),length(subj));
        for i = 1:length(subj)
            % avg with considering nan values since subjects might have
            % missed all 5 repetitions in one session:
            values(:,i) = mean([values_tmp(data.sess==sess(1) & data.sn==subj(i)),values_tmp(data.sess==sess(2) & data.sn==subj(i))],2,'omitmissing');
        end

        % modelling the difficulty for all chords.
        C = [];
        % loop on subjects and regression with leave-one-out:
        for sn = 1:length(subj)
            % values of 'not-out' subjects, Nx1 vector:
            y_train = values(:,setdiff(1:length(subj),sn));
            y_train = y_train(:);

            % avg of 'out' subject:
            y_test = values(:,sn);

            % loop on models to be tested:
            for i_mdl = 1:length(model_names)
                % getting design matrix for model:
                X = make_design_matrix(repmat(chords,length(subj)-1,1),model_names{i_mdl});

                % check design matrix's Rank:
                is_full_rank = rank(X) == size(X,2);

                % training the model:
                % [B,STATS] = linregress(y_train,X,'intercept',0);
                [B,STATS] = svd_linregress(y_train,X);

                % testing the model:
                X_test = make_design_matrix(chords,model_names{i_mdl});
                y_pred = X_test * B;
                r = corr(y_pred,y_test);
                SSR = sum((y_pred-y_test).^2);
                SST = sum((y_test-mean(y_test)).^2);
                r2 = 1 - SSR/SST;

                % storing the results:
                C_tmp.sn_out = sn;
                C_tmp.model = model_names(i_mdl);
                C_tmp.is_full_rank = is_full_rank;
                C_tmp.B = {B};
                C_tmp.stats = {STATS};
                C_tmp.r = r;
                C_tmp.r2 = r2;

                C = addstruct(C,C_tmp,'row',1);
            end
        end
        
        % stats between models:
        stats = [];
        for i = 1:length(model_names)-1
            r1 = C.r(strcmp(C.model,model_names{i}));
            for j = i+1:length(model_names)
                r2 = C.r(strcmp(C.model,model_names{j}));
                % paired t-test, one-tail r2>r1:
                [t,p] = ttest(r2,r1,1,'paired');
                tmp.models = {model_names{i},model_names{j}};
                tmp.t = t;
                tmp.p = p;
                stats = addstruct(stats,tmp,'row',1);
            end
        end


        % getting noise ceiling:
        [~,corr_struct] = efc1_analyze('selected_chords_reliability','blocks',[(sess(1)-1)*12+1 sess(2)*12],'chords',chords,'plot_option',0);
        if (strcmp(measure,'MD'))
            noise_ceil = mean(corr_struct.MD);
        elseif (strcmp(measure,'MT'))
            noise_ceil = mean(corr_struct.MT);
        else
            noise_ceil = mean(corr_struct.RT);
        end

        for i = 1:length(model_names)
            r = C.r(strcmp(C.model,model_names{i}));
            fprintf('ttest: model %s different from noise ceiling:\n',model_names{i})
            ttest(r-noise_ceil,[],2,'onesample')
        end

        % PLOT - regression results:
        figure;
        ax1 = axes('Units', 'centimeters', 'Position', [2 2 3.5 3],'Box','off');
        for j = 1:length(model_names)
            % getting cross validated r:
            r = C.r(strcmp(C.model,model_names{j}));
            
            r_avg(j) = mean(r);
            r_sem(j) = std(r)/sqrt(length(r));
        end
        drawline(noise_ceil,'dir','horz','color',[0.7 0.7 0.7],'lim',[0,length(model_names)+1],'linestyle',':'); hold on;
        plot(1:length(model_names),r_avg,'LineWidth',2,'Color',[0.1 0.1 0.1,0.1]);
        errorbar(1:length(model_names),r_avg,r_sem,'LineStyle','none','Color',[0.1 0.1 0.1],'CapSize',0)
        scatter(1:length(model_names),r_avg,15,'filled','MarkerFaceColor',[0.1 0.1 0.1],'MarkerEdgeColor',[0.1 0.1 0.1]);
        box off
        h = gca;
        h.YTick = 0:0.25:1;
        h.XTick = 1:length(model_names);
        h.XTickLabel = cellfun(@(x) replace(x,'_',' '),model_names,'uniformoutput',false);
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        ylabel('r','FontSize',my_font.ylabel)
        ylim([0, 1.05])
        xlim([0.5,length(model_names)+0.5])
        fontname("Arial")

        varargout{1} = C;
        varargout{2} = stats;


    case 'model_testing_avg_values'
        % handling input args:
        blocks = [25,48];
        model_names = {'n_trans','n_fing','additive'};
        chords = generateAllChords;
        measure = 'MD';
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
        if (strcmp(measure,'MD'))
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
        model_names = {'n_fing','n_fing+n_trans','n_fing+additive','n_fing+2fing_nonadj','n_fing+2fing_adj','n_fing+2fing'};
        chords = generateAllChords;
        measure = 'MD';
        vararginoptions(varargin,{'model_names','sess','chords','measure'})
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        subjects = unique(data.sn);
        n = get_num_active_fingers(chords);

        % getting the values of 'measure':
        values_tmp = eval(['data.' measure]);

        % remove nan values - subjects may have missed all 5 reps:
        nan_idx = isnan(values_tmp);
        values_tmp(nan_idx) = [];
        data = getrow(data,~nan_idx);

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
        measure = 'RT';
        sess = [3,4];
        vararginoptions(varargin,{'chords','measure','sess'})

        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        subj = unique(data.sn);
        n = get_num_active_fingers(chords);
        
        vs = get_chord_symmetry(chords,'vert');
        hs = get_chord_symmetry(chords,'horz');
        
        % getting the values of measure:
        values_tmp = eval(['data.' measure]);

        % getting the average of sessions for every subj:
        values = zeros(length(chords),length(subj));
        for i = 1:length(subj)
            % avg while considering nan values since subjects might have
            % missed all 5 repetitions in one session:
            values(:,i) = mean([values_tmp(data.sess==sess(1) & data.sn==subj(i)),values_tmp(data.sess==sess(2) & data.sn==subj(i))],2,'omitmissing');
        end
        
        % loop on subj:
        C = [];
        % loop on num fingers:
        for i = 1:5
            % doing a subj out cross validation:
            for sn = 1:length(subj)
                % "out" subjet data:
                y1_out_vs = values(n==i & ismember(chords,vs.chord),sn);
                y2_out_vs = values(n==i & ismember(chords,vs.chord_vs),sn);

                y1_out_hs = values(n==i & ismember(chords,hs.chord),sn);
                y2_out_hs = values(n==i & ismember(chords,hs.chord_hs),sn);
                
                % avg of "in" subjects data: 
                y1_in_vs = mean(values(n==i & ismember(chords,vs.chord),setdiff(1:length(subj),sn)),2);
                y2_in_vs = mean(values(n==i & ismember(chords,vs.chord_vs),setdiff(1:length(subj),sn)),2);

                y1_in_hs = mean(values(n==i & ismember(chords,hs.chord),setdiff(1:length(subj),sn)),2);
                y2_in_hs = mean(values(n==i & ismember(chords,hs.chord_hs),setdiff(1:length(subj),sn)),2);

                % estimating correlations:
                corr_ch_vs = corr(y1_out_vs,y2_in_vs);
                corr_vs_ch = corr(y2_out_vs,y1_in_vs);
                corr_ch_hs = corr(y1_out_hs,y2_in_hs);
                corr_hs_ch = corr(y2_out_hs,y1_in_hs);
                
                % storing values:
                C_tmp.num_fingers = i;
                C_tmp.sn_out = subj(sn);
                C_tmp.corr_vs = (corr_ch_vs + corr_vs_ch)/2;
                C_tmp.corr_hs = (corr_ch_hs + corr_hs_ch)/2;
                
                C = addstruct(C,C_tmp,'row',1);
            end
        end
        [mean(C.corr_vs(C.num_fingers==2)), mean(C.corr_vs(C.num_fingers==3)), mean(C.corr_vs(C.num_fingers==4)), mean(C.corr_vs(C.num_fingers==5))]
        [mean(C.corr_hs(C.num_fingers==2)), mean(C.corr_hs(C.num_fingers==3)), mean(C.corr_hs(C.num_fingers==4)), mean(C.corr_hs(C.num_fingers==5))]
        
        fprintf('corr_vert = %.4f\ncorr_horz = %.4f\n',mean(C.corr_vs),mean(C.corr_hs))
        varargout{1} = C;

    case 'chord_selection'
        sess = [3,4];
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        chords = data.chordID(data.sess==sess(1) & data.sn==1);
        subj = unique(data.sn);
        n = data.num_fingers(data.sess==sess(1) & data.sn==1);
        values_tmp = data.MD;
        
        % getting the average of sessions for every subj:
        values = zeros(length(chords),length(subj));
        for i = 1:length(subj)
            % avg with considering nan values since subjects might have
            % missed all 5 repetitions in one session:
            values(:,i) = mean([values_tmp(data.sess==sess(1) & data.sn==subj(i)),values_tmp(data.sess==sess(2) & data.sn==subj(i))],2,'omitmissing');
        end
        
        
        C = [];
        for i = 2:5
            for j = 1:length(subj)
                [~,idx] = sort(values(n==i,j));
                chords_tmp = chords(n==i);
                chords_tmp = chords_tmp(idx);

                C_tmp.num_fingers = i;
                C_tmp.sn = subj(j);
                % first 1/3:
                C_tmp.easy = chords_tmp(1:floor(length(chords_tmp)/3));
                % second 1/3:
                C_tmp.med = chords_tmp(ceil(length(chords_tmp)/3):floor(length(chords_tmp)*2/3));
                % third 1/3:
                C_tmp.diff = chords_tmp(ceil(length(chords_tmp)*2/3):end);

                C = addstruct(C,C_tmp,'row',1);
            end
        end


        % sorting out the chords for selection:
        easy_chords = unique(C.easy);
        med_chords = unique(C.med);
        diff_chords = unique(C.diff);

        count_easy = zeros(length(easy_chords),1);
        for i = 1:length(easy_chords)
            count_easy(i,1) = sum(C.easy == easy_chords(i))/length(subj)*100;
        end
        [sorted,idx] = sort(count_easy,'descend');
        count_easy = sorted;
        easy_chords = easy_chords(idx);

        count_med = zeros(length(med_chords),1);
        for i = 1:length(med_chords)
            count_med(i,1) = sum(C.med == med_chords(i))/length(subj)*100;
        end
        [sorted,idx] = sort(count_med,'descend');
        count_med = sorted;
        med_chords = med_chords(idx);

        count_diff = zeros(length(diff_chords),1);
        for i = 1:length(diff_chords)
            count_diff(i,1) = sum(C.diff == diff_chords(i))/length(subj)*100;
        end
        [sorted,idx] = sort(count_diff,'descend');
        count_diff = sorted;
        diff_chords = diff_chords(idx);

        % chord groups:
        easy = [easy_chords,count_easy,get_num_active_fingers(easy_chords)];
        med = [med_chords,count_med,get_num_active_fingers(med_chords)];
        difficult = [diff_chords,count_diff,get_num_active_fingers(diff_chords)];

        % chord selection for EMG natChord experiment:
        single_finger = [chords(n==1), zeros(size(chords(n==1))), ones(size(chords(n==1))), -1*ones(size(chords(n==1)))];

        % easy chords:
        selected_easy_3f = easy(easy(:,3)==3,:);
        selected_easy_3f = [selected_easy_3f(1:10,1), ones(10,1), 3*ones(10,1),selected_easy_3f(1:10,2)];

        selected_easy_5f = easy(easy(:,3)==5,:);
        selected_easy_5f = [selected_easy_5f(1:10,1), ones(10,1), 5*ones(10,1),selected_easy_5f(1:10,2)];

        % medium chords:
        selected_med_3f = med(med(:,3)==3,:);
        selected_med_3f = [selected_med_3f(1:10,1), 2*ones(10,1), 3*ones(10,1),selected_med_3f(1:10,2)];

        selected_med_5f = med(med(:,3)==5,:);
        selected_med_5f = [selected_med_5f(1:10,1), 2*ones(10,1), 5*ones(10,1),selected_med_5f(1:10,2)];

        % difficult chords:
        selected_diff_3f = difficult(difficult(:,3)==3,:);
        selected_diff_3f = [selected_diff_3f(1:10,1), 3*ones(10,1), 3*ones(10,1),selected_diff_3f(1:10,2)];

        selected_diff_5f = difficult(difficult(:,3)==5,:);
        selected_diff_5f = [selected_diff_5f(1:10,1) , 3*ones(10,1), 5*ones(10,1),selected_diff_5f(1:10,2)];

        chords = [single_finger ; selected_easy_3f ; selected_easy_5f ; selected_med_3f ; selected_med_5f ; ...
                  selected_diff_3f ; selected_diff_5f];

        varargout{1} = chords;
        varargout{2} = easy;
        varargout{3} = med;
        varargout{4} = difficult;

    case 'forward_selection'
        % handling input arguments:
        alpha = 0.05;
        measure = 'MD';
        sess = [3,4];
        models = {'n_fing','n_fing+additive','n_fing+2fing_adj','n_fing+2fing','n_fing+force_avg','n_fing+force_2fing'};
        vararginoptions(varargin,{'alpha','measure','models','sess'})
        base_models = models;
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        chords = data.chordID(data.sn==1 & data.sess==4);
        subj = unique(data.sn);
        
        % getting the values of measure:
        values_tmp = eval(['data.' measure]);

        % getting the average of sessions for every subj:
        values = zeros(length(chords),length(subj));
        for i = 1:length(subj)
            % avg with considering nan values since subjects might have
            % missed all 5 repetitions in one session:
            values(:,i) = mean([values_tmp(data.sess==sess(1) & data.sn==subj(i)),values_tmp(data.sess==sess(2) & data.sn==subj(i))],2,'omitmissing');
        end
        
        % selection steps:
        steps = length(models);
        winning_model = '';
        best_r = zeros(length(subj),1);
        C = [];
        for i = 1:steps
            for j = 1:length(models)
                r = zeros(length(subj),1);
                % loop on subjects and regression with leave-one-out:
                for sn = 1:length(subj)
                    % values of 'in' subjects, Nx1 vector:
                    y_train = values(:,setdiff(1:length(subj),sn));
                    y_train = mean(y_train,2);
        
                    % avg of 'out' subject:
                    y_test = values(:,sn);

                    % getting design matrix for model:
                    X = make_design_matrix(chords,models{j});
    
                    % training the model:
                    % [B,STATS] = linregress(y_train,X,'intercept',0);
                    [B,~] = svd_linregress(y_train,X);
    
                    % testing the model:
                    X_test = make_design_matrix(chords,models{j});
                    y_pred = X_test * B;
                    r(sn) = corr(y_pred,y_test);
                end
                tmp.step = i;
                tmp.model = models(j);
                tmp.r = {r};
                tmp.r_avg = mean(r);
                [~,tmp.pval] = ttest(r,best_r,1,'paired');
                tmp.significant = tmp.pval < alpha;

                % initialize this variable for later steps:
                tmp.win = 0;

                % save values in struct:
                C = addstruct(C,tmp,'row','force');
            end

            % competition between models:
            r_avg = C.r_avg(C.step==i);
            p_val = C.pval(C.step==i);

            % find the significant improvements:
            p_val = p_val < alpha;
            
            % if there was at least one significantly better model:
            if sum(p_val)~=0
                % remove the non-significant models from the comptetition:
                r_avg(p_val==0) = 0;
            end
            
            % find the best (significant) model:
            [~,idx] = sort(r_avg);
            
            % conclude the winner and give it a gold medal:
            winning_model = models{idx(end)};
            C.win(C.step==i & strcmp(C.model,winning_model)) = 1;
            % set the competition values for the next step:
            best_r = C.r{C.step==i & strcmp(C.model,winning_model)};

            % make models for the next step:
            models = base_models;
            split_names = strsplit(winning_model,'+');
            for j = 1:length(split_names)
                models(strcmp(models,split_names{j})) = [];
            end
            prefix = [winning_model , '+'];
            models = cellfun(@(x) [prefix x], models, 'UniformOutput', false);
        end
        
        % fing the significant winner:
        significant_steps = zeros(length(unique(C.step)),1);
        for i = 1:length(unique(C.step))
            significant = C.significant(C.step==i);
            if sum(significant)
                significant_steps(i) = 1;
            end
        end
        idx = find(significant_steps);
        idx = idx(end);
        significant_winner = C.model{C.step==idx & C.win==1};

        fprintf('\nThe significant winner of the forward selection is:\n%s\n',significant_winner)
        fprintf('\nThe r_avg winner of forward selection is:\n%s\n',winning_model);
        varargout{1} = C;

    case 'backward_selection'
        % handling input arguments:
        alpha = 0.05;
        measure = 'MD';
        sess = [3,4];
        models = {'n_fing','additive','2fing_adj','2fing','force_avg','force_2fing'};
        vararginoptions(varargin,{'alpha','measure','models','sess'})
        base_models = models;
        
        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        chords = data.chordID(data.sn==1 & data.sess==4);
        subj = unique(data.sn);
        
        % getting the values of measure:
        values_tmp = eval(['data.' measure]);
        
        % getting the average of sessions for every subj:
        values = zeros(length(chords),length(subj));
        for i = 1:length(subj)
            % avg with considering nan values since subjects might have
            % missed all 5 repetitions in one session:
            values(:,i) = mean([values_tmp(data.sess==sess(1) & data.sn==subj(i)),values_tmp(data.sess==sess(2) & data.sn==subj(i))],2,'omitmissing');
        end
        
        % full model:
        for i = 1:length(base_models)
            full_model = strjoin(base_models, '+');
        end
        
        best_r = zeros(length(subj),1);
        % loop on subjects and regression with leave-one-out:
        for sn = 1:length(subj)
            % values of 'in' subjects, Nx1 vector:
            y_train = values(:,setdiff(1:length(subj),sn));
            y_train = mean(y_train,2);

            % avg of 'out' subject:
            y_test = values(:,sn);

            % getting design matrix for model:
            X = make_design_matrix(chords,full_model);

            % training the model:
            % [B,STATS] = linregress(y_train,X,'intercept',0);
            [B,~] = svd_linregress(y_train,X);

            % testing the model:
            X_test = make_design_matrix(chords,full_model);
            y_pred = X_test * B;
            best_r(sn) = corr(y_pred,y_test);
        end
        
        % selection steps:
        steps = length(models)-1;

        % define models for the first step:
        winning_model = full_model;
        
        C = [];
        for i = 1:steps
            % define models to be removed for the current step:
            reduce_models = strsplit(winning_model,'+');
            
            for j = 1:length(reduce_models)
                model = reduce_models;
                model(strcmp(model,reduce_models{j})) = [];
                model = strjoin(model,'+');

                r = zeros(length(subj),1);
                % loop on subjects and regression with leave-one-out:
                for sn = 1:length(subj)
                    % values of 'in' subjects, Nx1 vector:
                    y_train = values(:,setdiff(1:length(subj),sn));
                    y_train = mean(y_train,2);
        
                    % avg of 'out' subject:
                    y_test = values(:,sn);

                    % getting design matrix for model:
                    X = make_design_matrix(chords,model);
    
                    % training the model:
                    % [B,STATS] = linregress(y_train,X,'intercept',0);
                    [B,~] = svd_linregress(y_train,X);
    
                    % testing the model:
                    X_test = make_design_matrix(chords,model);
                    y_pred = X_test * B;
                    r(sn) = corr(y_pred,y_test);
                end
                tmp.step = i;
                tmp.model = {model};
                tmp.r = {r};
                tmp.r_avg = mean(r);
                [~,tmp.pval] = ttest(best_r,r,1,'paired');
                tmp.significantly_worse = tmp.pval < alpha; % this is 1 if the reduced model is significantly worse than the starting model
                tmp.win = 0;

                if tmp.significantly_worse == 0
                    tmp.fail = 1;   % the reduced model fails if it does not significantly reduce performance
                end
                
                % save values in struct:
                C = addstruct(C,tmp,'row','force');
            end

            % conclude the step and choose a winning model for the next step:
            r_avg = C.r_avg(C.step==i);
            fail = C.fail(C.step==i);
            
            % if there was at least one significantly worse model:
            if sum(fail) ~= length(fail)
                % remove the good models from the competition
                r_avg(fail==0) = 0;
            end
            
            % sort the reduction of performance after removing each model:
            [~,idx] = sort(mean(best_r)-r_avg);

            % conclude the not-loser(winner?) and give it a gold medal:
            tmp_models = C.model(C.step==i);
            winning_model = tmp_models{idx(1)};
            C.win(C.step==i & strcmp(C.model,winning_model)) = 1;
            
            % set the competition values for the next step:
            best_r = C.r{C.step==i & strcmp(C.model,winning_model)};
        end
        
        % find the significant winner:
        % significant_winner = '';
        % significant_steps = zeros(length(unique(C.step)),1);
        % for i = 1:length(unique(C.step))
        %     significant = C.significant(C.step==i);
        %     if sum(significant)
        %         significant_steps(i) = 1;
        %     end
        % end
        % idx = find(significant_steps);
        % idx = idx(end);
        % significant_winner = C.model{C.step==idx & C.win==1};
        % 
        % fprintf('\nThe significant winner of the forward selection is:\n%s\n',significant_winner)
        % fprintf('\nThe r_avg winner of forward selection is:\n%s\n',winning_model);
        varargout{1} = C;

    otherwise
        error('The analysis you entered does not exist!')
end



