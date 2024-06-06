clear;
close;
clc;

data = dload('./analysis/efc1_chord.tsv');

[~, X, Y, COND, SN] = get_sem(data.MD, data.sn, data.sess, data.chordID);
finger_count = get_num_active_fingers(COND);

[~, X, Y, COND, SN] = get_sem(Y(finger_count==4), ones(size(SN(finger_count==4))), X(finger_count==4), COND(finger_count==4));

% get the sorted decision table:
dec_mat = [COND(X==1) , mean([Y(X==4),Y(X==3)],2)];

[B,I] = sort(dec_mat(:,2));

dec_mat_sorted = dec_mat(I,:);

% hard chords:
hard_trained = [29212;92122;91211;22911];
hard_untrained = [21291;12129;12291;19111];
[t,p] = check_select_chords(data,hard_trained,hard_untrained);

%%
function [t,p] = check_select_chords(data,grp_trained,grp_untrained)
    [~, X, Y, COND, SN] = get_sem(data.MD, data.sn, data.sess, data.chordID);
    
    % select trained chords:
    MD_trained = [];
    days_trained  = [];
    SN_trained  = [];
    for i = 1:length(grp_trained)
        MD_trained  = [MD_trained  ; Y(COND==grp_trained(i))];
        days_trained  = [days_trained  ; X(COND==grp_trained(i))];
        SN_trained  = [SN_trained  ; SN(COND==grp_trained(i))];
    end
    
    % select untrained chords:
    MD_untrained = [];
    days_untrained  = [];
    SN_untrained  = [];
    for i = 1:length(grp_untrained)
        MD_untrained  = [MD_untrained  ; Y(COND==grp_untrained(i))];
        days_untrained  = [days_untrained  ; X(COND==grp_untrained(i))];
        SN_untrained  = [SN_untrained  ; SN(COND==grp_untrained(i))];
    end
    
    % average values in day 3 and 4:
    MD_trained = 1/2*MD_trained(days_trained==3) + 1/2*MD_trained(days_trained==4);
    MD_untrained = 1/2*MD_untrained(days_untrained==3) + 1/2*MD_untrained(days_untrained==4);
    
    % paired ttest between the groups:
    [t,p] = ttest(MD_trained,MD_untrained,2,'paired');
    fprintf('\npaired 2-sample ttest: t = %.4f , p = %.4f\n',t,p);
end
