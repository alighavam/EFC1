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
my_font.legend = 8;

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

        % stats
        fprintf("\n======= Chord MD Improvement =======\n")
        T_MD_Imprv = anovaMixed(Y,SN,'within',X,{'days'});
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

    case 'training_finger_count_effect'
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

    case 'training_repetition_effect'
        C = dload(fullfile(project_path,'analysis','training_repetition.tsv'));

        % ====== MD ======:
        fig_MD = figure('Units','centimeters', 'Position',[15 15 6 6]);
        % average data over finger count:
        [~, X1, Y1, COND] = get_sem(C.MD_subj_rep1, C.sn, C.sess, ones(size(C.sn)));
        [~, X2, Y2, COND] = get_sem(C.MD_subj_rep2, C.sn, C.sess, ones(size(C.sn)));
        [~, X3, Y3, COND] = get_sem(C.MD_subj_rep3, C.sn, C.sess, ones(size(C.sn)));
        [~, X4, Y4, COND] = get_sem(C.MD_subj_rep4, C.sn, C.sess, ones(size(C.sn)));
        [~, X5, Y5, COND] = get_sem(C.MD_subj_rep5, C.sn, C.sess, ones(size(C.sn)));
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
        h.YTick = [0.5,1.7,2.8];
        ylim([0.5 2.8])
        xlim([0,21])
        xlabel('days','FontSize',my_font.label)
        ylabel('MD','FontSize',my_font.label)
        fontname("Arial")

        % stats:
        fprintf('\n======== MD Change in rep1 from day 1 to 4 ========\n')
        % T_MD_rep1Imprv = MANOVArp(C.sn,C.sess,C.MD_subj_rep1);
        T_MD_rep1Imprv = anovaMixed(C.MD_subj_rep1,C.sn,'within',[C.sess],{'days'});
        fprintf('\n')

        fprintf('\n======== MD Imprv in rep 2-5 ========\n')
        y = [C.MD_subj_rep2;C.MD_subj_rep3;C.MD_subj_rep4;C.MD_subj_rep5];
        sn = [C.sn;C.sn;C.sn;C.sn];
        rep = [2*ones(size(C.MD_subj_rep2));3*ones(size(C.MD_subj_rep3));4*ones(size(C.MD_subj_rep4));5*ones(size(C.MD_subj_rep5))];
        % T_MD_rep2to5 = MANOVArp(sn,rep,y);
        T_MD_rep2to5 = anovaMixed(y,sn,'within',[rep],{'repetitions'});
        fprintf('\n')
        
        % ====== RT ======: 
        fig_RT = figure('Units','centimeters', 'Position',[15 15 6 6]);
        % average data over finger count:
        [~, X1, Y1, COND] = get_sem(C.RT_subj_rep1, C.sn, C.sess, ones(size(C.sn)));
        [~, X2, Y2, COND] = get_sem(C.RT_subj_rep2, C.sn, C.sess, ones(size(C.sn)));
        [~, X3, Y3, COND] = get_sem(C.RT_subj_rep3, C.sn, C.sess, ones(size(C.sn)));
        [~, X4, Y4, COND] = get_sem(C.RT_subj_rep4, C.sn, C.sess, ones(size(C.sn)));
        [~, X5, Y5, COND] = get_sem(C.RT_subj_rep5, C.sn, C.sess, ones(size(C.sn)));
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
        h.YTick = [150,350,550];
        ylim([150 550])
        xlim([0,21])
        ylabel('RT','FontSize',my_font.label)
        xlabel('days','FontSize',my_font.label)
        fontname("Arial")

        % stats:
        fprintf('\n======== RT Change in rep1 from day 1 to 4 ========\n\n')
        % T_RT_rep1Imprv = MANOVArp(C.sn,C.sess,C.RT_subj_rep1);
        T_RT_rep1Imprv = anovaMixed(C.RT_subj_rep1,C.sn,'within',[C.sess],{'days'});
        fprintf('\n')

        fprintf('\n======== RT Imprv in rep 2-5 ========\n')
        y = [C.RT_subj_rep2;C.RT_subj_rep3;C.RT_subj_rep4;C.RT_subj_rep5];
        sn = [C.sn;C.sn;C.sn;C.sn];
        rep = [2*ones(size(C.RT_subj_rep2));3*ones(size(C.RT_subj_rep3));4*ones(size(C.RT_subj_rep4));5*ones(size(C.RT_subj_rep5))];
        % T_MD_rep2to5 = MANOVArp(sn,rep,y);
        T_MD_rep2to5 = anovaMixed(y,sn,'within',[rep],{'repetitions'});
        fprintf('\n')

    otherwise
        error('The analysis %s you entered does not exist!',what)
end



