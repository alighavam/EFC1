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
my_font.label = 10;
my_font.title = 11;
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
        scatter(C.sess,C.difficult,paper.marker_size,'MarkerFaceColor',colors_gray(5,:),'MarkerEdgeColor',colors_gray(5,:));
        
        errorbar(C.sess,C.all_chords,C.all_chords_sem,'LineStyle','none','CapSize',0,'Color',colors_gray(2,:),'LineWidth',paper.err_width); 
        plot(C.sess,C.all_chords,'Color',[colors_gray(2,:), 0.6],'LineWidth',paper.line_width)
        
        lgd = legend({'','',['Most Challenging' newline 'Chord per Subject'],'','','All 242 Chords'});
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
        [~, X, Y, COND, SN] = get_sem(C.MD(C.finger_count>1), C.sn(C.finger_count>1), C.sess(C.finger_count>1), ones(sum(C.finger_count>1),1));
        lineplot(X,Y,'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(5,:),'errorcap',0);
        h = gca;
        ylim([0.5 2])
        h.YTick = [0.5 1.3 2];
        xlim([0.5 4.5])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('days','FontSize',my_font.label)
        ylabel('MD','FontSize',my_font.label)
        h.LineWidth = paper.axis_width;
        fontname("arial")

        % average multi-finger chord MD imprv from day 1 to 4:
        day1 = Y(X==1);
        day4 = Y(X==4);
        % per subject improvements:
        imprv = (day1-day4) ./ day1;
        fprintf('\nMD Imprv day 1 to 4: AVG = %.4f%% , SEM = %.4f%%\n',mean(imprv)*100,std(imprv)/sqrt(length(day1))*100)

        % difference scale between chords and single-finger on day 1 to 4:
        day1_difference = (day1./C.MD(C.finger_count==1 & C.sess==1));
        day4_difference = (day4./C.MD(C.finger_count==1 & C.sess==4));
        fprintf('\nMD scale difference between chord and single-finger:\n')
        fprintf('day 1: %.2f , day 4: %.2f\n',mean(day1_difference),mean(day4_difference))

        % stats
        fprintf("\n======= Chord MD Improvement =======\n")
        T_MD_Imprv = anovaMixed(Y,SN,'within',X,{'days'});
        fprintf("\n")

        fprintf("\n======= Single-Finger MD Improvement =======\n")
        T_MD_1f_Imprv = anovaMixed(C.MD(C.finger_count==1),C.sn(C.finger_count==1),'within',C.sess(C.finger_count==1),{'days'});
        fprintf("\n")

        fprintf("\n======= Single-Finger MD Improvement =======\n")
        T_MD_1f_Imprv = anovaMixed(C.MD(C.finger_count==1),C.sn(C.finger_count==1),'within',C.sess(C.finger_count==1),{'days'});
        fprintf("\n")

        % ======== RT ========
        fig_RT = figure('Units','centimeters', 'Position',[15 15 4.2 6]);
        % single-finger chords as baseline:
        lineplot(C.sess(C.finger_count==1),C.RT(C.finger_count==1),'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_gray(2,:),'markercolor',colors_gray(2,:),'linecolor',colors_gray(2,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_gray(2,:),'errorcap',0); hold on;
        % multi-finger chords:
        [~, X, Y, COND, SN] = get_sem(C.RT(C.finger_count>1), C.sn(C.finger_count>1), C.sess(C.finger_count>1), ones(sum(C.finger_count>1),1));
        lineplot(X,Y,'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_blue(5,:),'errorcap',0);
        h = gca;
        ylim([170, 400])
        h.YTick = [170 280 400];
        xlim([0.5 4.5])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('days','FontSize',my_font.label)
        ylabel('RT','FontSize',my_font.label)
        h.LineWidth = paper.axis_width;
        fontname("arial")

        % average multi-finger chord RT imprv from day 1 to 4:
        day1 = Y(X==1);
        day4 = Y(X==4);
        % per subject improvements:
        imprv = (day1-day4) ./ day1;
        fprintf('\nRT Imprv day 1 to 4: AVG = %.4f%% , SEM = %.4f%%\n',mean(imprv)*100,std(imprv)/sqrt(length(day1))*100)

        % difference scale between chords and single-finger on day 1 to 4:
        day1_difference = (day1./C.RT(C.finger_count==1 & C.sess==1));
        day4_difference = (day4./C.RT(C.finger_count==1 & C.sess==4));
        fprintf('\nRT scale difference between chord and single-finger:\n')
        fprintf('day 1: %.2f , day 4: %.2f\n',mean(day1_difference),mean(day4_difference))

        % stats
        fprintf("\n======= Chord RT Improvement =======\n")
        T_RT_Imprv = anovaMixed(Y,SN,'within',X,{'days'});
        fprintf("\n")

        fprintf("\n======= Single-Finger RT Improvement =======\n")
        T_RT_1f_Imprv = anovaMixed(C.RT(C.finger_count==1),C.sn(C.finger_count==1),'within',C.sess(C.finger_count==1),{'days'});
        fprintf("\n")

        fprintf("\n======= RT: multi-finger vs single-finger on day 4 =======\n")
        [t,p] = ttest(day4,C.RT(C.finger_count==1 & C.sess==4),1,'paired');
        fprintf("t = %.4f , p = %.4f\n",t,p)

    case 'training_finger_count'
        C = dload(fullfile(project_path,'analysis','training_performance.tsv'));
        
        % ======== MD ========
        fig_MD = figure('Units','centimeters', 'Position',[15 15 4.5 6]);
        [~, X, Y, COND] = get_sem(C.MD, C.sn, ones(size(C.sn)), C.finger_count);
        lineplot(COND,Y,'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_pastel(1,:),'markercolor',colors_pastel(1,:),'linecolor',colors_pastel(1,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_pastel(1,:),'errorcap',0);
        h = gca;
        ylim([0 2.4])
        h.YTick = [0 1.2 2.4];
        xlim([0.5 5.5])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('Finger Count','FontSize',my_font.label)
        ylabel('MD','FontSize',my_font.label)
        h.LineWidth = paper.axis_width;
        fontname("arial")
        % ======== RT ========
        fig_RT = figure('Units','centimeters', 'Position',[15 15 4.5 6]);
        [~, X, Y, COND] = get_sem(C.RT, C.sn, ones(size(C.sn)), C.finger_count);
        lineplot(COND,Y,'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_pastel(2,:),'markercolor',colors_pastel(2,:),'linecolor',colors_pastel(2,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_pastel(2,:),'errorcap',0);
        h = gca;
        ylim([200 500])
        h.YTick = [200 350 500];
        xlim([0.5 5.5])
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        xlabel('Finger Count','FontSize',my_font.label)
        ylabel('RT','FontSize',my_font.label)
        h.LineWidth = paper.axis_width;
        fontname("arial")

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
        ylim([1.2 2.4])
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
        x = [ones(length(r_RT),1) ; 2*ones(length(r_MD),1)];
        y = [r_RT ; r_MD];
        split = [ones(length(r_RT),1) ; 2*ones(length(r_MD),1)];
        figure('Units','centimeters', 'Position',[15 15 5 6]);
        barwidth = 1;
        [x_coord,PLOT,ERROR] = barplot(x,y,'split',split,'facecolor',{colors_pastel(2,:),colors_pastel(1,:)},'barwidth',barwidth,'gapwidth',[0.5 0 0],'errorwidth',paper.err_width,'linewidth',1,'capwidth',0); hold on;
        drawline(mean(MD_ceil),'dir','horz','lim',[x_coord(2)-barwidth/1.5 x_coord(2)+barwidth/1.5],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        drawline(mean(RT_ceil),'dir','horz','lim',[x_coord(1)-barwidth/1.5 x_coord(1)+barwidth/1.5],'color',[0.8 0.8 0.8],'linewidth',paper.horz_line_width,'linestyle',':')
        box off
        h = gca;
        h.XTick = [1 2.5];
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        h.YTick = [0,0.5,1];
        ylim([0 1])
        xlim([x_coord(1)-barwidth,x_coord(2)+barwidth])
        ylabel('R','FontSize',my_font.label)
        xlabel('Finger Count','FontSize',my_font.label)
        fontname("Arial")
        
    otherwise
        error('The analysis %s you entered does not exist!',what)
end



