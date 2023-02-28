function ANA=sequencelearning2_subj(subjname,fig,block,trial)
%sequencelearning2:  tDCS study (test 12 seq, train 4)


if nargin<2
    fig=0;
end;
datafilename=['../data/sl2_' subjname '.dat']; %input
outfilename=['sl2_' subjname '.mat'];          %output   (to analyse folder)
TRA=[];
ANA=[];
D=dload(datafilename);
if (nargin<3) 
    s=1;
else
    if (nargin<4)
        s=find(D.BN==block & D.TN==1); 
    else 
        s=find(D.BN==block & D.TN==trial); 
    end;
end;

%Define trials of a block:
trials=[s:length(D.BN)];

oldblock=-1; %oldday=-1; oldtrialType=-1;
%bn=0;

for i=trials
    if (oldblock~=D.BN(i))
        load(['../data/sl2_' subjname '_' num2str(D.BN(i),'%02d'),'.mat']);  %Load mat files %MOV=
        oldblock=D.BN(i);
    end
    fprintf('%d %d\n',D.BN(i),D.TN(i));
    fig_name= sprintf('%s_%d_%d.jpg',subjname, D.BN(i),D.TN(i));
    [C]=sequencelearning2_trial(MOV{D.TN(i)},getrow(D,i),fig, 'fig_name', fig_name);                       %Call trial routine
    ANA=addstruct(ANA,C,'row','force');
end;

save(outfilename,'-struct','ANA');




% sequencelearning2_subj('s01', 0); 
% sequencelearning2_subj('s02', 0); 
% sequencelearning2_subj('s03', 0); 
% sequencelearning2_subj('s04', 0); 
% sequencelearning2_subj('s05', 0); 
% sequencelearning2_subj('s06', 0); 
% sequencelearning2_subj('s07', 0); 
% sequencelearning2_subj('s08', 0); 
% sequencelearning2_subj('s09', 0); 
% sequencelearning2_subj('s10', 0); 
% sequencelearning2_subj('s11', 0); 
% sequencelearning2_subj('s12', 0); 
% sequencelearning2_subj('s13', 0); 
% sequencelearning2_subj('s14', 0); 
% sequencelearning2_subj('s15', 0); 
% sequencelearning2_subj('s16', 0); 
% sequencelearning2_subj('s17', 0); 
% sequencelearning2_subj('s18', 0); 
% sequencelearning2_subj('s19', 0); 
% sequencelearning2_subj('s20', 0); 
% sequencelearning2_subj('s21', 0); 
% sequencelearning2_subj('s22', 0); 
% sequencelearning2_subj('s23', 0); 
% sequencelearning2_subj('s24', 0); 
% sequencelearning2_subj('s25', 0); 
% sequencelearning2_subj('s26', 0); 
% sequencelearning2_subj('s27', 0); 
% sequencelearning2_subj('s28', 0); 
% sequencelearning2_subj('s29', 0); 
% sequencelearning2_subj('s30', 0); 
% sequencelearning2_subj('s31', 0); 
% sequencelearning2_subj('s32', 0); 
% sequencelearning2_subj('s33', 0); 
% sequencelearning2_subj('s34', 0); 
% sequencelearning2_subj('s35', 0); 
% sequencelearning2_subj('s36', 0); 
% sequencelearning2_subj('s37', 0); 
% sequencelearning2_subj('s38', 0); 
% sequencelearning2_subj('s39', 0); 
% sequencelearning2_subj('s40', 0); 
% sequencelearning2_subj('s41', 0); 
% sequencelearning2_subj('s42', 0); 
% sequencelearning2_subj('s43', 0); 
% sequencelearning2_subj('s44', 0);
% sequencelearning2_subj('s45', 0);
% sequencelearning2_subj('s46', 0);

% function ANA=sequencelearning2_subj(subjname,fig,block,trial, trainSeq);
% 
% if nargin<2
%     fig=0;
% end;
% datafilename=['sl2_' subjname '.dat'];
% outfilename=['D_' subjname '.mat'];
% TRA=[];
% ANA=[];
% D=dload(datafilename);
% if (nargin<3) 
%     s=1;
% else
%     if (nargin<4)
%         s=find(D.BN==block & D.TN==1); 
%     else 
%         s=find(D.BN==block & D.TN==trial); 
%     end;
% end;
% %define  number of trials
% trials=[s:length(D.BN)];
% 
% oldblock=-1; oldday=-1; oldtrialType=-1;
% bn=0;
% for i=trials % loop over all trials
%    if (oldday~= D.day(i) || oldtrialType~= D.trialType(i)) && (D.trialType(i)~= 4) 
%        oldday= D.day(i);
%        oldtrialType= D.trialType(i);
%        bn= D.BN(i);
%    end
%    if (oldblock~=D.BN(i))
%         oldblock=D.BN(i);
%         MOV=movload(['SL1_' subjname '_' num2str(D.BN(i),'%02d') '.mov']); 
%    end;
% 
%    fprintf('%d %d\n',D.BN(i),D.TN(i));
%    [C]=sl1_trial(MOV{D.TN(i)},getrow(D,i),fig);
%    C.bn= D.BN(i)-bn;
%    % update TRA
%    ANA=addstruct(ANA,C);
% end;
% % to add
% % Phase: 1: pretest 2: training 3: scan 4: posttest
% ANA.phase= ANA.trialType;
% ANA.phase(ANA.trialType==2)= 1; %for right preTest
% ANA.phase(ANA.trialType==7)= 4; %for left postTest
% ANA.phase(ANA.trialType==8)= 4; %for right postTest
% 
% ANA.phase(ANA.trialType==3)= 2; %for training
% ANA.phase(ANA.trialType==4)= 2; %for scan training
% ANA.phase(ANA.trialType==9)= 5; %test unknown seq scan trial
% ANA.phase(ANA.trialType==5)= 3; %for first scan
% ANA.phase(ANA.trialType==6)= 3; %for second scan
% % Hand: 1 /2 (board) 
% % Day: (only for training 1-5 and scan 1-2)
% 
% ANA.day(ANA.phase==0)=0;    %set explain
% ANA.day(ANA.phase==1)=0;    %& pre test 
% ANA.day(ANA.phase==4)=0;    %& post test to zero
% ANA.day(ANA.trialType==10)=0; %retraining before pretest
% ANA.day(ANA.trialType==5)=1; %scan 1
% ANA.day(ANA.trialType==6)=2; %scan 2
% 
% %ANA.goodTrials= zeros(size(ANA.phase));
% %ANA.goodTrials(ANA.announce==0 & ANA.lastTrial==0 & ANA.seqError==0 & ANA.incompletePress==0)= 1;   % This mixes trials that we want to look at (error trials) 
% 
% ANA.seqCondition= zeros(size(ANA.phase));
% for i=1:4
%     ANA.seqCondition(ANA.seqType==trainSeq(i) & ANA.announce==0 & ANA.lastTrial==0)= 1;
% end
% untrainSeq=1:12;
% untrainSeq(trainSeq)= [];
% for i=1:8 % test and scan
%     ANA.seqCondition(ANA.seqType==untrainSeq(i) & ANA.announce==0 & ANA.lastTrial==0)= 2;
% end
% 
% %make bn_seq counter for the scans
% bn_helper= repmat([ones(1,4) ones(1,4)*2 ones(1,4)*3 ones(1,4)*4 ]', 8,1);
% seq= unique(ANA.seqType(ANA.phase==3 & ANA.seqType~=0));
% ANA.bn_seq= zeros(size(ANA.bn));
% for i= 1:length(seq)
%     ANA.bn_seq(ANA.phase==3 & ANA.seqType==seq(i))= bn_helper;
% end
% %make 4reg bn
% ANA.bn_4reg= zeros(size(ANA.bn));
% bn_helper= repmat(1:16, 4,1); 
% ANA.bn_4reg(ANA.phase==3  & ANA.seqType~=0)= repmat(bn_helper(:), 2*8,1);
% 
% D=ANA; 
% D.bn(D.day==0)=0 %bn == 0 for the testing phase
% 
% 
% save(outfilename,'D');
% 
% 
% % 
% % hold on 
% % subplot(4,2,1:2);lineplot([D.phase, D.day ,D.board D.bn ], D.MT, 'split', [D.board D.seqCondition],'subset',D.MT>0 & D.phase>0 & D.phase<5 & D.trialType~=4,'style_thickline','leg','auto', 'leglocation','EastOutside');
% % subplot(4,2,3:4); barplot(D.day, D.trialPoints,'subset',D.trialPoints==-1 & D.phase>1 & D.phase<5 & D.trialType~=4 & D.trialType~=9, 'split', [ D.phase,D.board, D.bn], 'plotfcn', 'sum')
% % subplot(4,2,5:6); lineplot([D.phase, D.day ,D.board D.bn ], D.MT, 'split', [D.board D.seqCondition D.seqType],'subset',D.MT>0 & D.phase>0 & D.phase<5 & D.trialType~=4,'style_thickline','leg','auto', 'leglocation','EastOutside');
% % subplot(4,2,7:8); barplot(D. seqType, D.MT,'subset',D.MT>0& (D.trialType==4 | D.trialType==9), 'split', D.seqCondition)
