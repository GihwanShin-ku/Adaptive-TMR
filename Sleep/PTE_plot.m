%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path, list{i}, '\'];
end
path = [path 'Analysis\Sleep\'];

%% Data load
matFiles = dir(fullfile([path 'PTE\\'],'*.mat'));
fileNames = fullfile([path 'PTE\\'], {matFiles.name});

cnt = 0;
numTrialsPerSet = 4;

time_windows = {51:450};

for n = 1:length(fileNames)
    % Load .mat file data
    cnt = cnt + 1;
    loadedData = load(fullfile(fileNames{n})); % ch x ch x trial x method x band x time_window

    totalTrials = size(loadedData.dPTE, 3);

    indicesPRES1 = reshape(1:numTrialsPerSet:totalTrials, [], 1); % 1, 5, 9, ...
    indicesPRES2 = reshape(bsxfun(@plus, (1:numTrialsPerSet:totalTrials)', (0:1)), [], 1); % 1, 2, 5, 6, ...
    indicesPRES3 = reshape(bsxfun(@plus, (1:numTrialsPerSet:totalTrials)', (0:2)), [], 1); % 1, 2, 3, 5, 6, 7, ...
    indicesPRES4 = reshape(bsxfun(@plus, (1:numTrialsPerSet:totalTrials)', (0:3)), [], 1); % 1, 2, 3, 4, ...

    PRES1(:,:,:,:,cnt,:) = squeeze(mean(loadedData.dPTE(:,:,indicesPRES1, :, :, :), 3)) - 0.5;
    PRES2(:,:,:,:,cnt,:) = squeeze(mean(loadedData.dPTE(:,:,indicesPRES2, :, :, :), 3)) - 0.5;
    PRES3(:,:,:,:,cnt,:) = squeeze(mean(loadedData.dPTE(:,:,indicesPRES3, :, :, :), 3)) - 0.5;
    PRES4(:,:,:,:,cnt,:) = squeeze(mean(loadedData.dPTE(:,:,indicesPRES4, :, :, :), 3)) - 0.5;
end

%% dPTE plot for each time window
% Diagonal zeros
for k = 1:size(PRES1, 5) % subjects
    for m = 1:size(PRES1, 3) % method (scott, otnes)
        for r = 1:size(PRES1, 4) % band (slow wave, spindle)
            for tw = 1:length(time_windows) 
                PRES1(:,:,m,r,k,tw) = PRES1(:,:,m,r,k,tw) - diag(diag(PRES1(:,:,m,r,k,tw)));
                PRES2(:,:,m,r,k,tw) = PRES2(:,:,m,r,k,tw) - diag(diag(PRES2(:,:,m,r,k,tw)));
                PRES3(:,:,m,r,k,tw) = PRES3(:,:,m,r,k,tw) - diag(diag(PRES3(:,:,m,r,k,tw)));
                PRES4(:,:,m,r,k,tw) = PRES4(:,:,m,r,k,tw) - diag(diag(PRES4(:,:,m,r,k,tw)));
            end
        end
    end
end

mycolormap = customcolormap(linspace(0,1,11), {'#a60026','#d83023','#f66e44','#faac5d','#ffdf93','#ffffbd','#def4f9','#abd9e9','#73add2','#4873b5','#313691'});

meanPRES = {mean(PRES1, 5), mean(PRES2, 5), mean(PRES3, 5), mean(PRES4, 5)};
presTitles = {'PRES 1', 'PRES 2', 'PRES 3', 'PRES 4'};
methodNames = {'Scott', 'Otnes'};
bandNames = {'Slow Wave', 'Spindle'};

for tw = 1:length(time_windows)
    for m = 1 % method (Scott, Otnes)
        for r = 1:2 % band (Slow Wave, Spindle)
            figure;
            % sgtitle(['Method: ', methodNames{m}, ' | Band: ', bandNames{r}, ' | Time Window: ', time_windows{tw}]);

            allPRES = cat(3, meanPRES{1}(:,:,m,r,tw), meanPRES{2}(:,:,m,r,tw), meanPRES{3}(:,:,m,r,tw), meanPRES{4}(:,:,m,r,tw));
            cmax = max(allPRES, [], 'all');
            cmin = min(allPRES, [], 'all');

            for p = 1:4 
                subplot(1, 4, p);
                imagesc(meanPRES{p}(:,:,m,r,tw));
                colormap(mycolormap);
                colorbar;
                title([presTitles{p}]);
                xlabel('Channels');
                ylabel('Channels');
                caxis([cmin cmax]);
            end
        end
    end
end

%% Statistics for each time window
alpha = 0.05;
bonferroni_alpha = alpha / 15;

[pValues, tValues] = deal(zeros(size(PRES1, 1), size(PRES1, 2), 2, 2, 4, length(time_windows))); 

for tw = 1:length(time_windows)
    for m = 1 % method (Scott, Otnes)
        for r = 1:2 % band (Slow Wave, Spindle)
            for p = 1:4 
                switch p
                    case 1, data = squeeze(PRES1(:,:,m,r,:,tw));
                    case 2, data = squeeze(PRES2(:,:,m,r,:,tw));
                    case 3, data = squeeze(PRES3(:,:,m,r,:,tw));
                    case 4, data = squeeze(PRES4(:,:,m,r,:,tw));
                end

                reshapedData = reshape(data, [], size(data, 3));
                anovaPValues(m, r, p, tw) = anova1(reshapedData', [], 'off');
                
                if anovaPValues(m, r, p, tw) < alpha
                    for ch1 = 1:size(PRES1, 1)
                        for ch2 = 1:size(PRES1, 2)
                            if ch1 ~= ch2
                                [~, pValues(ch1, ch2, m, r, p, tw), ~, stats] = ...
                                    ttest(squeeze(data(ch1, ch2, :))); 
                                tValues(ch1, ch2, m, r, p, tw) = stats.tstat;
                            end
                        end
                    end
                else
                    pValues(:,:,m,r,p,tw) = 1;
                end
            end
        end
    end
end

% Plot significant t-values for each time window with Bonferroni correction
for tw = 1:length(time_windows)
    for m = 1 % method
        for r = 1:2 % band
            figure;
            % sgtitle(['Significant t-values - Method: ', methodNames{m}, ' | Band: ', bandNames{r}, ' | Time Window: ', time_windows{tw}]);

            for p = 1:4
                subplot(1, 4, p);
                sigTVal = tValues(:,:,m,r,p,tw);
                sigTVal(pValues(:,:,m,r,p,tw) >= bonferroni_alpha) = 0;

                imagesc(sigTVal);
                colormap(mycolormap);
                colorbar;
                title([presTitles{p}, ' (ANOVA p=', num2str(anovaPValues(m, r, p, tw), '%.3f'), ')']);
                xlabel('Channels');
                ylabel('Channels');
            end
        end
    end
end

%% barplot
channelNames = {'F3', 'F4', 'C3', 'C4', 'O1', 'O2'};
numConditions = 4; 

[~, ~, numMethods, numBands, ~, numTimeWindows] = size(PRES1);

means = zeros(numConditions, 15, numBands, numMethods, numTimeWindows);
stdErrors = zeros(numConditions, 15, numBands, numMethods, numTimeWindows);

channelPairs = nchoosek(1:length(channelNames), 2); 

colors = [0.8 0.9 1.0; 
          0.4 0.6 0.8; 
          0.2 0.45 0.7; 
          0.0 0.3 0.6]; 

% Bonferroni correction
bonferroni_alpha = 0.05 / numConditions;

for tw = 1:numTimeWindows
    for m = 1 
        for r = 1:numBands 
            for pairIdx = 1:size(channelPairs, 1)
                ch1 = channelPairs(pairIdx, 1);
                ch2 = channelPairs(pairIdx, 2);

                presData = [squeeze(PRES1(ch1, ch2, m, r, :, tw)), ...
                            squeeze(PRES2(ch1, ch2, m, r, :, tw)), ...
                            squeeze(PRES3(ch1, ch2, m, r, :, tw)), ...
                            squeeze(PRES4(ch1, ch2, m, r, :, tw))];

                means(:, pairIdx, r, m, tw) = mean(presData, 1);
                stdErrors(:, pairIdx, r, m, tw) = std(presData, [], 1) ./ sqrt(size(presData, 1));
            end
        end
    end
end

for tw = 1:numTimeWindows
    for m = 1 
        for r = 1:numBands 
            bandName = char(bandNames{r});
            methodName = char(methodNames{m});

            figure;
            % sgtitle(['PTE Comparison for ', methodName, ' Method | ', bandName, ' Band | Time Window: ', num2str(tw)]);

            for pairIdx = 1:size(channelPairs, 1)
                subplot(5, 3, pairIdx); 
                b = bar(means(:, pairIdx, r, m, tw), 'FaceColor', 'flat');
                hold on;
                errorbar(1:4, means(:, pairIdx, r, m, tw), stdErrors(:, pairIdx, r, m, tw), 'k', 'linestyle', 'none');

                % 색상 적용
                for i = 1:numConditions
                    b.CData(i, :) = colors(i, :); 
                end

                xticks(1:4);
                xticklabels({'1 PRES', '2 PRES', '3 PRES', '4 PRES'});
                % ylabel('Mean PTE');
                % title([channelNames{channelPairs(pairIdx, 1)}, ' to ', channelNames{channelPairs(pairIdx, 2)}], 'FontSize', 15);

                % set(gca,'YTickLabel',[]);
                % set(gca,'XTickLabel',[]);
                % set(gca,'XLabel',[]);
                % set(gca,'YLabel',[]);
                minY = min(means(:, pairIdx, r, m, tw) - 2 * stdErrors(:, pairIdx, r, m, tw), [], 'omitnan');
                maxY = max(means(:, pairIdx, r, m, tw) + 2 * stdErrors(:, pairIdx, r, m, tw), [], 'omitnan');

                if isempty(minY) || isempty(maxY) || minY == maxY
                    if minY == 0 && maxY == 0
                        minY = -0.05;
                        maxY = 0.05;
                    else
                        minY = -0.1;
                        maxY = 0.1;
                    end
                end
                ylim([minY, maxY]); 
            end

            for emptyIdx = size(channelPairs, 1) + 1:15
                subplot(5, 3, emptyIdx);
                axis off; 
            end
        end
    end
end
