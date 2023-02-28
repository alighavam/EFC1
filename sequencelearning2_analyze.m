function varargout=sequencelearning2_analyze (what, varargin)

%SEQUENCE LEARNING 2:  Longitudinal tDCS study
%Only the analyses/figures actually used in the paper are here (see sequencelearning2_analyseitall for complete options). 

behavDir='D:\Dropbox\project\ChordSequence_tDCS\SequenceLearning\SequenceLearning2\analyse';
%behavDir='/Users/joern/Projects/ChordSequence_tDCS/SequenceLearning/SequenceLearning2/analyse'
cd(behavDir);

%GLOBALS:
subj_name={'s01', 's02', 's03', 's04', 's05', 's06', 's07', 's08', 's09', 's10', ...
    's11', 's12', 's13', 's14', 's15', 's16', 's17', 's18', 's19', 's20', ...
    's21', 's22', 's23', 's24', 's25', 's26', 's27', 's28', 's29', 's30', ...
    's31', 's32', 's33', 's34', 's35', 's36', 's37', 's38', 's39', 's40', ...
    's41', 's42', 's43', 's44', 's45', 's46', 's47', 's48', 's49', 's50', ...
    's51', 's52', 's53', 's54'};

switch (what)
    case 'all_subj'                                                        %DATAPREP:  Analyse all subjects with subj routine
        for s=1:length(subj_name)
            sequencelearning2_subj(subj_name{s},0);
        end;
    case 'make_alldat'                                                     %DATAPREP:  Create the alldat file (----ADJUST SN---)
        %sequencelearning2_analyze('make_alldat', 1:54);
        T=[];
        subj=varargin{1};
        for s=subj
            D=load(['sl2_' subj_name{s} '.mat']);                          %Use load as a function
            D.SN=ones(length(D.BN),1)*s;                                   %Add subject numbers to .mat file
            D.SN=ones(length(D.BN),1)*s;
            T=addstruct(T,D);
        end; 
        save('SL2_alldat.mat','-struct', 'T');
            %         T=[];
            %         %         S=max(T.SN);
            %         %         for s=[1:S]
            %         for s=1:54  % Run over certain subjects (length(subj_name)), insert subj you wish to include
            %             subj=varargin{1};
            %             %             for s=subj
            %             %                 D=load(['SL2_' subj_name{s} '.mat']);   % Use load as a function
            %             %                 D.SN=ones(length(D.BN),1)*s;            % Add subject numbers to .mat file
            %             %             end;
            %             D=load(['SL2_' subj_name{s} '.mat']);   % Use load as a function
            %             D.SN=ones(length(D.BN),1)*s;
            %             T=addstruct(T,D);
            %         end;
            %         save('SL2_alldat.mat','-struct', 'T');
            %         %dsave('SL2_alldat.ana',T);
    case 'insert_seqCategory'                                              %DATAPREP:  Insert the Sequence Category (i.e. trained vs. untrained) here
        %sequencelearning2_analyze('insert_seqCategory');
        T=[];
        D=load('SL2_alldat.mat');
        
        train_seq={...
            [8; 10; 3;  9;];...                           %s01 (cath), s10, s16, s42, s45
            [2; 4;  11; 8;];...                           %s02, s12
            [1; 3;  5;  7;];...                           %s03, s14, s41, s46
            [1; 4;  10; 12;];...                          %s04, s11, s39, s44
            [2; 5;  6;  9;];...                           %s05, s09
            [2; 3;  11; 6;];...                           %s06, s15, s37, s40
            [6; 9;  12; 4;];...                           %s07, s08 (exlude), s13, s17, s18
            [];...                                        %subj s19-36, 38, 43
            };
        test_seq={...
            [5; 1; 11; 6; 4; 7; 12; 2;];...                %s01 (cath), s10, s16, s42, s45
            [1; 3; 5;  6; 7; 9;  10; 12;];...              %s02, s12
            [2; 4; 6;  8; 9; 10; 11; 12;];...              %s03, s14, s41, s46
            [2; 3; 5;  6; 7; 8; 9; 11;];...                %s04, s11, s39, s44
            [1; 3; 4;  7; 8; 10; 11; 12;];...              %s05, s09
            [1; 4; 5;  7; 8; 9; 10; 12;];...               %s06, s15, s37, s40
            [1; 2; 3;  5; 7; 8; 10; 11;];...               %s07, s08 (exclude), s13, s17, s18
            [1; 2; 3;  4; 5; 6; 7; 8; 9; 10; 11; 12;];...  %subj s19-36, 38, 43
            };
        
        %indices 1-8:  This indexes the sequence set of each participant:
        idx=[1;2;3;4;5;6;7;7;5;1;4;2;7;3;6;1;7;7;8;8;8;8;8;8;8;8;8;8;8;8;8;8;8;8;8;8;6;8;4;6;3;1;8;4;1;3;8;8;8;8;8;8;8;8;];
        
        for i=1:length(D.SN)
            isTrain (i) = isincluded (train_seq  {idx(D.SN(i))}, D.seqType (i));
            isTest  (i) = isincluded (test_seq   {idx(D.SN(i))}, D.seqType (i));
            %         if (any(sum([isTrain isTest ],2)>1))
            %             fprintf('error in coding');
            %         end;
            D.seqCategory (i) =isTrain (i)+isTest (i)*2;
        end;
        
        T=addstruct(T,D);
        T.seqCategory= T.seqCategory';
        save('SL2_alldat.mat','-struct', 'T');
    case 'insert_subj-specific_variables'                                  %DATAPREP:  Update the alldat file with subject-specific variables (note that Quesionnaire data is located in QData.mat)
        %sequencelearning2_analyze('insert_subj-specific_variables');
        T=[];
        D=load('SL2_alldat.mat');
        
        %SPECIFY SN rename (for online/offline function), from 1:
        seqReNum=  [0;1;2;3;4;5;6;0;7;8;9;10;11;12;13;14;15;16;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;17;0;18;19;20;21;0;22;23;24;0;0;0;0;0;0;0;0;];
        chordReNum=[0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;0;19;0;0;0;0;20;0;0;0;21;22;23;24;25;26;27;28;];
        %SPECIFY: tDCS group or sham (-1=cathodal, 0=sham, 1=anodal)
        tDCS=[-1;1;1;0;0;1;0;1;1;1;1;0;1;0;0;0;0;1;1;0;1;0;1;0;1;0;1;1;0;1;1;0;1;1;0;0;1;0;1;0;1;1;0;0;0;0;0;1;0;1;0;1;0;1;];
        %Specify Group:  
        Group=[0;2;2;1;1;2;1;0;2;2;2;1;2;1;1;1;1;2;4;3;4;3;4;3;4;3;4;4;3;4;4;3;4;4;3;3;2;3;2;1;2;2;3;1;1;1;3;4;3;4;3;4;3;4;];
        %SPECIFY: subject inclusion or exclusion:
        exclude=[0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;];
        % Definitely excluding s08 because she didn't sleep properly (allnighters due to deadlines with her course) and was extremely distressed out by the tDCS (though she didn't show it or tell me about it--was reflected in her questionnaire which I did not view till later and confirmed when I asked her about it) and the electrodes kept slipping anteriorally AND she was VERY late in attending day 33 (over 2 weeks late, because she was out of the country)
        %(maybe) exluding s06 because she didn't sleep properly and always seemed stressed (was always late, always running somewhere after the experiment)
        % also, note the following subjects were sick at various points throughout the study (though they all still performed well): s28, s31, s42
        %SPECIFY: Subj for whom I have finished the entire study through day 33:
        complete=[1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;0;0;0;0;0;0;0;0;];
        %SPECIFY:  starting hand (for all tasks):  1=start L, 2=start R
        startHand=[2;2;1;1;2;2;1;1;2;2;2;2;1;1;2;1;2;1;2;1;1;2;2;1;2;1;1;1;2;1;2;1;2;1;2;1;2;2;1;2;1;1;2;1;1;2;2;2;2;1;1;1;1;1;];
        %SPECIFY:  experimental session slot:
        slotCode=[1;1;2;3;4;1;2;3;4;3;1;2;3;4;3;4;1;3;1;2;3;4;1;2;3;4;4;1;2;3;4;1;2;3;4;1;2;3;4;2;3;4;1;2;3;4;1;1;2;3;2;4;1;3;];
        %SPECIFY:  chord set:
        seqSet=[1;2;3;4;5;6;7;7;5;1;4;2;7;3;6;1;7;7;8;8;8;8;8;8;8;8;8;8;8;8;8;8;8;8;8;8;6;8;4;6;3;1;8;4;1;3;8;8;8;8;8;8;8;8;];
        %SPECIFY: the training group (1=sequence, 2=chord)
        trainGroup=[1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;2;1;2;1;1;1;1;2;1;1;1;2;2;2;2;2;2;2;2;];
        %SPECIFY: Basic Demographics (full demog are in Qdata):
        Sex=[1;1;2;1;2;1;2;1;2;1;2;2;2;2;1;1;1;1;1;1;2;2;2;2;1;2;1;1;1;1;2;1;2;2;1;2;2;2;2;1;1;2;1;2;2;2;2;2;1;1;1;1;1;2;]; %1=female, 2=male
        Age=[25;24;25;20;23;19;20;23;23;19;20;28;19;20;21;30;23;21;19;25;23;22;22;25;23;20;20;20;20;20;19;24;25;24;20;20;21;21;18;23;20;22;23;20;19;22;0;0;0;0;0;0;0;0;];
        Ethnic=[1;1;1;1;2;2;2;2;1;2;2;3;2;1;2;2;1;1;2;2;2;2;1;1;2;1;1;1;2;1;1;1;1;1;1;1;1;1;1;1;2;1;1;1;1;1;2;1;2;1;2;2;2;1;];  %1=White, %2=Asian/Indian, %3=Black
        EdinburghOrig=[90;100;65;85;65;80;100;80;55;80;100;100;90;65;90;-10;85;75;60;100;80;75;80;30;85;55;65;95;0;60;85;95;85;70;70;80;75;80;45;90;100;100;100;90;85;90;0;0;0;0;0;0;0;0;];
        EdinburghNew= [86.67;100;60;73.33;63.33;80;86.67;63.33;60;76.67;100;100;86.67;66.67;90;-16.67;86.67;73.33;56.67;100;86.67;80;70;30;83.33;50;70;96.67;-6.67;46.67;76.67;90;83.33;66.67;70;63.33;66.67;80;50;83.33;100;96.67;100;80;83.33;83.33;0;0;0;0;0;0;0;0;];
        
        %Save all of these variables in the alldat:
        for i=1:length(D.SN)                       %specify SN you want to loop over
            D.seqReNum=seqReNum(D.SN);
            D.chordReNum=chordReNum(D.SN);
            D.tDCS=tDCS(D.SN);
            D.Group=Group(D.SN);
            D.exclude=exclude(D.SN);
            D.complete=complete(D.SN);
            D.startHand=startHand(D.SN);
            D.slotCode=slotCode(D.SN);
            D.seqSet=seqSet(D.SN);
            D.trainGroup=trainGroup(D.SN);
            %Demographics (Basic):
            D.Sex=Sex(D.SN);
            D.Age=Age(D.SN);
            D.Ethnic=Ethnic(D.SN);
            D.EdinburghOrig=EdinburghOrig(D.SN);
            D.EdinburghNew=EdinburghNew(D.SN);
        end;
        
        T=addstruct(T,D);
        save('SL2_alldat.mat','-struct', 'T');

    case 'intratask_MAKETABLE'                                             %INTRA-TASK TABLE:  Sequence-trained 
        %sequencelearning2_analyze('intratask_MAKETABLE');
        cd(behavDir);
        C=load('SL2_alldat.mat');
        %Pre/Post-test Table (all trial types except 3 and seqCategory>0 excludes the practice trials):
        subs = [C.announce==0  & C.good~=0 & C.exclude==0 & C.trainGroup==1 & C.trialType~=3 & C.tDCS~=-1 & C.seqCategory>0];
        H=tapply(C,{'SN', 'seqReNum', 'test', 'day', 'seqCategory', 'hand', 'tDCS', 'trialType', 'trainGroup'},...
            {C.MTnew,'nanmean','name','MTnew'},...
            {C.Error,'nanmean','name','Error'},...
            {C.MT,'nanmean','name','MT'},...
            {C.seqError,'nanmean','name','seqError'},...
            'subset', subs);
        %Training Table:
        subs = [C.announce==0 & C.good~=0 & C.exclude==0 & C.trainGroup==1 & C.trialType==3 & C.tDCS~=-1];
        I=tapply(C,{'SN', 'seqReNum', 'BN', 'day', 'seqCategory', 'hand', 'tDCS', 'trialType', 'trainGroup'},...
            {C.MTnew,'nanmean','name','MTnew'},...
            {C.Error,'nanmean','name','Error'},...
            {C.MT,'nanmean','name','MT'},...
            {C.seqError,'nanmean','name','seqError'},...
            'subset', subs);
        %Pre/Post-test Table with BNs:
        subs = [C.announce==0  & C.good~=0 & C.exclude==0 & C.trainGroup==1 & C.trialType~=3 & C.tDCS~=-1 & C.seqCategory>0];
        J=tapply(C,{'SN', 'seqReNum', 'BN', 'test', 'day', 'seqCategory', 'hand', 'tDCS', 'trialType', 'trainGroup'},...
            {C.MTnew,'nanmean','name','MTnew'},...
            {C.Error,'nanmean','name','Error'},...
            {C.MT,'nanmean','name','MT'},...
            {C.seqError,'nanmean','name','seqError'},...
            'subset', subs);
        %Pre/Post-test Table with Phase:
        C.ptPhase=C.SN*0;
        C.ptPhase(C.day==5)  =  (C.BN(C.day==5)>110)+1;
        C.ptPhase(C.day==12) =  (C.BN(C.day==12)>118)+3;
        C.ptPhase(C.day==33) =  (C.BN(C.day==33)>126)+5;
        subs = [C.announce==0  & C.good~=0 & C.exclude==0 & C.trainGroup==1 & C.trialType~=3 & C.tDCS~=-1 & C.seqCategory>0];
        K=tapply(C,{'SN', 'ptPhase', 'seqReNum', 'test', 'day', 'seqCategory', 'hand', 'tDCS', 'trialType', 'trainGroup'},...
            {C.MTnew,'nanmean','name','MTnew'},...
            {C.Error,'nanmean','name','Error'},...
            {C.MT,'nanmean','name','MT'},...
            {C.seqError,'nanmean','name','seqError'},...
            'subset', subs);
        
        %Pre/Post-test Table with Phase:  Sequence-trained and Configuration-trained groups.
        C.ptPhase=C.SN*0;
        C.ptPhase(C.day==5  & C.trainGroup==1)  =  (C.BN(C.day==5  & C.trainGroup==1)>110)+1;
        C.ptPhase(C.day==12 & C.trainGroup==1)  =  (C.BN(C.day==12 & C.trainGroup==1)>118)+3;
        C.ptPhase(C.day==33 & C.trainGroup==1)  =  (C.BN(C.day==33 & C.trainGroup==1)>126)+5;
        C.ptPhase(C.day==5  & C.trainGroup==2)  =  (C.BN(C.day==5  & C.trainGroup==2)>14)+1;
        C.ptPhase(C.day==12 & C.trainGroup==2)  =  (C.BN(C.day==12 & C.trainGroup==2)>22)+3;
        C.ptPhase(C.day==33 & C.trainGroup==2)  =  (C.BN(C.day==33 & C.trainGroup==2)>30)+5;
        subs = [C.announce==0  & C.good~=0 & C.exclude==0 & C.trialType~=3 & C.tDCS~=-1 & C.seqCategory>0];
        L=tapply(C,{'SN', 'ptPhase', 'seqReNum', 'test', 'day', 'seqCategory', 'hand', 'tDCS', 'trialType', 'trainGroup'},...
            {C.MTnew,'nanmean','name','MTnew'},...
            {C.Error,'nanmean','name','Error'},...
            {C.MT,'nanmean','name','MT'},...
            {C.seqError,'nanmean','name','seqError'},...
            'subset', subs);
        
        %Pre/Post-test Table:  Configuration-trained and sequence-trained groups.
        subs = [C.announce==0  & C.good~=0 & C.exclude==0 & C.trialType~=3 & C.tDCS~=-1 & C.seqCategory>0];
        M=tapply(C,{'SN', 'seqReNum', 'chordReNum', 'test', 'day', 'seqCategory', 'hand', 'tDCS', 'trialType', 'trainGroup'},...
            {C.MTnew,'nanmean','name','MTnew'},...
            {C.Error,'nanmean','name','Error'},...
            {C.MT,'nanmean','name','MT'},...
            {C.seqError,'nanmean','name','seqError'},...
            'subset', subs);
        
        %For plotting in MATLAB:
        dsave('SL2_preposttest.dat',H);
        dsave('SL2_training.dat',I);
        dsave('SL2_preposttest_learn.dat',J);
        dsave('SL2_prehalfposttest.dat',K);
        dsave('SL2_prehalfposttest_all.dat',L);
        dsave('SL2_preposttest_all.dat',M);
        
        %For generating ANOVAs of LH and RH diffs (to determine if valid to average over them):
        %Table for PRE-TEST and posttest (all trial types except 3 and seqCategory>0 excludes the practice trials)
        subs = [C.announce==0  & C.good~=0 & C.exclude==0 & C.trainGroup==1 & C.trialType~=3 & C.seqCategory>0 & C.tDCS~=-1 & C.day>4];
        N=tapply(C,{'SN', 'seqReNum', 'test', 'seqCategory', 'hand', 'tDCS', 'trainGroup'},...
            {C.MTnew,'nanmean','name','MTnew'},...
            {C.Error,'nanmean','name','Error'},...
            {C.MT,'nanmean','name','MT'},...
            {C.seqError,'nanmean','name','seqError'},...
            'subset', subs);
        dsave('SL2_preposttest_averaged.dat', N);
    case 'intratask_MAKETABLE_DIFFSCORE'                                   %INTRA-TASK TABLE:  Sequence-trained pre-post diff scores (original and 'adjusted')
        %sequencelearning2_analyze('intratask_MAKETABLE_DIFFSCORE');
        cd(behavDir);
        %Calc the General Learning effect:
        %Defaults/Varargin:
        postdays=[5];  %Base the correction only on the first post-test
        tDCS=[0 1];
        sn=[1:54];
        vararginoptions(varargin,{'postdays', 'tDCS', 'sn'});
        T=dload('SL2_preposttest_diff_ChordTr.dat');
        U=getrow(T,  isincluded(sn,T.SN) & isincluded(postdays, T.day) & isincluded(tDCS, T.tDCS));
        MTnew_adj_L     =  mean  (U.MTnew_DIFF     (U.hand==1));
        MTnew_adj_R     =  mean  (U.MTnew_DIFF     (U.hand==2));
        Error_adj_L     =  mean  (U.Error_DIFF     (U.hand==1));
        Error_adj_R     =  mean  (U.Error_DIFF     (U.hand==2));
        %You may want to consider correcting individually for the sham and tDCS 'no trained' groups
        %It could be argued that (since the tDCS perform better, esp have
        %more transfer from chording to sequence task), that this
        %underestimates the level of benefit from training that sham are
        %getting.
        MTnew_adj_Ls     =  mean  (U.MTnew_DIFF     (U.hand==1 & U.tDCS==0));
        MTnew_adj_Rs     =  mean  (U.MTnew_DIFF     (U.hand==2 & U.tDCS==0));
        Error_adj_Ls     =  mean  (U.Error_DIFF     (U.hand==1 & U.tDCS==0));
        Error_adj_Rs     =  mean  (U.Error_DIFF     (U.hand==2 & U.tDCS==0));
        MTnew_adj_Lt     =  mean  (U.MTnew_DIFF     (U.hand==1 & U.tDCS==1));
        MTnew_adj_Rt     =  mean  (U.MTnew_DIFF     (U.hand==2 & U.tDCS==1));
        Error_adj_Lt     =  mean  (U.Error_DIFF     (U.hand==1 & U.tDCS==1));
        Error_adj_Rt     =  mean  (U.Error_DIFF     (U.hand==2 & U.tDCS==1));
        
        D = dload('SL2_preposttest.dat');
        D1 = getrow(D,D.day==1);
        D = getrow(D,D.day>1);
        for s = unique(D.SN)'
            for seq = unique(D.seqCategory)'
                for h = unique(D.hand)'
                    i1 = find(D1.SN==s & D1.day==1 & D1.seqCategory==seq & D1.hand==h);
                    for day = [5 12 33]
                        i = find(D.SN==s & D.day==day & D.seqCategory==seq & D.hand==h);
                        %Raw difference values:
                        %D.Diff(i,1)= (D.(variable{variable_idx})(i) ) - (D1.(variable{variable_idx})(i1) );  %individual variable
                        D.MTnew_DIFF(i,1)    =  D1.MTnew(i1)    -  D.MTnew(i);
                        D.Error_DIFF(i,1)    =  D1.Error(i1)    -  D.Error(i);
                        D.MT_DIFF(i,1)       =  D1.MT(i1)       -  D.MT(i);
                        D.seqError_DIFF(i,1) =  D1.seqError(i1) -  D.seqError(i);
                        i';
                    end;
                end;
            end;
        end;
        
        for s = unique(D.SN)'
            for seq = unique(D.seqCategory)'
                %for h = unique(D.hand)'
                i1 = find(D1.SN==s & D1.day==1 & D1.seqCategory==seq & D1.hand==1);
                i2 = find(D1.SN==s & D1.day==1 & D1.seqCategory==seq & D1.hand==2);
                for day = [5 12 33]
                    j1 = find(D.SN==s & D.day==day & D.seqCategory==seq & D.hand==1);
                    j2 = find(D.SN==s & D.day==day & D.seqCategory==seq & D.hand==2);
                    %                     k1 = find(D.SN==s & D.day==day & D.seqCategory==seq & D.hand==1 & D.tDCS==0);
                    %                     k2 = find(D.SN==s & D.day==day & D.seqCategory==seq & D.hand==2 & D.tDCS==0);
                    %                     k3 = find(D.SN==s & D.day==day & D.seqCategory==seq & D.hand==1 & D.tDCS==1);
                    %                     k4 = find(D.SN==s & D.day==day & D.seqCategory==seq & D.hand==2 & D.tDCS==1);
                    %Difference values adjusted for 'general learning rate' (i.e. of the sequence-trained (non-configuration trained group)--avg across sham and tDCS:
                    MTnew_DIFF_adj(j1)        =  (D1.MTnew(i1)       -  D.MTnew(j1))     -  MTnew_adj_L;
                    Error_DIFF_adj(j1)        =  (D1.Error(i1)       -  D.Error(j1))     -  Error_adj_L;
                    MTnew_DIFF_adj(j2)        =  (D1.MTnew(i2)       -  D.MTnew(j2))     -  MTnew_adj_R;
                    Error_DIFF_adj(j2)        =  (D1.Error(i2)       -  D.Error(j2))     -  Error_adj_R;

                    %Difference values adjusted with 'general learning rate' (i.e. of the sequence-trained (non-configuration trained group)--avg across sham only:
                    MTnew_DIFF_adjS(j1)        =  (D1.MTnew(i1)       -  D.MTnew(j1))     -  MTnew_adj_Ls;
                    Error_DIFF_adjS(j1)        =  (D1.Error(i1)       -  D.Error(j1))     -  Error_adj_Ls;
                    MTnew_DIFF_adjS(j2)        =  (D1.MTnew(i2)       -  D.MTnew(j2))     -  MTnew_adj_Rs;
                    Error_DIFF_adjS(j2)        =  (D1.Error(i2)       -  D.Error(j2))     -  Error_adj_Rs;
                    
                    if D.tDCS (j1)==0
                        MTnew_DIFF_adjST(j1)        =  (D1.MTnew(i1)       -  D.MTnew(j1))     -  MTnew_adj_Ls;
                        Error_DIFF_adjST(j1)        =  (D1.Error(i1)       -  D.Error(j1))     -  Error_adj_Ls;
                        MTnew_DIFF_adjST(j2)        =  (D1.MTnew(i2)       -  D.MTnew(j2))     -  MTnew_adj_Rs;
                        Error_DIFF_adjST(j2)        =  (D1.Error(i2)       -  D.Error(j2))     -  Error_adj_Rs;
                    elseif D.tDCS (j1)==1
                        MTnew_DIFF_adjST(j1)        =  (D1.MTnew(i1)       -  D.MTnew(j1))     -  MTnew_adj_Lt;
                        Error_DIFF_adjST(j1)        =  (D1.Error(i1)       -  D.Error(j1))     -  Error_adj_Lt;
                        MTnew_DIFF_adjST(j2)        =  (D1.MTnew(i2)       -  D.MTnew(j2))     -  MTnew_adj_Rt;
                        Error_DIFF_adjST(j2)        =  (D1.Error(i2)       -  D.Error(j2))     -  Error_adj_Rt;
                    end;
                    
                    D.MTnew_DIFF_adj      =  MTnew_DIFF_adj';
                    D.Error_DIFF_adj      =  Error_DIFF_adj';
                    
                    D.MTnew_DIFF_adjS     =  MTnew_DIFF_adjS';
                    D.Error_DIFF_adjS     =  Error_DIFF_adjS';
                    
                    D.MTnew_DIFF_adjST    =  MTnew_DIFF_adjST';
                    D.Error_DIFF_adjST    =  Error_DIFF_adjST';
                end;
            end;
        end;
        %For plotting in Matlab:
        dsave('SL2_preposttest_diff.dat',D);
        %         %How to reformat?
        %         %For ANOVA in SPSS:
        %         E=pivottable([D.SN D.tDCS D.seqReNum], [D.day D.hand D.seqCategory], D.(variable{variable_idx}), 'mean', 'datafilename', 'SL2_preposttest_diff_ANOVA_HandChordCat.dat');
        %         F=pivottable([D.SN D.tDCS D.seqReNum], [D.day D.hand], D.(variable{variable_idx}), 'mean', 'datafilename', 'SL2_preposttest_diff_ANOVA_Hand.dat');

        E = dload('SL2_prehalfposttest.dat');
        E1 = getrow(E,E.ptPhase==0);
        E = getrow(E,E.ptPhase>0);
        for s = unique(E.SN)'
            for seq = unique(E.seqCategory)'
                for h = unique(E.hand)'
                    i1 = find(E1.SN==s & E1.ptPhase==0 & E1.seqCategory==seq & E1.hand==h);
                    for ptPhase = [1 2 3 4 5 6]
                        i = find(E.SN==s & E.ptPhase==ptPhase & E.seqCategory==seq & E.hand==h);
                        %Raw difference values:
                        E.MTnew_DIFF(i,1)     =  E1.MTnew(i1)     -  E.MTnew(i);
                        E.Error_DIFF(i,1)     =  E1.Error(i1)     -  E.Error(i);
                        E.MT_DIFF(i,1)        =  E1.MT(i1)        -  E.MT(i);
                        E.seqError_DIFF(i,1)  =  E1.seqError(i1)  -  E.seqError(i);
                        i';
                    end;
                end;
            end;
        end;
        
        for s = unique(E.SN)'
            for seq = unique(E.seqCategory)'
                %for h = unique(E.hand)'
                i1 = find(E1.SN==s & E1.ptPhase==0 & E1.seqCategory==seq & E1.hand==1);
                i2 = find(E1.SN==s & E1.ptPhase==0 & E1.seqCategory==seq & E1.hand==2);
                for day = [1 2 3 4 5 6]
                    j1 = find(E.SN==s & E.ptPhase==ptPhase & E.seqCategory==seq & E.hand==1);
                    j2 = find(E.SN==s & E.ptPhase==ptPhase & E.seqCategory==seq & E.hand==2);
                    %Eifference values adjusted for 'general learning rate' (i.e. of the sequence-trained (non-configuration trained group)--avg across sham and tDCS:
                    MTnew_DIFF_adj(j1)        =  (E1.MTnew(i1)       -  E.MTnew(j1))     -  MTnew_adj_L;
                    Error_DIFF_adj(j1)        =  (E1.Error(i1)       -  E.Error(j1))     -  Error_adj_L;
                    MTnew_DIFF_adj(j2)        =  (E1.MTnew(i2)       -  E.MTnew(j2))     -  MTnew_adj_R;
                    Error_DIFF_adj(j2)        =  (E1.Error(i2)       -  E.Error(j2))     -  Error_adj_R;
                    %Eifference values adjusted with 'general learning rate' (i.e. of the sequence-trained (non-configuration trained group)--avg across sham only:
                    MTnew_DIFF_adjS(j1)       =  (E1.MTnew(i1)       -  E.MTnew(j1))     -  MTnew_adj_Ls;
                    Error_DIFF_adjS(j1)       =  (E1.Error(i1)       -  E.Error(j1))     -  Error_adj_Ls;
                    MTnew_DIFF_adjS(j2)       =  (E1.MTnew(i2)       -  E.MTnew(j2))     -  MTnew_adj_Rs;
                    Error_DIFF_adjS(j2)       =  (E1.Error(i2)       -  E.Error(j2))     -  Error_adj_Rs;
                    if E.tDCS (j1)==0
                        MTnew_DIFF_adjST(j1)  =  (E1.MTnew(i1)       -  E.MTnew(j1))     -  MTnew_adj_Ls;
                        Error_DIFF_adjST(j1)  =  (E1.Error(i1)       -  E.Error(j1))     -  Error_adj_Ls;
                        MTnew_DIFF_adjST(j2)  =  (E1.MTnew(i2)       -  E.MTnew(j2))     -  MTnew_adj_Rs;
                        Error_DIFF_adjST(j2)  =  (E1.Error(i2)       -  E.Error(j2))     -  Error_adj_Rs;
                    elseif E.tDCS (j1)==1
                        MTnew_DIFF_adjST(j1)  =  (E1.MTnew(i1)       -  E.MTnew(j1))     -  MTnew_adj_Lt;
                        Error_DIFF_adjST(j1)  =  (E1.Error(i1)       -  E.Error(j1))     -  Error_adj_Lt;
                        MTnew_DIFF_adjST(j2)  =  (E1.MTnew(i2)       -  E.MTnew(j2))     -  MTnew_adj_Rt;
                        Error_DIFF_adjST(j2)  =  (E1.Error(i2)       -  E.Error(j2))     -  Error_adj_Rt;
                    end;
                    
                    E.MTnew_DIFF_adj      =  MTnew_DIFF_adj';
                    E.Error_DIFF_adj      =  Error_DIFF_adj';
                    
                    E.MTnew_DIFF_adjS     =  MTnew_DIFF_adjS';
                    E.Error_DIFF_adjS     =  Error_DIFF_adjS';
                    
                    E.MTnew_DIFF_adjST    =  MTnew_DIFF_adjST';
                    E.Error_DIFF_adjST    =  Error_DIFF_adjST';
                end;
            end;
        end;
        
        %For plotting in Matlab:
        dsave('SL2_prehalfposttest_diff.dat',E);

        F = dload('SL2_prehalfposttest_all.dat');
        F1 = getrow(F,F.ptPhase==0);
        F = getrow(F,F.ptPhase>0);
        for s = unique(F.SN)'
            for seq = unique(F.seqCategory)'
                for h = unique(F.hand)'
                    i1 = find(F1.SN==s & F1.ptPhase==0 & F1.seqCategory==seq & F1.hand==h);
                    for ptPhase = [1 2 3 4 5 6]
                        i = find(F.SN==s & F.ptPhase==ptPhase & F.seqCategory==seq & F.hand==h);
                        %Raw difference values:
                        F.MTnew_DIFF(i,1)    =  F1.MTnew(i1)     -  F.MTnew(i);
                        F.Error_DIFF(i,1)    =  F1.Error(i1)     -  F.Error(i);
                        F.MT_DIFF(i,1)       =  F1.MT(i1)        -  F.MT(i);
                        F.seqError_DIFF(i,1) =  F1.seqError(i1)  -  F.seqError(i);
                        i';
                    end;
                end;
            end;
        end;
        
        %For plotting in Matlab:
        dsave('SL2_prehalfposttest_diff_all.dat',F);
    case 'intertask_MAKETABLE'                                             %INTER-TASK TABLE:  Configuration-trained
        %sequencelearning2_analyze('intertask_MAKETABLE');
        
        cd(behavDir);
        %vararginoptions(varargin,{'experiment_idx'});
        C=load('SL2_alldat.mat');
        %Make table for PRE-TEST and posttest (all trial types except 3 and seqCategory>0 excludes the practice trials):
        subs = [C.announce==0  & C.good~=0 & C.exclude==0 & C.trainGroup==2 & C.trialType~=3 & C.tDCS~=-1 & C.seqCategory>0];
        H=tapply(C,{'SN', 'chordReNum', 'test', 'day', 'seqCategory', 'hand', 'tDCS', 'trialType', 'trainGroup'},...
            {C.MTnew,'nanmean','name','MTnew'},...
            {C.Error,'nanmean','name','Error'},...
            {C.MT,'nanmean','name','MT'},...
            {C.seqError,'nanmean','name','seqError'},...
            'subset', subs);
        %For plotting in MATLAB:
        dsave('SL2_preposttest_ChordTR.dat',H);
        
        %Pre/Post-test Table with Phase:
        C.ptPhase=C.SN*0;
        C.ptPhase(C.day==5)  =  (C.BN(C.day==5)>14)+1;
        C.ptPhase(C.day==12) =  (C.BN(C.day==12)>22)+3;
        C.ptPhase(C.day==33) =  (C.BN(C.day==33)>30)+5;
        subs = [C.announce==0  & C.good~=0 & C.exclude==0 & C.trainGroup==2 & C.trialType~=3 & C.tDCS~=-1 & C.seqCategory>0];
        K=tapply(C,{'SN', 'ptPhase', 'chordReNum', 'test', 'day', 'seqCategory', 'hand', 'tDCS', 'trialType', 'trainGroup'},...
            {C.MTnew,'nanmean','name','MTnew'},...
            {C.Error,'nanmean','name','Error'},...
            {C.MT,'nanmean','name','MT'},...
            {C.seqError,'nanmean','name','seqError'},...
            'subset', subs);
        %For plotting in MATLAB:
        dsave('SL2_prehalfposttest_ChordTR.dat',K);
        
        %For generating ANOVAs of LH and RH diffs (to determine if valid to average over them):
        % Table for PRE-TEST and posttest (all trial types except 3 and seqCategory>0 excludes the practice trials)
        subs = [C.announce==0  & C.good~=0 & C.exclude==0 & C.trainGroup==2 & C.trialType~=3 & C.seqCategory>0 & C.tDCS~=-1 & C.day>4];
        M=tapply(C,{'SN', 'chordReNum', 'test', 'seqCategory', 'hand', 'tDCS', 'trainGroup'},...
            {C.MTnew,'nanmean','name','MTnew'},...
            {C.Error,'nanmean','name','Error'},...
            {C.MT,'nanmean','name','MT'},...
            {C.seqError,'nanmean','name','seqError'},...
            'subset', subs);  %
        dsave('SL2_preposttest_averaged_ChordTR.dat', M);

        %         %INPUT ARGUMENTS:
        %         fcn='nanmean';  %'nanmedian','nanvar', 'nanstd'
        %         %VARARGIN INDICES:
        %         vararginoptions(varargin,{'fcn'});
        %         %LOAD DATA:
        %         C=load('SL2_alldat.mat');
        %         %GENERATE TABLE:
        %         % Table for PRE-TEST and posttest (all trial types except 3 and seqCategory>0 excludes the practice trials)
        %         H=tapply(C,{'SN','chordReNum','test','day','seqCategory','hand','tDCS','trialType'},...
        %             {C.MTnew,'nanmean','name','MTnew'},...
        %             {C.Error,'nanmean','name','Error'},...
        %             {C.MT,'nanmean','name','MT'},...
        %             {C.seqError,'nanmean','name','seqError'},...
        %             'subset', C.announce==0 & C.good~=0 & C.exclude==0 & C.trainGroup==2 & C.trialType~=3 & C.tDCS~=-1 & C.seqCategory>0);
        %         %C.Error~=error{error_idx}
        %         %For plotting in MATLAB:
        %         dsave('SL2_preposttest_ChordTr.dat',H);
        %         %For generating ANOVAs of LH and RH diffs (to determine if valid to average over them):
        %         M=tapply(C,{'SN','chordReNum','test','seqCategory','hand','tDCS'},...
        %             {C.MTnew,'nanmean','name','MTnew'},...
        %             {C.Error,'nanmean','name','Error'},...
        %             {C.MT,'nanmean','name','MT'},...
        %             {C.seqError,'nanmean','name','seqError'},...
        %             'subset', [C.announce==0  & C.good~=0 & C.exclude==0 & C.trainGroup==2 & C.trialType~=3 & C.seqCategory>0 & C.tDCS~=-1 & C.day>4]);  %
        %         dsave('SL2_preposttest_averaged_ChordTr.dat', M);
        %         %K=pivottable([H.SN H.tDCS], [H.day H.hand], H.(variable), 'mean', 'datafilename', 'SL2_preposttest_ChordTrANOVA.dat');
    case 'intertask_MAKETABLE_DIFFSCORE'                                   %INTER-TASK TABLE:  Configuration-trained pre-post diff scores
        %sequencelearning2_analyze('intertask_MAKETABLE_DIFFSCORE');  
        cd(behavDir);
        D=dload('SL2_preposttest_ChordTr.dat');
        D1=getrow(D,D.day==1);
        D=getrow(D,D.day>1);
        for s=unique(D.SN)'
            for seq=unique(D.seqCategory)'
                for h=unique(D.hand)'
                    i1=find(D1.SN==s & D1.day==1 & D1.seqCategory==seq & D1.hand==h);
                    for day=[5 12 33]
                        i=find(D.SN==s & D.day==day & D.seqCategory==seq & D.hand==h);
                        D.MTnew_DIFF(i,1)      =  D1.MTnew(i1)     -  D.MTnew(i);  
                        D.Error_DIFF(i,1)      =  D1.Error(i1)     -  D.Error(i); 
                        D.MT_DIFF(i,1)         =  D1.MT(i1)        -  D.MT(i); 
                        D.seqError_DIFF(i,1)   =  D1.seqError(i1)  -  D.seqError(i); 
                        i';
                    end;
                end;
            end;
        end;
        %For plotting in Matlab:
        dsave('SL2_preposttest_diff_ChordTr.dat',D);
        E = dload('SL2_prehalfposttest_ChordTr.dat');
        E1 = getrow(E,E.ptPhase==0);
        E = getrow(E,E.ptPhase>0);
        for s = unique(E.SN)'
            for seq = unique(E.seqCategory)'
                for h = unique(E.hand)'
                    i1 = find(E1.SN==s & E1.ptPhase==0 & E1.seqCategory==seq & E1.hand==h);
                    for ptPhase = [1 2 3 4 5 6]
                        i = find(E.SN==s & E.ptPhase==ptPhase & E.seqCategory==seq & E.hand==h);
                        %Raw difference values:
                        E.MTnew_DIFF(i,1)         =  E1.MTnew(i1)       -    E.MTnew(i);
                        E.Error_DIFF(i,1)         =  E1.Error(i1)       -    E.Error(i);
                        E.MT_DIFF(i,1)            =  E1.MT(i1)          -    E.MT(i);
                        E.seqError_DIFF(i,1)      =  E1.seqError(i1)    -    E.seqError(i);
                        i';
                    end;
                end;
            end;
        end;
        %For plotting in Matlab:
        dsave('SL2_prehalfposttest_diff_ChordTr.dat',E);
    case 'intratask_MAKETABLE_ONOFF'                                       %INTRA-TASK TABLE:  Calculate online and offline learning for all variables
        %sequencelearning2_analyze('intratask_MAKETABLE_ONOFF');
        cd(behavDir);
        %DEFAULTS/VARGARIN:
        numblocks=4;
        vararginoptions(varargin,{'numblocks'});
        %LOAD DATA:
        D=dload('SL2_training.dat');
        T=[];
        E=[];
        U=[];
        for s=unique(D.SN)'  %Loop over each subj
            for day=unique(D.day)'
                DD=getrow(D,D.SN==s & D.day==day);
                S.SN=s;
                S.day=day;
                S.tDCS=DD.tDCS(1);
                S.seqReNum=DD.seqReNum(1);
                [r,b] = scatterplot(DD.BN,(DD.MTnew),'regression','linear');
                %[r,b]=scatterplot(DD.BN,(DD.MTnew/1000),'regression','linear');
                S.MTstartReg_MTnew   =  b(1)+min(DD.BN)*b(2);
                S.MTendReg_MTnew     =  b(1)+max(DD.BN)*b(2);
                S.MTstartBN_MTnew    =  mean(DD.MTnew(1:numblocks));
                S.MTendBN_MTnew      =  mean(DD.MTnew(end-numblocks+1:end));
                [r,c] = scatterplot(DD.BN,(DD.Error),'regression','linear');
                S.MTstartReg_Error   =  c(1)+min(DD.BN)*c(2);
                S.MTendReg_Error     =  c(1)+max(DD.BN)*c(2);
                S.MTstartBN_Error    =  mean(DD.Error(1:numblocks));
                S.MTendBN_Error      =  mean(DD.Error(end-numblocks+1:end));
                T=addstruct(T,S);
            end;
        end;
        T.onlineReg_MTnew  =  T.MTstartReg_MTnew-T.MTendReg_MTnew;
        T.offlineReg_MTnew =  T.onlineReg_MTnew*NaN;
        T.onlineBN_MTnew   =  T.MTstartBN_MTnew-T.MTendBN_MTnew;
        T.offlineBN_MTnew  =  T.onlineBN_MTnew*NaN;
        T.onlineReg_Error  =  T.MTstartReg_Error-T.MTendReg_Error;
        T.offlineReg_Error =  T.onlineReg_Error*NaN;
        T.onlineBN_Error   =  T.MTstartBN_Error-T.MTendBN_Error;
        T.offlineBN_Error  =  T.onlineBN_Error*NaN;
        for day=1:3
            i=find(T.day==day);
            j=find(T.day==day+1);
            T.offlineReg_MTnew(i,1)  = T.MTendReg_MTnew(i)-T.MTstartReg_MTnew(j);
            T.offlineBN_MTnew(i,1)   = T.MTendBN_MTnew(i)-T.MTstartBN_MTnew(j);
            T.offlineReg_Error(i,1)  = T.MTendReg_Error(i)-T.MTstartReg_Error(j);
            T.offlineBN_Error(i,1)   = T.MTendBN_Error(i)-T.MTstartBN_Error(j);
        end;
        varargout={T};
        dsave('SL2_ONOFFTOT_allVar.dat',T);
       
    case 'intratask_Figure'                                                %FIGURE 5C,D:  Generates learning plots with pre/post tests
        %sequencelearning2_analyze('intratask_Figure');
        %sequencelearning2_analyze('intratask_Figure', 'variable', 'Error');
        cd(behavDir);
        %VARARGIN:
        colorset={[0 0  1],[1 0 0]};  
        legend1={'Sham-Train','Anodal-Train','Sham-Test', 'Anodal-Test'};
        variable='MTnew';
        sn=[1:54];
        vararginoptions(varargin,{'colour_set','variable', 'sn'});
        %LOAD DATA:
        K=dload('SL2_training.dat');
        L=getrow(K,  isincluded(sn,K.SN) );
        C=dload('SL2_preposttest.dat');
        D=getrow(C,  isincluded(sn,C.SN) );
        %CONJOIN INTO SINGLE STRUC:
        CAT.linewidth=2;
        CAT.linecolor={colorset{:},colorset{:}};
        CAT.markercolor={colorset{:},colorset{:}};
        CAT.markerfill={colorset{:},[1 1 1],[1 1 1]};
        CAT.markertype={'o','o','^','^'};
        CAT.errorcolor={[0 0 1],[1 0 0],[0 0 1],[1 0 0]};
        CAT.errorwidth=2; %causes black boxes!
        CAT.errorcap=0;
        CAT.markersize=5;
        CAT.linestyle={'-','-',':',':'};
        CATLearn.linewidth=2;
        CATLearn.linecolor=colorset;
        CATLearn.markercolor=colorset;
        CATLearn.markerfill=colorset;
        if (strcmp(variable,'MTnew')) || (strcmp(variable,'MT')) || (strcmp(variable,'Error'))
            L.(variable)=L.(variable);
            D.(variable)=D.(variable);
        elseif (strcmp(variable,'seqError'))
            L.(variable)=L.(variable)>0;
            D.(variable)=D.(variable)>0;
        end;
        % ****************TRAINING:  Days 1,2,3,4****************
        [x,y2]=lineplot([L.day L.BN],L.(variable),'split',L.tDCS, 'CAT', CATLearn,'style_shade','gap',[1.3 0.5]); %colour_pick_train {colour_pick_train_idx}
        hold on;
        % ****************PRE-TEST:  Day 1****************
        [x,y1]=lineplot([D.tDCS*1.2+(D.seqCategory)/3]*2-5, D.(variable),'subset',[D.day==1 & D.hand==1],'split',[D.seqCategory,D.tDCS],'CAT', CAT);
        ylabel(variable);
        % ****************POST-TEST A:  Day 5-33****************
        [x,y3]=lineplot([D.day]/1.5+51,D.(variable),'subset',[D.day>1 & D.hand==1],'split',[D.seqCategory,D.tDCS],'CAT',CAT,'leg', legend1, 'leglocation', 'north');  % 'leg', {'Cathodal-Train', 'Sham-Train','Anodal-Train', 'Cathodal-Test', 'Sham-Test', 'Anodal-Test'});
        title('Post-Tests');
        hold off;
        set(gca,'XLim',[-8 77],'XTick',[]);
        if (strcmp(variable,'MT'))
            set(gca,'YLim',[0.50 3.5]);
        elseif (strcmp(variable,'MTnew'))
            set(gca,'YLim',[0.50 3.5]);
        elseif (strcmp(variable,'Error'))
            set(gca,'YLim',[0.00 0.40]);
        elseif (strcmp(variable,'seqError'))
            set(gca,'YLim',[0.05 0.50]);
        end;
        %Set paper position, give little extra space to Pre-Test column:
        set(gcf,'PaperPosition',  [4 4 15.24 8]);%[4 4 6 4]); %[4 4 15.24 8.89]);    % Win7 [4 4 15.24 8.89] %MAC [4 4 6 3.5]
        wysiwyg;
    case 'intratask_Figure_STATS_ONOFF'                                    %FIGURE 5E,F (+STATS)   Generate barplots + statistics
        %sequencelearning2_analyze('intratask_Figure_STATS_ONOFF'); %MTnew
        %sequencelearning2_analyze('intratask_Figure_STATS_ONOFF', 'variable', 'Error', 'analysisType','reg','onReg','onlineReg_Error','offReg','offlineReg_Error','onBN','onlineBN_Error','offBN','offlineBN_Error'); %Error, reg

        cd(behavDir);
        %DEFAULTS/VARARGIN:
        colorset = {[0 0  1],[1 0 0]};  %blue, red
        legend1 = {'Sham','Anodal'};
        variable='MTnew';
        analysisType='reg'; % or bn
        onReg = 'onlineReg_MTnew';
        offReg= 'offlineReg_MTnew';
        onBN  = 'onlineBN_MTnew';
        offBN = 'offlineBN_MTnew';
        vararginoptions(varargin,{'colorset','variable','analysisType','onReg','offReg','onBN','offBN'});
        
        %CONJOIN:
        CAT.facecolor={colorset{:}};
        CAT.errorcolor={colorset{:}};
        CAT.errorwidth=2;
        CAT.errorcap=0;
        
        %LOAD DATA:
        D=dload('SL2_ONOFFTOT_allVar.dat');
        
        %TABLE:
        T1=tapply(D,{'SN','tDCS'},...
            {D.(onReg),'nansum','name','reg'},...
            {D.(onBN),'nansum','name','bn'});
        T2=tapply(D,{'SN','tDCS'},...
            {D.(offReg),'nansum','name','reg'},...
            {D.(offBN),'nansum','name','bn'});
        T1.onoff=ones(length(T1.SN),1)*1;
        T2.onoff=ones(length(T2.SN),1)*2;  % Offline
        T=addstruct(T1,T2);
        
        %PLOT:
        barplot([T.onoff], T.(analysisType), 'split',[T.tDCS], 'CAT', CAT,'leg', legend1, 'leglocation', 'northeast');   
        if (strcmp(variable,'MTnew'))
            set(gca,'YLim',[-0.5 1.5]);
        elseif (strcmp(variable,'Error'))
            set(gca,'YLim',[-0.20 0.15]);
        end;
        %SET PAPER POSITION:
        set(gcf,'PaperPosition',[4 4 8 8]);
        wysiwyg;
        
        %STATS:
        fprintf('\nOnline Learning\n');
        ttestDirect(T.(analysisType),[T.tDCS T.SN],2,'independent','subset',T.onoff==1);
        fprintf('\nOffline Learning\n');
        ttestDirect(T.(analysisType),[T.tDCS T.SN],2,'independent','subset',T.onoff==2);
        
        %SAVE:
        if (strcmp(variable,'MTnew'))
            dsave('SL2_ONOFF_TOT_MTnew.dat',T);
        elseif (strcmp(variable,'RT'))
            dsave('SL2_ONOFF_TOT_Error.dat',T);
        end;
        %dsave('SL2_ONOFF_TOT_tempfile.dat',T);   %just use this as a temp file (re-write every time)
        
        varargout={T};
    case 'intermanual_BARPLOT'                                             %FIGURE 3A,B,C:  The pre-post diff with the LH and RH for the 2 groups %make legend in AI:  hand x tDCS group (LH RH on top across and tDCS group down)
        %sequencelearning2_analyze('intermanual_BARPLOT'); %MTnew_DIFF
        %sequencelearning2_analyze('intermanual_BARPLOT', 'variable', 'Error_DIFF'); %Error_DIFF
        cd(behavDir);
        %Defaults/Varargin:
        colorset = {[0 0 1],[1 0 0]}; % CHANGE THE RH COLOURS IN AI MANUALLY %colorset={[0.22 0.02 0.45],[0.62 0.02 0.03], [0.22 0.02 0.45],[0.62 0.02 0.03],   [0.67 0.67 1.0],[1.0 0.63 0.48],  [0.67 0.67 1.0],[1.0 0.63 0.48]};
        variable = 'MTnew_DIFF';  %You can also plot the adjusted values
        legend1  = {'Sham-LH','tDCS-LH','Sham-RH','tDCS-RH'};
        sn       = [1:54];
        postdays = [5]; %For both drawlines and plotted data
        tDCS     = [0 1];   %For drawlines only 
        drawWhat = [1];
        vararginoptions(varargin,{'colour_set', 'variable', 'sn', 'postdays', 'tDCS', 'drawWhat'});
        %LOAD DATA:
        %Load pre-post trained data:
        C=dload('SL2_preposttest_diff.dat');
        D=getrow(C,  isincluded(sn,C.SN) & isincluded(postdays, C.day) );
        %Load pre-post non-trained data:
        T=dload('SL2_preposttest_diff_ChordTr.dat');  %This is only for drawlines
        U=getrow(T,  isincluded(sn,T.SN) & isincluded(postdays, T.day) & isincluded(tDCS, T.tDCS));
        %Conjoin into single strux:
        CAT.facecolor=colorset;
        CAT.errorcolor=colorset;
        CAT.errorwidth=2;
        CAT.errorcap=0;
        %GENERATE barplot of differences Divided by hand:
        barplot([D.hand], D.(variable), 'split',[D.seqCategory  D.tDCS],...
            'gapwidth',[0.7 0.2 0],'CAT', CAT,'leg', legend1, 'leglocation', 'north');
        %%Divided by seq Cat (original):
        %barplot([D.seqCategory], D.(variable), 'split',[D.hand  D.tDCS],'gapwidth',[0.7 0.2 0],'CAT', CAT,'leg', legend1, 'leglocation', 'north');
        %if (strcmp(variable,'MTnew_DIFF')) || (strcmp(variable,'RT_DIFF ')) || (strcmp(variable,'meanDevR_DIFF '))
        if drawWhat==1
            drawline(mean (U.(variable)(U.hand==1 & U.tDCS==0)), 'dir','horz', 'color',[0.1 0.1 0.1], 'linewidth', 1, 'linestyle', '--'); %dark blue LEFT HAND
            drawline(mean (U.(variable)(U.hand==2 & U.tDCS==0)), 'dir','horz', 'color',[0.5 0.5 0.5], 'linewidth', 1, 'linestyle', '--');  %light blue RIGHT HAND
        elseif drawWhat==2
            %These values are AVERAGED ACROSS TDCS GROUP.
            drawline(mean (U.(variable)(U.hand==1)), 'dir','horz', 'color',[0.1 0.1 0.1], 'linewidth', 3, 'linestyle', '-'); %Black  LEFT HAND
            drawline(mean (U.(variable)(U.hand==2)), 'dir','horz', 'color',[0.5 0.5 0.5], 'linewidth', 3, 'linestyle', '-'); %Grey  %RIGHT HAND
            %If you want just the sham, use these:
            drawline(mean (U.(variable)(U.hand==1 & U.tDCS==0)), 'dir','horz', 'color',[0.22 0.02 0.45], 'linewidth', 1, 'linestyle', '--'); %dark blue LEFT HAND
            drawline(mean (U.(variable)(U.hand==2 & U.tDCS==0)), 'dir','horz', 'color',[0.67 0.67 1.0], 'linewidth', 1, 'linestyle', '--');  %light blue RIGHT HAND
            %If you want just the tDCS, use these:
            drawline(mean (U.(variable)(U.hand==1 & U.tDCS==1)), 'dir','horz', 'color',[0.62 0.02 0.03], 'linewidth', 1, 'linestyle', '--'); %dark red LEFT HAND
            drawline(mean (U.(variable)(U.hand==2 & U.tDCS==1)), 'dir','horz', 'color',[1.0 0.63 0.48], 'linewidth', 1, 'linestyle', '--');  %light red RIGHT HAND
        end;
         %Show mean and SD of no train group (sham only):
         fprintf('Means and SE of No train group improvement from baseline\n');
         MeanL =mean (U.(variable)(U.hand==1 & U.tDCS==0))
         SEL = (std (U.(variable)(U.hand==1 & U.tDCS==0))) / (sqrt(12))
         MeanR =mean (U.(variable)(U.hand==2 & U.tDCS==0))
         SER = (std (U.(variable)(U.hand==2 & U.tDCS==0))) / (sqrt(12))
        ylabel(variable);
        set(gca,'XTickLabel',{'sLT', 'tLT', 'sLU', 'tLU', 'sRT', 'tRT', 'sRU', 'tRU'});
    case 'intermanual_CATCHUP'                                             %FIGURE3D,E,F:  Plot learning across the 3 post-tests
        %sequencelearning2_analyze('intermanual_CATCHUP', 'variable', 'MTnew', 'filename', 'SL2_prehalfposttest_all.dat', 'plotType', 12);
        %sequencelearning2_analyze('intermanual_CATCHUP', 'variable', 'MTnew', 'filename', 'SL2_prehalfposttest_all.dat', 'plotType', 13);

        %Filenames:
        %PT1='SL2_preposttest.dat' /_diff     PT2-5='SL2_prehalfposttest.dat'/_diff,      PT6-8='SL2_prehalfposttest_seqTr.dat'/_diff,     PT9-11='SL2_prehalfposttest_all.dat'/_diff
        
        cd(behavDir);
        
        %DEFAULTS/VARARGIN:
        colorset={ [0 0 1], [0.67 0.67 1.0], [1 0 0], [1.0 0.63 0.48]};    %colorset={ [0.22 0.02 0.45], [0.67 0.67 1.0], [0.62 0.02 0.03], [1.0 0.63 0.48]};
        variable='MTnew';                                                  %Select variable
        filename='SL2_preposttest.dat';                                    %Select file to load
        sn=[1:54];                                                         %Select subj
        plotType=[12];                                                     %Select figure type
        legend1={'Sham-LH', 'Anodal-LH', 'Sham-RH', 'Anodal-RH'};
        vararginoptions(varargin,{'colour_set','variable','filename','sn','plotType'});
        C=dload(filename);
        D=getrow(C,  isincluded(sn,C.SN) );
        %DEFAULT CAT (rewrite if changes needed)
        CAT.linewidth=2;
        CAT.linecolor={colorset{:}};
        CAT.markercolor={colorset{:}};
        CAT.markerfill={colorset{:},[1 1 1],[1 1 1]};
        CAT.markertype={'o','o','o','o'};
        CAT.errorcolor={colorset{:}};
        CAT.errorwidth=2;
        CAT.errorcap=0;
        CAT.markersize=5;
        CAT.linestyle={'-','-','-','-'};
        CATLearn.linewidth=2;
        CATLearn.linecolor=colorset; %{colorset{:}};
        CATLearn.markercolor=colorset;
        CATLearn.markerfill=colorset;
        if plotType==12                                                    %Combined seq-trained and non-seq-trained (i.e. sequence-trained-->sham only!!!) groups on one plot (trained only)
            colorset={ [0 0 1], [0.1 0.1 0.1],   [0.67 0.67 1.0], [0.5 0.5 0.5],     [1 0 0],   [1.0 0.63 0.48]};
            D.tDCS(D.trainGroup==2 & D.tDCS==1)=2;                         %Relabel the sham tDCS no train group as 2 so you can remove it from the analysis.
            D.seqCategory(D.trainGroup==2)=1;                              %Make all seqCategory equal to 1 for the sequence-trained group
            CAT.linecolor={colorset{:}};
            CAT.markercolor={colorset{:}};
            CAT.markerfill={colorset{:},[1 1 1],[1 1 1]};
            CAT.errorcolor={colorset{:}};
            CAT.linestyle={'-','--','-','--','-','-'};
            CATLearn.linecolor={colorset{:}};
            CATLearn.markercolor={colorset{:}};
            %TABLE1:  Table for PRE-TEST and posttest (all trial types except 3 and seqCategory>0 excludes the practice trials)
            %Get means for the 6 bins:
            subs = [D.day>1 & D.seqCategory==1 & D.tDCS~=2];
            E=tapply(D,{'SN', 'test', 'day', 'ptPhase', 'hand', 'tDCS', 'trainGroup'},...
                {D.(variable),'mean','name',variable},...
                'subset', subs);
            lineplot(E.ptPhase, E.(variable), 'split', [E.tDCS E.hand E.trainGroup], 'CAT', CAT); %'style_shade',CATLearn
            ylabel(variable);
            set(gca,'XTickLabel',{'D5A', 'D5B', 'D12A', 'D12B', 'D33A', 'D33B'},'XLim',[0.5 6.5]);
            fprintf(variable);

            fprintf('\n ANOVA across sham, tDCS, and no train (no train is only sham)\n');
            [~,~,E.allGroup]=unique([E.tDCS E.trainGroup],'rows');
            anovaMixed(E.(variable), E.SN, 'within',[E.hand E.ptPhase], {'hand','ptPhase'}, 'between', E.allGroup,{'group'});
            %anovaMixed(E.(variable),E.SN,'within',[E.hand E.ptPhase],{'hand','ptPhase'}, 'between',[E.tDCS E.trainGroup],{'tDCS', 'trainGroup'});
            varargout={E};
            
            fprintf('\n Sham vs. No train ANOVA \n');
            subs = [E.tDCS~=1];
            F=tapply(E,{'SN', 'test', 'day', 'ptPhase', 'hand', 'tDCS', 'trainGroup'},...
                {E.(variable),'mean','name',variable},...
                'subset', subs);
            anovaMixed(F.(variable), F.SN, 'within',[F.hand F.ptPhase], {'hand','ptPhase'}, 'between', F.trainGroup,{'trainGroup'});
            
            fprintf('\n Catchup ttests B\n');
            subs = [F.day==5];
            %average across phase (already excluded the tDCS group).
            G=tapply(F,{'SN', 'hand', 'trainGroup'},...
                {F.(variable),'mean','name',variable},...
                'subset', subs);
            fprintf('\n Sham vs. No train:  day 5 only, both hands\n');
            i1=find(G.trainGroup==1);
            i2=find(G.trainGroup==2);
            ttest(G.(variable)(i1),G.(variable)(i2),2,'independent');
            fprintf('\n Sham vs. No train:  day 5 only, left hand\n');
            i1=find(G.trainGroup==1 & G.hand==1);
            i2=find( G.trainGroup==2 & G.hand==1);
            ttest(G.(variable)(i1),G.(variable)(i2),2,'independent');
            fprintf('\n Sham vs. No train:  day 5 only, right hand\n');
            i1=find(G.trainGroup==1 & G.hand==2);
            i2=find(G.trainGroup==2 & G.hand==2);
            ttest(G.(variable)(i1),G.(variable)(i2),2,'independent');
        elseif plotType==13                                                 %Combined seq-trained and non-seq-trained (i.e. sequence-trained-->aham only!!!) groups on one plot (trained only)
            colorset={ [0 0 1], [0.1 0.1 0.1],   [0.67 0.67 1.0], [0.5 0.5 0.5],     [1 0 0],   [1.0 0.63 0.48]};
            D.tDCS(D.trainGroup==2 & D.tDCS==1)=2;                         %Relabel the sham tDCS no train group as 2 so you can remove it from the analysis.
            D.seqCategory(D.trainGroup==2)=2;                            %Make all seqCategory equal to 2 for the sequence-trained group
            CAT.linecolor={colorset{:}};
            CAT.markercolor={colorset{:}};
            CAT.markerfill={colorset{:},[1 1 1],[1 1 1]};
            CAT.errorcolor={colorset{:}};
            CAT.linestyle={'--','--','--','--'};
            CATLearn.linecolor={colorset{:}};
            CATLearn.markercolor={colorset{:}};
            CATLearn.markerfill={colorset{:}};
            
            %TABLE1:  Table for PRE-TEST and posttest (all trial types except 3 and seqCategory>0 excludes the practice trials)
            %Get means for the 6 bins:
            subs = [D.day>1 & D.seqCategory==2 & D.tDCS~=2];
            E=tapply(D,{'SN', 'test', 'day', 'ptPhase', 'hand', 'tDCS', 'trainGroup'},...
                {D.(variable),'mean','name',variable},...
                'subset', subs);
            %D.tDCS(D.tDCS==1 & D.trainGroup==2)=0;
            lineplot(E.ptPhase, E.(variable), 'split', [E.tDCS E.hand E.trainGroup], 'CAT', CAT); %'style_shade',CATLearn
            ylabel(variable);
            set(gca,'XTickLabel',{'D5A', 'D5B', 'D12A', 'D12B', 'D33A', 'D33B'});
            fprintf(variable);
            
            fprintf('\n ANOVA across sham, tDCS, and no train (no train is only sham)\n');
            [~,~,E.allGroup]=unique([E.tDCS E.trainGroup],'rows');
            anovaMixed(E.(variable), E.SN, 'within',[E.hand E.ptPhase], {'hand','ptPhase'}, 'between', E.allGroup,{'group'});
            %anovaMixed(E.(variable),E.SN,'within',[E.hand E.ptPhase],{'hand','ptPhase'}, 'between',[E.tDCS E.trainGroup],{'tDCS', 'trainGroup'});
            varargout={E};
            
            fprintf('\n Sham vs. No train ANOVA \n');
            subs = [E.tDCS~=1];
            F=tapply(E,{'SN', 'test', 'day', 'ptPhase', 'hand', 'tDCS', 'trainGroup'},...
                {E.(variable),'mean','name',variable},...
                'subset', subs);
            anovaMixed(F.(variable), F.SN, 'within',[F.hand F.ptPhase], {'hand','ptPhase'}, 'between', F.trainGroup,{'trainGroup'});
            
            fprintf('\n Catchup ttests B\n');
            subs = [F.day==5];
            %average across phase (already excluded the tDCS group).
            G=tapply(F,{'SN', 'hand', 'trainGroup'},...
                {F.(variable),'mean','name',variable},...
                'subset', subs);
            fprintf('\n Sham vs. No train:  day 5 only, both hands\n');
            i1=find(G.trainGroup==1);
            i2=find(G.trainGroup==2);
            ttest(G.(variable)(i1),G.(variable)(i2),2,'independent');
            fprintf('\n Sham vs. No train:  day 5 only, left hand\n');
            i1=find(G.trainGroup==1 & G.hand==1);
            i2=find( G.trainGroup==2 & G.hand==1);
            ttest(G.(variable)(i1),G.(variable)(i2),2,'independent');
            fprintf('\n Sham vs. No train:  day 5 only, right hand\n');
            i1=find(G.trainGroup==1 & G.hand==2);
            i2=find(G.trainGroup==2 & G.hand==2);
            ttest(G.(variable)(i1),G.(variable)(i2),2,'independent'); 
        end;
    case 'intermanual_Figure_original'                                     %Make FIGURE 3:  Original (with both trained and untrained configurations and non-trained data)
        %sequencelearning2_analyze('intermanual_Figure_original');
        subplot(3,3,1);
        sequencelearning2_analyze('intermanual_BARPLOT', 'variable','MTnew_DIFF');
        subplot(3,3,2);
        sequencelearning2_analyze('intermanual_BARPLOT', 'variable','Error_DIFF');
        subplot(3,3,3);  %Blank but needed to keep windows same size as configuration task
        subplot(3,3,4);
        sequencelearning2_analyze('intermanual_CATCHUP', 'variable', 'MTnew', 'filename', 'SL2_prehalfposttest_all.dat', 'plotType', 12);
        subplot(3,3,5);
        sequencelearning2_analyze('intermanual_CATCHUP', 'variable', 'Error','filename', 'SL2_prehalfposttest_all.dat', 'plotType', 12);
        subplot(3,3,6);  %Blank but needed to keep windows same size as configuration task
        subplot(3,3,7);
        sequencelearning2_analyze('intermanual_CATCHUP', 'variable', 'MTnew', 'filename', 'SL2_prehalfposttest_all.dat', 'plotType', 13);
        subplot(3,3,8);
        sequencelearning2_analyze('intermanual_CATCHUP', 'variable', 'Error', 'filename', 'SL2_prehalfposttest_all.dat', 'plotType', 13);
        subplot(3,3,9);  %Blank but needed to keep windows same size as configuration task
        set(gcf,'PaperPosition', [2 2 20 15]);     %MAC [2 2 5 4](mult 2.54 to get Win) %[2 2 12.7 10.16] original
        wysiwyg;
    case 'intermanual_Figure'                                              %TODO-FIX POSITION:  Make FIGURE 3:  Original (with both trained and untrained configurations and non-trained data)
        %sequencelearning2_analyze('intermanual_Figure');
        subplot(2,3,1);
        sequencelearning2_analyze('intermanual_BARPLOT', 'variable','MTnew_DIFF');
        %set(gca,'Position',[0.132 0.58 0.331 0.45]);
        subplot(2,3,2);
        sequencelearning2_analyze('intermanual_BARPLOT', 'variable','Error_DIFF');
        subplot(2,3,3); %Blank but needed to keep windows same size as configuration task
        subplot(2,3,4);
        sequencelearning2_analyze('intermanual_CATCHUP', 'variable', 'MTnew', 'filename', 'SL2_prehalfposttest_all.dat', 'plotType', 12);
        subplot(2,3,5);
        sequencelearning2_analyze('intermanual_CATCHUP', 'variable', 'Error','filename', 'SL2_prehalfposttest_all.dat', 'plotType', 12);
        set(gca,'YLim',[0 .25]); 
        subplot(2,3,6);%Blank but needed to keep windows same size as configuration task
       
        set(gcf,'PaperPosition', [2 2 20 15]/2.54);
        %MAC [2 2 5 4](mult 2.54 to get Win) %[2 2 12.7 10.16] original
        wysiwyg;

        % Get aspect ratio right 
        for i=1:3 
            subplot(2,3,i); 
            a=get(gca,'Position'); 
            a(2)=a(2)+0.06;  % y=pos
            a(4)=a(4)-0.06;  % Height 
            set(gca,'Position',a);
        end; 
        for i=4:6 
            subplot(2,3,i); 
            a=get(gca,'Position'); 
            a(4)=a(4)+0.07;  % Height 
            set(gca,'Position',a);
        end; 
    case 'intertask_FigureSupp'                                            %FIGURE FOR REVIEWERS:  Lineplot of inter-task transfer of sequence training benefits to configuration performance
        %sequencelearning2_analyze('intertask_FigureSupp');
        cd(behavDir);
        %DEFAULTS:
        variable='MTnew';
        legend1={'Sham','Anodal'};
        sn=[1:54];
        vararginoptions(varargin,{'colour_set','variable', 'sn'});
        C=dload('SL2_preposttest_ChordTr.dat');
        D=getrow(C,  isincluded(sn,C.SN) );
        colorset={[0.67 0.67 1.0],[0.22 0.02 0.45],[1.0 0.63 0.48],[0.62 0.02 0.03]};
        %CONJOIN INTO SINGLE STRUC:
        CAT.linewidth=2;
        CAT.linecolor={colorset{:}};
        CAT.markercolor={colorset{:}};
        CAT.markerfill={colorset{:},[1 1 1],[1 1 1]};
        CAT.markertype={'o','o','o','o'};
        CAT.errorcolor={colorset{:}};
        CAT.errorwidth=2;
        CAT.errorcap=0;
        CAT.markersize=5;
        CAT.linestyle={'-','-','-','-'};
        CATLearn.linewidth=2;
        CATLearn.linecolor=colorset;
        CATLearn.markercolor=colorset;
        CATLearn.markerfill=colorset;
        %GENERATE LINPLOT:
        lineplot([D.day>2 D.day],D.(variable), 'split',[D.tDCS D.hand],'CAT',CAT,'leg', legend1, 'leglocation', 'northeast');
        ylabel(variable);
        set(gca,'XTick',[1 2 2.7 3.4]);
        set(gca,'XLim',[-0.1 4]);
        set(gca,'XTickLabel',{'D1', 'D5', 'D12', 'D33'});
        set(gca,'YLim',[1.1 3.9]);
        %         if (strcmp(variable,'MTnew'))
        %             set(gca,'YLim',[0.55 3.9]);
        %         elseif (strcmp(variable,'meanDevR'))
        %             set(gca,'YLim',[0.12 0.38]);
        %         elseif (strcmp(variable,'RT'))
        %             set(gca,'YLim',[0.3 1.1]);
        %         end;
        set(gcf,'PaperPosition',[2 2 6.35 10.16]);  %[2 2 2.5 4] MAC
        wysiwyg;

    case 'ANOVA_baseline'                                                  %STATS:  Table 1 stats:  Are there any significant differences at baseline across ALL GROUPS
        %sequencelearning2_analyze('ANOVA_baseline');
        %sequencelearning2_analyze('ANOVA_baseline', 'variable', 'Error');
        
        cd(behavDir);
        U=dload('SL2_preposttest_all.dat');
        
        variable='MTnew';            %Select variable.
        seqCat     =   [1 2];      %1=trained, 2=untrained (probably don't need this since you will always want this as a between facto
        vararginoptions(varargin,{'variable', 'seqCat'});
        
        T=getrow(U, isincluded(seqCat, U.seqCategory) & U.day==1 & U.trainGroup==2);
        fprintf('\n========================================================\n');
        fprintf('\n SEQUENCE-TRAINED SHAM VS. TDCS\n');
        S = tapply(T,{'SN','tDCS','seqCategory','hand'},...
            {variable,'mean','name', variable});
        fprintf('\n ANOVA across days, hand-trained groups, and tDCS groups\n');
        anovaMixed(S.(variable), S.SN, 'between',S.tDCS,{'tDCS'},  'within',  [S.seqCategory S.hand], {'seqCategory' 'hand'});
        anovaMixed(S.(variable), S.SN, 'between',[S.tDCS],{'tDCS'});
        
        R = tapply(S,{'SN','tDCS'},...
            {variable,'mean','name', variable});
        %T-test day 1:
        fprintf('\n TRAINED ONLY:  sham vs. tDCS\n');
        i1=find(R.tDCS==0);
        i2=find(R.tDCS==1);
        ttest(R.(variable)(i1),R.(variable)(i2),2,'independent');

        fprintf('\n========================================================\n');
        T=getrow(U, isincluded(seqCat, U.seqCategory) & U.day==1 & U.tDCS==0);
        fprintf('\n SEQUENCE-TRAINED SHAM VS. NON-TRAINED (i.e. sequence-trained)\n');
        S = tapply(T,{'SN','trainGroup','hand'},...
            {variable,'mean','name', variable});
        fprintf('\n ANOVA across days, hand-trained groups, and tDCS groups\n');
        anovaMixed(S.(variable), S.SN, 'between',S.trainGroup,{'trainGroup'},  'within',  [S.hand], {'hand'});
        anovaMixed(S.(variable), S.SN, 'between',[S.trainGroup],{'trainGroup'});
        
        R = tapply(S,{'SN','trainGroup'},...
            {variable,'mean','name', variable});
        %T-test day 1:
        fprintf('\n SHAM ONLY:  Trained vs. untrained\n');
        i1=find(R.trainGroup==1);
        i2=find(R.trainGroup==2);
        ttest(R.(variable)(i1),R.(variable)(i2),2,'independent');

         fprintf('\n========================================================\n');
        T=getrow(U, isincluded(seqCat, U.seqCategory) & U.day==1 & U.trainGroup==1);
        fprintf('\n SEQUENCE-TRAINED SHAM VS. TDCS\n');
        S = tapply(T,{'SN','tDCS','hand'},...
            {variable,'mean','name', variable});
        fprintf('\n ANOVA across days, hand-trained groups, and tDCS groups\n');
        anovaMixed(S.(variable), S.SN, 'between',S.tDCS,{'tDCS'},  'within',  [S.hand], { 'hand'});
        anovaMixed(S.(variable), S.SN, 'between',[S.tDCS],{'tDCS'});
        %T-test day 1:
        R = tapply(S,{'SN','tDCS'},...
            {variable,'mean','name', variable});
        %T-test day 1:
        fprintf('\n TRAINED ONLY:  sham vs. tDCS\n');
        i1=find(R.tDCS==0);
        i2=find(R.tDCS==1);
        ttest(R.(variable)(i1),R.(variable)(i2),2,'independent');
        
        fprintf('\n========================================================\n');
        T=getrow(U, isincluded(seqCat, U.seqCategory) & U.day==1);
        fprintf('\n ALL:  SEQUENCE-TRAINED SHAM VS. TDCS VS. NON-TRAINED SHAM VS. TDCS \n');
        S = tapply(T,{'SN','trainGroup', 'hand', 'tDCS'},...
            {variable,'mean','name', variable});
        fprintf('\n ANOVA across days, hand-trained groups, and tDCS groups\n');
        anovaMixed(S.(variable), S.SN, 'between', [S.trainGroup S.tDCS], {'trainGroup' 'tDCS'},  'within',  [S.hand], {'hand'});
        anovaMixed(S.(variable), S.SN, 'between',[S.trainGroup],{'trainGroup'});
        
        R = tapply(S,{'SN','trainGroup', 'tDCS'},...
            {variable,'mean','name', variable});
       
         fprintf('\n========================================================\n');
        fprintf('\n CONFIGURATION-TRAINED:  sham vs. tDCS \n');
        i1=find(R.trainGroup==2 & R.tDCS==0);
        i2=find(R.trainGroup==2 & R.tDCS==1);
        ttest(R.(variable)(i1),R.(variable)(i2),2,'independent');
        fprintf('\n SEQUENCE-TRAINED:  sham vs. tDCS\n');
        i1=find(R.trainGroup==1 & R.tDCS==0);
        i2=find(R.trainGroup==1 & R.tDCS==1);
        ttest(R.(variable)(i1),R.(variable)(i2),2,'independent');
        fprintf('\n TRAINED vs. UNTRAINED:  sham \n');
        i1=find(R.trainGroup==1 & R.tDCS==0);
        i2=find(R.trainGroup==2 & R.tDCS==0);
        ttest(R.(variable)(i1),R.(variable)(i2),2,'independent');
        fprintf('\n TRAINED vs. UNTRAINED:  tDCS \n');
        i1=find(R.trainGroup==1 & R.tDCS==1);
        i2=find(R.trainGroup==2 & R.tDCS==1);
        ttest(R.(variable)(i1),R.(variable)(i2),2,'independent');

         fprintf('\n========================================================\n');
        U.tDCS(U.trainGroup==2 & U.tDCS==1)=2;
        T=getrow(U, isincluded(seqCat, U.seqCategory) & U.day==1);
        fprintf('\n SEQUENCE-TRAINED SHAM VS. TDCS VS. NON-TRAINED \n');
        S = tapply(T,{'SN','trainGroup', 'hand', 'tDCS'},...
            {variable,'mean','name', variable, 'subset', T.tDCS~=2});
        fprintf('\n ANOVA across days, hand-trained groups, and tDCS groups\n');
        %anovaMixed(O.(variable), O.SN, 'between', [O.trainGroup O.tDCS], {'trainGroup' 'tDCS'},  'within',  [O.hand], {'hand'});
        anovaMixed(S.(variable), S.SN, 'between',[S.trainGroup],{'trainGroup'},  'within',  [S.hand], {'hand'});
        
        fprintf('\n========================================================\n');
        U.tDCS(U.trainGroup==2 & U.tDCS==2)=1;  %Switch tDCS group of untrained back
        T=getrow(U, isincluded(seqCat, U.seqCategory) & U.day==1);
        fprintf('\n SEQUENCE-TRAINED SHAM VS. TDCS VS. NON-TRAINED \n');
        S = tapply(T,{'SN','trainGroup', 'hand', 'tDCS'},...
            {variable,'mean','name', variable});
        fprintf('\n ANOVA across days, hand-trained groups, and tDCS groups and hand\n');
        anovaMixed(S.(variable), S.SN, 'between', [S.trainGroup S.tDCS], {'trainGroup' 'tDCS'},  'within',  [S.hand], {'hand'});
        fprintf('\n ANOVA across days, hand-trained groups, and tDCS groups\n');
        R = tapply(S,{'SN','trainGroup','tDCS'},...
            {variable,'mean','name', variable});
        anovaMixed(R.(variable), R.SN, 'between', [R.trainGroup R.tDCS], {'trainGroup' 'tDCS'});
    case 'ANOVA_learn'                                                     %STATS: LH Training ANOVA (for data Fig 2D,E,F)
        %sequencelearning2_analyze('ANOVA_learn'); %MTnew
        %sequencelearning2_analyze('ANOVA_learn', 'variable', 'Error'); %Error
        
        cd(behavDir);
        T=dload('SL2_training.dat');
        variable='MTnew';
        vararginoptions(varargin,{'variable'});
        
        % Day x tDCS interaction
        fprintf('2 (groups) x 4 (days) ANOVA\n');
        S=tapply(T,{'SN','tDCS','day'},{variable,'mean','name',variable});
        anovaMixed(S.(variable),S.SN,'within',[S.day],{'day'},'between',S.tDCS,{'tDCS'});
        subplot(2,1,1);
        lineplot(S.day,S.(variable),'style_thickline','split',S.tDCS);
        
        % T-test day 4
        fprintf('\nt-test day 4\n');
        i1=find(S.tDCS==0 & S.day==4);
        i2=find(S.tDCS==1 & S.day==4);
        ttest(S.(variable)(i1),S.(variable)(i2),2,'independent');
        
        % Beginning / end
        fprintf('\n2 (groups) x 2 (days) ANOVA - last and first 12 blocks\n');
        T.phase=T.BN*0;
        T.phase(T.BN<=10+12)=1; % First 12 blocks
        T.phase(T.BN>10+3*24+12)=2; % First 12 blocks
        S=tapply(T,{'SN','tDCS','phase'},{variable,'mean','name',variable},'subset',T.phase>0);
        anovaMixed(S.(variable),S.SN,'within',[S.phase],{'phase'},'between',S.tDCS,{'tDCS'});
        subplot(2,1,2);
        lineplot(S.phase,S.(variable),'style_thickline','split',S.tDCS);
    case 'ANOVA_prepost'                                                   %STATS: ANOVA:  tDCS vs. sham (select hand)
        %sequencelearning2_analyze('ANOVA_prepost', 'seqCat', 1, 'anovaType', 1);                         %DURABILITY:  is it valid to average across post-test days? MTnew (trained sequences)
        %sequencelearning2_analyze('ANOVA_prepost', 'variable', 'Error', 'seqCat', 1, 'anovaType', 1);    %DURABILITY:  is it valid to average across post-test days? Error (trained sequences)
        
        %sequencelearning2_analyze('ANOVA_prepost', 'postdays', 5, 'anovaType', 2);  %INTRA-TASK TRANSFER:  Interaction of tDCS effect with sequence type:  MTnew
        %sequencelearning2_analyze('ANOVA_prepost', 'postdays', 5, 'anovaType', 2);  %INTRA-TASK TRANSFER:  Interaction of tDCS effect with sequence type:  Error
        
        %sequencelearning2_analyze('ANOVA_prepost', 'postdays', 5, 'hand', 2, 'anovaType', 2);  %INTER-MANUAL TRANSFER:  Interaction of tDCS effect with sequence type:  MTnew
        %sequencelearning2_analyze('ANOVA_prepost', 'postdays', 5, 'hand', 2, 'anovaType', 2);  %INTER-MANUAL TRANSFER:  Interaction of tDCS effect with sequence type:  RT
        %sequencelearning2_analyze('ANOVA_prepost', 'postdays', 5, 'hand', 2, 'anovaType', 2);  %INTER-MANUAL TRANSFER:  Interaction of tDCS effect with sequence type:  Mean deviation
        
        cd(behavDir);
        U=dload('SL2_preposttest.dat'); %U=dload('SL2_preposttest_diff.dat');
        %DEFAULTS/VARARGIN:
        variable  =  'MTnew';
        postdays  =  [5 12 33]; %Which post-test days to include
        seqCat  =  [1 2];
        hand      =  [1];
        anovaType =   1;
        vararginoptions(varargin,{'variable', 'seqCat', 'postdays', 'hand', 'anovaType'});
        T=getrow(U, U.hand==hand); %Trained, Left Hand
        %GENERATE TABLE:
        S=tapply(T,{'SN','tDCS','day','seqCategory'},...
            {variable,'mean','name', variable, 'subset', [isincluded(postdays,T.day) & isincluded(seqCat,T.seqCategory)]});
        %S=tapply(T,{'SN','tDCS','test'},...%seqCategory
         %   {variable,'mean','name',variable,'subset',isincluded([1 postdays],T.day)});
        fprintf('ANOVA with pre vs. post:\n');
        if anovaType==1
        anovaMixed(S.(variable), S.SN,  'between',S.tDCS,{'tDCS'},  'within',S.day,{'day'});
        elseif anovaType==2
        anovaMixed(S.(variable), S.SN,  'between',S.tDCS,{'tDCS'},  'within',S.seqCategory,{'seqCategory'});
        end;
        varargout={S};
    case 'ANCOVA_prepost'                                                  %STATS:  ANCOVA:  tDCS vs. sham (select hand)
        %sequencelearning2_analyze('ANCOVA_prepost', 'variable', 'MTnew',    'seqCat', 1);                     %DURABILTY: MTnew, trained, all post-tests
        %sequencelearning2_analyze('ANCOVA_prepost', 'variable', 'Error',    'seqCat', 1);                     %DURABILTY: Error, trained, all post-tests
        
        %sequencelearning2_analyze('ANCOVA_prepost', 'variable', 'MTnew',    'seqCat', 2,     'postdays',5);    %INTRA-TASK TRANSFER:  MTnew, untrained, D5 post-test
        %sequencelearning2_analyze('ANCOVA_prepost', 'variable', 'Error',    'seqCat', 2,     'postdays',5);    %INTRA-TASK TRANSFER:  Error, untrained, D5 post-test

        %sequencelearning2_analyze('ANCOVA_prepost', 'variable', 'MTnew',    'seqCat', [1 2], 'postdays',5, 'hand', 2);   %INTER-MANUAL TRANSFER:  MTnew, untrained, D5 post-test
        %sequencelearning2_analyze('ANCOVA_prepost', 'variable', 'Error',    'seqCat', [1 2], 'postdays',5, 'hand', 2);   %INTER-MANUAL TRANSFER:  Error, untrained, D5 post-test
        
        cd(behavDir);
        %DEFAULTS/VARARGIN:
        variable  =  'MTnew';
        postdays  =  [5 12 33]; %Which post-test days to include
        seqCat  =  [1 2];
        hand      =  [1];
        vararginoptions(varargin,{'variable', 'seqCat', 'postdays', 'hand'});
        U=dload('SL2_preposttest.dat');
        T=getrow(U, U.hand==hand);
        %GENERATE TABLE:
        S=tapply(T,{'SN','tDCS','seqCategory'},...
            {variable,'mean','name','pre', 'subset', T.day==1 & isincluded(seqCat,T.seqCategory)},...
            {variable,'mean','name','post','subset', [isincluded(postdays,T.day) & isincluded(seqCat,T.seqCategory)]});
        %ANCOVA:
        fprintf('ANCOVA with pre as covariate:\n');
        ancova1(S.post,S.tDCS,'covariate',S.pre,'fig',1);
        fprintf('Simple ANOVA without covariate:\n');
        ancova1(S.post,S.tDCS,'fig',1);
        varargout={S};
    case 'ANCOVA_prepost_NT'                                               %STATS:  ANCOVA:  sham vs. non-trained (select hand)
        %sequencelearning2_analyze('ANCOVA_prepost_NT', 'variable', 'MTnew',   'seqCat', 2,'postdays',5); %INTRA-TASK TRANSFER:  MTnew, D1vsD5, untrained
        %sequencelearning2_analyze('ANCOVA_prepost_NT', 'variable', 'Error',   'seqCat', 2,'postdays',5); %INTRA-TASK TRANSFER:  Error, D1vD5, untrained
        
        %sequencelearning2_analyze('ANCOVA_prepost_NT', 'variable', 'MTnew',   'seqCat', 1,'postdays',5); %INTRA-TASK TRANSFER:  MTnew, D1vsD5, trained
        %sequencelearning2_analyze('ANCOVA_prepost_NT', 'variable', 'Error',   'seqCat', 1,'postdays',5); %INTRA-TASK TRANSFER:  Error, D1vD5, trained

        %sequencelearning2_analyze('ANCOVA_prepost_NT', 'variable', 'MTnew',    'postdays',5, 'hand', 2, 'seqAvg', 2); %INTRA-MANUAL TRANSFER:  MTnew, D1vsD5, trained/untrained
        %sequencelearning2_analyze('ANCOVA_prepost_NT', 'variable', 'Error',    'postdays',5, 'hand', 2, 'seqAvg', 2); %INTRA-MANUAL TRANSFER:  Error, D1vD5, trained/untrained
        
        %sequencelearning2_analyze('ANCOVA_prepost_NT', 'variable', 'MTnew',    'seqCat', 1, 'postdays',5, 'hand', 2); %INTRA-MANUAL TRANSFER:  MTnew, D1vsD5, trained/untrained
        %sequencelearning2_analyze('ANCOVA_prepost_NT', 'variable', 'Error',    'seqCat', 1, 'postdays',5, 'hand', 2); %INTRA-MANUAL TRANSFER:  Error, D1vD5, trained/untrained
        
        %sequencelearning2_analyze('ANCOVA_prepost_NT', 'variable', 'MTnew',    'seqCat', 2, 'postdays',5, 'hand', 2); %INTRA-MANUAL TRANSFER:  MTnew, D1vsD5, trained/untrained
        %sequencelearning2_analyze('ANCOVA_prepost_NT', 'variable', 'Error',    'seqCat', 2, 'postdays',5, 'hand', 2); %INTRA-MANUAL TRANSFER:  Error, D1vD5, trained/untrained
        
        cd(behavDir);
        %DEFAULTS/VARARGIN:
        variable =  'MTnew';
        postdays =  [5 12 33]; %Which post-test days to include
        seqCat   =  [1 2];
        hand     =  [1];
        tDCS     =  [0];       %Exclude the tDCS group of both trained and nontrained groups
        seqAvg   =  [1];       %1=when you look at one seq category; 2=when you use both trained and untrained 
        vararginoptions(varargin,{'variable', 'seqCat', 'postdays', 'hand', 'seqAvg'});
        U=dload('SL2_preposttest_all.dat');
        if seqAvg==1
        U.seqCategory(U.trainGroup==2)=seqCat;                         %Just call the sequences of the no trained group whatever you are comparing them to 
        T=getrow(U,isincluded(hand,U.hand) & isincluded(seqCat,U.seqCategory) & isincluded(tDCS,U.tDCS));
        %D.tDCS(D.trainGroup==1 & D.tDCS==1)=0;                            %If you want to combine 'no trained' (i.e,. sequence-trained) tDCS and sham groups               
        %GENERATE TABLE:
        S=tapply(T,{'SN','trainGroup','seqCategory'},...
            {variable,'mean','name','pre', 'subset',  T.day==1},...
            {variable,'mean','name','post','subset', isincluded(postdays,T.day)}); %subs = [T.tDCS~=1]; %Exclude all tDCS of the no-trained and sequence-trained groups.
        
        elseif seqAvg==2
        T=getrow(U,isincluded(hand,U.hand) & isincluded(tDCS,U.tDCS));            
        %GENERATE TABLE:
        S=tapply(T,{'SN','trainGroup'},...
            {variable,'mean','name','pre', 'subset',  T.day==1},...
            {variable,'mean','name','post','subset', isincluded(postdays,T.day)}); %subs = [T.tDCS~=1]; %Exclude all tDCS of the no-trained and sequence-trained groups.
        end;
        %ANCOVA:
        fprintf('ANCOVA with pre as covariate:\n');
        ancova1(S.post,S.trainGroup,'covariate',S.pre,'fig',1);
        fprintf('Simple ANOVA without covariate:\n');
        ancova1(S.post,S.trainGroup,'fig',1);
        varargout={S};
    case 'TrainedVSUntrained'                                              %STATS:  TTESTS and ANOVAS for Training-specific transfer (select hand)
        %sequencelearning2_analyze('TrainedVSUntrained', 'variable', 'MTnew');              %TRAINED VS. UNTRAINED:  Left hand MTnew
        %sequencelearning2_analyze('TrainedVSUntrained', 'variable', 'Error');              %TRAINED VS. UNTRAINED:  Left hand Error
        %sequencelearning2_analyze('TrainedVSUntrained', 'variable', 'MTnew', 'hand', 2);   %TRAINED VS. UNTRAINED:  Right hand MTnew
        %sequencelearning2_analyze('TrainedVSUntrained', 'variable', 'Error', 'hand', 2);   %TRAINED VS. UNTRAINED:  Right hand Error
        
        cd(behavDir);
        %DEFAULTS/VARARGIN:
        variable  =  'MTnew';   %MTnew_DIFF
        day       =  [1 5];     %Which post-test days to include
        hand      =  [1];
        vararginoptions(varargin,{'variable', 'day', 'hand'});
        U=dload('SL2_preposttest.dat');
        T=getrow(U,isincluded(hand,U.hand) & isincluded(day,U.day) );

        fprintf('+++++++++++++++TRAINED VS. UNTRAINED (day 5) Sham:+++++++++++++++\n');
        X=pivottable(T.SN,T.seqCategory,T.(variable),'mean','subset',T.tDCS==0 & T.day==5);
        ttest(X(:,1),X(:,2),2,'paired');
        
        fprintf('+++++++++++++++TRAINED VS. UNTRAINED (day 5) TDCS:+++++++++++++++\n');
        Y=pivottable(T.SN,T.seqCategory,T.(variable),'mean','subset',T.tDCS==1 & T.day==5);
        ttest(Y(:,1),Y(:,2),2,'paired');
        
        fprintf('\ntdcs vs sham (day 5) for trained vs. untrained:\n');
        S=tapply(T,{'SN','tDCS','seqCategory'},...
            {variable,'mean','name','pre','subset',T.day==1},...
            {variable,'mean','name','post','subset',T.day==5});
        X=pivottable(S.tDCS,S.seqCategory,S.post,'mean');
        fprintf('\ntDCS effect trained %2.3f and untrained %2.3f\n',X(1,1)-X(2,1),X(1,2)-X(2,2));
        
        % ancova1(S.post,S.tDCS,'covariate',S.pre,'fig',0,'subset',S.seqCategory==2);
        anovaMixed(S.post,S.SN,'within',S.seqCategory,{'seq'},'between',S.tDCS,{'tDCS'});
    case 'MAKETABLE-STATS-BAR_SPECRATIO'                                   %STATS/RATIOS:  Chord-trained only, INTRA-TASK TRANSFER as proportion of trained hand skill (original diff and adjusted)
        %sequencelearning2_analyze('MAKETABLE-STATS-BAR_SPECRATIO');
        %sequencelearning2_analyze('MAKETABLE-STATS-BAR_SPECRATIO', 'variable', 'Error_DIFF_adjS');
        
        %Calculate the intermanual transfer ratio as:
        %RH (trained+untrained) / LH (trained)
        %Calculate the specificity as:
        %LH (untrained) / LH (trained)
        
        cd(behavDir);
        %Defaults/Varargin:
        variable='MTnew_DIFF_adjS'; %Select variable (i.e. MTnew_DIFF, RT_DIFF, or meanDevR_DIFF or their adjusted equivalents, i.e. _adj which is over sham and tDCS no trained _adjS is just over sham!) 
        postdays=[5];
        sn=[1:54];
        %sn=[1:32, 34:52, 54];
        %For MT, the subj ratios go high due to dividing by a close-to-0
        %denom:  s53
        %Also, oddly tDCS subj num s33 is neg
        vararginoptions(varargin,{'postdays', 'variable', 'sn'});
        C=dload('SL2_preposttest_diff.dat');
        D=getrow(C,  isincluded(sn,C.SN) & isincluded(postdays, C.day));
        
        T=tapply(D,{'SN','tDCS'},...%,'seqCategory' %,'day'
            {D.(variable),       'mean','name','LTU',        'subset',   D.hand==1},...
            {D.(variable),       'mean','name','LT',         'subset',  [D.hand==1 & D.seqCategory==1]},...
            {D.(variable),       'mean','name','LU',         'subset',  [D.hand==1 & D.seqCategory==2]},...
            {D.(variable),       'mean','name','RTU',        'subset',   D.hand==2},...
            {D.(variable),       'mean','name','RT',         'subset',  [D.hand==2 & D.seqCategory==1]},...
            {D.(variable),       'mean','name','RU',         'subset',  [D.hand==2 & D.seqCategory==2]});
        
        figure(1)
        % subplot(4,1,1);
        scatterplot(T.LT, T.LU./T.LT, 'split', T.tDCS);
        title('\n LU / LT\n')
        
        figure (2)
        colorset={[0 0 1 ],[1 0 0]};
        legend1={'Sham-TR','tDCS-TR','Sham-UTR','tDCS-UTR'};
        
        %Conjoin into single strux:
        CAT.facecolor={colorset{:}};
        CATLearn.facecolor=colorset;
        CAT.errorcolor={colorset{:}};
        CAT.errorwidth=2;
        CAT.errorcap=0;
        
        %Generate barplot:
        barplot([D.seqCategory], D.(variable), 'split',[D.tDCS],...
            'gapwidth',[0.7 0.2 0],'CAT', CAT,'leg', legend1, 'leglocation', 'north');
        ylabel(variable);
        set(gca,'XTickLabel',{'TR', 'TR', 'UNTR', 'UNTR'});
        
        i1=find(T.tDCS==0);
        i2=find(T.tDCS==1);
        fprintf('\n Sham vs. Anodal:  Transfer Ratio t-tests\n')
        fprintf('\n LU / LT\n')
        ttest(T.LU(i1)./T.LT(i1),   T.LU(i2)./T.LT(i2) , 2,'independent');
        
        %Compute ratios based on the means:
        fprintf('ratio(mean) \nsham=%2.5f\ntDCS=%2.5f\n',mean(T.LU(i1))./mean(T.LT(i1)),mean(T.LU(i2))./mean(T.LT(i2)))
        fprintf('ratio(std) \nsham=%2.5f\ntDCS=%2.5f\n',std(T.LU(i1))./std(T.LT(i1)), std(T.LU(i2))./std(T.LT(i2)))
        fprintf('ratio(SE) \nsham=%2.5f\ntDCS=%2.5f\n',  ((std(T.LU(i1))./std(T.LT(i1)))/sqrt(length(i1))),    ((std(T.LU(i2))./std(T.LT(i2)))/sqrt(length(i2))  ) );
       
        
        if length(postdays)>1
            anovaMixed(T.LU./T.LT,   T.SN,  'within', T.day,{'day'},  'between',[T.tDCS],{'tDCS'});
        else
        end;
        dsave('SL2_preposttest_SpecRat.dat',T);
    case 'MAKETABLE-STATS-BAR_TRANSRATIO'                                  %STATS/RATIOS:  Chord-trained only, INTER-MANUAL TRANSFER as proportion of trained hand skill (original diff and adjusted)
        %sequencelearning2_analyze('MAKETABLE-STATS-BAR_TRANSRATIO');
        %sequencelearning2_analyze('MAKETABLE-STATS-BAR_TRANSRATIO', 'variable', 'Error_DIFF_adjS');
        
        %Calculate the intermanual transfer ratio as:
        %RH (trained+untrained) / LH (trained)
        %Calculate the specificity as:
        %LH (untrained) / LH (trained)
        
        cd(behavDir);
        %Defaults/Varargin:
        variable='MTnew_DIFF_adjS'; %Select variable (i.e. MTnew_DIFF, RT_DIFF, or meanDevR_DIFF or their adjusted equivalents,  i.e. _adj which is over sham and tDCS no trained _adjS is just over sham!)
        postdays=[5];
        sn=[1:54];
        vararginoptions(varargin,{'postdays', 'variable', 'sn'});
        C=dload('SL2_preposttest_diff.dat');
        D=getrow(C,  isincluded(sn,C.SN) & isincluded(postdays, C.day));
        
        T=tapply(D,{'SN','tDCS'},...%,'seqCategory' %,'day'
            {D.(variable),       'mean','name','LTU',        'subset',   D.hand==1},...
            {D.(variable),       'mean','name','LT',         'subset',  [D.hand==1 & D.seqCategory==1]},...
            {D.(variable),       'mean','name','LU',         'subset',  [D.hand==1 & D.seqCategory==2]},...
            {D.(variable),       'mean','name','RTU',        'subset',   D.hand==2},...
            {D.(variable),       'mean','name','RT',         'subset',  [D.hand==2 & D.seqCategory==1]},...
            {D.(variable),       'mean','name','RU',         'subset',  [D.hand==2 & D.seqCategory==2]});
        
        figure(1)
        % subplot(4,1,1);
        scatterplot(T.LT, T.RTU./T.LT, 'split', T.tDCS);
        title('\n RTU / LT\n')
        
        figure (2)
        colorset={[0 0 1 ],[1 0 0]};
        legend1={'Sham-TR','tDCS-TR','Sham-UTR','tDCS-UTR'};
        
        %Conjoin into single strux:
        CAT.facecolor={colorset{:}};
        CATLearn.facecolor=colorset;
        CAT.errorcolor={colorset{:}};
        CAT.errorwidth=2;
        CAT.errorcap=0;
        
        %Generate barplot:
        barplot([D.seqCategory], D.(variable), 'split',[D.tDCS],...
            'gapwidth',[0.7 0.2 0],'CAT', CAT,'leg', legend1, 'leglocation', 'north');
        ylabel(variable);
        set(gca,'XTickLabel',{'TR', 'TR', 'UNTR', 'UNTR'});
        
        i1=find(T.tDCS==0);
        i2=find(T.tDCS==1);
        fprintf('\n Sham vs. Anodal:  Transfer Ratio t-tests\n')
        fprintf('\n RTU / LT\n')
        ttest(T.RTU(i1)./T.LT(i1),   T.RTU(i2)./T.LT(i2) , 2,'independent');
        
        %Compute ratios based on the means: 
        fprintf('ratio(mean) \nsham=%2.5f\ntDCS=%2.5f\n', mean(T.RTU(i1))./mean(T.LT(i1)),mean(T.RTU(i2))./mean(T.LT(i2)));
        fprintf('ratio(std)  \nsham=%2.5f\ntDCS=%2.5f\n', std(T.RTU(i1))./std(T.LT(i1)),std(T.RTU(i2))./std(T.LT(i2)));
        fprintf('ratio(SE)   \nsham=%2.5f\ntDCS=%2.5f\n', ((std(T.RTU(i1))./std(T.LT(i1))) / sqrt(length(i1))), ((std(T.RTU(i2))./std(T.LT(i2))) / sqrt(length(i2))) );
        
        
        if length(postdays)>1
            anovaMixed(T.RTU./T.LT,   T.SN,  'within', T.day,{'day'},  'between',[T.tDCS],{'tDCS'});
        else
        end;
        dsave('SL2_preposttest_TransRat.dat',T);                           %Only useful if you kill variable and put all the vars back in
    case 'ANOVA_catchup'                                                   %STATS:   RH catch up, avg across trained and untrained sequences
        %sequencelearning2_analyze('ANOVA_catchup'); %MTnew
        %sequencelearning2_analyze('ANOVA_catchup', 'variable', 'Error');

        T=dload('SL2_preposttest.dat');  %T=dload('SL2_prehalfposttest_diff.dat');
        variable='MTnew';
        vararginoptions(varargin,{'variable'});
        T=getrow(T,T.hand==2 & T.day~=1);
        
        %Day x tDCS interaction:
        fprintf('\n============================================================\n');
        fprintf('\nTDCS:  SHAM VS. TDCS\n');
        fprintf('\n********************************************************\n');
        fprintf('2 (groups) x 3 (days) ANOVA:  both trained and untrained sequences\n');
        S=tapply(T,{'SN','tDCS','day', 'seqCategory'},...
        {variable,'mean','name',variable});
        anovaMixed(S.(variable),S.SN,'within',[S.day S.seqCategory],{'day' 'seqCategory'},'between',S.tDCS,{'tDCS'});
        subplot(2,1,1);
        lineplot(S.day,S.(variable),'style_thickline','split',S.tDCS);
        fprintf('\n********************************************************\n');
        fprintf('2 (groups) x 3 (days) ANOVA:  trained sequences only\n');
        R=tapply(T,{'SN','tDCS','day'},...
        {variable,'mean','name',variable}, 'subset', T.seqCategory==1 & T.hand==2);
        anovaMixed(R.(variable),R.SN,'within',[R.day],{'day'},'between',R.tDCS,{'tDCS'});
        fprintf('\n********************************************************\n');
        %T-test day 4:
        fprintf('\nt-test day 33: averaged across sequence category\n');
        i1=find(S.tDCS==0 & S.day==33);
        i2=find(S.tDCS==1 & S.day==33);
        ttest(S.(variable)(i1),S.(variable)(i2),2,'independent');

        fprintf('\n============================================================\n');
        D=dload('SL2_preposttest_all.dat');
        D=getrow(D,D.hand==2 & D.tDCS~=1 & D.day~=1);
        fprintf('TRAINING:  SHAM VS. NO TRAIN\n');
        fprintf('2 (groups) x 3 (days) ANOVA:  both trained and untrained sequences\n');
        C=tapply(D,{'SN','trainGroup','day'},...
        {variable,'mean','name',variable});
        anovaMixed(C.(variable),C.SN,'within',[C.day],{'day'},'between',C.trainGroup,{'trainGroup'});
        subplot(2,1,1);
        lineplot(C.day,C.(variable),'style_thickline','split',C.trainGroup);
        fprintf('\n********************************************************\n');
        %T-test day 4:
        fprintf('\nt-test day 33: averaged across sequence category\n');
        i1=find(C.trainGroup==1 & C.day==33);
        i2=find(C.trainGroup==2 & C.day==33);
        ttest(C.(variable)(i1),C.(variable)(i2),2,'independent');
    case 'ANCOVA_CH4'                                                      %STATS:  INTER-TASK ANCOVA:  non-trained (sequence-trained; SL2) sham vs. tDCS
        %sequencelearning2_analyze('ANCOVA_CH4', 'variable','MTnew','LR',1);
        %sequencelearning2_analyze('ANCOVA_CH4', 'variable','MTnew','LR',2);
        %sequencelearning2_analyze('ANCOVA_CH4', 'variable','Error','LR',1);
        %sequencelearning2_analyze('ANCOVA_CH4', 'variable','Error','LR',2);
        cd(behavDir);
        variable='MTnew';
        postdays=[5 12 33]; % Which posttestdays to include
        LR=1;
        vararginoptions(varargin,{'variable','postdays','LR'});
        
        T=dload('SL2_preposttest_ChordTr.dat');
        T=getrow(T,T.hand==LR);   %***Change Traingroup and Hand***
        
        % Condense into table
        S=tapply(T,{'SN','tDCS'},...
            {variable,'mean','name','pre','subset',T.day==1},...
            {variable,'mean','name','post','subset',isincluded(postdays,T.day)});
        
        fprintf('ANCOVA with pre as covariate:\n');
        ancova1(S.post,S.tDCS,'covariate',S.pre,'fig',1);
        fprintf('Simple ANOVA without covariat:\n');
        ancova1(S.post,S.tDCS,'fig',1);
        varargout={S};       
    
    case 'maketable_SL4format'
        %sequencelearning2_analyze('maketable_SL4format');

        cd(behavDir);
        D=load('SL2_alldat.mat');
           
        %Over all error trials of all days, replace error trials with max MT (specific to sequence type):
        D.MTmc = D.MTnew;   %Copy MT values to new variable MTmc
        C = tapply(D,{'SN','hand','seqCategory','seqType','day'},...
                  {D.MTnew,  'max',  'name',  'maxMT'},   'subset', [D.good==1 & D.Error==0 & D.announce==0]); %Uses non-announced, non-error trials
        indx=find(D.Error>0 & D.day>0);  %Find the trials with errors:
        for j=indx'  %Loop over each value and replace error trials with max MT.
            D.MTmc(j,1) =  C.maxMT(C.SN==D.SN(j) & C.day==D.day(j) & C.seqType==D.seqType(j) & C.hand==D.hand(j) & C.seqCategory==D.seqCategory(j));
        end;

        %---(1) Table for Pre- and post-tests:
        %subs = [D.announce==0  & D.good~=0 & D.seqCategory>0 & D.trialType~=3 & (D.day==1 | D.day==6) & D.BN<86]; %Note that the practice trials are coded as day=0.
        subs = [D.announce==0  & D.good~=0 & D.exclude==0 & D.Group~=4 & D.trialType~=3 & (D.day==1 | D.day==5) & D.tDCS~=-1 & D.seqCategory>0];
        H=tapply(D,{'SN', 'day', 'seqCategory', 'hand', 'tDCS', 'trainGroup','Group'},...
            {D.MTmc/1000,    'median', 'name', 'MTmc',      'subset', subs},...
            {D.MTnew/1000,   'mean',   'name', 'MT',        'subset', subs & D.Error==0},...
            {D.MTnew/1000,   'median', 'name', 'MTm',       'subset', subs & D.Error==0},...
            {D.MTnew,        'length', 'name', 'numtrials', 'subset', subs & D.Error==0},...
            {D.Error,        'mean',   'name', 'Error',     'subset', subs });
        dsave('SL2_preposttest_SL4format.dat',H);

        %Table for Post-test only (diff scores and pre scores) for ANCOVA correction.  
        cd(behavDir);
        T=getrow(H,H.day==5); % Get a table for post-test values only
        P=getrow(H,H.day==1); % Get the corresponding table for pre-test values 
        T.MTmc_pre          =  P.MTmc;
        T.MT_pre            =  P.MT;
        T.Error_pre         =  P.Error;
        T.numtrials_pre     =  P.numtrials;
        T.MT_diff           =  T.MT_pre     -   T.MT;                   
        T.MTmc_diff         =  T.MTmc_pre   -   T.MTmc;
        T.Error_diff        =  T.Error_pre  -   T.Error;
        dsave('SL2_posttest_SL4format.dat',T);
    case 'Transfer_Lineplot_SL4format'                                     %(TDCS-M) Plot transfer to the untrained hand
        %sequencelearning2_analyze('Transfer_Lineplot_SL4format');
        cd(behavDir);
        post='MT'; 
        pre='MT_pre'; 
        colorset   =   {[0 0 0], [0 1 0],[0 0 0]};
        legend    =   {'Sham', 'Bi(anodal)','Non-trained'};
        vararginoptions(varargin,{'post', 'pre', 'colorset', 'legend'});
        %CONJOIN INTO SINGLE STRUC:
        CAT.linewidth        =  2;
        CAT.linecolor        =  {colorset{:},colorset{:}};
        CAT.markercolor      =  {colorset{:},colorset{:}};
        CAT.markerfill       =  {colorset{:},[1 1 1],[1 1 1],[1 1 1],[1 1 1]};
        CAT.markertype       =  {'o','s','*',  'o','s','*'};
        CAT.errorcolor       =  {colorset{:},colorset{:}};
        CAT.errorwidth=4; 
        CAT.errorcap=0;
        CAT.markersize       =  6.5;
        CAT.linestyle        =  {'-','-','-','-'}; %':',':',':',':'
        CATLearn.linewidth   =  2;
        CATLearn.linecolor   =  {colorset{:}};
        CATLearn.markercolor =  {colorset{:}};
        CATLearn.markerfill =   {colorset{:}};
        CATLearn.shadecolor  =  {colorset{:}};
        
        %LOAD POST-TEST DATA (with the appropriate hand and tDCS groups):
        D=dload('SL2_posttest_SL4format.dat');
        %         D.Group(D.Group==1)=0;  %Sham seq
        %         D.Group(D.Group==2)=1;  %tDCS seq
        %         D.Group(D.Group==3)=2;  %Sham chord

        subplot(2,1,1);
        lineplot([D.hand], D.(post),  'split',[D.Group],  'style_thickline',...
                  'leg',legend, 'gap',[0.7 1 0 0], 'CAT', CAT); %'linecolor',colorset,  'markercolor',colorset,  'errorcolor',colorset
        hold on;
        lineplot([D.hand], D.(pre), 'gap',[0.7 1 0 0]);  %Pre-test averaged over all groups
        hold off;
        ylabel('Post-test MT');
        
        subplot(2,1,2);
        lineplot([D.hand], D.(post) - D.(pre), 'split',[D.tDCS],...
                 'style_thickline',  'leg',legend, 'gap',[1 2 0 0],  'CAT', CAT); %'linecolor',colorset,  'markercolor',colorset,  'errorcolor',colorset
        ylabel('Difference (Post - Pre)');
        set(gcf,'PaperPosition',[2 2 10.16 25.4]);%set(gcf,'PaperPosition',[2 2 4 10]);
        wysiwyg;
       
        
     otherwise
        error('No such case exists!')
                
end;