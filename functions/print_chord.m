function print_chord(selected)

group = unique(selected(:,2));
n = unique(selected(:,3));


for i = 1:length(group)
    for j = 1:length(n)
        chords = selected(selected(:,2)==group(i) & selected(:,3)==n(j),1);
        if (isempty(chords))
            continue
        end
        to_print = [];
        for k = 1:length(chords)
            tmp = num2str(chords(k));
            digits = tmp - '0';
            digitStrs = arrayfun(@num2str, digits, 'UniformOutput', false);
            resultStr = strjoin(digitStrs, ',');
            to_print = [to_print '[' resultStr ']'];
        end
        to_print
    end
end