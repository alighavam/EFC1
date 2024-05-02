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
paper.err_width = 1.5;
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
        [~, X, Y, COND] = get_sem(C.MD(C.finger_count>1), C.sn(C.finger_count>1), C.sess(C.finger_count>1), ones(sum(C.finger_count>1),1));
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

        % ======== RT ========
        fig_RT = figure('Units','centimeters', 'Position',[15 15 4.2 6]);
        % single-finger chords as baseline:
        lineplot(C.sess(C.finger_count==1),C.RT(C.finger_count==1),'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_gray(2,:),'markercolor',colors_gray(2,:),'linecolor',colors_gray(2,:),'linewidth',paper.lineplot_line_width,'errorcolor',colors_gray(2,:),'errorcap',0); hold on;
        % multi-finger chords:
        [~, X, Y, COND] = get_sem(C.RT(C.finger_count>1), C.sn(C.finger_count>1), C.sess(C.finger_count>1), ones(sum(C.finger_count>1),1));
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
        measure = 'MD';
        vararginoptions(varargin,{'measure'});
        C = dload(fullfile(project_path,'analysis',['training_repetition_' measure '.tsv']));
        varargout{1} = C;
        value = [C.value_rep1,C.value_rep2,C.value_rep3,C.value_rep4,C.value_rep5];
        value_subj = [C.value_subj_rep1,C.value_subj_rep2,C.value_subj_rep3,C.value_subj_rep4,C.value_subj_rep5];
        sem = [C.sem_rep1,C.sem_rep2,C.sem_rep3,C.sem_rep4,C.sem_rep5];
        
        % PLOT - repetition trends across sessions:
        fig = figure('Units','centimeters', 'Position',[15 15 25 30]);
        offset_size = 5;
        x_offset = 0:offset_size:5*(length(unique(C.sess))-1);
        num_fingers_unique = unique(C.num_fingers);
        
        for i = 1:length(num_fingers_unique)
            for j = 1:length(unique(C.sess))
                plot((1:5)+x_offset(j), mean(value(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1),'Color',colors_blue(num_fingers_unique(i),:),'LineWidth',paper.line_width); hold on;
                errorbar((1:5)+x_offset(j), mean(value(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1), mean(sem(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1), 'CapSize', 0,'LineWidth',paper.err_width, 'Color', colors_blue(num_fingers_unique(i),:));
                scatter((1:5)+x_offset(j), mean(value(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1), paper.marker_size,'MarkerFaceColor',colors_blue(num_fingers_unique(i),:),'MarkerEdgeColor',colors_blue(num_fingers_unique(i),:))
            end
        end
        box off
        h = gca;
        
        h.XTick = 5*(1:length(unique(C.sess))) - 2;
        xlabel('Days','FontSize',my_font.label)
        h.XTickLabel = {'1','2','3','4'};
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        ylabel(measure,'FontSize',my_font.label)
        if measure=='MD'
            h.YTick = [0.5,1.7,3]; % MD
            ylim([0.5 3])
        elseif measure=='RT'
            h.YTick = [120,360,600]; % RT
            ylim([120 600])
        elseif measure=='MT'
            h.YTick = 0:1000:3000; % MT
            ylim([0 2600])
        end
        % ylim([0.3 3])
        % ylim([0 2600])
        % ylim([0 650])
        xlim([0,21])
        fontname("Arial")

        % PLOT - repetition trends across sessions:
        fig = figure('Units','centimeters', 'Position',[15 15 15.5 19]);
        num_fingers_unique = unique(C.num_fingers);
        [C_sem1, X1, Y1, COND] = get_sem(value_subj(:,1), C.sn, C.sess, ones(size(C.sn)));
        [C_sem2, X2, Y2, COND] = get_sem(value_subj(:,2), C.sn, C.sess, ones(size(C.sn)));
        [C_sem3, X3, Y3, COND] = get_sem(value_subj(:,3), C.sn, C.sess, ones(size(C.sn)));
        [C_sem4, X4, Y4, COND] = get_sem(value_subj(:,4), C.sn, C.sess, ones(size(C.sn)));
        [C_sem5, X5, Y5, COND] = get_sem(value_subj(:,5), C.sn, C.sess, ones(size(C.sn)));
        y = [C_sem1.y,C_sem2.y,C_sem3.y,C_sem4.y,C_sem5.y];
        y_sem = [C_sem1.sem,C_sem2.sem,C_sem3.sem,C_sem4.sem,C_sem5.sem];
        % loop on number of fingers:
        offset_size = 5;
        x_offset = 0:offset_size:5*(length(unique(C.sess))-1);
        for j = 1:length(unique(C.sess))
            plot((1:5)+x_offset(j), y(j,:),'Color',colors_blue(num_fingers_unique(i),:),'LineWidth',paper.line_width); hold on;
            errorbar((1:5)+x_offset(j), y(j,:), y_sem(j,:), 'CapSize', 0,'LineWidth',paper.err_width, 'Color', colors_blue(num_fingers_unique(i),:));
            scatter((1:5)+x_offset(j), y(j,:), paper.marker_size,'MarkerFaceColor',colors_blue(num_fingers_unique(i),:),'MarkerEdgeColor',colors_blue(num_fingers_unique(i),:))
        end
        box off
        h = gca;

        h.XTick = 5*(1:length(unique(C.sess))) - 2;
        xlabel('days','FontSize',my_font.label)
        h.XTickLabel = {'1','2','3','4'};
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        ylabel(measure,'FontSize',my_font.label)
        if measure=='MD'
            h.YTick = [0.5,1.7,2.8]; % MD
            ylim([0.5 2.8])
        elseif measure=='RT'
            h.YTick = [150,350,550]; % RT
            ylim([150 550])
        elseif measure=='MT'
            h.YTick = 0:1000:3000; % MT
            ylim([0 2600])
        end
        % ylim([0.3 3])
        % ylim([0 2600])
        % ylim([0 650])
        xlim([0,21])
        fontname("Arial")

    otherwise
        error('The analysis %s you entered does not exist!',what)
end



