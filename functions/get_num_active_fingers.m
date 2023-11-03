function n = get_num_active_fingers(chordID)

n = 5 - sum(num2str(chordID)'=='9');
n = n';
    
if ~isvector(chordID)
    error('get_num_active_fingers: input chordID should be a scalar or vector')
end