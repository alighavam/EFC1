function movsave(filename,D)

if nargin==1
    D=filename;
    filename='';
end
if (~iscell(D))
    error('Cannot save the mov file. input needs to be a cell with 1xN or Nx1 dimension (N is the number of trials).');
end
if isempty(filename)
   [F,P]=uiputfile('*.*','Save Cell Array as');
   filename = [P,F];
end
fid=fopen(filename,'wt');
if (fid==-1)
    error(sprintf('Error opening file %s\n',filename));
end

trialNum = length(D);
linefeed=sprintf('\n');
tab=sprintf('\t');

% Writing the file
for i = 1:trialNum
    fprintf(fid,"Trial %d\n",i);
    for j = 1:size(D{i},1) % num data points
        for col = 1:size(D{i},2) % num of columns
            if (col<=22)
                fprintf(fid,"%.3f",D{i}(j,col));
                fprintf(fid,tab);
            else
                fprintf(fid,"%.3f",D{i}(j,col));
            end
        end
        if (j~=size(D{i},1))
            fprintf(fid,linefeed);
        end
    end
    fprintf(fid,linefeed);
end

fclose(fid);