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
my_font.xlabel = 11;
my_font.ylabel = 11;
my_font.title = 12;
my_font.tick_label = 9;
my_font.legend = 9;

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
    
    case 'make_chord_dataframe'
        % fields:
        % sn, sess, chordID, num_trials, num_fingers, MD, MT, RT, MD_std, MT_std, RT_std  

        % load trial dataframe:
        data = dload(fullfile(project_path, 'analysis', 'efc1_all.tsv'));
        subjects = unique(data.sn);
        sess = (data.BN<=12) + 2*(data.BN>=13 & data.BN<=24) + 3*(data.BN>=25 & data.BN<=36) + 4*(data.BN>=37 & data.BN<=48);
        chords = generateAllChords;
        n = get_num_active_fingers(chords);

        % container to hold the dataframe:
        ANA = [];
        % loop on subjects:
        for i = 1:length(subjects)
            tmp = [];
            % loop on sess:
            cnt = 1;
            for j = 1:length(unique(sess))
                % loop on chords:
                for k = 1:length(chords)
                    tmp.sn(cnt,1) = subjects(i);
                    tmp.sess(cnt,1) = j;
                    tmp.chordID(cnt,1) = chords(k);
                    
                    row = data.sn==subjects(i) & sess==j & data.chordID==chords(k) & data.trialCorr==1;
                    tmp.num_trials(cnt,1) = sum(row);
                    tmp.num_fingers(cnt,1) = n(k);
                    tmp.MD(cnt,1) = mean(data.mean_dev(row));
                    tmp.MT(cnt,1) = mean(data.MT(row));
                    tmp.RT(cnt,1) = mean(data.RT(row));
                    tmp.MD_std(cnt,1) = std(data.mean_dev(row));
                    tmp.MT_std(cnt,1) = std(data.MT(row));
                    tmp.RT_std(cnt,1) = std(data.RT(row));

                    cnt = cnt+1;
                end
            end
            ANA = addstruct(ANA,tmp,'row','force');
        end
        dsave(fullfile(project_path,'analysis','efc1_chord.tsv'),ANA);
    

    case 'subject_chords_doability'
        data = dload(fullfile(project_path, 'analysis', 'efc1_all.tsv'));
        sess = (data.BN<=12) + 2*(data.BN>=13 & data.BN<=24) + 3*(data.BN>=25 & data.BN<=36) + 4*(data.BN>=37 & data.BN<=48);
        
        subjects = unique(data.sn);

        C = [];
        for i = 1:length(subjects)
            % the trials that subject could not make the chords:
            hard_chords = data.chordID(data.sn==subjects(i) & data.trialCorr~=1 & data.trialErrorType ~= 1);

            % most undoable chords for subject i:
            hard_chords = unique(hard_chords);

            % selecting from hard_chords:
            n_incorr = [];
            for j = 1:length(hard_chords)
                corr_trials = data.trialCorr(data.sn==subjects(i) & data.chordID==hard_chords(j) & sess<=2 & data.trialErrorType~=1);
                n_incorr(j) = 10-sum(corr_trials);
            end
            hard_chord = hard_chords(n_incorr == max(n_incorr));
            
            if (~isempty(hard_chord))
                tmp = [];
                for j = 1:length(hard_chord)
                    tmp.sn(j,1) = subjects(i);
                    tmp.chordID(j,1) = hard_chord(j);
                    % number of correct trials:
                    tmp.n_sess01(j,1) = sum(data.trialCorr(data.sn==subjects(i) & data.chordID==hard_chord(j) & sess==1));
                    tmp.n_sess02(j,1) = sum(data.trialCorr(data.sn==subjects(i) & data.chordID==hard_chord(j) & sess==2));
                    tmp.n_sess03(j,1) = sum(data.trialCorr(data.sn==subjects(i) & data.chordID==hard_chord(j) & sess==3));
                    tmp.n_sess04(j,1) = sum(data.trialCorr(data.sn==subjects(i) & data.chordID==hard_chord(j) & sess==4));
                end
                C = addstruct(C,tmp,'row','force');
            end
        end

        % plot:
        subjects = unique(C.sn);
        for i = 1:length(subjects)
            fig = figure();
            fontsize(fig, my_font.tick_label, 'points')
            scatter(ones(length(C.n_sess01(C.sn==subjects(i)))), C.n_sess01(C.sn==subjects(i)), 40, 'k', 'filled')
            hold on
            scatter(2*ones(length(C.n_sess02(C.sn==subjects(i)))), C.n_sess02(C.sn==subjects(i)), 40, 'k', 'filled')
            scatter(3*ones(length(C.n_sess03(C.sn==subjects(i)))), C.n_sess03(C.sn==subjects(i)), 40, 'k', 'filled')
            scatter(4*ones(length(C.n_sess04(C.sn==subjects(i)))), C.n_sess04(C.sn==subjects(i)), 40, 'k', 'filled')
            drawline(5,'dir','horz','color',[0.7,0.7,0.7])
            plot(1:4, ...
                [C.n_sess01(C.sn==subjects(i))' ; C.n_sess02(C.sn==subjects(i))' ; C.n_sess03(C.sn==subjects(i))' ; C.n_sess04(C.sn==subjects(i))'] ...
                ,'Color',[0 0 0],'LineWidth',1.5)
            ylim([0 5.5])
            xticks([1 2 3 4])
            yticks([0 1 2 3 4 5])
            title(['subj ' num2str(subjects(i))],'FontSize',my_font.title)
            ylabel('num correct executions','FontSize',my_font.ylabel)
            xlabel('sess','FontSize',my_font.xlabel)
        end

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
        measure = 'mean_dev';
        vararginoptions(varargin,{'measure'})

        % loading data:
        data = dload(fullfile(project_path,'analysis','efc1_all.tsv'));

        % getting the values of measure:
        values = eval(['data.' measure]);

        sess = (data.BN<=12) + 2*(data.BN>=13 & data.BN<=24) + 3*(data.BN>=25 & data.BN<=36) + 4*(data.BN>=37 & data.BN<=48);

        % avg trend acorss sessions:
        fig = figure('Position', [500 500 310 310]);
        fontsize(fig, my_font.tick_label, 'points')
        lineplot(sess(data.trialCorr==1 & data.num_fingers==1),values(data.trialCorr==1 & data.num_fingers==1),'markertype','o','markersize',7,'markerfill',colors_blue(1,:),'markercolor',colors_blue(1,:),'linecolor',colors_blue(1,:),'linewidth',2,'errorbars','');hold on;
        lineplot(sess(data.trialCorr==1 & data.num_fingers==2),values(data.trialCorr==1 & data.num_fingers==2),'markertype','o','markersize',7,'markerfill',colors_blue(2,:),'markercolor',colors_blue(2,:),'linecolor',colors_blue(2,:),'linewidth',2,'errorbars','');
        lineplot(sess(data.trialCorr==1 & data.num_fingers==3),values(data.trialCorr==1 & data.num_fingers==3),'markertype','o','markersize',7,'markerfill',colors_blue(3,:),'markercolor',colors_blue(3,:),'linecolor',colors_blue(3,:),'linewidth',2,'errorbars','');
        lineplot(sess(data.trialCorr==1 & data.num_fingers==4),values(data.trialCorr==1 & data.num_fingers==4),'markertype','o','markersize',7,'markerfill',colors_blue(4,:),'markercolor',colors_blue(4,:),'linecolor',colors_blue(4,:),'linewidth',2,'errorbars','');
        lineplot(sess(data.trialCorr==1 & data.num_fingers==5),values(data.trialCorr==1 & data.num_fingers==5),'markertype','o','markersize',7,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',2,'errorbars','');
        % legend('n_{fingers}=1','n_{fingers}=2','n_{fingers}=3','n_{fingers}=4','n_{fingers}=5');
        % legend boxoff
        xlabel('sess','FontSize',my_font.xlabel)
        ylabel(['avg ' replace(measure,'_',' ') ' across subj'],'FontSize',my_font.ylabel)
        title([replace(measure,'_',' ')],'FontSize',my_font.title)
        h = gca;
        h.YTick = linspace(h.YTick(1),h.YTick(end),5);
        
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
        % fig = figure('Position', [10 10 900 600]);
        % lineplot(data.BN(data.trialCorr==1 & data.num_fingers==1),values(data.trialCorr==1 & data.num_fingers==1),'linecolor',colors(1,:));hold on;
        % lineplot(data.BN(data.trialCorr==1 & data.num_fingers==2),values(data.trialCorr==1 & data.num_fingers==2),'linecolor',colors(2,:));
        % lineplot(data.BN(data.trialCorr==1 & data.num_fingers==3),values(data.trialCorr==1 & data.num_fingers==3),'linecolor',colors(3,:));
        % lineplot(data.BN(data.trialCorr==1 & data.num_fingers==4),values(data.trialCorr==1 & data.num_fingers==4),'linecolor',colors(4,:));
        % lineplot(data.BN(data.trialCorr==1 & data.num_fingers==5),values(data.trialCorr==1 & data.num_fingers==5),'linecolor',colors(5,:));
        % xlabel('Block','FontSize',my_font.xlabel);
        % ylabel(['avg ' measure(measure~='_') ' across subj'],'FontSize',my_font.ylabel)

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

    case 'var_decomp_overall'
        chords = generateAllChords;
        measure = 'mean_dev';
        centered = 1;
        vararginoptions(varargin,{'chords','measure','centered'})

        data = dload(fullfile(project_path, 'analysis', 'efc1_all.tsv'));

        subjects = unique(data.sn);

        % getting the values of measure:
        values = eval(['data.' measure]);

        sess = (data.BN<=12) + 2*(data.BN>=13 & data.BN<=24) + 3*(data.BN>=25 & data.BN<=36) + 4*(data.BN>=37 & data.BN<=48);
        
        % container for subj MDs:
        subj_MD = {};
        % estimating (v_g + v_s + v_e) and (v_g + v_s):
        v_gse = 0;
        v_gs = 0;
        for i = 1:length(subjects)
            A = [];
            for j = 3:4
                tmp_val = 0;
                % loop on chords:
                for k = 1:length(chords)
                    tmp_val(k) = mean(values(data.sn==subjects(i) & data.trialCorr==1 & data.chordID==chords(k) & sess==j));
                end
                if centered
                    tmp_val = tmp_val-mean(tmp_val);
                end
                A = [A,tmp_val'];
            end
            subj_MD{i} = A;
            B = A' * A;
            % number of partitions:
            N = size(A,2);

            % adding sum of diagonal elems (y_ij' * y_ij):
            v_gse = v_gse + trace(B)/N/length(subjects);

            % adding sum of off-diagonal elems (y_ij' * y_ik):
            mean_cov = B .* (1-eye(N));
            mean_cov = sum(mean_cov(:))/(N*(N-1));
            v_gs = v_gs + mean_cov/length(subjects);
        end

        % estimating v_g:
        v_g = 0;
        N = length(subjects);
        for i = 1:length(subjects)-1
            for j = i+1:length(subjects)
                B = subj_MD{i}' * subj_MD{j};
                v_g = v_g + sum(B(:))/size(B,1)^2/(N*(N-1)/2);
            end
        end

        % plot:
        fig = figure();
        fontsize(fig, my_font.tick_label, "points")
        bar(1,1,'FaceColor','flat','EdgeColor',[1,1,1],'LineWidth',4,'CData',[0.8 0.8 0.8])
        hold on
        bar(1,1-(v_gs-v_g)/v_gse,'FaceColor','flat','EdgeColor',[1,1,1],'LineWidth',4,'CData',[36, 168, 255]/255)
        bar(1,v_g/v_gse,'FaceColor','flat','EdgeColor',[1,1,1],'LineWidth',4,'CData',[238, 146, 106]/255)
        drawline(1,'dir','horz','color',[0.8 0.8 0.8])
        legend('e','s','g')
        legend boxoff
        box off
        ylim([0 1.2])
        xticklabels('all chords')
        ylabel('percent variance','FontSize',my_font.ylabel)
        title(['var decomp ' replace(measure,'_',' ')],'FontSize',my_font.title);

        varargout{1} = [v_g, v_gs, v_gse];


    case 'var_decomp_nfingers'
        chords = generateAllChords;
        measure = 'mean_dev';
        centered = 1;
        vararginoptions(varargin,{'chords','measure','centered'})

        data = dload(fullfile(project_path, 'analysis', 'efc1_all.tsv'));

        subjects = unique(data.sn);

        % getting the values of measure:
        values = eval(['data.' measure]);

        sess = (data.BN<=12) + 2*(data.BN>=13 & data.BN<=24) + 3*(data.BN>=25 & data.BN<=36) + 4*(data.BN>=37 & data.BN<=48);

        n = get_num_active_fingers(chords);
        
        % container for subj MDs:
        subj_MD = {};
        % estimating (v_g + v_s + v_e) and (v_g + v_s):
        v_gse = zeros(length(unique(n)),1);
        v_gs = zeros(length(unique(n)),1);
        for i_n = 1:length(unique(n))
            for i = 1:length(subjects)
                A = [];
                for j = 3:4
                    tmp_val = 0;
                    % loop on chords:
                    for k = 1:length(chords)
                        tmp_val(k) = mean(values(data.sn==subjects(i) & data.trialCorr==1 & data.chordID==chords(k) & sess==j));
                    end
                    tmp_val = tmp_val(n==i_n);
                    if centered
                        tmp_val = tmp_val-mean(tmp_val);
                    end
                    A = [A,tmp_val'];
                end
                subj_MD{i,i_n} = A;
                B = A' * A;
                % number of partitions:
                N = size(A,2);
    
                % adding sum of diagonal elems (y_ij' * y_ij):
                v_gse(i_n) = v_gse(i_n) + trace(B)/N/length(subjects);
    
                % adding sum of off-diagonal elems (y_ij' * y_ik):
                mean_cov = B .* (1-eye(N));
                mean_cov = sum(mean_cov(:))/(N*(N-1));
                v_gs(i_n) = v_gs(i_n) + mean_cov/length(subjects);
            end
        end

        % estimating v_g:
        v_g = zeros(length(unique(n)),1);
        N = length(subjects);
        for i_n = 1:length(unique(n))
            for i = 1:length(subjects)-1
                for j = i+1:length(subjects)
                    B = subj_MD{i,i_n}' * subj_MD{j,i_n};
                    v_g(i_n) = v_g(i_n) + sum(B(:))/size(B,1)^2/(N*(N-1)/2);
                end
            end
        end
            
        % plot:
        y = [];
        fig = figure();
        fontsize(fig,my_font.tick_label,"points")
        for i = 1:length(unique(n))
            y(i,:) = [v_g(i)/v_gse(i) (v_gs(i)-v_g(i))/v_gse(i) (v_gse(i)-v_gs(i))/v_gse(i)];
            b = bar(i,y(i,:),'stacked','FaceColor','flat');
            b(1).CData = [238, 146, 106]/255;   % global var
            b(2).CData = [36, 168, 255]/255;  % subj var
            b(3).CData = [0.8 0.8 0.8];  % noise var
            b(1).EdgeColor = [1 1 1];
            b(2).EdgeColor = [1 1 1];
            b(3).EdgeColor = [1 1 1];
            b(1).LineWidth = 3;
            b(2).LineWidth = 3;
            b(3).LineWidth = 3;
            hold on
        end
        drawline(1,'dir','horz','color',[0.7 0.7 0.7])
        set(gca, 'XTick', 1:5);
        box off;
        title(['var decomp ' replace(measure,'_',' ')],'FontSize',my_font.title)
        xlabel('num fingers','FontSize',my_font.xlabel)
        ylabel('percent variance','FontSize',my_font.ylabel)
        title(['var decomp ' replace(measure,'_',' ')],'FontSize',my_font.title);
        legend('g','s','e')
        legend boxoff
        ylim([0,1.2])

        varargout{1} = [v_g, v_gs, v_gse];
        


    
        
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
        model_names = {'n_fing','n_fing+n_trans','n_fing+additive'};
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
                X = cell(1,length(names));
                for k = 1:length(names)
                    X{k} = repmat(make_design_matrix(chords,names{k}),length(subjects)-1,1);
                end
                
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



