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

colors_blue = hex2rgb(colors_blue);
colors_green = hex2rgb(colors_green);
colors_cyan = hex2rgb(colors_cyan);
colors_gray = hex2rgb(colors_gray);
colors_random = hex2rgb(colors_random);
colors_pastel = hex2rgb(colors_pastel);

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
        C = dload(fullfile(project_path,'analysis','success_rate.tsv'));
        varargout{1} = C;

        fig = figure('Units','centimeters', 'Position',[15 15 5 6]);
        fontsize(fig, my_font.tick_label, 'points')
        drawline(1,'dir','horz','color',[0.8 0.8 0.8],'lim',[0 5],'linewidth',paper.horz_line_width,'linestyle',':'); hold on;
        
        errorbar(C.sess,C.difficult,C.difficult_sem,'LineStyle','none','CapSize',0,'Color',colors_gray(5,:),'LineWidth',paper.err_width); 
        plot(C.sess,C.difficult,'Color',colors_gray(5,:),'LineWidth',paper.line_width)
        % scatter(C.sess,C.difficult,paper.marker_size,'MarkerFaceColor',colors_gray(5,:),'MarkerEdgeColor',colors_gray(5,:));
        
        errorbar(C.sess,C.all_chords,C.all_chords_sem,'LineStyle','none','CapSize',0,'Color',colors_gray(2,:),'LineWidth',paper.err_width); 
        plot(C.sess,C.all_chords,'Color',[colors_gray(2,:), 0.6],'LineWidth',paper.line_width)
        
        lgd = legend({'','',['Most Challenging' newline 'Chord per Subject'],'','All 242 Chords'});
        legend boxoff
        fontsize(lgd,my_font.legend,'points')
        
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
        
    case 'training_performance'
        C = dload(fullfile(project_path,'analysis','training_performance.tsv'));
        
        % ======== MD ========
        fig_MD = figure('Units','centimeters', 'Position',[15 15 4.2 6]);
        % single-finger chords as baseline:
        lineplot(C.sess(C.finger_count==1),C.MD(C.finger_count==1),'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_gray(2,:),'markercolor',colors_gray(2,:),'linecolor',colors_gray(2,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_gray(2,:),'errorcap',0); hold on;
        % multi-finger chords:
        [~, X, Y, COND, SN] = get_sem(C.MD, C.sn, C.sess, ones(size(C.MD)));
        lineplot(X,Y,'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(5,:),'errorcap',0);
        h = gca;
        ylim([0 1.2])
        h.YTick = [0 0.6 1.2];
        xlim([0.5 4.5])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('days','FontSize',my_font.label)
        ylabel('MD','FontSize',my_font.label)
        h.LineWidth = paper.axis_width;
        fontname("arial")

        % stats
        fprintf("\n======= MD Improvement =======\n")
        T_MD_Imprv = anovaMixed(Y,SN,'within',X,{'days'});
        fprintf("\n")

        % ======== RT ========
        fig_RT = figure('Units','centimeters', 'Position',[15 15 4.2 6]);
        % multi-finger chords:
        [~, X, Y, COND, SN] = get_sem(C.RT, C.sn, C.sess, ones(size(C.RT)));
        lineplot(X,Y,'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(5,:),'errorcap',0);
        h = gca;
        ylim([170, 400])
        h.YTick = [170 280 400];
        xlim([0.5 4.5])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('days','FontSize',my_font.label)
        ylabel('response time','FontSize',my_font.label)
        h.LineWidth = paper.axis_width;
        fontname("arial")

        % stats
        fprintf("\n======= RT Improvement =======\n")
        T_RT_Imprv = anovaMixed(Y,SN,'within',X,{'days'});
        fprintf("\n")

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
        
        disp('gooz')


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

        % ======== RT ========
        % fig_RT = figure('Units','centimeters', 'Position',[15 15 4.5 6]);
        % [~, X, Y, COND] = get_sem(C.RT, C.sn, ones(size(C.sn)), C.finger_count);
        % lineplot(COND,Y,'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_pastel(2,:),'markercolor',colors_pastel(2,:),'linecolor',colors_pastel(2,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_pastel(2,:),'errorcap',0);
        % h = gca;
        % ylim([200 500])
        % h.YTick = [200 350 500];
        % xlim([0.5 5.5])
        % h.XAxis.FontSize = my_font.tick_label;
        % h.YAxis.FontSize = my_font.tick_label;
        % xlabel('Finger Count','FontSize',my_font.label)
        % ylabel('RT','FontSize',my_font.label)
        % h.LineWidth = paper.axis_width;
        % fontname("arial")

        % stats
        % fprintf("\nRT finger-count effect:\n")
        % T_RT = anovaMixed(Y,SN,'within',COND,{'finger count'});
        % fprintf("\n")

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
        
    case 'training_model_finger_count'
        C_MD = dload(fullfile(project_path,'analysis','training_models_MD.tsv'));
        C_RT = dload(fullfile(project_path,'analysis','training_models_RT.tsv'));
        MD_ceil = C_MD.r_ceil(1:14);
        RT_ceil = C_RT.r_ceil(1:14);
        
        % get rows for the finger_count model:
        model_table = struct2table(C_MD);
        model_table = model_table(:,6:end);
        rows = model_table.n_fing==1 & all(model_table{:,2:end}==0, 2);

        % get fitted r for MD and RT:
        r_MD = C_MD.r(rows);
        r_RT = C_RT.r(rows);
        
        % barplot:
        x = [ones(length(r_MD),1)];
        y = [r_MD];
        split = [ones(length(r_MD),1)];
        figure('Units','centimeters', 'Position',[15 15 4 6]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{colors_gray(1,:)},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
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
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")

        % stats:
        [t_md,p_md] = ttest(r_MD,MD_ceil,2,'paired');
        [t_rt,p_rt] = ttest(r_RT,RT_ceil,2,'paired');
        fprintf('\nFinger Count Model:\n')
        fprintf('MD explained vs noise-ceiling: (%.6f,%.6f)\n',t_md,p_md)
        fprintf('RT explained vs noise-ceiling: (%.6f,%.6f)\n',t_rt,p_rt)
        
    case 'emg_vs_force'
        C = dload(fullfile(project_path,'analysis','emg_models_MD.tsv'));
        ceil = C.r_ceil(1:14);

        % get rows for the finger_count model:
        model_table = struct2table(C);
        model_table = model_table(:,6:end);
        rows_nfing = model_table.n_fing==1 & all(model_table{:,2:end}==0, 2);
        
        % get rows for the force_avg model:
        model_table = struct2table(C);
        model_table = model_table(:,6:end);
        rows_force = model_table.n_fing==1 & model_table.force_avg==1 & all(model_table{:,[2:3,5:end]}==0, 2);

        % get rows for the emg model:
        model_table = struct2table(C);
        model_table = model_table(:,6:end);
        rows_emg = model_table.n_fing==1 & model_table.emg_additive_avg==1 & all(model_table{:,[2:5,7:end]}==0, 2);

        % get fitted r for models
        r_nfing = C.r(rows_nfing);
        r_force = C.r(rows_force);
        r_emg = C.r(rows_emg);
        
        % barplot:
        x = [ones(length(r_force),1) ; 2*ones(length(r_emg),1)];
        y = [r_force ; r_emg];
        split = [ones(length(r_force),1) ; 2*ones(length(r_emg),1)];
        figure('Units','centimeters', 'Position',[15 15 5 6]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{colors_gray(4,:),[1,1,1]},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        drawline(mean(ceil),'dir','horz','lim',[x_coord(1)-barwidth x_coord(2)+barwidth],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        h.XTick = [1 2.5];
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [round(mean(r_nfing),2),round(mean(ceil),2),1];
        ylim([round(mean(r_nfing),2) 1])
        xlim([x_coord(1)-barwidth,x_coord(2)+barwidth])
        ylabel('model fit (Pearson''s R)','FontSize',my_font.label)
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")

        % stats:
        [t,p] = ttest(r_emg,r_force,1,'paired');
        fprintf('\nttest emg > force: (%.6f,%.6f)\n',t,p)

        [t,p] = ttest(ceil,r_emg,2,'paired');
        fprintf('\nttest ceiling > emg: (%.6f,%.6f)\n',t,p)
    
    case 'nSphere_within_finger_corr'
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
            xlabel('$log(\frac{n}{d})$, distance from natural','interpreter','LaTex','FontSize',my_font.label)
            fontname("Arial")
        end
        fprintf('corr: %.6f, %.6f, %.6f\n',model_corr(1),model_corr(2),model_corr(3))
        fprintf('corr significance: %.6f, %.6f, %.6f\n',p_val(1),p_val(2),p_val(3))
    
    case 'magnitude_within_finger_corr'
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
            xlabel('$$\| pattern_{EMG} \|_{2}$$, muscle magnitude','interpreter','LaTex','FontSize',my_font.label)
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
                
                ana_tmp.sn = SN_unique(i);
                ana_tmp.finger_count = fc(j);
                ana_tmp.corr_log = -corr(x,y_log);
                ana_tmp.corr_mag = corr(x,y_mag);
                ana_tmp.ceil = ceil(i);
                ana = addstruct(ana,ana_tmp,'row','force');
            end
        end
        varargout{1} = ana;

        % barplot:
        ceil1 = mean(ana.ceil(ana.finger_count==1));
        ceil3 = mean(ana.ceil(ana.finger_count==3));
        ceil5 = mean(ana.ceil(ana.finger_count==5));
        x = [ana.finger_count ; ana.finger_count];
        y = [ana.corr_mag ; ana.corr_log] ./ [repelem([ceil1;ceil3;ceil5],length(SN_unique),1) ; repelem([ceil1;ceil3;ceil5],length(SN_unique),1)];
        split = [ones(length(ana.finger_count),1) ; 2*ones(length(ana.finger_count),1)];
        figure('Units','centimeters', 'Position',[15 15 6 6]);
        barwidth = 1;
        bar_colors = {colors_pastel(1,:),colors_blue(3,:)};
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',bar_colors,'barwidth',barwidth,'gapwidth',[1 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
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
        xlim([0,9])
        ylabel('normalized correlation (Pearson''s)','FontSize',my_font.label)
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")
        
        % model correlations:
        fprintf('\nnSphere Corrs:\n')
        fprintf('   1-f: %.4f (%.4f-%.4f)\n',mean(ana.corr_log(ana.finger_count==1)),min(ana.corr_log(ana.finger_count==1)),max(ana.corr_log(ana.finger_count==1)));
        fprintf('   3-f: %.4f (%.4f-%.4f)\n',mean(ana.corr_log(ana.finger_count==3)),min(ana.corr_log(ana.finger_count==3)),max(ana.corr_log(ana.finger_count==3)));
        fprintf('   5-f: %.4f (%.4f-%.4f)\n',mean(ana.corr_log(ana.finger_count==5)),min(ana.corr_log(ana.finger_count==5)),max(ana.corr_log(ana.finger_count==5)));
        
        fprintf('\nMagnitude Corrs:\n')
        fprintf('   1-f: %.4f (%.4f-%.4f)\n',mean(ana.corr_mag(ana.finger_count==1)),min(ana.corr_mag(ana.finger_count==1)),max(ana.corr_mag(ana.finger_count==1)));
        fprintf('   3-f: %.4f (%.4f-%.4f)\n',mean(ana.corr_mag(ana.finger_count==3)),min(ana.corr_mag(ana.finger_count==3)),max(ana.corr_mag(ana.finger_count==3)));
        fprintf('   5-f: %.4f (%.4f-%.4f)\n',mean(ana.corr_mag(ana.finger_count==5)),min(ana.corr_mag(ana.finger_count==5)),max(ana.corr_mag(ana.finger_count==5)));
        
        % stats:
        [t,p] = ttest(ana.corr_log(ana.finger_count==1),ana.corr_mag(ana.finger_count==1),1,'paired');
        fprintf('\n1-f nSphere > mag: (%.6f,%.6f)\n',t,p)

        [t,p] = ttest(ana.corr_mag(ana.finger_count==3),ana.corr_log(ana.finger_count==3),1,'paired');
        fprintf('\n3-f mag > nSphere: (%.6f,%.6f)\n',t,p)

        [t,p] = ttest(ana.corr_log(ana.finger_count==5),ana.corr_mag(ana.finger_count==5),1,'paired');
        fprintf('\n5-f nSphere > mag: (%.6f,%.6f)\n',t,p)

        % stats compared to 0 corr:
        [t1,p1] = ttest(ana.corr_mag(ana.finger_count==1),[],1,'onesample');
        [t3,p3] = ttest(ana.corr_mag(ana.finger_count==3),[],1,'onesample');
        [t5,p5] = ttest(ana.corr_mag(ana.finger_count==5),[],1,'onesample');
        fprintf('\nMagnitude:');
        fprintf('\n     1-f: (%.6f,%.6f)\n     3-f: (%.6f,%.6f)\n     5-f: (%.6f,%.6f)\n',t1,p1,t3,p3,t5,p5)

        [t1,p1] = ttest(ana.corr_log(ana.finger_count==1),[],1,'onesample');
        [t3,p3] = ttest(ana.corr_log(ana.finger_count==3),[],1,'onesample');
        [t5,p5] = ttest(ana.corr_log(ana.finger_count==5),[],1,'onesample');
        fprintf('\nnSphere:');
        fprintf('\n     1-f: (%.6f,%.6f)\n     3-f: (%.6f,%.6f)\n     5-f: (%.6f,%.6f)\n',t1,p1,t3,p3,t5,p5)

    case 'across_subj_model'
        C = dload(fullfile(project_path,'analysis','emg_models_MD.tsv'));
        ceil = C.r_ceil(1:14);
        
        % get rows for the finger_count model:
        model_table = struct2table(C);
        model_table = model_table(:,6:end);
        rows_nfing = model_table.n_fing==1 & all(model_table{:,2:end}==0, 2);
        
        % get rows for the magnitude model:
        model_table = struct2table(C);
        model_table = model_table(:,6:end);
        rows_mag = model_table.n_fing==1 & model_table.magnitude_avg==1 & all(model_table{:,[2:8]}==0, 2);

        % get rows for the natural+magnitude model:
        model_table = struct2table(C);
        model_table = model_table(:,6:end);
        rows_nSphere_mag = model_table.n_fing==1 & model_table.magnitude_avg==1 & model_table.nSphere_avg==1 & all(model_table{:,[2:7]}==0, 2);

        % get fitted r for models
        r_nfing = C.r(rows_nfing);
        r_mag = C.r(rows_mag);
        r_nSphere_mag = C.r(rows_nSphere_mag);
        
        % barplot:
        x = [ones(length(r_mag),1) ; 2*ones(length(r_nSphere_mag),1)];
        y = [r_mag ; r_nSphere_mag];
        split = [ones(length(r_mag),1) ; 2*ones(length(r_nSphere_mag),1)];
        figure('Units','centimeters', 'Position',[15 15 5 6]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{colors_pastel(1,:),hex2rgb('#A4CCFF')},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        drawline(mean(ceil),'dir','horz','lim',[x_coord(1)-barwidth x_coord(2)+barwidth],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        h.XTick = [1 2.5];
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [round(mean(r_nfing),2),round(mean(ceil),2),1];
        ylim([round(mean(r_nfing),2) 1])
        xlim([x_coord(1)-barwidth,x_coord(2)+barwidth])
        ylabel('model fit (Pearson''s R)','FontSize',my_font.label)
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")
        
        % stats:
        [t,p] = ttest(r_nSphere_mag,r_mag,1,'paired');
        fprintf('\nttest nSphere+mag > mag: (%.6f,%.6f)\n',t,p)

        [t,p] = ttest(r_mag,r_nfing,1,'paired');
        fprintf('\nttest mag > finger-count: (%.6f,%.6f)\n',t,p)
        
        [t,p] = ttest(ceil,r_nSphere_mag,2,'paired');
        fprintf('\nttest ceiling > nSpehre+mag: (%.6f,%.6f)\n',t,p)

    case 'explained_var_by_natural'
        C = dload(fullfile(project_path,'analysis','natChord_pca.tsv'));
        halves = unique(C.half);

        avg_nat = 0;
        avg_chord = 0;
        for i = 1:length(halves)
            row = C.half == halves(i);
            [~, X_nat, Y_nat, COND, SN] = get_sem(C.nat_explained(row), C.sn(row), ones(sum(row),1), C.PC(row));
            [~, X_chord, Y_chord, COND, SN] = get_sem(C.chord_explained(row), C.sn(row), ones(sum(row),1), C.PC(row));
            avg_nat = avg_nat + Y_nat/length(halves);
            avg_chord = avg_chord + Y_chord/length(halves);
        end
        figure('Units','centimeters', 'Position',[15 15 7 7]);
        hold on;
        drawline(0,'dir','horz','linestyle',':','linewidth',paper.horz_line_width,'color',[0.8 0.8 0.8],'lim',[0 11])
        lineplot(COND,avg_nat,'markertype','o','markersize',paper.lineplot_marker_size-2,'markerfill',colors_blue(2,:),'markercolor',colors_blue(2,:),'linecolor',colors_blue(2,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(2,:),'errorcap',0);
        lineplot(COND,avg_chord,'markertype','o','markersize',paper.lineplot_marker_size-2,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(5,:),'errorcap',0);
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
        
        % stats:
        n_pc = length(unique(COND));
        for i = 1:n_pc
            [t,p] = ttest(Y_chord(COND==i),Y_nat(COND==i),1,'paired');
            fprintf('PC %d: (%.6f,%.6f)\n',i,t,p)
        end

    case 'PCA_impaired_model'
        C = dload(fullfile(project_path,'analysis','natChord_impaired_model.tsv'));
        halves = unique(C.half);

        r2_force1 = 0;
        r2_force2 = 0;
        var_nat1 = 0;
        var_nat2 = 0;
        for i = 1:length(halves)
            row = C.half == halves(i);
            [~, ~, r2_force1_tmp, COND, SN] = get_sem(C.r2_force1(row), C.sn(row), ones(sum(row),1), C.dim1(row));
            [~, ~, r2_force2_tmp, COND, SN] = get_sem(C.r2_force2(row), C.sn(row), ones(sum(row),1), C.dim1(row));
            [~, ~, var_nat1_tmp, COND, SN] = get_sem(C.nat_explained1(row), C.sn(row), ones(sum(row),1), C.dim1(row));
            [~, ~, var_nat2_tmp, COND, SN] = get_sem(C.nat_explained2(row), C.sn(row), ones(sum(row),1), C.dim1(row));
            
            r2_force1 = r2_force1 + r2_force1_tmp/length(halves);
            r2_force2 = r2_force2 + r2_force2_tmp/length(halves);
            var_nat1 = var_nat1 + var_nat1_tmp/length(halves);
            var_nat2 = var_nat2 + var_nat2_tmp/length(halves);
        end

        % barplot:
        row = COND>=4 & COND<=5;
        x = [COND(row) ; COND(row)];
        y = [r2_force1(row) ; r2_force2(row)];
        split = [ones(length(r2_force1(row)),1) ; 2*ones(length(r2_force2(row)),1)];
        figure('Units','centimeters', 'Position',[15 15 7 6]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{colors_gray(4,:),[1,1,1]},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        drawline(mean(r2_force1(COND==10)),'dir','horz','lim',[0,5.5],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        XTickLabels = {[num2str(mean(var_nat1(COND==4)),4),'%'], [num2str(mean(var_nat2(COND==4)),4),'%'], [num2str(mean(var_nat1(COND==5)),4),'%'], [num2str(mean(var_nat2(COND==5)),4),'%']};
        h.XTickLabel = XTickLabels;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [0:0.25:1];
        ylim([0 1])
        xlim([0,5.5])
        ylabel('force pattern explained (R-squared)','FontSize',my_font.label)
        xlabel('Impaired Models','FontSize',my_font.label)
        fontname("Arial")

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
        figure('Units','centimeters', 'Position',[15 15 6.5 4]);
        lineplot(COND,r2_force_by_nat,'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_gray(5,:),'markercolor',colors_gray(5,:),'linecolor',colors_gray(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_gray(5,:),'errorcap',0);
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

    case 'PCA_impaired_model_crossval'
        C = dload(fullfile(project_path,'analysis','natChord_impaired_model_crossval.tsv'));
        halves = unique(C.half);
        
        r2_force1 = 0;
        r2_force2 = 0;
        var_nat1 = 0;
        var_nat2 = 0;
        for i = 1:length(halves)
            row = C.half == halves(i);
            [~, ~, r2_force1_tmp, COND, SN] = get_sem(C.r2_force1(row), C.sn(row), ones(sum(row),1), C.dim1(row));
            [~, ~, r2_force2_tmp, COND, SN] = get_sem(C.r2_force2(row), C.sn(row), ones(sum(row),1), C.dim1(row));
            [~, ~, var_nat1_tmp, COND, SN] = get_sem(C.nat_explained1(row), C.sn(row), ones(sum(row),1), C.dim1(row));
            [~, ~, var_nat2_tmp, COND, SN] = get_sem(C.nat_explained2(row), C.sn(row), ones(sum(row),1), C.dim1(row));
            
            r2_force1 = r2_force1 + r2_force1_tmp/length(halves);
            r2_force2 = r2_force2 + r2_force2_tmp/length(halves);
            var_nat1 = var_nat1 + var_nat1_tmp/length(halves);
            var_nat2 = var_nat2 + var_nat2_tmp/length(halves);
        end
        % barplot:
        row = COND==5;
        x = [COND(row) ; COND(row)];
        y = [r2_force1(row) ; r2_force2(row)];
        split = [ones(length(r2_force1(row)),1) ; 2*ones(length(r2_force2(row)),1)];
        figure('Units','centimeters', 'Position',[15 15 3.5 3.5]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{colors_gray(4,:),[1,1,1]},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        drawline(1,'dir','horz','lim',[0,3],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        % XTickLabels = {[num2str(mean(var_nat1(COND==4)),4),'%'], [num2str(mean(var_nat2(COND==4)),4),'%'], [num2str(mean(var_nat1(COND==5)),4),'%'], [num2str(mean(var_nat2(COND==5)),4),'%']};
        % h.XTickLabel = XTickLabels;
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [0:0.25:1];
        ylim([0 1])
        xlim([0,3])
        ylabel('force pattern explained (R-squared)','FontSize',my_font.label)
        xlabel('Impaired Models','FontSize',my_font.label)
        fontname("Arial")

    case 'PCA_accumulative'
        C = dload(fullfile(project_path,'analysis','natChord_impaired_model_crossval.tsv'));
        halves = unique(C.half);
        
        r2_force = 0;
        for i = 1:length(halves)
            row = C.half == halves(i);
            [~, ~, r2_force1_tmp, COND, SN] = get_sem(C.r2_force1(row), C.sn(row), ones(sum(row),1), C.dim1(row));
            r2_force = r2_force + r2_force1_tmp/length(halves);
        end

        % plot:
        figure('Units','centimeters', 'Position',[15 15 6.5 4]);
        lineplot(COND,r2_force,'markertype','o','markersize',paper.lineplot_marker_size-1,'markerfill',colors_gray(5,:),'markercolor',colors_gray(5,:),'linecolor',colors_gray(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_gray(5,:),'errorcap',0);
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
        ylabel('force pattern explained (R-squared)','FontSize',my_font.label)
        xlabel('natural PCs accumulative models','FontSize',my_font.label)
        fontname("Arial")

    otherwise
        error('The analysis %s you entered does not exist!',what)
end



