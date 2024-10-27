function varargout=efc1_paper(what, varargin)

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
colors_pastel = ['#FFA500' ; '#1E90FF'];
colors_colorblind = ['#332288' ; '#117733' ; '#88CCEE' ; '#DDCC77' ; '#882255'];

colors_blue = hex2rgb(colors_blue);
colors_green = hex2rgb(colors_green);
colors_cyan = hex2rgb(colors_cyan);
colors_gray = hex2rgb(colors_gray);
colors_random = hex2rgb(colors_random);
colors_pastel = hex2rgb(colors_pastel);
colors_colorblind = hex2rgb(colors_colorblind);

colors_measures = [colors_red(3,:) ; colors_cyan(3,:) ; colors_blue(5,:)];

% figure properties:
my_font.label = 8;
my_font.title = 8;
my_font.tick_label = 8;
my_font.legend = 6;

% paper fig sizes:
paper.err_width = 0.7;
paper.line_width = 2;
paper.lineplot_line_width = 2;
paper.marker_size = 35;
paper.lineplot_marker_size = 3.5;
paper.horz_line_width = 2;
paper.axis_width = 1;
paper.bar_line_width = 1.5;
paper.bar_width = 1;

switch (what)
    case 'success_rate'
        data = dload(fullfile(project_path, 'analysis', 'efc1_chord.tsv'));
        % avg success rate of chords from day 1 to 4:
        [~, ~, succ, chords, sn] = get_sem(data.accuracy,data.sn,ones(size(data.sn)),data.chordID);
        [~,I] = sort(succ);
        succ = succ(I);
        chords = chords(I);
        sn = sn(I);
        
        % sucess rate of most difficult chords per subject:
        subjects = unique(sn);
        n_chords = 5;
        day_diff = [];
        success_rate_diff = [];
        for i = 1:length(subjects)
            tmp_chords = chords(sn==subjects(i));
            tmp_chords = tmp_chords(1:n_chords);
            row = data.sn==subjects(i) & ismember(data.chordID,tmp_chords);
            [~,X,Y,~,~] = get_sem(data.accuracy(row),data.sn(row),data.sess(row),ones(sum(row),1));
            day_diff = [day_diff ; X];    
            success_rate_diff = [success_rate_diff ; Y];
        end
        
        % avg success rate of all chords
        [~, day_avg, success_rate_avg, ~, ~] = get_sem(data.accuracy,data.sn,data.sess,ones(size(data.sn)));
    
        % avg success rate of chords with 0 success rate on first day:
        tbl = [data.sn,data.sess,data.chordID,data.accuracy];
        [~,I] = sort(tbl(:,4));
        tbl = tbl(I,:);
        fail_thresh = 0.3;
        condition = tbl(:,4)<=fail_thresh;
        impossible_subj_chords = tbl(tbl(:,2)==1 & condition,3);
        sn = tbl(tbl(:,2)==1 & condition,1);
        subj_unique = unique(sn);
        day = [];
        succ = [];
        for i = 1:length(subj_unique)
            tmp_chords = impossible_subj_chords(sn==subj_unique(i));
            row = data.sn==subj_unique(i) & ismember(data.chordID,tmp_chords);
            [~,X,Y,~,SN] = get_sem(data.accuracy(row),data.sn(row),data.sess(row),ones(sum(row),1));
            day = [day ; X];
            succ = [succ ; Y];
        end
        fprintf("%d participants failed to produce %d.\n",length(subj_unique),length(unique(impossible_subj_chords)))
        
        fig = figure('Units','centimeters', 'Position',[15 15 5 6]);
        fontsize(fig, my_font.tick_label, 'points')
        drawline(1,'dir','horz','color',[0.8 0.8 0.8],'lim',[0 5],'linewidth',paper.horz_line_width,'linestyle',':'); hold on;
        lineplot(day_avg,success_rate_avg,'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_gray(2,:),'markercolor',colors_gray(2,:),'linecolor',colors_gray(2,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_gray(2,:),'errorcap',0);
        lineplot(day,succ,'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_red(2,:),'markercolor',colors_red(2,:),'linecolor',colors_red(2,:),'linestyle','-','linewidth',paper.lineplot_line_width,'errorcolor',colors_red(2,:),'errorcap',0);
        lineplot(day_diff,success_rate_diff,'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_gray(5,:),'markercolor',colors_gray(5,:),'linecolor',colors_gray(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_gray(5,:),'errorcap',0);
        % lgd = legend({'','',['Most Challenging' newline 'Chord per Subject'],'','All 242 Chords'});
        % legend boxoff
        % fontsize(lgd,my_font.legend,'points')
        ylim([0,1])
        xlim([0.8,4.2])
        h = gca;
        h.YAxis.TickValues = 0:0.5:1;
        h.XAxis.TickValues = 1:4;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        xlabel('days','FontSize',my_font.label)
        ylabel('success rate','FontSize',my_font.label)
        box off
        set(gca, 'FontName', 'arial');

        % distribution plot:
        fig = figure('Units','centimeters', 'Position',[15 15 5 6]);
        [~, day, succ, ~, ~] = get_sem(data.accuracy,ones(size(data.sn)),data.sess,data.chordID);
        Y = reshape(succ,[],4);
        c =  [0.45, 0.80, 0.69;...
              0.98, 0.40, 0.35;...
              0.55, 0.60, 0.79;...
              0.90, 0.70, 0.30];  
        h = daboxplot(Y*100,'colors',c,'whiskers',0,'scatter',2,'scattersize',10,'scatteralpha',1,...
                      'boxspacing',0.8,'outliers',0,'scattercolors',{'k','w'},'linkline',0,'fill',1); 
        h.md(1).YData(1)
        h.md(2).YData(1)
        h.md(3).YData(1)
        h.md(4).YData(1)
        ylim([0,1]*100)
        xlim([0.5,4.5])
        h = gca;
        h.YAxis.TickValues = (0:0.5:1)*100;
        h.XAxis.TickValues = 1:4;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        xlabel('days','FontSize',my_font.label)
        ylabel('success rate','FontSize',my_font.label)
        box off
        set(gca, 'FontName', 'arial');
        
    case 'training_performance'
        C = dload(fullfile(project_path,'analysis','training_performance.tsv'));
        
        % ======== MD ========
        % fig_MD = figure('Units','centimeters', 'Position',[15 15 4.2 6]);
        % % single-finger chords as baseline:
        % lineplot(C.sess(C.finger_count==1),C.MD(C.finger_count==1),'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_gray(2,:),'markercolor',colors_gray(2,:),'linecolor',colors_gray(2,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_gray(2,:),'errorcap',0); hold on;
        % % multi-finger chords:
        % [~, X, Y, COND, SN] = get_sem(C.MD, C.sn, C.sess, ones(size(C.MD)));
        % lineplot(X,Y,'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(5,:),'errorcap',0);
        % h = gca;
        % % ylim([0 1.2])
        % % h.YTick = [0 0.6 1.2];
        % xlim([0.5 4.5])
        % h.XAxis.FontSize = my_font.tick_label;
        % h.YAxis.FontSize = my_font.tick_label;
        % xlabel('days','FontSize',my_font.label)
        % ylabel('MD','FontSize',my_font.label)
        % h.LineWidth = paper.axis_width;
        % fontname("arial")

        % ======== MD Separate ========
        fig_MD = figure('Units','centimeters', 'Position',[15 15 4.2 6]);
        % single-finger chords:
        lineplot(C.sess(C.finger_count==1),C.MD(C.finger_count==1),'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(1,:),'markercolor',colors_blue(1,:),'linecolor',colors_blue(1,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(1,:),'errorcap',0); hold on;
        lineplot(C.sess(C.finger_count==2),C.MD(C.finger_count==2),'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(2,:),'markercolor',colors_blue(2,:),'linecolor',colors_blue(2,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(2,:),'errorcap',0); hold on;
        lineplot(C.sess(C.finger_count==3),C.MD(C.finger_count==3),'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(3,:),'markercolor',colors_blue(3,:),'linecolor',colors_blue(3,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(3,:),'errorcap',0); hold on;
        lineplot(C.sess(C.finger_count==4),C.MD(C.finger_count==4),'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(4,:),'markercolor',colors_blue(4,:),'linecolor',colors_blue(4,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(4,:),'errorcap',0); hold on;
        lineplot(C.sess(C.finger_count==5),C.MD(C.finger_count==5),'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(5,:),'errorcap',0); hold on;
        h = gca;
        ylim([0 2])
        h.YTick = [0 1 2];
        xlim([0.5 4.5])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('days','FontSize',my_font.label)
        ylabel('mean deviation [N]','FontSize',my_font.label)
        h.LineWidth = paper.axis_width;
        fontname("arial")
        
        fprintf("\nMD Improvement:\n")
        [~, X, Y, COND, SN] = get_sem(C.MD, C.sn, C.sess, ones(size(C.MD)));
        fprintf('2-way ANOVA, MD:\n')
        T_ET_Imprv = anovaMixed(C.MD,C.sn,'within',[C.sess,C.finger_count],{'days','finger count'});
        fprintf("\n")
        
        fprintf("\nMD t-test, days 1 vs 4:\n")
        [t,p] = ttest(C.MD(C.sess==1 & C.finger_count==5),C.MD(C.sess==4  & C.finger_count==5),1,'paired');
        fprintf("     n=5: (%.3f,%16e)\n",t,p)

        [t,p] = ttest(C.MD(C.sess==1 & C.finger_count==4),C.MD(C.sess==4 & C.finger_count==4),1,'paired');
        fprintf("     n=4: (%.3f,%16e)\n",t,p)

        [t,p] = ttest(C.MD(C.sess==1 & C.finger_count==3),C.MD(C.sess==4 & C.finger_count==3),1,'paired');
        fprintf("     n=3: (%.3f,%16e)\n",t,p)

        [t,p] = ttest(C.MD(C.sess==1 & C.finger_count==2),C.MD(C.sess==4 & C.finger_count==2),1,'paired');
        fprintf("     n=2: (%.3f,%16e)\n",t,p)

        [t,p] = ttest(C.MD(C.sess==1 & C.finger_count==1),C.MD(C.sess==4 & C.finger_count==1),1,'paired');
        fprintf("     n=1: (%.3f,%16e)\n",t,p)


        % ======== ET Separate ========
        fig_ET = figure('Units','centimeters', 'Position',[15 15 4.6 6]);
        % single-finger chords:
        lineplot(C.sess(C.finger_count==1),C.ET(C.finger_count==1),'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(1,:),'markercolor',colors_blue(1,:),'linecolor',colors_blue(1,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(1,:),'errorcap',0); hold on;
        lineplot(C.sess(C.finger_count==2),C.ET(C.finger_count==2),'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(2,:),'markercolor',colors_blue(2,:),'linecolor',colors_blue(2,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(2,:),'errorcap',0); hold on;
        lineplot(C.sess(C.finger_count==3),C.ET(C.finger_count==3),'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(3,:),'markercolor',colors_blue(3,:),'linecolor',colors_blue(3,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(3,:),'errorcap',0); hold on;
        lineplot(C.sess(C.finger_count==4),C.ET(C.finger_count==4),'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(4,:),'markercolor',colors_blue(4,:),'linecolor',colors_blue(4,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(4,:),'errorcap',0); hold on;
        lineplot(C.sess(C.finger_count==5),C.ET(C.finger_count==5),'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(5,:),'errorcap',0); hold on;
        h = gca;
        ylim([0 3200])
        h.YTick = [0 1600 3200];
        h.YTickLabels = {'0', '1.6', '3.2'};
        xlim([0.5 4.5])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('days','FontSize',my_font.label)
        ylabel('execution time [s]','FontSize',my_font.label)
        h.LineWidth = paper.axis_width;
        fontname("arial")

        % stats
        fprintf("\nET Improvement:\n")
        [~, X, Y, COND, SN] = get_sem(C.ET, C.sn, C.sess, ones(size(C.ET)));
        fprintf('2-way ANOVA, ET:\n')
        T_ET_Imprv = anovaMixed(C.ET,C.sn,'within',[C.sess,C.finger_count],{'days','finger count'});
        fprintf("\n")
        
        fprintf("\nET t-test, days 1 vs 4:\n")
        [t,p] = ttest(C.ET(C.sess==1 & C.finger_count==5),C.ET(C.sess==4  & C.finger_count==5),1,'paired');
        fprintf("     n=5: (%.3f,%16e)\n",t,p)

        [t,p] = ttest(C.ET(C.sess==1 & C.finger_count==4),C.ET(C.sess==4 & C.finger_count==4),1,'paired');
        fprintf("     n=4: (%.3f,%16e)\n",t,p)

        [t,p] = ttest(C.ET(C.sess==1 & C.finger_count==3),C.ET(C.sess==4 & C.finger_count==3),1,'paired');
        fprintf("     n=3: (%.3f,%16e)\n",t,p)

        [t,p] = ttest(C.ET(C.sess==1 & C.finger_count==2),C.ET(C.sess==4 & C.finger_count==2),1,'paired');
        fprintf("     n=2: (%.3f,%16e)\n",t,p)

        [t,p] = ttest(C.ET(C.sess==1 & C.finger_count==1),C.ET(C.sess==4 & C.finger_count==1),1,'paired');
        fprintf("     n=1: (%.3f,%16e)\n",t,p)

    case 'trial_by_trial_corr_ET_MD'
        C = dload(fullfile('analysis','efc1_all.tsv'));
        C = getrow(C, C.trialCorr==1);
        % chords = unique(C.chordID);
        days = unique(C.sess);
        sn = unique(C.sn);
        num_fingers = unique(C.num_fingers);
        chords = unique(C.chordID);
        
        ana = [];
        % for i = 1:length(sn)
        %     for day = 1:length(days)
        %         for n = 1:length(num_fingers)
        %             ET = C.ET(C.sn==sn(i) & C.sess==days(day) & C.num_fingers==n);
        %             MD = C.MD(C.sn==sn(i) & C.sess==days(day) & C.num_fingers==n);
        %             if length(MD) < 2
        %                 continue
        %             end
        %             tmp.sn = sn(i);
        %             tmp.day = days(day);
        %             % tmp.chord = chords(chord);
        %             tmp.num_fingers = n;
        %             tmp.corr = corr(ET,MD);
        %             ana = addstruct(ana, tmp, 'row', 'force');
        %         end
        %     end
        % end
        for i = 1:length(chords)
            ET = C.ET(C.chordID==chords(i));
            MD = C.MD(C.chordID==chords(i));
            if length(MD) < 2
                continue
            end
            % tmp.day = days(day);
            tmp.chord = chords(i);
            % tmp.num_fingers = n;
            tmp.corr = corr(ET,MD);
            ana = addstruct(ana, tmp, 'row', 'force');
        end
        varargout{1} = ana;

        fprintf('corr ET with MD:\n')
        fprintf('rho = %.4f', mean(ana.corr))
        [t,p] = ttest(ana.corr,[],1,'onesample');
        fprintf(', t(%d)= %.3f, p=%.6f\n',length(ana.corr)-1, t, p)

    case 'measure_reliability'
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        data = getrow(data,data.sess>=3);

        [~, X, Y, COND, SN] = get_sem(data.MD, data.sn, ones(size(data.sn)), data.chordID);

        finger_count = get_num_active_fingers(COND);
        fc = unique(finger_count);
        
        % loop on finger count:
        r = [];
        for i = 1:length(fc)
            row = finger_count==fc(i);
            r = [r ; crossval_reliability(Y(row),'split',SN(row))];
        end
        r = [r ; crossval_reliability(Y,'split',SN)];
        
        % barplot:
        X = [repelem(fc,length(unique(SN)),1) ; 6*ones(14,1)];
        y = r;
        split = [repelem(fc,length(unique(SN)),1) ; 6*ones(14,1)];
        figure('Units','centimeters', 'Position',[15 15 5 6]);
        barwidth = 1;
        bar_colors = {colors_blue(1,:),colors_blue(2,:),colors_blue(3,:),colors_blue(4,:),colors_blue(5,:),colors_gray(1,:)};
        [x_coord,PLOT,ERROR] = barplot(X,y,'split',split,'facecolor',bar_colors,'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        box off
        h = gca;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = 0:0.2:1;
        ylim([0 1])
        xlim([0 9.5])
        ylabel('MD group correlation (cross-validated)','FontSize',my_font.label)
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")

        fprintf('\nNoise Ceiling:\n')
        fprintf(['   1-f: r=%.4f (%.4f,%.4f)\n   2-f: r=%.4f (%.4f,%.4f)\n   3-f: r=%.4f (%.4f,%.4f)\n   4-f: r=%.4f (%.4f,%.4f)\n' ...
            '   5-f: r=%.4f (%.4f,%.4f)\n   all: r=%.4f (%.4f,%.4f)\n'],mean(r(X==1)),min(r(X==1)),max(r(X==1)) ...
            ,mean(r(X==2)),min(r(X==2)),max(r(X==2)),mean(r(X==3)),min(r(X==3)),max(r(X==3)) ...
            ,mean(r(X==4)),min(r(X==4)),max(r(X==4)),mean(r(X==5)),min(r(X==5)),max(r(X==5)) ...
            ,mean(r(X==6)),min(r(X==6)),max(r(X==6)))
        
        fprintf('\nttest:\n')
        for i = 1:5
            [t,p] = ttest(r(X==i),[],1,'onesample');
            fprintf('   t(%d)=%.3f, p=%.6f\n', length(r(X==i))-1, t, p)
        end


    case 'training_finger_count'
        C = dload(fullfile(project_path,'analysis','training_performance.tsv'));
        
        % ======== MD ========
        fig_MD = figure('Units','centimeters', 'Position',[15 15 4.5 6]);
        [~, X, Y, COND, SN] = get_sem(C.MD, C.sn, ones(size(C.sn)), C.finger_count);
        lineplot(COND,Y,'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_gray(5,:),'markercolor',colors_gray(5,:),'linecolor',colors_gray(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_gray(5,:),'errorcap',0);
        h = gca;
        ylim([0 1.8])
        h.YTick = [0 0.9 1.8];
        xlim([0.5 5.5])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('Finger Count','FontSize',my_font.label)
        ylabel('MD','FontSize',my_font.label)
        h.LineWidth = paper.axis_width;
        fontname("arial")
        
        % stats
        fprintf("\nMD finger-count effect:\n")
        T_MD = anovaMixed(Y,SN,'within',COND,{'finger count'});
        fprintf("\n")

        % ======== ET ========
        fig_MD = figure('Units','centimeters', 'Position',[15 15 4.5 6]);
        [~, X, Y, COND, SN] = get_sem(C.ET, C.sn, ones(size(C.sn)), C.finger_count);
        lineplot(COND,Y,'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_gray(5,:),'markercolor',colors_gray(5,:),'linecolor',colors_gray(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_gray(5,:),'errorcap',0);
        h = gca;
        ylim([0 3200])
        h.YTick = [0 1600 3200];
        xlim([0.5 5.5])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('Finger Count','FontSize',my_font.label)
        ylabel('ET','FontSize',my_font.label)
        h.LineWidth = paper.axis_width;
        fontname("arial")
        
        % stats
        fprintf("\nET finger-count effect:\n")
        T_ET = anovaMixed(Y,SN,'within',COND,{'finger count'});
        fprintf("\n")


    case 'training_repetition'
        C = dload(fullfile(project_path,'analysis','training_repetition.tsv'));
        
        % ====== MD ======:
        fig_MD = figure('Units','centimeters', 'Position',[15 15 5.5 5]);
        % average data across finger count for multi-finger chords:
        idx = C.finger_count>1;
        [~, X1, Y1, COND] = get_sem(C.MD_subj_rep1(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X2, Y2, COND] = get_sem(C.MD_subj_rep2(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X3, Y3, COND] = get_sem(C.MD_subj_rep3(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X4, Y4, COND] = get_sem(C.MD_subj_rep4(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X5, Y5, COND] = get_sem(C.MD_subj_rep5(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        
        offset_size = 5;
        x_offset = 0:offset_size:5*(length(unique(C.sess))-1);
        hold on;
        for j = 1:length(unique(C.sess))
            x_tmp = [ones(sum(X1==j),1);2*ones(sum(X2==j),1);3*ones(sum(X3==j),1);4*ones(sum(X4==j),1);5*ones(sum(X5==j),1)];
            y_tmp = [Y1(X1==j);Y2(X2==j);Y3(X3==j);Y4(X4==j);Y5(X5==j)];
            lineplot(x_tmp+x_offset(j),y_tmp,'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width-0.7,'errorcolor',colors_blue(5,:),'errorwidth',paper.err_width,'errorcap',0);
        end
        
        % average data across finger count for single-finger chords:
        idx = C.finger_count==1;
        [~, X1, Y1, COND] = get_sem(C.MD_subj_rep1(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X2, Y2, COND] = get_sem(C.MD_subj_rep2(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X3, Y3, COND] = get_sem(C.MD_subj_rep3(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X4, Y4, COND] = get_sem(C.MD_subj_rep4(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X5, Y5, COND] = get_sem(C.MD_subj_rep5(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));

        % for j = 1:length(unique(C.sess))
        %     x_tmp = [ones(sum(X1==j),1);2*ones(sum(X2==j),1);3*ones(sum(X3==j),1);4*ones(sum(X4==j),1);5*ones(sum(X5==j),1)];
        %     y_tmp = [Y1(X1==j);Y2(X2==j);Y3(X3==j);Y4(X4==j);Y5(X5==j)];
        %     lineplot(x_tmp+x_offset(j),y_tmp,'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_gray(1,:),'markercolor',colors_gray(1,:),'linecolor',colors_gray(1,:),'linewidth',paper.lineplot_line_width-0.7,'errorcolor',colors_gray(1,:),'errorwidth',paper.err_width,'errorcap',0);
        % end
        box off
        h = gca;
        h.XTick = 5*(1:length(unique(C.sess))) - 2;
        h.XTickLabel = {'1','2','3','4'};
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [1.2,1.8,2.4];
        ylim([0 2.4])
        xlim([0,21])
        xlabel('days','FontSize',my_font.label)
        ylabel('MD','FontSize',my_font.label)
        fontname("Arial")

        % stats - Imprv from rep 1 to 2:
        sf = C.finger_count==1;
        MF_imprv = 0;
        SF_imprv = 0;
        for i = 1:4
            for j = 2:5
                MF_imprv = MF_imprv + (C.MD_subj_rep1(C.sess==i & C.finger_count==j) - C.MD_subj_rep2(C.sess==i & C.finger_count==j))/4/4;
            end
            SF_imprv = SF_imprv + (C.MD_subj_rep1(sf & C.sess==i) - C.MD_subj_rep2(sf & C.sess==i))/4;
        end
        [t_mf,p_mf] = ttest(MF_imprv,[],1,'onesample');
        [t_sf,p_sf] = ttest(SF_imprv,[],1,'onesample');
        fprintf('\nMD Imprv from rep 1 to 2:\n')
        fprintf('multi-finger: (%.4f,%.4f)\nsingle-finger: (%.4f,%.4f)\n',t_mf,p_mf,t_sf,p_sf)
        
        % stats:
        fprintf('\nMD Change in rep1 from day 1 to 4:\n')
        T_MD_rep1Imprv = anovaMixed(C.MD_subj_rep1,C.sn,'within',[C.sess],{'days'});
        fprintf('\n')
        
        fprintf('\nMD Imprv in rep 2-5:\n')
        y = [C.MD_subj_rep2;C.MD_subj_rep3;C.MD_subj_rep4;C.MD_subj_rep5];
        sn = [C.sn;C.sn;C.sn;C.sn];
        rep = [2*ones(size(C.MD_subj_rep2));3*ones(size(C.MD_subj_rep3));4*ones(size(C.MD_subj_rep4));5*ones(size(C.MD_subj_rep5))];
        % T_MD_rep2to5 = MANOVArp(sn,rep,y);
        T_MD_rep2to5 = anovaMixed(y,sn,'within',[rep],{'repetitions'});
        fprintf('\n')
        
        % ====== RT ======: 
        fig_RT = figure('Units','centimeters', 'Position',[15 15 5.5 5]);
        % average data across finger count for single-finger chords:
        idx = C.finger_count==1;
        [~, X1, Y1, COND] = get_sem(C.RT_subj_rep1(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X2, Y2, COND] = get_sem(C.RT_subj_rep2(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X3, Y3, COND] = get_sem(C.RT_subj_rep3(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X4, Y4, COND] = get_sem(C.RT_subj_rep4(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X5, Y5, COND] = get_sem(C.RT_subj_rep5(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));

        % offset_size = 5;
        % x_offset = 0:offset_size:5*(length(unique(C.sess))-1);
        % hold on;
        % for j = 1:length(unique(C.sess))
        %     x_tmp = [ones(sum(X1==j),1);2*ones(sum(X2==j),1);3*ones(sum(X3==j),1);4*ones(sum(X4==j),1);5*ones(sum(X5==j),1)];
        %     y_tmp = [Y1(X1==j);Y2(X2==j);Y3(X3==j);Y4(X4==j);Y5(X5==j)];
        %     lineplot(x_tmp+x_offset(j),y_tmp,'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_gray(1,:),'markercolor',colors_gray(1,:),'linecolor',colors_gray(1,:),'linewidth',paper.lineplot_line_width-0.7,'errorcolor',colors_gray(1,:),'errorwidth',paper.err_width,'errorcap',0);
        % end

        % average data across finger count for multi-finger chords:
        idx = C.finger_count>1;
        [~, X1, Y1, COND] = get_sem(C.RT_subj_rep1(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X2, Y2, COND] = get_sem(C.RT_subj_rep2(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X3, Y3, COND] = get_sem(C.RT_subj_rep3(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X4, Y4, COND] = get_sem(C.RT_subj_rep4(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        [~, X5, Y5, COND] = get_sem(C.RT_subj_rep5(idx), C.sn(idx), C.sess(idx), ones(sum(idx),1));
        
        offset_size = 5;
        x_offset = 0:offset_size:5*(length(unique(C.sess))-1);
        hold on;
        for j = 1:length(unique(C.sess))
            x_tmp = [ones(sum(X1==j),1);2*ones(sum(X2==j),1);3*ones(sum(X3==j),1);4*ones(sum(X4==j),1);5*ones(sum(X5==j),1)];
            y_tmp = [Y1(X1==j);Y2(X2==j);Y3(X3==j);Y4(X4==j);Y5(X5==j)];
            lineplot(x_tmp+x_offset(j),y_tmp,'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width-0.7,'errorcolor',colors_blue(5,:),'errorwidth',paper.err_width,'errorcap',0);
        end
        box off
        h = gca;
        h.XTick = 5*(1:length(unique(C.sess))) - 2;
        h.XTickLabel = {'1','2','3','4'};
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [140,370,600];
        ylim([140 600])
        xlim([0,21])
        ylabel('RT','FontSize',my_font.label)
        xlabel('days','FontSize',my_font.label)
        fontname("Arial")

        % stats - Imprv from rep 1 to 2:
        sf = C.finger_count==1;
        MF_imprv = 0;
        SF_imprv = 0;
        for i = 1:4
            for j = 2:5
                MF_imprv = MF_imprv + (C.RT_subj_rep1(C.sess==i & C.finger_count==j) - C.RT_subj_rep2(C.sess==i & C.finger_count==j))/4/4;
            end
            SF_imprv = SF_imprv + (C.RT_subj_rep1(sf & C.sess==i) - C.RT_subj_rep2(sf & C.sess==i))/4;
        end
        [t_mf,p_mf] = ttest(MF_imprv,[],1,'onesample');
        [t_sf,p_sf] = ttest(SF_imprv,[],1,'onesample');
        fprintf('\nRT Imprv from rep 1 to 2:\n')
        fprintf('multi-finger: (%.4f,%.4f)\nsingle-finger: (%.4f,%.4f)\n',t_mf,p_mf,t_sf,p_sf)

        % stats:
        fprintf('\nRT Change in rep1 from day 1 to 4:\n\n')
        % T_RT_rep1Imprv = MANOVArp(C.sn,C.sess,C.RT_subj_rep1);
        T_RT_rep1Imprv = anovaMixed(C.RT_subj_rep1,C.sn,'within',[C.sess],{'days'});
        fprintf('\n')

        fprintf('\nRT Imprv in rep 2-5:\n')
        y = [C.RT_subj_rep2;C.RT_subj_rep3;C.RT_subj_rep4;C.RT_subj_rep5];
        sn = [C.sn;C.sn;C.sn;C.sn];
        rep = [2*ones(size(C.RT_subj_rep2));3*ones(size(C.RT_subj_rep3));4*ones(size(C.RT_subj_rep4));5*ones(size(C.RT_subj_rep5))];
        T_MD_rep2to5 = anovaMixed(y,sn,'within',[rep],{'repetitions'});
        fprintf('\n')

    case 'training_rep_imprv'
        C = dload(fullfile(project_path,'analysis','training_rep_imprv.tsv'));
        
        % ========= MD =========:
        [~, ~, Y_rep1, COND_rep1, SN] = get_sem(C.MD_imprv_rep1, C.sn, ones(length(C.sn),1), C.finger_count);
        [~, ~, Y_rep2, COND_rep2] = get_sem(C.MD_imprv_rep2, C.sn, ones(length(C.sn),1), C.finger_count);
        [~, ~, Y_rep3, COND_rep3] = get_sem(C.MD_imprv_rep3, C.sn, ones(length(C.sn),1), C.finger_count);
        [~, ~, Y_rep4, COND_rep4] = get_sem(C.MD_imprv_rep4, C.sn, ones(length(C.sn),1), C.finger_count);
        [~, ~, Y_rep5, COND_rep5] = get_sem(C.MD_imprv_rep5, C.sn, ones(length(C.sn),1), C.finger_count);
        % avg of rep 2 to 5:
        Y_rep2_5 = (Y_rep2+Y_rep3+Y_rep4+Y_rep5)/4;

        figure('Units','centimeters', 'Position',[15 15 6 5]);
        % finger count:
        x = [COND_rep1;COND_rep2];
        % improvements:
        y = [Y_rep1;Y_rep2_5];
        % repetitions (1 or 2+)
        rep = [ones(size(Y_rep1));2*ones(size(Y_rep2))];

        row = x>1;
        bar_colors = {colors_blue(3,:), colors_blue(3,:), colors_blue(3,:), colors_blue(3,:)};
        barplot(rep(row),y(row),'split',x(row),'barwidth',0.5,'gapwidth', [0 -0.5 0], 'facecolor', bar_colors,'errorwidth',paper.err_width,'linewidth',1,'capwidth',0);
        box off
        h = gca;
        h.XTick = [1:0.5:2.5 , 3.5:0.5:5];
        h.XTickLabel = {'2','3','4','5','2','3','4','5'};
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [0,0.25,0.5];
        ylim([0 0.5])
        xlim([0.25,5.75])
        ylabel('MD_{day1} - MD_{day4}','FontSize',my_font.label)
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")

        % stats - MD first rep across finger-count:
        t = [];
        p = [];
        [t(1),p(1)] = ttest(Y_rep1(COND_rep1==1),[],1,'onesample');
        [t(2),p(2)] = ttest(Y_rep1(COND_rep1==2),[],1,'onesample');
        [t(3),p(3)] = ttest(Y_rep1(COND_rep1==3),[],1,'onesample');
        [t(4),p(4)] = ttest(Y_rep1(COND_rep1==4),[],1,'onesample');
        [t(5),p(5)] = ttest(Y_rep1(COND_rep1==5),[],1,'onesample');
        fprintf('\nMD imprv first rep:\n')
        fprintf('1f: (%.4f,%.4f)\n2f: (%.4f,%.4f)\n3f: (%.4f,%.4f)\n4f: (%.4f,%.4f)\n5f: (%.4f,%.4f)\n',...
                t(1),p(1),t(2),p(2),t(3),p(3),t(4),p(4),t(5),p(5))

        % stats - MD 1f chords imprv across repetitions:
        t = [];
        p = [];
        [t(1),p(1)] = ttest(Y_rep2(COND_rep2==1),[],1,'onesample');
        [t(2),p(2)] = ttest(Y_rep3(COND_rep3==1),[],1,'onesample');
        [t(3),p(3)] = ttest(Y_rep4(COND_rep4==1),[],1,'onesample');
        [t(4),p(4)] = ttest(Y_rep5(COND_rep5==1),[],1,'onesample');
        fprintf('\nMD imprv single-finger in rep 2-5:\n')
        fprintf('rep2: (%.4f,%.4f)\nrep3: (%.4f,%.4f)\nrep4: (%.4f,%.4f)\nrep5: (%.4f,%.4f)\n',...
                t(1),p(1),t(2),p(2),t(3),p(3),t(4),p(4))
        
        % stats - MD rep2-5 imprv from 2f to 5f:
        finger_count = [COND_rep2;COND_rep3;COND_rep4;COND_rep5];
        sn = [SN;SN;SN;SN];
        imprv = [Y_rep2;Y_rep3;Y_rep4;Y_rep5];
        fprintf("\nMD rep2-5 imprv from 2f to 5f:\n")
        row = finger_count>1;
        T_MD_Imprv = anovaMixed(imprv(row),sn(row),'within',finger_count(row),{'finger count'});
        fprintf("\n")
        
       
        % ========= RT =========:
        [~, ~, Y_rep1, COND_rep1, SN] = get_sem(C.RT_imprv_rep1, C.sn, ones(length(C.sn),1), C.finger_count);
        [~, ~, Y_rep2, COND_rep2] = get_sem(C.RT_imprv_rep2, C.sn, ones(length(C.sn),1), C.finger_count);
        [~, ~, Y_rep3, COND_rep3] = get_sem(C.RT_imprv_rep3, C.sn, ones(length(C.sn),1), C.finger_count);
        [~, ~, Y_rep4, COND_rep4] = get_sem(C.RT_imprv_rep4, C.sn, ones(length(C.sn),1), C.finger_count);
        [~, ~, Y_rep5, COND_rep5] = get_sem(C.RT_imprv_rep5, C.sn, ones(length(C.sn),1), C.finger_count);
        % avg of rep 2 to 5:
        Y_rep2_5 = (Y_rep2+Y_rep3+Y_rep4+Y_rep5)/4;

        figure('Units','centimeters', 'Position',[15 15 6 5]);
        % finger count:
        x = [COND_rep1;COND_rep2];
        % improvements:
        y = [Y_rep1;Y_rep2_5];
        % repetitions (1 or 2+)
        rep = [ones(size(Y_rep1));2*ones(size(Y_rep2))];

        row = x>1;
        bar_colors = {colors_blue(3,:), colors_blue(3,:), colors_blue(3,:), colors_blue(3,:)};
        barplot(rep(row),y(row),'split',x(row),'barwidth',0.5,'gapwidth', [0 -0.5 0], 'facecolor', bar_colors,'errorwidth',paper.err_width,'linewidth',1,'capwidth',0);
        box off
        h = gca;
        h.XTick = [1:0.5:2.5 , 3.5:0.5:5];
        h.XTickLabel = {'2','3','4','5','2','3','4','5'};
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [0,120,240];
        ylim([0 240])
        xlim([0.25,5.75])
        ylabel('RT_{day1} - RT_{day4}','FontSize',my_font.label)
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")
        
        % stats - RT first rep across finger-count:
        t = [];
        p = [];
        [t(1),p(1)] = ttest(Y_rep1(COND_rep1==1),[],1,'onesample');
        [t(2),p(2)] = ttest(Y_rep1(COND_rep1==2),[],1,'onesample');
        [t(3),p(3)] = ttest(Y_rep1(COND_rep1==3),[],1,'onesample');
        [t(4),p(4)] = ttest(Y_rep1(COND_rep1==4),[],1,'onesample');
        [t(5),p(5)] = ttest(Y_rep1(COND_rep1==5),[],1,'onesample');
        fprintf('\nRT imprv first rep:\n')
        fprintf('1f: (%.4f,%.4f)\n2f: (%.4f,%.4f)\n3f: (%.4f,%.4f)\n4f: (%.4f,%.4f)\n5f: (%.4f,%.4f)\n',...
                t(1),p(1),t(2),p(2),t(3),p(3),t(4),p(4),t(5),p(5))

        % stats - RT 1f chords imprv across repetitions:
        t = [];
        p = [];
        [t(1),p(1)] = ttest(Y_rep2(COND_rep2==1),[],1,'onesample');
        [t(2),p(2)] = ttest(Y_rep3(COND_rep3==1),[],1,'onesample');
        [t(3),p(3)] = ttest(Y_rep4(COND_rep4==1),[],1,'onesample');
        [t(4),p(4)] = ttest(Y_rep5(COND_rep5==1),[],1,'onesample');
        fprintf('\nRT imprv single-finger in rep 2-5:\n')
        fprintf('rep2: (%.4f,%.4f)\nrep3: (%.4f,%.4f)\nrep4: (%.4f,%.4f)\nrep5: (%.4f,%.4f)\n',...
                t(1),p(1),t(2),p(2),t(3),p(3),t(4),p(4))
        
        % stats - RT rep2-5 imprv from 2f to 5f:
        finger_count = [COND_rep2;COND_rep3;COND_rep4;COND_rep5];
        sn = [SN;SN;SN;SN];
        imprv = [Y_rep2;Y_rep3;Y_rep4;Y_rep5];
        fprintf("\nRT rep2-5 imprv from 1f to 5f:\n")
        row = finger_count>1;
        T_RT_Imprv = anovaMixed(imprv(row),sn(row),'within',finger_count(row),{'finger count'});
        fprintf("\n")
        
    case 'training_models_finger_count'
        C_MD = dload(fullfile(project_path,'analysis','training_models_MD.tsv'));
        C_RT = dload(fullfile(project_path,'analysis','training_models_RT.tsv'));
        C_ET = dload(fullfile(project_path,'analysis','training_models_ET.tsv'));
        MD_ceil = C_MD.r_ceil(1:14);
        ET_ceil = C_ET.r_ceil(1:14);
        
        % get rows for the finger_count model:
        model_table = struct2table(C_MD);
        model_table = model_table(:,6:end);
        rows = model_table.n_fing==1 & all(model_table{:,2:end}==0, 2);

        % get fitted r for MD and RT:
        r_MD = C_MD.r(rows);
        
        % barplot:
        x = [ones(length(r_MD),1)];
        y = [r_MD];
        split = [ones(length(r_MD),1)];
        figure('Units','centimeters', 'Position',[15 15 3 6]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{colors_gray(1,:)},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        fprintf("\nnumber of fingers prediction of MD: r = %.2f\n",mean(y))
        fprintf("MD noise ceil = %.2f\n",mean(MD_ceil))
        drawline(mean(MD_ceil),'dir','horz','lim',[x_coord(1)-barwidth,x_coord(1)+barwidth],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        % drawline(mean(RT_ceil),'dir','horz','lim',[x_coord(1)-barwidth/1.5 x_coord(1)+barwidth/1.5],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        h.XTick = [1 2.5];
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [0,0.5,1];
        ylim([0 1])
        xlim([x_coord(1)-barwidth,x_coord(1)+barwidth])
        ylabel('model fit (Pearson''s r)','FontSize',my_font.label)
        xlabel('number of fingers model','FontSize',my_font.label)
        fontname("Arial")

        % get fitted r for MD and RT:
        r_ET = C_ET.r(rows);
        
        % barplot:
        x = [ones(length(r_ET),1)];
        y = [r_ET];
        split = [ones(length(r_ET),1)];
        figure('Units','centimeters', 'Position',[15 15 4 6]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{colors_gray(1,:)},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        drawline(mean(ET_ceil),'dir','horz','lim',[x_coord(1)-barwidth,x_coord(1)+barwidth],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        % drawline(mean(RT_ceil),'dir','horz','lim',[x_coord(1)-barwidth/1.5 x_coord(1)+barwidth/1.5],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        h.XTick = [1 2.5];
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [0,0.5,1];
        ylim([0 1])
        xlim([x_coord(1)-barwidth,x_coord(1)+barwidth])
        ylabel('model fit (Pearson''s r)','FontSize',my_font.label)
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")

        % stats:
        [t_md,p_md] = ttest(r_MD,MD_ceil,2,'paired');
        [t_rt,p_rt] = ttest(r_ET,ET_ceil,2,'paired');
        fprintf('\nFinger Count Model:\n')
        fprintf('MD explained vs noise-ceiling: (%.6f,%.6f)\n',t_md,p_md)
        fprintf('ET explained vs noise-ceiling: (%.6f,%.6f)\n',t_rt,p_rt)
        
    case 'model_comparison'
        C = dload(fullfile(project_path,'analysis','emg_models_MD.tsv'));
        ceil = C.r_ceil(1:14);
        ceil_mean = mean(ceil);
        ceil_sem = std(ceil)/sqrt(length(ceil));
        
        % get rows for the finger_count model:
        model_table = struct2table(C);
        model_table = model_table(:,6:end);
        rows_nfing = model_table.n_fing==1 & all(model_table{:,2:end}==0, 2);
        
        % get rows for the force_avg model:
        rows_force = model_table.n_fing==1 & model_table.force_avg==1 & all(model_table{:,[2:4,6:end]}==0, 2);

        % get rows for the transition model:
        rows_trans = model_table.n_fing==1 & model_table.transition==1 & all(model_table{:,[3:end]}==0, 2);

        % get rows for the emg model:
        rows_emg = model_table.n_fing==1 & model_table.emg_additive_avg==1 & all(model_table{:,[2:6,8:end]}==0, 2);

        % get fitted r for models
        r_nfing = C.r(rows_nfing);
        r_force = C.r(rows_force);
        r_trans = C.r(rows_trans);
        r_emg = C.r(rows_emg);
        
        % barplot:
        x = [ones(length(r_force),1) ; 2*ones(length(r_trans),1) ; 3*ones(length(r_emg),1)];
        y = [r_force ; r_trans ; r_emg];
        split = [ones(length(r_force),1) ; 2*ones(length(r_trans),1) ; 3*ones(length(r_emg),1)];
        figure('Units','centimeters', 'Position',[15 15 5 6]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{colors_gray(4,:),colors_gray(2,:),[1,1,1]},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        % Draw a gray rectangle
        % rectangle('Position', [x_coord(1)-barwidth, ceil_mean-ceil_sem/2, x_coord(end)-x_coord(1)+2*barwidth, ceil_sem], 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'none');
        drawline(mean(ceil),'dir','horz','lim',[x_coord(1)-barwidth x_coord(end)+barwidth],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        % h.XTick = [1 2.5];
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [round(mean(r_nfing),2),round(mean(ceil),2),1];
        ylim([round(mean(r_nfing),2) 1])
        % xlim([x_coord(1)-barwidth,x_coord(2)+barwidth])
        ylabel('model fit (Pearson''s r)','FontSize',my_font.label)
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")

        fprintf("\nnumber of fingers prediction of MD: r = %.2f\n",mean(r_nfing))
        fprintf("MD noise ceil = %.2f\n",mean(ceil))

        fprintf("\nPrediction correlations:\n")
        fprintf('   baseline: %.4f +- %.4f\n',mean(r_nfing),std(r_nfing)/sqrt(length(r_nfing)));
        fprintf('   noise ceiling: %.4f +- %.4f\n',mean(ceil),std(ceil)/sqrt(length(ceil)));
        fprintf('   Muslce: %.4f +- %.4f\n',mean(r_emg),std(r_emg)/sqrt(length(r_emg)));
        fprintf('   Force: %.4f +- %.4f\n',mean(r_force),std(r_force)/sqrt(length(r_force)));
        fprintf('   Complexity: %.4f +- %.4f\n',mean(r_trans),std(r_trans)/sqrt(length(r_trans)));

        % stats:
        [t,p] = ttest(ceil,r_nfing,1,'paired');
        fprintf('\nttest ceiling > nfing: (%.6f,%.16e)\n',t,p)

        [t,p] = ttest(r_trans,r_force,1,'paired');
        fprintf('\nttest transition > force: (%.6f,%.16e)\n',t,p)

        [t,p] = ttest(r_emg,r_nfing,1,'paired');
        fprintf('\nttest emg > nfing: (%.6f,%.16e)\n',t,p)

        [t,p] = ttest(r_emg,r_trans,1,'paired');
        fprintf('\nttest emg > transition: (%.6f,%.16e)\n',t,p)
        
        [t,p] = ttest(r_emg,r_force,1,'paired');
        fprintf('\nttest emg > force: (%.6f,%.16e)\n',t,p)

        [t,p] = ttest(ceil,r_emg,2,'paired');
        fprintf('\nttest ceiling > emg: (%.6f,%.16e)\n',t,p)
    
    

    case 'nSphere_correlation'
        C = dload(fullfile(project_path,'analysis','natChord_analysis.tsv'));
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        chords_emg = C.chordID(C.sn==1 & C.sess==1);
        data = getrow(data,ismember(data.chordID,chords_emg));
        data = getrow(data,data.sess>=3);

        [~, ~, MD_avg, COND, ~] = get_sem(data.MD, ones(length(data.sn),1), ones(length(data.sn),1), data.chordID);
        [~, ~, log_avg, COND, ~] = get_sem(C.log_slope, ones(length(C.sn),1), ones(length(C.sn),1), C.chordID);
        
        finger_count = get_num_active_fingers(COND);
        fc = unique(finger_count);
        model_corr = zeros(length(fc),1);
        p_val = zeros(length(fc),1);
        ylims = [[0 0.3] ; [0.1 1.5] ; [0.3 2.1]];
        % ylims = [[300 480] ; [500 2200] ; [900 2200]]; % for ET
        xlims = [[7 19] ; [8.2 12.8] ; [8.7 12.8]];
        for i = 1:length(fc)
            x = log_avg(finger_count==fc(i));
            y = MD_avg(finger_count==fc(i));
            chords = COND(finger_count==fc(i));
            [~,sort_idx] = sort(x);
            fprintf('%d-finger chords ascending naturality:\n',fc(i))
            disp(chords(sort_idx))
            md = fitlm(x, y);
            p_val(i) = md.Coefficients.pValue(2);
            coefs = md.Coefficients.Estimate;
            model_corr(i) = corr(x,y);

            num_sample_plot = 1000;
            x_plot = linspace(min(x),max(x), num_sample_plot)';
            y_plot = [ones(num_sample_plot,1), x_plot]*coefs;
            figure('Units','centimeters', 'Position',[15 15 5 5]);
            plot(x_plot, y_plot, 'Color', colors_gray(5,:), 'LineWidth',1); hold on;
            scatter(x, y, 15, "filled", "MarkerFaceColor", colors_gray(1,:), 'MarkerEdgeColor', colors_gray(5,:), 'LineWidth', 0.7); 
            box off
            h = gca;
            h.XTick = [xlims(i,1), round((xlims(i,1)+xlims(i,2))/2,2), xlims(i,2)];
            h.XAxis.FontSize = my_font.tick_label;
            h.YAxis.FontSize = my_font.tick_label;
            h.LineWidth = paper.axis_width;
            h.YTick = [ylims(i,1), round((ylims(i,1)+ylims(i,2))/2,2), ylims(i,2)];
            ylim(ylims(i,:))
            xlim([xlims(i,1)-0.5 xlims(i,2)+0.5])
            ylabel('mean deviation','FontSize',my_font.label)
            xlabel('$log(\frac{n}{d^{10}})$, naturalness likelihood','interpreter','LaTex','FontSize',my_font.label)
            fontname("Arial")
        end
        fprintf('corr: %.6f, %.6f, %.6f\n',model_corr(1),model_corr(2),model_corr(3))
        fprintf('corr significance: %.6f, %.6f, %.6f\n',p_val(1),p_val(2),p_val(3))
    
    case 'magnitude_correlation'
        C = dload(fullfile(project_path,'analysis','natChord_analysis.tsv'));
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        chords_emg = C.chordID(C.sn==1 & C.sess==1);
        data = getrow(data,ismember(data.chordID,chords_emg));
        data = getrow(data,data.sess>=3);
        
        [~, ~, MD_avg, COND, ~] = get_sem(data.MD, ones(length(data.sn),1), ones(length(data.sn),1), data.chordID);
        [~, ~, magnitude_avg, COND, ~] = get_sem(C.magnitude, ones(length(C.sn),1), ones(length(C.sn),1), C.chordID);
        
        finger_count = get_num_active_fingers(COND);
        fc = unique(finger_count);
        ylims = [[0 0.3] ; [0.1 1.5] ; [0.3 2.1]];
        % ylims = [[300 480] ; [500 2200] ; [900 2200]]; % for ET
        xlims = [[0.1 0.35] ; [0.2 0.5] ; [0.25 0.6]];
        p_val = zeros(length(fc),1);
        model_corr = zeros(length(fc),1);
        for i = 1:length(fc)
            x = magnitude_avg(finger_count==fc(i));
            y = MD_avg(finger_count==fc(i));
            chords = COND(finger_count==fc(i));
            
            [~,sort_idx] = sort(x);
            fprintf('%d-finger chords ascending magnitude (first and last 3 chords):\n',fc(i))
            disp(chords(sort_idx([1:3 , end-2:end])))
            md = fitlm(x, y);
            p_val(i) = md.Coefficients.pValue(2);
            coefs = md.Coefficients.Estimate;
            model_corr(i) = corr(x,y);
            num_sample_plot = 1000;
            x_plot = linspace(min(x),max(x), num_sample_plot)';
            y_plot = [ones(num_sample_plot,1), x_plot]*coefs;
            figure('Units','centimeters', 'Position',[15 15 5 5]);
            plot(x_plot, y_plot, 'Color', colors_gray(5,:), 'LineWidth',1); hold on;
            scatter(x, y, 15, "filled", "MarkerFaceColor", colors_gray(1,:), 'MarkerEdgeColor', colors_gray(5,:), 'LineWidth', 0.7); 
            box off
            h = gca;
            h.XTick = [xlims(i,1), round((xlims(i,1)+xlims(i,2))/2,2), xlims(i,2)];
            h.XAxis.FontSize = my_font.tick_label;
            h.YAxis.FontSize = my_font.tick_label;
            h.LineWidth = paper.axis_width;
            h.YTick = [ylims(i,1), round((ylims(i,1)+ylims(i,2))/2,2), ylims(i,2)];
            ylim(ylims(i,:))
            xlim([xlims(i,1)-0.05 xlims(i,2)+0.05])
            ylabel('mean deviation','FontSize',my_font.label)
            xlabel('$$\| \vec{m}_i \|_{2}$$, muscle magnitude','interpreter','LaTex','FontSize',my_font.label)
            fontname("Arial")
        end
        fprintf('corr: %.6f, %.6f, %.6f\n',model_corr(1),model_corr(2),model_corr(3))
        fprintf('corr significance: %.6f, %.6f, %.6f\n',p_val(1),p_val(2),p_val(3))
    case 'coact_correlation'
        C = dload(fullfile(project_path,'analysis','natChord_analysis.tsv'));
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        chords_emg = C.chordID(C.sn==1 & C.sess==1);
        data = getrow(data,ismember(data.chordID,chords_emg));
        data = getrow(data,data.sess>=3);

        [~, ~, MD_avg, COND, ~] = get_sem(data.MD, ones(length(data.sn),1), ones(length(data.sn),1), data.chordID);
        [~, ~, coact_avg, COND, ~] = get_sem(C.coact, ones(length(C.sn),1), ones(length(C.sn),1), C.chordID);
        
        finger_count = get_num_active_fingers(COND);
        fc = unique(finger_count);
        ylims = [[0 0.3] ; [0.1 1.5] ; [0.3 2.1]];
        % ylims = [[300 480] ; [500 2200] ; [900 2200]]; % for ET
        xlims = [[0.1 0.35] ; [0.2 0.5] ; [0.25 0.6]];
        p_val = zeros(length(fc),1);
        model_corr = zeros(length(fc),1);
        for i = 1:length(fc)
            x = coact_avg(finger_count==fc(i));
            y = MD_avg(finger_count==fc(i));
            chords = COND(finger_count==fc(i));
            
            [~,sort_idx] = sort(x);
            fprintf('%d-finger chords ascending coact (first and last 3 chords):\n',fc(i))
            disp(chords(sort_idx([1:3 , end-2:end])))
            md = fitlm(x, y);
            p_val(i) = md.Coefficients.pValue(2);
            coefs = md.Coefficients.Estimate;
            model_corr(i) = corr(x,y);
            num_sample_plot = 1000;
            x_plot = linspace(min(x),max(x), num_sample_plot)';
            y_plot = [ones(num_sample_plot,1), x_plot]*coefs;
            figure('Units','centimeters', 'Position',[15 15 5 5]);
            plot(x_plot, y_plot, 'Color', colors_gray(5,:), 'LineWidth',1); hold on;
            scatter(x, y, 15, "filled", "MarkerFaceColor", colors_gray(1,:), 'MarkerEdgeColor', colors_gray(5,:), 'LineWidth', 0.7); 
            box off
            h = gca;
            h.XTick = [xlims(i,1), round((xlims(i,1)+xlims(i,2))/2,2), xlims(i,2)];
            h.XAxis.FontSize = my_font.tick_label;
            h.YAxis.FontSize = my_font.tick_label;
            h.LineWidth = paper.axis_width;
            h.YTick = [ylims(i,1), round((ylims(i,1)+ylims(i,2))/2,2), ylims(i,2)];
            % ylim(ylims(i,:))
            % xlim([xlims(i,1)-0.05 xlims(i,2)+0.05])
            ylabel('mean deviation','FontSize',my_font.label)
            xlabel('$$\| \vec{m}_i \|_{2}$$, muscle coact','interpreter','LaTex','FontSize',my_font.label)
            fontname("Arial")
        end
        fprintf('corr: %.6f, %.6f, %.6f\n',model_corr(1),model_corr(2),model_corr(3))
        fprintf('corr significance: %.6f, %.6f, %.6f\n',p_val(1),p_val(2),p_val(3))
    case 'within_finger_model'
        C = dload(fullfile(project_path,'analysis','natChord_analysis.tsv'));
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        chords_emg = C.chordID(C.sn==1 & C.sess==1);
        data = getrow(data,ismember(data.chordID,chords_emg));
        data = getrow(data,data.sess>=3);

        [~, ~, MD_avg, COND_MD, SN] = get_sem(data.MD, data.sn, ones(length(data.sn),1), data.chordID);
        [~, ~, log_avg, COND_log, ~] = get_sem(C.log_slope, ones(length(C.sn),1), ones(length(C.sn),1), C.chordID);
        [~, ~, mag_avg, COND_mag, ~] = get_sem(C.magnitude, ones(length(C.sn),1), ones(length(C.sn),1), C.chordID);
        [~, ~, coact_avg, COND_coact, ~] = get_sem(C.coact, ones(length(C.sn),1), ones(length(C.sn),1), C.chordID);
        
        SN_unique = unique(SN);
        finger_count_MD = get_num_active_fingers(COND_MD);
        finger_count_log = get_num_active_fingers(COND_log);
        
        fc = unique(finger_count_MD);
        ana = [];
        % loop on finger count:
        for j = 1:length(fc)
            % get the noise ceiling:
            [ceil,~] = crossval_reliability(MD_avg(finger_count_MD==fc(j)),'split',SN(finger_count_MD==fc(j)));
            % loop on subj:
            for i = 1:length(SN_unique)
                x = MD_avg(SN==SN_unique(i) & finger_count_MD==fc(j));
                y_log = log_avg(finger_count_log==fc(j));
                y_mag = mag_avg(finger_count_log==fc(j));
                y_coact = coact_avg(finger_count_log==fc(j));
                
                ana_tmp.sn = SN_unique(i);
                ana_tmp.finger_count = fc(j);
                ana_tmp.corr_log = -corr(x,y_log);
                ana_tmp.corr_mag = corr(x,y_mag);
                ana_tmp.corr_coact = corr(x,y_coact);
                ana_tmp.ceil = ceil(i);
                ana = addstruct(ana,ana_tmp,'row','force');
            end
        end
        varargout{1} = ana;
        
        % barplot:
        ceil1 = mean(ana.ceil(ana.finger_count==1));
        ceil3 = mean(ana.ceil(ana.finger_count==3));
        ceil5 = mean(ana.ceil(ana.finger_count==5));
        x = [ana.finger_count ; ana.finger_count ; ana.finger_count];
        y = [ana.corr_mag ; ana.corr_log ; ana.corr_coact] ./ [repelem([ceil1;ceil3;ceil5],length(SN_unique),1) ; repelem([ceil1;ceil3;ceil5],length(SN_unique),1) ; repelem([ceil1;ceil3;ceil5],length(SN_unique),1)];
        split = [ones(length(ana.finger_count),1) ; 2*ones(length(ana.finger_count),1) ; 3*ones(length(ana.finger_count),1)];
        figure('Units','centimeters', 'Position',[15 15 6 6]);
        barwidth = 1;
        bar_colors = {colors_pastel(1,:),colors_blue(3,:),colors_blue(2,:)};
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',bar_colors,'barwidth',barwidth,'gapwidth',[1 0 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        hold on;
        drawline(1,'dir','horz','lim',[0 9],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        % h.XTick = [1 2.5];
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        % h.YTick = [0,0.5,1];
        ylim([0 1])
        xlim([0,12])
        ylabel('normalized correlation (Pearson''s)','FontSize',my_font.label)
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")
        
        % model correlations:
        fprintf('\nnSphere Corrs:\n')
        fprintf('   1-f: %.3f +- %.3f\n',mean(ana.corr_log(ana.finger_count==1)),std(ana.corr_log(ana.finger_count==1))/sqrt(14));
        fprintf('   3-f: %.3f +- %.3f\n',mean(ana.corr_log(ana.finger_count==3)),std(ana.corr_log(ana.finger_count==3))/sqrt(14));
        fprintf('   5-f: %.3f +- %.3f\n',mean(ana.corr_log(ana.finger_count==5)),std(ana.corr_log(ana.finger_count==5))/sqrt(14));
        
        fprintf('\nMagnitude Corrs:\n')
        fprintf('   1-f: %.3f +- %.3f\n',mean(ana.corr_mag(ana.finger_count==1)),std(ana.corr_mag(ana.finger_count==1))/sqrt(14));
        fprintf('   1-f: %.3f +- %.3f\n',mean(ana.corr_mag(ana.finger_count==3)),std(ana.corr_mag(ana.finger_count==3))/sqrt(14));
        fprintf('   1-f: %.3f +- %.3f\n',mean(ana.corr_mag(ana.finger_count==5)),std(ana.corr_mag(ana.finger_count==5))/sqrt(14));
        % 
        % fprintf('\nCoact Corrs:\n')
        % fprintf('   1-f: %.2f (%.2f-%.2f)\n',mean(ana.corr_coact(ana.finger_count==1))/ceil1,min(ana.corr_coact(ana.finger_count==1))/ceil1,max(ana.corr_coact(ana.finger_count==1))/ceil1);
        % fprintf('   3-f: %.2f (%.2f-%.2f)\n',mean(ana.corr_coact(ana.finger_count==3))/ceil3,min(ana.corr_coact(ana.finger_count==3))/ceil3,max(ana.corr_coact(ana.finger_count==3))/ceil3);
        % fprintf('   5-f: %.2f (%.2f-%.2f)\n',mean(ana.corr_coact(ana.finger_count==5))/ceil5,min(ana.corr_coact(ana.finger_count==5))/ceil5,max(ana.corr_coact(ana.finger_count==5))/ceil5);
        
        % stats compared to 0 corr:
        [t1,p1] = ttest(ana.corr_mag(ana.finger_count==1),[],1,'onesample');
        [t3,p3] = ttest(ana.corr_mag(ana.finger_count==3),[],1,'onesample');
        [t5,p5] = ttest(ana.corr_mag(ana.finger_count==5),[],1,'onesample');
        fprintf('\nMagnitude:');
        fprintf('\n     1-f: (%.6f,%.16e)\n     3-f: (%.6f,%.16e)\n     5-f: (%.6f,%.16e)\n',t1,p1,t3,p3,t5,p5)
        
        [t1,p1] = ttest(ana.corr_log(ana.finger_count==1),[],1,'onesample');
        [t3,p3] = ttest(ana.corr_log(ana.finger_count==3),[],1,'onesample');
        [t5,p5] = ttest(ana.corr_log(ana.finger_count==5),[],1,'onesample');
        fprintf('\nnSphere:');
        fprintf('\n     1-f: (%.6f,%.16e)\n     3-f: (%.6f,%.16e)\n     5-f: (%.6f,%.16e)\n',t1,p1,t3,p3,t5,p5)
        
        [t1,p1] = ttest(ana.corr_coact(ana.finger_count==1),[],1,'onesample');
        [t3,p3] = ttest(ana.corr_coact(ana.finger_count==3),[],1,'onesample');
        [t5,p5] = ttest(ana.corr_coact(ana.finger_count==5),[],1,'onesample');
        fprintf('\nCoact:');
        fprintf('\n     1-f: (%.6f,%.16e)\n     3-f: (%.6f,%.16e)\n     5-f: (%.6f,%.16e)\n',t1,p1,t3,p3,t5,p5)
        
    case 'across_subj_model'
        C = dload(fullfile(project_path,'analysis','emg_models_MD.tsv'));
        ceil = C.r_ceil(1:14);
        
        % get rows for the finger_count model:
        model_table = struct2table(C);
        model_table = model_table(:,6:end);
        rows_nfing = model_table.n_fing==1 & all(model_table{:,2:end}==0, 2);
        
        % get rows for the magnitude model:
        rows_mag = model_table.n_fing==1 & model_table.magnitude_avg==1 & all(model_table{:,[2:9,11]}==0, 2);

        % get rows for the natural+magnitude model:
        rows_nSphere_mag = model_table.n_fing==1 & model_table.magnitude_avg==1 & model_table.nSphere_avg==1 & all(model_table{:,[2:8,11]}==0, 2);

        % get rows for the emg model:
        rows_emg = model_table.n_fing==1 & model_table.emg_additive_avg==1 & all(model_table{:,[2:6,8:end]}==0, 2);

        % get fitted r for models
        r_nfing = C.r(rows_nfing);
        r_mag = C.r(rows_mag);
        r_nSphere_mag = C.r(rows_nSphere_mag);
        r_emg = C.r(rows_emg);
        
        % barplot:
        x = [ones(length(r_mag),1) ; 2*ones(length(r_nSphere_mag),1) ; 3*ones(length(r_emg),1)];
        y = [r_mag ; r_nSphere_mag ; r_emg];
        split = [ones(length(r_mag),1) ; 2*ones(length(r_nSphere_mag),1) ; 3*ones(length(r_emg),1)];
        figure('Units','centimeters', 'Position',[15 15 5 6]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{hex2rgb('#C4B7C8'),hex2rgb('#FF8A80'),[1,1,1]},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        drawline(mean(ceil),'dir','horz','lim',[x_coord(1)-barwidth x_coord(end)+barwidth],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [round(mean(r_nfing),2),round(mean(ceil),2),1];
        ylim([round(mean(r_nfing),2) 1])
        xlim([x_coord(1)-barwidth,x_coord(end)+barwidth])
        ylabel('model fit (Pearson''s r)','FontSize',my_font.label)
        xlabel('place holder','FontSize',my_font.label)
        fontname("Arial")

        % model correlations:
        fprintf('\nPrediction corrs:\n')
        fprintf('   mag: %.3f +- %.3f\n',mean(r_mag),std(r_mag)/sqrt(14));
        fprintf('   nat+mag: %.3f +- %.3f\n',mean(r_nSphere_mag),std(r_nSphere_mag)/sqrt(14));

        % stats:
        [t,p] = ttest(r_mag,r_nfing,1,'paired');
        fprintf('\nttest mag > baseline: (%.6f,%.16e)\n',t,p)

        [t,p] = ttest(r_nSphere_mag,r_nfing,1,'paired');
        fprintf('ttest nSphere+mag > baseline: (%.6f,%.16e)\n',t,p)
        
        [t,p] = ttest(r_nSphere_mag,r_mag,1,'paired');
        fprintf('ttest nSphere+mag > mag: (%.6f,%.16e)\n',t,p)
        
        [t,p] = ttest(ceil,r_nSphere_mag,1,'paired');
        fprintf('ttest ceiling > nSpehre+mag: (%.6f,%.16e)\n',t,p)
        
        [t,p] = ttest(r_emg,r_nSphere_mag,1,'paired');
        fprintf('ttest muscle model > nSpehre+mag: (%.6f,%.16e)\n',t,p)
    
    case 'across_subj_model_coact'
        C = dload(fullfile(project_path,'analysis','emg_models_MD.tsv'));
        ceil = C.r_ceil(1:14);
        
        % get rows for the finger_count model:
        model_table = struct2table(C);
        model_table = model_table(:,6:end);
        rows_nfing = model_table.n_fing==1 & all(model_table{:,2:end}==0, 2);
        
        % get rows for the magnitude model:
        rows_mag = model_table.n_fing==1 & model_table.magnitude_avg==1 & all(model_table{:,[2:9,11]}==0, 2);

        rows_mag_coact = model_table.n_fing==1 & model_table.magnitude_avg==1 & model_table.coact_avg==1 & all(model_table{:,[2:9]}==0, 2);

        % get rows for the natural+magnitude model:
        % rows_nSphere_mag = model_table.n_fing==1 & model_table.magnitude_avg==1 & model_table.nSphere_avg==1 & all(model_table{:,[2:8]}==0, 2);
            
        rows_nSphere_mag_coact = model_table.n_fing==1 & model_table.magnitude_avg==1 & model_table.coact_avg==1 & model_table.nSphere_avg==1 & all(model_table{:,[2:8]}==0, 2);
        
        % get rows for the emg model:
        rows_emg = model_table.n_fing==1 & model_table.emg_additive_avg==1 & all(model_table{:,[2:6,8:end]}==0, 2);

        % get fitted r for models
        r_nfing = C.r(rows_nfing);
        r_mag = C.r(rows_mag);
        r_mag_coact = C.r(rows_mag_coact);
        r_nSphere_mag_coact = C.r(rows_nSphere_mag_coact);
        r_emg = C.r(rows_emg);
        
        % barplot:
        x = [ones(length(r_mag),1) ; 2*ones(length(r_mag_coact),1) ; 3*ones(length(r_nSphere_mag_coact),1) ; 4*ones(length(r_emg),1)];
        y = [r_mag ; r_mag_coact ; r_nSphere_mag_coact ; r_emg];
        split = [ones(length(r_mag),1) ; 2*ones(length(r_mag_coact),1); 3*ones(length(r_nSphere_mag_coact),1) ; 4*ones(length(r_emg),1)];
        figure('Units','centimeters', 'Position',[15 15 5 6]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{hex2rgb('#C4B7C8'),hex2rgb('#FF8A80'),[1,1,1]},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        drawline(mean(ceil),'dir','horz','lim',[x_coord(1)-barwidth x_coord(end)+barwidth],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [round(mean(r_nfing),2),round(mean(ceil),2),1];
        ylim([round(mean(r_nfing),2) 1])
        xlim([x_coord(1)-barwidth,x_coord(end)+barwidth])
        ylabel('model fit (Pearson''s r)','FontSize',my_font.label)
        xlabel('place holder','FontSize',my_font.label)
        fontname("Arial")

        % stats:
        [t,p] = ttest(r_mag,r_nfing,2,'paired');
        fprintf('\nttest mag != baseline: (%.6f,%.6f)\n',t,p)

        [t,p] = ttest(r_mag_coact,r_mag,1,'paired');
        fprintf('ttest mag+coact > mag: (%.6f,%.6f)\n',t,p)
        
        [t,p] = ttest(r_nSphere_mag_coact,r_mag_coact,1,'paired');
        fprintf('ttest nSphere+mag+coact > mag+coact: (%.6f,%.6f)\n',t,p)
        
        [t,p] = ttest(ceil,r_nSphere_mag_coact,1,'paired');
        fprintf('ttest ceiling > nSpehre+mag+coact: (%.6f,%.6f)\n',t,p)
        
        [t,p] = ttest(r_emg,r_nSphere_mag_coact,1,'paired');
        fprintf('ttest muscle model > nSpehre+mag+coact: (%.6f,%.6f)\n',t,p)
    case 'explained_var_by_natural'
        C = dload(fullfile(project_path,'analysis','natChord_pca.tsv'));
        halves = unique(C.half);
        PCs = C.PC(1:100);
        avg_nat = 0;
        avg_chord = 0;
        % avg across halves:
        for i = 1:length(halves)
            row = C.half==halves(i);
            avg_nat = avg_nat + C.nat_explained(row)/length(halves);
            avg_chord = avg_chord + C.chord_explained(row)/length(halves);
        end
        nat_mean = mean(reshape(avg_nat,[length(unique(PCs)),length(unique(C.sn))]),2);
        chord_mean = mean(reshape(avg_chord,[length(unique(PCs)),length(unique(C.sn))]),2);
        nat_sem = std(reshape(avg_nat,[length(unique(PCs)),length(unique(C.sn))]),0,2) / sqrt(length(unique(C.sn)));
        chord_sem = std(reshape(avg_chord,[length(unique(PCs)),length(unique(C.sn))]),0,2) / sqrt(length(unique(C.sn)));
        x = (1:length(unique(PCs)))';

        figure('Units','centimeters', 'Position',[15 15 7 7]);
        hold on;
        drawline(0,'dir','horz','linestyle',':','linewidth',paper.horz_line_width,'color',[0.8 0.8 0.8],'lim',[0 11])
        patch([x ; flipud(x)], [nat_mean + nat_sem ; flipud(nat_mean - nat_sem)], colors_gray(2,:),...
              'FaceAlpha', 0.3, 'EdgeColor', 'none'); % SEM patch for nat
        patch([x ; flipud(x)], [chord_mean + chord_sem ;flipud(chord_mean - chord_sem)], colors_cyan(5,:), ...
              'FaceAlpha', 0.2, 'EdgeColor', 'none'); % SEM patch for var2
        [~,PLOT,~] = lineplot(PCs,avg_nat,'markertype','o','markersize',paper.lineplot_marker_size-2.5,'markerfill',colors_gray(2,:),'markercolor',colors_gray(2,:),'linecolor',colors_gray(2,:),'linewidth',paper.lineplot_line_width*0.7,'errorcolor','none','errorcap',0);
        [~,PLOT_chord,~] = lineplot(PCs,avg_chord,'markertype','o','markersize',paper.lineplot_marker_size-2.5,'markerfill',colors_cyan(5,:),'markercolor',colors_cyan(5,:),'linecolor',colors_cyan(5,:),'linewidth',paper.lineplot_line_width*0.7,'errorcolor','none','errorcap',0);
        
        legend({'','natural EMG','','','','','','','','','','','chord EMG'},'FontSize',my_font.legend);
        legend('boxoff')
        box off
        h = gca;
        % h.XTick = [1 2.5];
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [0,35,70];
        ylim([-5 70])
        xlim([0,11])
        ylabel('Variance Explained by Component','FontSize',my_font.label)
        xlabel('Natural PCs','FontSize',my_font.label)
        fontname("Arial")
        
        fprintf('\nnatural PC1 to PC5 explains: %.2f\n',sum(PLOT(1:5)))

        fprintf('projection of chord onto PC1 to PC5 explains: %.2f\n\n',sum(PLOT_chord(1:5)))
        
        % stats:
        n_pc = length(unique(PCs));
        for i = 1:n_pc
            [t,p] = ttest(avg_chord(PCs==i),avg_nat(PCs==i),2,'paired');
            fprintf('PC %d: (%.6f,%.16e)\n',i,t,p)
        end
        
    case 'single_PC_impaired_model'
        C = dload(fullfile(project_path,'analysis','natChord_single_pc_impared.tsv'));
        halves = unique(C.half);
        
        r2_force_by_nat = 0;
        r2_force_by_chord = 0;
        for i = 1:length(halves)
            row = C.half == halves(i);
            [~, ~, r2_force1_tmp, COND, SN] = get_sem(C.r2_force_by_nat(row), C.sn(row), ones(sum(row),1), C.dim(row));
            [~, ~, r2_force2_tmp, COND, SN] = get_sem(C.r2_force_by_chord(row), C.sn(row), ones(sum(row),1), C.dim(row));
            
            r2_force_by_nat = r2_force_by_nat + r2_force1_tmp/length(halves);
            r2_force_by_chord = r2_force_by_chord + r2_force2_tmp/length(halves);
        end

        % barplot:
        figure('Units','centimeters', 'Position',[15 15 6.5 3]);
        lineplot(COND,r2_force_by_nat,'markertype','o','markersize',paper.lineplot_marker_size-2,'markerfill',colors_gray(5,:),'markercolor',colors_gray(5,:),'linecolor',colors_gray(5,:),'linewidth',paper.lineplot_line_width-0.5,'errorcolor',colors_gray(5,:),'errorcap',0);
        box off
        h = gca;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [0,0.1,0.2];
        h.XTick = 1:10;
        ylim([0 0.2])
        xlim([0,11])
        ylabel('force pattern explained (R-squared)','FontSize',my_font.label)
        xlabel('Natural PCs','FontSize',my_font.label)
        fontname("Arial")
        anovaMixed(r2_force_by_nat,SN,'within',COND,{'PCs'});

    
    case 'PCA_accumulative'
        C = dload(fullfile(project_path,'analysis','natChord_impaired_model_crossval.tsv'));
        halves = unique(C.half);
        
        r2_forward = 0;
        r2_backward = 0;
        for i = 1:length(halves)
            row = C.half == halves(i);
            [~, ~, r2_force1_tmp, COND1, SN] = get_sem(C.r2_force1(row), C.sn(row), ones(sum(row),1), C.dim1(row));
            r2_forward = r2_forward + r2_force1_tmp/length(halves);

            [~, ~, r2_force2_tmp, COND2, SN] = get_sem(C.r2_force2(row), C.sn(row), ones(sum(row),1), C.dim2(row));
            r2_backward = r2_backward + r2_force2_tmp/length(halves);
        end
        
        % plot:
        % figure('Units','centimeters', 'Position',[15 15 8 5]);
        % x = [COND1 ; 11-COND2];
        % y = [r2_forward ; r2_backward];
        % split = [ones(length(r2_forward),1) ; 2*ones(length(r2_backward),1)];
        % barwidth = 1;
        % [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{colors_gray(3,:),[1,1,1]},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',0.7,'capwidth',0); hold on;
        % hold on;
        % drawline(1,'dir','horz','lim',[x_coord(1)-1,x_coord(end)+1],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        % box off
        % h = gca;
        % h.XAxis.FontSize = my_font.tick_label;
        % h.YAxis.FontSize = my_font.tick_label;
        % h.LineWidth = paper.axis_width;
        % h.YTick = [0:0.25:1];
        % ylim([0 1])
        % xlim([x_coord(1)-1,x_coord(end)+1])
        % ylabel('','FontSize',my_font.label)
        % xlabel('number of natural PCs','FontSize',my_font.label)
        % fontname("Arial")

        figure('Units','centimeters', 'Position',[15 15 6.7 4.5]);
        lineplot(COND1,r2_forward,'markertype','o','markersize',paper.lineplot_marker_size-2,'markerfill',colors_gray(3,:),'markercolor',colors_gray(3,:),'linecolor',colors_gray(3,:),'linewidth',paper.lineplot_line_width-0.5,'errorcolor',colors_gray(3,:),'errorcap',0);
        hold on;
        lineplot(11-COND2,r2_backward,'markertype','o','markersize',paper.lineplot_marker_size-2,'markerfill',colors_random(5,:),'markercolor',colors_random(5,:),'linecolor',colors_random(5,:),'linewidth',paper.lineplot_line_width-0.5,'errorcolor',colors_random(5,:),'errorcap',0);
        drawline(1,'dir','horz','lim',[0,11],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [0:0.25:1];
        h.XTick = 1:10;
        xlim([0,11])
        ylim([0 1])
        ylabel('R^2 reconstructed force','FontSize',my_font.label)
        xlabel('number of natural PCs','FontSize',my_font.label)
        fontname("Arial")

        % ANOVA:
        fprintf('2-way ANOVA, cummulative force prediction:\n')
        Y = [r2_forward ; r2_backward];
        pc_num = [COND1;11-COND2];
        group = [ones(size(r2_forward));2*ones(size(r2_backward))];
        T = anovaMixed(Y,[SN;SN],'within',[pc_num,group],{'PC','group'});
        fprintf("\n")

        % ttest:
        for i = 1:10
            [t,p] = ttest(r2_forward(COND1==i), r2_backward((11-COND2)==i), 2, 'paired');
            fprintf('\ndim = %d: (%.4f,%.6f)',i,t,p)
        end
        fprintf('\n')
        
    case 'avg_chord_EMG'
        df = dload(fullfile(project_path,'analysis','avg_emg_patterns.tsv'));
        chords = df.chords;

        M = [df.f1_avg , df.f2_avg , df.f3_avg , df.f4_avg , df.f5_avg,...
             df.e1_avg , df.e2_avg , df.e3_avg , df.e4_avg , df.e5_avg]';
        M2 = M;

        idx = [find(chords==29999),...
               find(chords==92999),...
               find(chords==99299),...
               find(chords==99929),...
               find(chords==99992),...
               find(chords==19999),...
               find(chords==91999),...
               find(chords==99199),...
               find(chords==99919),...
               find(chords==99991)];
        M = M(:,idx);
        
        idx2 = [find(chords==11111),...
                find(chords==92912),...
                find(chords==22222),...
                find(chords==11122),...
                find(chords==29129),...
                find(chords==22111)];
        M2 = M2(:,idx2);

        % Create the colormap figure
        figure('Units','centimeters', 'Position',[15 15 7 6]);
        imagesc(M);
        clim([0 0.3])
        % Set colormap to a visually appealing one, e.g., 'parula', 'jet', 'hot'
        colormap(cividis);
        % Add colorbar for reference
        colorbar;
        % Customize axis labels
        % ylabel('electrode sites');
        % Adjust figure properties for better aesthetics
        set(gca, 'FontSize', 12);
        set(gcf, 'Color', 'w');
        ax = gca;
        ax.XGrid = 'on';
        ax.YGrid = 'on';
        ax.GridColor = [0, 0, 0]; % Set grid lines color to black
        ax.GridAlpha = 1; % Set grid lines transparency to fully opaque
        % Adjust the position of the grid lines
        ax.XTick = 0.5:1:68.5;
        ax.YTick = 0.5:1:10.5;
        ax.XTickLabel = {};
        ax.YTickLabel = {};
        % Set the grid lines to appear on top of the image
        ax.Layer = 'top';
        % Adjust tick length to make the grid lines fit perfectly
        ax.TickLength = [0 0];


        figure('Units','centimeters', 'Position',[15 15 4.2 6]);
        imagesc(M2);
        clim([0 0.3])
        % Set colormap to a visually appealing one, e.g., 'parula', 'jet', 'hot'
        colormap(cividis);
        % Add colorbar for reference
        % colorbar;
        % Customize axis labels
        % ylabel('electrode sites');
        % Adjust figure properties for better aesthetics
        set(gca, 'FontSize', 12);
        set(gcf, 'Color', 'w');
        ax = gca;
        ax.XGrid = 'on';
        ax.YGrid = 'on';
        ax.GridColor = [0, 0, 0]; % Set grid lines color to black
        ax.GridAlpha = 1; % Set grid lines transparency to fully opaque
        % Adjust the position of the grid lines
        ax.XTick = 0.5:1:68.5;
        ax.YTick = 0.5:1:10.5;
        ax.XTickLabel = {};
        ax.YTickLabel = {};
        % Set the grid lines to appear on top of the image
        ax.Layer = 'top';
        % Adjust tick length to make the grid lines fit perfectly
        ax.TickLength = [0 0];
                        
    case 'chord_force_examples'
        chordID = generateAllChords;
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        subj_unique = unique(data.sn);
        % choosing a random chord and subject:
        chord = chordID(randi(length(chordID)));
        sn = subj_unique(randi(length(subj_unique)));
        vararginoptions(varargin,{'chord','sn'})
        fprintf('\nplotting for subj %d\n',sn)

        % load dat:
        all_dat = dload(fullfile(project_path,'analysis','efc1_all.tsv'));
        dat = dload(fullfile(project_path,'analysis',['efc1_subj',num2str(sn,'%02d'),'_raw.tsv']));
        % load mov file:
        mov = load(fullfile(project_path,'analysis',['efc1_subj',num2str(sn,'%02d'),'_mov.mat']));
        mov = mov.MOV_struct;
        
        blocks = [[1,12];[13,24];[25,36];[37,48]];
        % loop on days:
        for i = 1:3:4
            idx = find(dat.BN >= blocks(i,1) & dat.BN <= blocks(i,2) & dat.trialCorr==1 & dat.chordID==chord);
            if (isempty(idx))
                continue
            end
            MD = all_dat.MD(all_dat.sn==sn & all_dat.sess==i & all_dat.trialCorr==1 & all_dat.chordID==chord);
            RT = all_dat.RT(all_dat.sn==sn & all_dat.sess==i & all_dat.trialCorr==1 & all_dat.chordID==chord);
            ET = all_dat.ET(all_dat.sn==sn & all_dat.sess==i & all_dat.trialCorr==1 & all_dat.chordID==chord);
            for j = 1:length(idx)
                table = mov{idx(j)};
                % trial states:
                states = table(:,1);
                % trial timing:
                time = table(:,3);
                % differential forces, d1 to d5:
                f = table(:,end-4:end);
                f = movmean(f,50,1) .* [ones(size(f,1),3),1.5*ones(size(f,1),2)];

                go_cue = time(find(states==3,1));
                t = time - go_cue;
                figure('Units','centimeters', 'Position',[15 15 5 4.3]);
                x_box = [-400, -400, 5, 5];
                y_box = [-1.2, 1.2, -1.2, 1.2]; % Assume y-axis range is 0 to 1
                % Add a gray box using the 'fill' function
                fill(x_box, y_box, [0.9 0.9 0.9], 'EdgeColor', 'none'); hold on;
                p = plot(t/1000,f,'LineWidth',1.5); hold on;
                yline(2,'--')
                yline(-2,'--')
                % xline(0+RT(j),'-')
                % xline(0+ET(j),'-')
                box off;
                for l = 1:5
                    p(l).Color = colors_colorblind(l,:);
                end
                h = gca;
                h.YTick = [-5 0 5];
                h.XTick = [0,1,2,3,4,5];
                xlim([-400,4500]/1000);
                ylim([-6 6])
                h.XAxis.FontSize = my_font.tick_label;
                h.YAxis.FontSize = my_font.tick_label;
                xlabel('trial time (s)','FontSize',my_font.label)
                ylabel('force (N)','FontSize',my_font.label)
                h.LineWidth = paper.axis_width;
                fontname("arial")
                title(sprintf('MD=%.2f, ET=%.2f',MD(j),ET(j)))
                % legend({'d1','d2','d3','d4','d5','go-cue','reaction time','forming chord'})
            end
        end

    otherwise
        error('The analysis %s you entered does not exist!',what)
end



