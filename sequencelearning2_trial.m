function [D]=sequencelearning2_trial(MOV,D,fig,varargin)
%SEQUENCE2:  tDCS study (test 12 seq, train 4)
%example:  sequencelearning2_subj('s01',1); %extracts the statistics from the movement data for ONE trial and generates display.
%sequencelearning2_subj('s01', 1, 11);  %11th block, trial 1
%sequencelearning2_subj('s01',0, 2) %generates figure

%BN, TN, startTR, lastTrial, startTime, board, hand, seqType, announce, feedback, day, sounds, trialType, complete, iti,
%trialPoints, seqError, hardPress, latePress, incompletePress, MT,
%resp1, RT1, pressT1 |  resp2, RT2, pressT2  |  resp3, RT3, pressT3 | resp4, RT4, pressT4  |  resp5, RT5, pressT5
%Exclusions:  announce and blocks 1 and 2 (practice runs)

%Define constants:
relTH=0.5;
resTH=0.6;
maxTH=2.5;
timeTHpctsuperfast=0.8;
timeTHpctlate=1.2;

%Define sequences:
sequences=[...
    5,3,4,2,1;...  %----1  %test/train
    5,2,1,3,4;...  %----2  %test/train
    4,5,1,3,2;...  %----3  %test/train
    4,1,3,5,2;...  %----4  %test/train
    3,1,4,2,5;...  %----5  %test/train
    2,3,5,4,1;...  %----6  %test/train
    2,5,3,1,4;...  %----7  %test/train
    1,4,2,5,3;...  %----8  %test/train
    1,2,4,3,5;...  %----9  %test/train
    1,5,4,2,3;...  %----10 %test/train
    3,5,2,1,4;...  %----11 %test/train
    3,2,5,1,4;...  %----12 %test/train
    4,2,5,3,1;...  %----13 practice/demo
    2,5,4,1,3;...  %----14 practice/demo
    ];

%Concatenate to yield single variables:
finger=[D.resp1 D.resp2 D.resp3 D.resp4 D.resp5 (D.resp1)+5 (D.resp2)+5 (D.resp3)+5 (D.resp4)+5 (D.resp5)+5];
RT=[D.RT1 D.RT2 D.RT3 D.RT4 D.RT5];
pressT=[D.pressT1 D.pressT2 D.pressT3 D.pressT4 D.pressT5];

% OPTIONS:
vararginoptions(varargin,{'startthres','endthres','minstart','maxstop','plane', 'fig_name'});

% (1) EXTRACT DATA:
if (isempty(MOV))
    return;
end;

state=MOV(:,1);
time=MOV(:,2);
screentime=MOV(:,3);

%(2) SMOOTH DATA:
Force=smooth_kernel(MOV(:,4:13), 5);

% Display trial
if (D.announce)
    return; % EXIT THE FUNCTION AND DON'T ANALYZE THE ANNOUCE TRIALS
end;


%(3) ELIMINATE NaN trials (trials that did not reach all states)
D.good=1;      % Display trial
if (D.announce)
    D.good=0;
    
    return; % EXIT THE FUNCTION AND DON'T ANALYZE THE ANNOUNCE TRIALS
end;


%(4) RECALCULATE MT, 5xRT, 5xPressT, 5xReleaseT
for i=1:5                              %presses 1-5
    if D.announce==0 && D.good==1;      %%&& D.hand==1;
        
        RTround = round(RT * 1000);      %need to round RT and time such that they match
        t=round (time * 1000);           %need to round RT and time such that they match
        pressT5ms= (D.pressT5 * 1000);   %because you must add this to the MT, you need to make it ms
        
        r=find (t==RTround(i));          %find the location of the appropriate timestamp (original RT)
        
        if (Force(r(finger(i)<relTH)))   % Check for Error:  points to a major error in the program, will stop here
            %error ('error');
            %keyboard;
            D.ForceError=1;
        else
            D.ForceError=0;
        end;
        
        
        if D.hand==1                     %Specify force vector for each left hand
            F=Force(:,1:5);
        elseif D.hand==2                 %Specify force vector for each right hand
            F=Force(:,6:10);
        end;
        
        
        j=0;
        while (r-j>0 && F(r-j, finger(i)) > relTH)   %r-j>0 (because some people will press early accidentally)
            j=j+1;   %skips backward from original
        end;
        %         %Identify trials with an early press:
        %         if (r<0 && F(r-j, finger(i)) > relTH)                 %CHECK
        %             D.earlyPress=1;
        %         else
        %             D.earlyPress=0;
        %         end;
     
        D.RTnew(i)=t(r-j+1);
        
        MTnew=max(D.RTnew)+(pressT5ms)-min(D.RTnew);   %subtract last finger timepoint from that of the first finger %T.MT= T.RT5+T.pressT5-T.RT1;
        D.MTnew=MTnew/1000; %divide to get in sec, rather than ms.
        
        
        %MTs of incorrect seq (to see if it's merely because they go to fast, don't exclude error seq at the beginning of the if statement but create another MT variable here)
        if D.seqError==0      
            D.MTfinal=MTnew;
        else
            D.MTfinal=NaN;
        end;
        
        %Flag when MT is different from online generated values:
        MT=round (D.MT * 1000);
        if MT~=MTnew
            D.MTflag=1;
        else
            D.MTflag=0;
        end;
        
    else D.RTnew(i)=NaN;
    end;
end;

%(5) ERROR RATE:  Make Error all or nothing (this is based on pre-existing error term but this will be recalculated later):
if D.seqError>0
    D.Error=1;
else
    D.Error=0;
end;

%REPETITION NUMBER:
D.repNum=mod(D.TN-1,5);   %announce=0, 1,2,3, 4  [4 repetitions]

%PRE and POST-TEST LABELS (for collapsing the post-tests)
if D.trialType>3
    D.test=2;
elseif D.trialType<3 && D.trialType>0
    D.test=1;
else
    D.test=0;
end;



%TO DO:            MIRROR MOVEMENT:  SORT THIS OUT LATER!!!!!!!!!!!
% I4=find(state==4);               %state 3 corresponds to  WAIT_READY
% I5=find(state==5);               %state 4 corresponds to  WAIT_RESPONSE
% baseline=mean(Force(I4,:));  %WAIT_READY (baseline force on all fingers)
% press=mean(Force(I5,:)); 
% meanforce=press-baseline; 
% D.mirror_corrMean=corr([meanforce([1:5])' meanforce([6:10])']); 


  
if (fig>0)
    plot(time,Force);
    drawline([D.RT1 D.RT2 D.RT3 D.RT4 D.RT5]);
    drawline(D.RTnew/1000,'color','r');
    drawline([0.5 0.6 2.5],'dir','horz');   %drawline at thresholds release, response, and max
    xlabel('time[ms]');
    if (fig==1)
        keyboard;
    elseif (fig==2) %---- now we like to save the figure without looking at it 
        saveas(gcf,['figures', filesep, fig_name]);
    end
end;




% %ErrorRate
% incorrect/total possible
% X/16 train
% X/24
%
% sum(D.announce==0) %number of sequences
%
% sum(D.announce(D.BN))
%
% D.ErrorRate=sum(D.Error(D.BN)>0);
%
% %D.ErrorRate=(100/sum(D.announce==0))*sum(D.Error(D.BN)>0);
%
%
% %Recalculate Error Rate based on readjusted thresholds:


%'Error Rate: ',num2str((100/sum(T.announce==0))*sum(D.seqError(D.BN==gExp.BN)>0))];

% if T.(['resp',num2str(seqCounter)]) ~= gExp.seq(T.seqType,seqCounter) %----wrong finger was pressed
%     if (T.feedback) 		%----if feedback => Red  set color of the SEQ and center array
%         gExp.seqColor(seqCounter)=4;
%     end
%     T.seqError= T.seqError+1;	%----set error flag


%Visualise (print out) the inputs
% for i=1:5
%     if D.announce==0
%     fprintf(' %d     %d     %d  ', i, finger (i), RT (i));
%     %keyboard;
%     end;
% end


%Good trials
% I2=find(state);               %state 2 corresponds to % WAIT_TR
% if (length(I2)<4 )  %eliminate NaNs %|| length(I5)<4 || length(I45)<4
%     D.good=0;
%     return;
% end;

%
% if (D.RT1<0.1 || D.RT2<0.1 || D.RT3<0.1 || D.RT4<0.1 || D.RT5<0.1 || D.pressT1<0.1 || D.pressT1<0.1 || D.pressT1<0.1 || D.pressT1<0.1 || D.pressT1<0.1)
%     D.good=0;
%     return;
% end;



%  5,3,4,2,1;...  %----1  %test/train
%  5,2,1,3,4;...  %----2  %test/train
%  4,5,1,3,2;...  %----3  %test/train
%  4,1,3,5,2;...  %----4  %test/train
%  3,1,4,2,5;...  %----5  %test/train
%  2,3,5,4,1;...  %----6  %test/train
%  2,5,3,1,4;...  %----7  %test/train
%  1,4,2,5,3;...  %----8  %test/train
%  1,2,4,3,5;...  %----9  %test/train
%  1,5,4,2,3;...  %----10 %test/train
%  3,5,2,1,4;...  %----11 %test/train
%  3,2,5,1,4;...  %----12 %test/train
%  4,2,5,3,1;...          %----practice/demo
%  2,5,4,1,3;...          %----practice/demo
%  2,1,3,5,4;...  %----15 %----use to determine pass for the scan with unkown seq
%  4,5,3,1,2;...  %----16 %----use to determine pass for the scan with unkown seq
%  3,5,4,2,1;...  %----17 %----use to determine pass for the scan with unkown seq
%  1,4,5,3,2];
%  %1,3,5,4,2;...  %----18 %----use to determine pass for the scan with unkown seq


%  5,3,4,2,1;...
%  5,2,1,3,4;...
%  4,5,1,3,2;...
%  4,1,3,5,2;...
%  3,1,4,2,5;...
%  2,3,5,4,1;...
%  2,5,3,1,4;...
%  1,4,2,5,3;...
%  1,2,4,3,5;...
%  1,5,4,2,3;...
%  3,5,2,1,4;...
%  3,2,5,1,4;...
%  4,2,5,3,1;...
%  2,5,4,1,3;...
%  2,1,3,5,4;...
%  4,5,3,1,2;...
%  3,5,4,2,1;...
%  1,4,5,3,2



% function [D]=sequencelearning2_trial(MOV,D,fig,varargin)
% % Reach_trial
% % extracts the statistics from the movement data
% % for one trial.
% % Does a nice display of each trial
%
% % ------------------------------------------------
% % Defaults
% sample=5;
%
% % ------------------------------------------------
% % OPTIONS
% vararginoptions(varargin,{'startthres','endthres','minstart','maxstop','plane'});
%
% % ------------------------------------------------
% % extract data
% if (isempty(MOV))
%     return;
% end;
% state=MOV(:,1);
% TR=MOV(:,2);
% t=MOV(:,5); %WAS (:,5) before
% sampfreq=1000/sample;
% Volts=smooth_kernel(MOV(:,6:15),5);  %THAT WAS BEFORE I INCLUDED THE TR COUNTER IN THE MOV FILE (MOV(:,5:9),5);
% %Volts=smooth_kernel(MOV(:,6:10),5);  %for s05 because only 5 left hand was measured
% %Volts= MOV(:,6:15);
% pres= [(state(1:end-1)==3 & state(2:end)==4);0];
% cycle=cumsum(pres);
%
% if D.board==1 % if we test the right finger ana the data for the right finger otherwise the left finger data are analysed
%     Volts= Volts(:,6:10);
% end
%
% % definde the timewindow where to look for the maxima
% idx_RT(1)= round((D.RT1/5)+1);
% idx_RT(2)= round((D.RT5/5+ D.pressT5/5*1.1)+1);
% if idx_RT(1)>length(Volts)
%     idx_RT(1)=1;
% end
% if idx_RT(2)>length(Volts) || idx_RT(2)<idx_RT(1)
%     idx_RT(2)=length(Volts);
% end
% idx_all= 1:idx_RT(2);
% % find the maxima
% for i=1:5%max(cycle)
%     %j=find(cycle==i);
%     if D.announce==0 & D.lastTrial==0%D.feedback~=3
%         [b_max(i), t_max(i)]=max(Volts(idx_RT(1):idx_RT(2), i));
%
%         [D.(sprintf('max_volts%d',i-1))]= b_max(i); %,D.(sprintf('digit%d',i-1))]=max(b);
%         [D.(sprintf('max_volts%d_time',i-1))]= (t_max(i)-1)*5+D.RT1;
%         [D.(sprintf('force_sum%d',i-1))]= sum(Volts(idx_RT(1):idx_RT(2), i));
%         idx= idx_all;
%         if D.(['pressT',num2str(i)])>0
%             idx_end= round((D.(['RT',num2str(i)])+D.(['pressT',num2str(i)]))/5);
%             idx_begin= round(D.(['RT',num2str(i)])/5);
%             if idx_end>idx_all(end)
%                 idx_end= idx_all(end);
%             end
%             idx(unique(round([idx_begin: idx_end])))= [];
%             [D.(sprintf('force_noPresssum%d',i-1))]= sum(Volts(idx, D.(['resp',num2str(i)])));
%             [D.(sprintf('force_noPressvar%d',i-1))]= var(Volts(idx, D.(['resp',num2str(i)])));
%         else
%             [D.(sprintf('force_noPresssum%d',i-1))]= 0;
%             [D.(sprintf('force_noPressvar%d',i-1))]= 0;
%         end
%
%     else
%         tm=[];
%        [D.(sprintf('max_volts%d',i-1))]=0;
%        [D.(sprintf('max_volts%d_time',i-1))]= 0;
%        [D.(sprintf('force_sum%d',i-1))]= 0;
%        [D.(sprintf('force_noPresssum%d',i-1))]= 0;
%        [D.(sprintf('force_noPressvar%d',i-1))]= 0;
%     end
% end;
%
% % ------------------------------------------------
% % Display trial
% if (fig>0)
%    plot(t,Volts');
%    %drawline(t(find(pres)));
%    drawline([D.RT1 D.RT2 D.RT3 D.RT4 D.RT5])
%    line(1:t(end), ones(t(end),1) *0.5)
%    line(1:t(end), ones(t(end),1) *0.4)
%    legend('Thumb', 'Index', 'Middle', 'Ring', 'Pinky', 'location', 'EastOutside' )
%    hold on
%    for i=1:5
%     if D.announce==0
%         plot([D.(sprintf('max_volts%d_time',i-1))], [D.(sprintf('max_volts%d',i-1))], 'm*')
%     end
%    end
% %    if D.board==1 % if we test the right finger ana the data for the right finger otherwise the left finger data are analysed
% %        V= smooth_kernel(MOV(:,6:10),5);
% %    elseif D.board==0
% %        V= smooth_kernel(MOV(:,11:15),5);
% %    end
% %    subplot(3,1,3); plot(t,V');
%    hold off
%    waitforbuttonpress;
%    % keyboard;
% end;
