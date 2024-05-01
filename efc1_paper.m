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

colors_blue = hex2rgb(colors_blue);
colors_green = hex2rgb(colors_green);
colors_cyan = hex2rgb(colors_cyan);
colors_gray = hex2rgb(colors_gray);
colors_random = hex2rgb(colors_random);

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
paper.lineplot_marker_size = 5;
paper.horz_line_width = 2;
paper.axis_width = 1;
paper.bar_line_width = 1.5;
paper.bar_width = 1;


switch (what)
    case 'success_rate'
        C = dload(fullfile(project_path,'analysis','success_rate.tsv'));
        varargout{1} = C;
        
        avg_diff = [mean(C.acc_diff_s01) ; mean(C.acc_diff_s02) ; mean(C.acc_diff_s03) ; mean(C.acc_diff_s04)];
        sem_diff = [std(C.acc_diff_s01) ; std(C.acc_diff_s02) ; std(C.acc_diff_s03) ; std(C.acc_diff_s04)]/sqrt(length(C.sn));
        avg_all = [mean(C.acc_avg_s01) ; mean(C.acc_avg_s02) ; mean(C.acc_avg_s03) ; mean(C.acc_avg_s04)];
        sem_all = [std(C.acc_avg_s01) ; std(C.acc_avg_s02) ; std(C.acc_avg_s03) ; std(C.acc_avg_s04)]/sqrt(length(C.sn));

        fig = figure('Units','centimeters', 'Position',[15 15 5 6]);
        fontsize(fig, my_font.tick_label, 'points')
        drawline(1,'dir','horz','color',[0.8 0.8 0.8],'lim',[0 5],'linewidth',paper.horz_line_width,'linestyle',':'); hold on;
        
        errorbar(1:4,avg_diff,sem_diff,'LineStyle','none','CapSize',0,'Color',colors_gray(5,:),'LineWidth',paper.err_width); 
        plot(1:4,avg_diff,'Color',colors_gray(5,:),'LineWidth',paper.line_width)
        scatter(1:4,avg_diff,paper.marker_size,'MarkerFaceColor',colors_gray(5,:),'MarkerEdgeColor',colors_gray(5,:));
        
        errorbar(1:4,avg_all,sem_all,'LineStyle','none','CapSize',0,'Color',colors_gray(2,:),'LineWidth',paper.err_width); 
        plot(1:4,avg_all,'Color',[colors_gray(2,:), 0.6],'LineWidth',paper.line_width)
        % scatter(1:4,avg_all,30,'MarkerFaceColor',colors_blue(2,:),'MarkerEdgeColor',colors_blue(2,:),'MarkerEdgeAlpha',0,'MarkerFaceAlpha',0.4);
        
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
        set(gca, 'FontName', 'calibri');
        
    case 'training_performance'
        measure = 'MD';
        vararginoptions(varargin,{'measure'})

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
        fig1 = figure('Units','centimeters', 'Position',[15 15 4.2 6]);
        % for i = 1:5
        %     errorbar(sem_subj.partitions(sem_subj.cond==i),sem_subj.y(sem_subj.cond==i),sem_subj.sem(sem_subj.cond==i),'LineStyle','none','Color',colors_blue(i,:),'CapSize',0,'LineWidth',conf.err_width); hold on;
        %     lineplot(data.sess(data.num_fingers==i & ~isnan(values)),values(data.num_fingers==i & ~isnan(values)),'markertype','o','markersize',12,'markerfill',colors_blue(i,:),'markercolor',colors_blue(i,:),'linecolor',colors_blue(i,:),'linewidth',6,'errorbars','');
        % end
        
        % all avg:
        [sem_subj, ~, ~, ~] = get_sem(values, data.sn, data.sess, data.num_fingers);
        errorbar(sem_subj.partitions(sem_subj.cond==1),sem_subj.y(sem_subj.cond==1),sem_subj.sem(sem_subj.cond==1),'LineStyle','none','Color',colors_gray(2,:),'CapSize',0,'LineWidth',paper.err_width); hold on;
        lineplot(data.sess(data.num_fingers==1 & ~isnan(values)),values(data.num_fingers==1 & ~isnan(values)),'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_gray(2,:),'markercolor',colors_gray(2,:),'linecolor',colors_gray(2,:),'linewidth',paper.lineplot_line_width,'errorbars','');
        
        values_tmp = values(data.num_fingers>1);
        [sem_subj, ~, ~, ~] = get_sem(values_tmp, data.sn(data.num_fingers>1), data.sess(data.num_fingers>1), ones(size(data.sess(data.num_fingers>1))));
        errorbar(sem_subj.partitions,sem_subj.y,sem_subj.sem,'LineStyle','none','Color',colors_blue(5,:),'CapSize',0,'LineWidth',paper.err_width); hold on;
        lineplot(data.sess(data.num_fingers>1 & ~isnan(values)),values(data.num_fingers>1 & ~isnan(values)),'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width,'errorbars','');
        
        % lgd = legend({'','n=1','','n=2','','n=3','','n=4','','n=5'});
        % legend boxoff
        % fontsize(lgd,my_font.conf_legend,'points')
        h = gca;
        if measure=='MD'
            ylim([0.5 2])
            h.YTick = [0.5 1.3 2];
        elseif measure=='RT'
            ylim([170, 400])
            h.YTick = [170 280 400];
        elseif measure=='MT'
            ylim([0 2600])
        end
        xlim([0.5 4.5])
        xlabel('days','FontSize',my_font.label)
        ylabel([measure],'FontSize',my_font.label)
        % ylabel([measure],'FontSize',my_font.tick_label)
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        fontname("calibri")
        
        fig2 = figure('Units','centimeters', 'Position',[15 15 6 8.6]);
        [C_sem, X_subj, Y_subj, ~] = get_sem(values, data.sn, ones(size(data.sn)), data.num_fingers);
        errorbar(C_sem.cond,C_sem.y,C_sem.sem,'LineStyle','none','Color',colors_blue(5,:),'CapSize',0,'LineWidth',paper.err_width); hold on;
        lineplot(data.num_fingers(~isnan(values)),values(~isnan(values)),'markertype','o','markersize',paper.lineplot_marker_size,'markerfill',colors_blue(5,:),'markercolor',colors_blue(5,:),'linecolor',colors_blue(5,:),'linewidth',paper.lineplot_line_width,'errorbars','');
        
        % lgd = legend({'','n=1','','n=2','','n=3','','n=4','','n=5'});
        % legend boxoff
        % fontsize(lgd,my_font.conf_legend,'points')
        h = gca;
        if measure=='MD'
            ylim([0 2.4])
            h.YTick = [0 1.2 2.4];
        elseif measure=='RT'
            ylim([200, 500])
            h.YTick = [200 350 500];
        elseif measure=='MT'
            ylim([0 2600])
        end
        xlim([0.5 5.5])
        xlabel('Finger Count','FontSize',my_font.label)
        ylabel([measure],'FontSize',my_font.label)
        % ylabel([measure],'FontSize',my_font.tick_label)
        h.XAxis.FontSize = my_font.tick_label;
        h.YAxis.FontSize = my_font.tick_label;
        h.LineWidth = paper.axis_width;
        fontname("calibri")
        
        exportgraphics(fig1,'behaviour.eps','ContentType','vector')

    case 'training_repetition_effect'
        measure = 'MD';
        vararginoptions(varargin,{'measure'});
        C = dload(fullfile(project_path,'analysis',['training_repetition_' measure '.tsv']));
        
        % PLOT - repetition trends across sessions:
        fig = figure('Units','centimeters', 'Position',[15 15 25 30]);
        offset_size = 5;
        x_offset = 0:offset_size:5*(length(unique(C.sess))-1);
        num_fingers_unique = unique(C.num_fingers);
        for i = 1:length(num_fingers_unique)
            for j = 1:length(unique(C.sess))
                plot((1:5)+x_offset(j), mean(C.value(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1),'Color',colors_blue(num_fingers_unique(i),:),'LineWidth',conf.line_width); hold on;
                errorbar((1:5)+x_offset(j), mean(C.value(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1), mean(C.sem(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1), 'CapSize', 0,'LineWidth',conf.err_width, 'Color', colors_blue(num_fingers_unique(i),:));
                scatter((1:5)+x_offset(j), mean(C.value(C.num_fingers==num_fingers_unique(i) & C.sess==j, :),1), conf.marker_size,'MarkerFaceColor',colors_blue(num_fingers_unique(i),:),'MarkerEdgeColor',colors_blue(num_fingers_unique(i),:))
            end
        end
        box off
        h = gca;

        h.XTick = 5*(1:length(unique(C.sess))) - 2;
        xlabel('Days','FontSize',my_font.conf_label)
        h.XTickLabel = {'1','2','3','4'};
        h.XAxis.FontSize = my_font.conf_tick_label;
        h.YAxis.FontSize = my_font.conf_tick_label;
        h.LineWidth = conf.axis_width;
        ylabel(measure,'FontSize',my_font.conf_label)
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
        [C_sem1, X1, Y1, COND] = get_sem(C.value_subj(:,1), C.sn, C.sess, ones(size(C.sn)));
        [C_sem2, X2, Y2, COND] = get_sem(C.value_subj(:,2), C.sn, C.sess, ones(size(C.sn)));
        [C_sem3, X3, Y3, COND] = get_sem(C.value_subj(:,3), C.sn, C.sess, ones(size(C.sn)));
        [C_sem4, X4, Y4, COND] = get_sem(C.value_subj(:,4), C.sn, C.sess, ones(size(C.sn)));
        [C_sem5, X5, Y5, COND] = get_sem(C.value_subj(:,5), C.sn, C.sess, ones(size(C.sn)));
        y = [C_sem1.y,C_sem2.y,C_sem3.y,C_sem4.y,C_sem5.y];
        y_sem = [C_sem1.sem,C_sem2.sem,C_sem3.sem,C_sem4.sem,C_sem5.sem];
        % loop on number of fingers:
        offset_size = 5;
        x_offset = 0:offset_size:5*(length(unique(C.sess))-1);
        for j = 1:length(unique(C.sess))
            plot((1:5)+x_offset(j), y(j,:),'Color',colors_blue(num_fingers_unique(i),:),'LineWidth',4); hold on;
            errorbar((1:5)+x_offset(j), y(j,:), y_sem(j,:), 'CapSize', 0,'LineWidth',2, 'Color', colors_blue(num_fingers_unique(i),:));
            scatter((1:5)+x_offset(j), y(j,:), 100,'MarkerFaceColor',colors_blue(num_fingers_unique(i),:),'MarkerEdgeColor',colors_blue(num_fingers_unique(i),:))
        end
        box off
        h = gca;

        h.XTick = 5*(1:length(unique(C.sess))) - 2;
        xlabel('days','FontSize',my_font.xlabel)
        h.XTickLabel = {'1','2','3','4'};
        h.XAxis.FontSize = my_font.conf_tick_label;
        h.YAxis.FontSize = my_font.conf_tick_label;
        h.LineWidth = conf.axis_width;
        ylabel(measure,'FontSize',my_font.conf_label)
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





