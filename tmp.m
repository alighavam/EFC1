nfing = df.finger_count;

for i = 1:2:5
    figure;
    imagesc(M(nfing==i,:))
    colormap(cividis);
    colorbar;
    ax = gca;
    % ax.GridColor = [0, 0, 0]; % Set grid lines color to black
    % ax.GridAlpha = 1; 
    % ax.XGrid = 'on';
    % ax.YGrid = 'on';
    ax.XTick = 1:1:10;
    ax.YTick = 1:1:sum(nfing==i);
    ax.XTickLabel = {'f1','f2','f3','f4','f5','e1','e2','e3','e4','e5'};
    ax.YTickLabel = df.chords(nfing==i);
end

%%
i = 21;
x = M(i,:);
figure;
imagesc(x'*x);
colormap(cividis)
colorbar;
ax = gca;
ax.XTick = 1:1:10;
ax.YTick = 1:1:10;
ax.XTickLabel = {'f1','f2','f3','f4','f5','e1','e2','e3','e4','e5'};
ax.YTickLabel = {'f1','f2','f3','f4','f5','e1','e2','e3','e4','e5'};
title('chord ',df.chords(i))
axis square

%%
mag = zeros(68,1);
coact = zeros(68,1);
chords = df.chords;
for i = 1:68
    x = M(i,:);
    G = x' * x;
    mag(i) = trace(G);
    coact(i) = (sum(G(:)) - mag(i))/mag(i);
end
table = [chords,mag,coact];

%% Natural






