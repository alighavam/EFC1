function mov = smoothing(mov, win_len, fs)
% Description:
%       smooth the input signal.
%
% INPUTS: 
%       fs: sampling rate of the signal in Hz
%       win_len: length of the smoothing window in ms

if (win_len <= 0)
    error('smoothing: win length should be bigger than 0.')
else
    for i = 4:size(mov,2)
        mov(:,i) = movmean(mov(:,i),2*floor(win_len/1000*fs/2)+1);
    end
end