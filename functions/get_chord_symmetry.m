function C = get_chord_symmetry(chords,option)

% dataframe to store the symmetries:
C = [];

cnt = 1;
for i = 1:length(chords)
    % skip flagged chords:
    % if (chords(i) == 0)
    %     continue
    % end
    if strcmp(option,'vert')
        % skip flagged chords:
        if (chords(i) == 0)
            continue
        end
        C.chord(cnt,1) = chords(i);
    
        chord_str = int2str(chords(i));
        
        % make vertical symmetry of chord i:
        chord_vs = strrep(chord_str,'1','3');
        chord_vs = strrep(chord_vs,'2','1');
        chord_vs = strrep(chord_vs,'3','2');
        
        % store in dataframe:
        C.chord_vs(cnt,1) = str2double(chord_vs);
        cnt = cnt+1;

        % flagging chords that are already made to avoid repetition:
        chords(chords==str2double(chord_vs)) = 0;
        
    elseif strcmp(option,'horz')
        % skip flagged chords:
        if (chords(i) == 0)
            continue
        end

        chord_str = int2str(chords(i));
        % make horizontal symmetry of chord i:
        chord_hs = flip(chord_str);
        
        % if the chord_hs was not the same the original chord:
        if ~strcmp(chord_hs,chord_str)
            % store in dataframe:
            C.chord(cnt,1) = chords(i);
            C.chord_hs(cnt,1) = str2double(chord_hs);
            cnt = cnt+1;

            % flagging chords that are already made to avoid repetition:
            chords(chords==str2double(chord_hs)) = 0;
        else
            continue;
        end

    elseif strcmp(option,'all')
        % skip flagged chords:
        if (chords(i) == 0)
            continue
        end

        % original chord:
        C.chord(cnt,1) = chords(i);
        
        % transforming chord from num to str:
        chord_str = int2str(chords(i));

        % make vertical symmetry of chord i:
        chord_vs = strrep(chord_str,'1','3');
        chord_vs = strrep(chord_vs,'2','1');
        chord_vs = strrep(chord_vs,'3','2');

        % make horizontal symmetry of chord i:
        chord_hs = flip(chord_str);

        % make vertical horizontal symmetry of chord i:
        chord_vhs = flip(chord_vs);

        % store in dataframe:
        C.chord_vs(cnt,1) = str2double(chord_vs);
        C.chord_hs(cnt,1) = str2double(chord_hs);
        C.chord_vhs(cnt,1) = str2double(chord_vhs);
        cnt = cnt+1;
    
        % flagging chords that are already made to avoid repetition:
        chords(chords==str2double(chord_vs)) = 0;
        chords(chords==str2double(chord_hs)) = 0;
        chords(chords==str2double(chord_vhs)) = 0;
    end
    
    % C.chord(cnt,1) = chords(i);
    % 
    % chord_str = int2str(chords(i));
    % 
    % % make vertical symmetry of chord i:
    % chord_vs = strrep(chord_str,'1','3');
    % chord_vs = strrep(chord_vs,'2','1');
    % chord_vs = strrep(chord_vs,'3','2');
    % 
    % % make horizontal symmetry of chord i:
    % chord_hs = flip(chord_str);
    % 
    % % make vertical horizontal symmetry of chord i:
    % chord_vhs = flip(chord_vs);
    % 
    % % store in dataframe:
    % C.chord_vs(cnt,1) = str2double(chord_vs);
    % C.chord_hs(cnt,1) = str2double(chord_hs);
    % C.chord_vhs(cnt,1) = str2double(chord_vhs);
    % cnt = cnt+1;

    % % flagging chords that are already made to avoid repetition:
    % chords(chords==str2double(chord_vs)) = 0;
    % chords(chords==str2double(chord_hs)) = 0;
    % chords(chords==str2double(chord_vhs)) = 0;
end