%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp, '\');

path = [];
for i = 1:length(list)-2
    path = [path, list{i}, '\'];
end
path = [path 'Analysis\Sleep\Classification\'];

%% Load Results
files = {'SW_SVM_rbf.mat', 'SS_SVM_rbf.mat','SWSS_SVM_rbf.mat'}; 

results = cell(1, numel(files));

for i = 1:numel(files)
    loadedData = load(fullfile(path, files{i}));
    results{i} = loadedData.results;
end

%% Plot Results
% Plotting parameters
timeSW = linspace(-0.5, 4, 53);
timeSWSS = linspace(-0.5, 4, 450); 
chanceAccuracy = 0.33;
chanceAUC = 0.5;
fileColors = {
    [0.1176, 0.1216, 0.5647], 
    [0.6627, 0.0431, 0.0431], 
    [1.0000, 0.5569, 0.0000]  
};

% Iterate over result files and levels
for i = 1:numel(results)
    currentResults = results{i};
    levels = fieldnames(currentResults);

    if i == 3 
        time = timeSWSS;
    else 
        time = timeSW;
    end

    currentColor = fileColors{i};

    for idx = 1:numel(levels)
        condition = levels{idx};
        % Accuracy plotting
        observedAccMean = squeeze(currentResults.(condition).accuracyMean);
        observedAccSTE = squeeze(currentResults.(condition).accuracySTE);
        surrogateAccMean = squeeze(currentResults.(condition).surrogateAccuracyMean);
        surrogateAccSTE = squeeze(currentResults.(condition).surrogateAccuracySTE);
        clusterPAcc = currentResults.(condition).clusterPAcc;

        plotWithCI(time, observedAccMean, observedAccSTE, surrogateAccMean, surrogateAccSTE, clusterPAcc, ...
            [condition, ' Decoding Accuracy'], 'Accuracy (%)', chanceAccuracy, currentColor, i);

        % AUC plotting
        observedAUCMean = squeeze(currentResults.(condition).aucMean);
        observedAUCSTE = squeeze(currentResults.(condition).aucSTE);
        surrogateAUCMean = squeeze(currentResults.(condition).surrogateAUCMean);
        surrogateAUCSTE = squeeze(currentResults.(condition).surrogateAUCSTE);
        clusterPAUC = currentResults.(condition).clusterPAUC;

        plotWithCI(time, observedAUCMean, observedAUCSTE, surrogateAUCMean, surrogateAUCSTE, clusterPAUC, ...
            [condition, ' Decoding AUC'], 'AUC', chanceAUC, currentColor, i);
    end
end

%% Helper Functions
function plotWithCI(time, observedMean, observedStd, surrogateMean, surrogateStd, clusterP, titleStr, yLabel, chanceLevel, color, fileIndex)
    figure; hold on;

    shadedErrorBar(time, observedMean, observedStd, 'lineprops', {'-', 'Color', color, 'LineWidth', 1.5}, 'patchSaturation', 0.2);

    shadedErrorBar(time, surrogateMean, surrogateStd, 'lineprops', {'--', 'Color', color, 'LineWidth', 1.5}, 'patchSaturation', 0.2);

    yline(chanceLevel, 'k');

    xlim([-0.5 4]); 
    xticks(0:1:4);  
    xticklabels({'0', '1', '2', '3', '4'}); 

    if contains(titleStr, 'All') && contains(titleStr, 'Accuracy')
        ylim([0 0.8]); yticks([0 0.2 0.4 0.6 0.8]); yPos = 0.05;
    elseif contains(titleStr, 'All') && contains(titleStr, 'AUC')
        ylim([0.2 1.0]); yticks([0.2 0.4 0.6 0.8 1.0]); yPos = 0.25;
    elseif contains(titleStr, 'Level_3') && contains(titleStr, 'Accuracy')
        ylim([0 0.8]); yticks([0 0.2 0.4 0.6 0.8]); yPos = 0.05;
    elseif contains(titleStr, 'Level_3') && contains(titleStr, 'AUC')
        ylim([0.2 1.0]); yticks([0.2 0.4 0.6 0.8 1.0]); yPos = 0.25;
    else
        yRange = ylim;
        yPos = yRange(1) + diff(yRange) * 0.05;
    end

    plotSignificantClusters(time, clusterP, yPos, color);


    % title(titleStr);
    xlabel('Time (s)');
    ylabel(yLabel);

    set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);
    set(gca,'XLabel',[]);
    set(gca,'YLabel',[]);

    hold off;
end

function plotSignificantClusters(time, clusterP, yPos, color)
    sig = clusterP < 0.05; 
    significantIndices = find(sig);
    if isempty(significantIndices)
        return;
    end

    clusterBreaks = [0; find(diff(significantIndices) > 1); length(significantIndices)];
    startIdx = significantIndices(clusterBreaks(1:end-1) + 1);
    endIdx = significantIndices(clusterBreaks(2:end));

    for i = 1:length(startIdx)
        idxRange = startIdx(i):endIdx(i);
        clusterTimes = time(idxRange);

        if length(clusterTimes) == 1
            clusterTimes = [clusterTimes, clusterTimes];
        end

        clusterPositions = yPos * ones(size(clusterTimes));
        plot(clusterTimes, clusterPositions, '-', 'Color', color, 'LineWidth', 1.5);
    end
end