function C = get_chord_symmetry(chords)

% dataframe to store the symmetries:
C = [];

cnt = 1;
for i = 1:length(chords)
    % skip flagged chords:
    % if (chords(i) == 0)
    %     continue
    % end

    C.chord(cnt,1) = chords(i);
    
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

    % % flagging chords that are already made to avoid repetition:
    % chords(chords==str2double(chord_vs)) = 0;
    % chords(chords==str2double(chord_hs)) = 0;
    % chords(chords==str2double(chord_vhs)) = 0;
end