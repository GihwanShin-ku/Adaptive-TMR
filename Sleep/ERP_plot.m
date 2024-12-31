%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Sleep\ERP\'];

%% data load
groups = {'Adaptive_TMR', 'TMR', 'CNT'}; 
data = struct('Adaptive_TMR', struct('cue', {{}}, 'level', {{}}), ...
              'TMR', struct('cue', {{}}, 'level', {{}}), ...
              'CNT', {{}});  

for g = 1:length(groups)
    group_path = fullfile(path, groups{g});
    subjects = dir(fullfile(group_path, '*.mat')); 

    for s = 1:length(subjects)
        file_path = fullfile(group_path, subjects(s).name);
        loadedData = load(file_path); 

        if isfield(loadedData, 'Adaptive_TMR_ERP') 
            data.Adaptive_TMR.cue{end+1} = loadedData.Adaptive_TMR_ERP;
            data.Adaptive_TMR.level{end+1} = loadedData.Level;
        end
        if isfield(loadedData, 'TMR_ERP')
            data.TMR.cue{end+1} = loadedData.TMR_ERP;
            data.TMR.level{end+1} = loadedData.Level;
        end
        if isfield(loadedData, 'CNT_ERP')
            data.CNT{end+1} = loadedData.CNT_ERP;
        end
    end
end

%% data process
levels = 3; 
allData = [{'All'}, num2cell(levels)]; 
colors = {[0 0.3 0.6], [0.7 0.2 0.1], [0.315 0.315 0.315]};

for idx = 1:length(allData)
    level = allData{idx};
    
    LevelTMRData = {};
    TMRData = {};
    CNTData = data.CNT;

    if strcmp(level, 'All')
        LevelTMRData = data.Adaptive_TMR.cue;
        TMRData = data.TMR.cue;
    else
        for subj = 1:numel(data.Adaptive_TMR.level)
            numericLevels = str2double(data.Adaptive_TMR.level{subj});
            levelIndices = find(numericLevels == level);
            if ~isempty(levelIndices)
                LevelTMRData{end+1} = data.Adaptive_TMR.cue{subj}(:,:,levelIndices);
            end
        end
        for subj = 1:numel(data.TMR.level)
            numericLevels = str2double(data.TMR.level{subj});
            levelIndices = find(numericLevels == level);
            if ~isempty(levelIndices)
                TMRData{end+1} = data.TMR.cue{subj}(:,:,levelIndices);
            end
        end
    end

    LevelTMRDataAvg = extractTimepointData(LevelTMRData);
    TMRDataAvg = extractTimepointData(TMRData);
    CNTDataAvg = extractTimepointData(CNTData);

    figure
    hold on;
    plotOverallData(LevelTMRDataAvg, colors{1});
    plotOverallData(TMRDataAvg, colors{2});
    plotOverallData(CNTDataAvg, colors{3});

    yRange = ylim; 
   
    for t = 1:size(LevelTMRDataAvg, 2)
        all_data = [LevelTMRDataAvg(:, t); TMRDataAvg(:, t); CNTDataAvg(:, t)];
        group_labels = [ones(size(LevelTMRDataAvg, 1), 1); 2*ones(size(TMRDataAvg, 1), 1); 3*ones(size(CNTDataAvg, 1), 1)];
    
        p_anova = anova1(all_data, group_labels, 'off');
    
        if p_anova < 0.05
            yBase = yRange(1); 
            yIntervalPercentage = 5; 
            yInterval = diff(yRange) * (yIntervalPercentage / 100);
            yPositions = yBase - (0:2) * yInterval;
    
            plotSignificantMarkers(t, LevelTMRDataAvg(:, t), TMRDataAvg(:, t), colors{1}, colors{2}, yPositions(1));
            plotSignificantMarkers(t, LevelTMRDataAvg(:, t), CNTDataAvg(:, t), colors{1}, colors{3}, yPositions(2));
            plotSignificantMarkers(t, TMRDataAvg(:, t), CNTDataAvg(:, t), colors{2}, colors{3}, yPositions(3));
        end
    end

    hold off;

    xlim([0 450]); 
    xticks([50, 150, 250, 350, 450]); 
    xticklabels({'0', '1', '2', '3', '4'}); 

    set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);
    set(gca,'XLabel',[]);
    set(gca,'YLabel',[]);  
end

function timepointData = extractTimepointData(dataCell)
    numSubjects = numel(dataCell);
    if numSubjects == 0
        timepointData = []; 
        return;
    end
    
    sampleData = dataCell{1};
    if ndims(sampleData) == 3
        numTimepoints = size(sampleData, 2);
        timepointData = zeros(numSubjects, numTimepoints);
        for i = 1:numSubjects
            tempData = mean(dataCell{i}, 3);
            timepointData(i, :) = mean(tempData, 1); 
        end
    elseif ismatrix(sampleData)
        numTimepoints = size(sampleData, 2);
        timepointData = zeros(numSubjects, numTimepoints);
        for i = 1:numSubjects
            timepointData(i, :) = mean(dataCell{i}, 1);
        end
    end
end

function [pValues, hValues] = performTimepointTTests(groupAData, groupBData)
    numTimepoints = size(groupAData, 2);
    pValues = zeros(1, numTimepoints);
    hValues = zeros(1, numTimepoints);
    for t = 1:numTimepoints
        [h, p] = ttest2(groupAData(:, t), groupBData(:, t));
        pValues(t) = p;
        hValues(t) = h;
    end
end

function plotSignificantMarkers(timePoint, data1, data2, color1, color2, yPos)
    [pValue, hValue] = performTimepointTTests(data1, data2);
    if pValue < 0.05/3 
        highlightColor = calculateMidColor(color1, color2);
        plot(timePoint, yPos, 's', 'MarkerSize', 6, 'MarkerEdgeColor', highlightColor, 'MarkerFaceColor', highlightColor);
    end
end

function plotOverallData(data, color)
    shadedErrorBar(1:size(data, 2), mean(data, 1), std(data, 0, 1) / sqrt(size(data, 1)), ...
                   'lineprops', {'Color', color, 'LineWidth', 1});
end

function midColor = calculateMidColor(color1, color2)
    midColor = (color1 + color2) / 2;
end
