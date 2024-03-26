function X = make_design_matrix(chords,model_name)
% setting paths:
usr_path = userpath;
usr_path = usr_path(1:end-17);
project_path = fullfile(usr_path, 'Desktop', 'Projects', 'EFC1');

switch model_name
    case 'n_fing'
        X = zeros(length(chords),5);
        n = get_num_active_fingers(chords);
        for i = 1:length(n)
            X(i,n(i)) = 1;
        end
    
    case 'flexion'
        X = zeros(length(chords),5);
        for i = 1:length(chords)
            X(i,:) = num2str(chords(i)) == '2';
        end
    
    case 'extension'
        X = zeros(length(chords),5);
        for i = 1:length(chords)
            X(i,:) = num2str(chords(i)) == '1';
        end
    
    case 'additive'
        X = zeros(length(chords),10);
        for i = 1:length(chords)
            X(i,1:5) = num2str(chords(i)) == '1';
            X(i,6:10) = num2str(chords(i)) == '2';
        end

    case '2fing_adj'
        X = zeros(length(chords),16);
        neighbour_chords = [11555,12555,21555,22555,...
                   51155,51255,52155,52255,...
                   55115,55125,55215,55225,...
                   55511,55512,55521,55522];
        for i = 1:length(chords)
            for j = 1:length(neighbour_chords)
                if (sum(num2str(chords(i)) == num2str(neighbour_chords(j))) == 2)
                    X(i,j) = 1;
                end
            end
        end

    case '2fing_nonadj'
        X = make_design_matrix(chords,'2fing');
        X1 = make_design_matrix(chords,'2fing_adj');
        % rounding the correlations bc of precision problems:
        tmp = round(corr(X,X1),2);
        [i,~] = find(tmp==1);
        X(:,i) = [];

    case '2fing'
        X = [];
        X1 = make_design_matrix(chords,'additive');
        for j = 1:size(X1,2)-1
            for k = j+1:size(X1,2)
                if (k ~= j+5)
                    X = [X, X1(:,j).*X1(:,k)]; 
                end
            end
        end


    case 'force_avg'
        data = dload(fullfile(project_path,'analysis','efc1_chord.tsv'));
        sn_unique = unique(data.sn);
        sess = [3,4];

        % calculate group avg:
        avg_force = 0;
        for i = 1:length(sn_unique)
            % getting the subject session average:
            tmp_force = [];
            for j = 1:length(sess)
                diff_force = [data.diff_force_f1(data.sn==sn_unique(i) & data.sess==sess(j)),...
                              data.diff_force_f2(data.sn==sn_unique(i) & data.sess==sess(j)),...
                              data.diff_force_f3(data.sn==sn_unique(i) & data.sess==sess(j)),...
                              data.diff_force_f4(data.sn==sn_unique(i) & data.sess==sess(j)),...
                              data.diff_force_f5(data.sn==sn_unique(i) & data.sess==sess(j))];
                force = [diff_force,diff_force];
                for col = 1:5
                    force(force(:,col)<0,col) = 0;
                    force(force(:,col+5)>0,col+5) = 0;
                end
                force(:,6:10) = force(:,6:10)*-1;

                % if sum(isnan(force)) ~= 0
                %     fprintf('subject %d, sess %d contains nan \n',sn_unique(i),sess(j))
                % end

                % tmp_force = tmp_force + force/length(sess);
                tmp_force = cat(3,tmp_force,force);
            end
            tmp_force = sum(tmp_force,3,'omitnan')/length(sess);

            avg_force = avg_force + tmp_force/length(sn_unique);
        end
        chordID = data.chordID(data.sn==1 & data.sess==4);
        
        % making the design matrix:
        X = zeros(length(chords),10);
        for i = 1:length(chords)
            X(i,:) =  avg_force(chordID==chords(i),:);
        end

    case 'force_2fing'
        X = [];
        X1 = make_design_matrix(chords,'force_avg');
        for j = 1:size(X1,2)-1
            for k = j+1:size(X1,2)
                if (k ~= j+5)
                    X = [X, X1(:,j).*X1(:,k)];
                end
            end
        end

    case 'transition'
        n_trans = get_num_transition(chords) + 1;
        X = zeros(length(chords),5);
        for i = 1:size(X,1)
            X(i,n_trans(i)) = 1;
        end

    case 'symmetries'
        symmetries = get_chord_symmetry(unique(chords),'all');
        groups = [symmetries.chord,symmetries.chord_vs,symmetries.chord_hs,symmetries.chord_vhs];
        
        X = zeros(length(chords),size(groups,1));
        for i = 1:size(X,1)
            % finding the vis_complexity group that chords(i) belong to:
            [idx,~] = find(groups==chords(i));
            X(i,idx(1)) = 1;
        end

    otherwise
        names = strsplit(model_name,'+');
        if (length(names)<=1)
            error('requested model name %s does not exist',model_name)
        end
        X = [];
        for i = 1:length(names)
            tmp = make_design_matrix(chords,names{i});
            X = [X, tmp];
        end

        % if(sum(contains(names,'n_fing')))
        %     X(:,6:end) = X(:,6:end) - mean(X(:,6:end),2);
        % end
        
        % if(sum(contains(names,'n_fing')))
        %     X(:,6:end) = X(:,6:end) - mean(X(:,6:end),1);
        %     X(:,1) = [];
        % end

        % if(sum(contains(names,'n_fing') + contains(names,'2fing'))==2)
        %     X(:,1:2) = [];
        % end
        % 
        % if(sum(contains(names,'n_fing') + contains(names,'additive') + contains(names,'n_trans'))==3)
        %     X(:,1) = [];
        % end
        % 
        % if(sum(contains(names,'n_fing') + contains(names,'additive') + contains(names,'n_trans') + contains(names,'neighbour'))==4)
        %     X(:,14) = [];
        % end
end