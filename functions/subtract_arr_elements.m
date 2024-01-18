function vec = subtract_arr_elements(arr)

cnt = 1;
vec = [];

if length(arr)<2
 vec = nan;
else
    for i = 1:length(arr)-1
        for j = i+1:length(arr)
            vec(cnt) = arr(i) - arr(j);
            cnt = cnt+1;
        end
    end
end