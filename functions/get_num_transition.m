function num_transition = get_num_transition(chordVec)

% Decription: Calculates the numebr of transitions in chords. 
%
% input:
%       chordVec: a column vector of chords <N by 1>. The elements data type 
%       must be integer. An example input vector is: 
%       [19299 ; 991299 ; 99919 ; 19299]
%
% output:
%       num_transition: a matrix with N by 2 dimensions. First column is the
%       chords that was inputted to the function. Second column is the
%       number of transitions as an integer in range 0 to 4.


% turning integers to digit characters, N by 1 matrix to N by 5
chordVec_char = int2str(chordVec);

% container for num transitions:
num_transition = zeros(size(chordVec_char,1),1);

% looping through digits and calculating the num_transition
for j = 2:5
    col1 = chordVec_char(:,j-1);
    col2 = chordVec_char(:,j);

    % subtracting col2 and col1 and adding to transitions:
    col_transition = (str2num(col2) - str2num(col1));
    col_transition(col_transition~=0) = 1; 
    num_transition(:,1) = num_transition(:,1) + col_transition;
end
