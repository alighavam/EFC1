function rgb = hex2rgb(hexString)
% Ali Ghavampour
% inspired from Jakob Nikolas Kather 2015 -> https://gist.github.com/jnkather/6de1287c446713266e63 ,  http://www.kather.me

if (ismatrix(hexString))
    hexString(:,1) = [];
    rgb = zeros(size(hexString,1),3);
    for i = 1:size(hexString,1)
        if size(hexString(i,:),2) ~= 6
		    error('invalid input: not 6 characters');
	    else
		    r = double(hex2dec(hexString(i,1:2)))/255;
		    g = double(hex2dec(hexString(i,3:4)))/255;
		    b = double(hex2dec(hexString(i,5:6)))/255;
		    rgb(i,:) = [r, g, b];
        end
    end
else
    hexString(1) = [];
    if size(hexString,2) ~= 6
		error('invalid input: not 6 characters');
	else
		r = double(hex2dec(hexString(1:2)))/255;
		g = double(hex2dec(hexString(3:4)))/255;
		b = double(hex2dec(hexString(5:6)))/255;
		rgb = [r, g, b];
    end
end




