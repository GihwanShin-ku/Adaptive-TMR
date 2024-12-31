%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp, '\');

path_new = [];
for i = 1:length(list)-2
    path_new = [path_new, list{i}, '\'];
end
path_new = [path_new, 'Data\Sleep\'];

path_save = [];
for i = 1:length(list)-2
    path_save = [path_save, list{i}, '\'];
end
path_save = [path_save, 'Analysis\Sleep\Hypnogram\'];

%% Data load
groups = {'Adaptive_TMR', 'TMR', 'CNT'}; 
sleepStages = {'WK', 'REM', 'N1', 'N2', 'N3'};
yValues = [1, 2, 3, 4, 5];  

for g = 1:length(groups)
    group_path = fullfile(path_new, groups{g});
    subjects = dir(fullfile(group_path, 'sub*'));

    for s = 1:length(subjects)
        subject_path = fullfile(group_path, subjects(s).name);
        csvfolders = dir(fullfile(subject_path, 'SleepStaging_L*')); 
        
        csvFilePath = fullfile(csvfolders.folder, csvfolders.name);
        data = readtable(csvFilePath, 'ReadVariableNames', false);

        yData = zeros(size(data, 1), 1); 

        for i = 1:numel(sleepStages)
            yData(strcmp(data{:, 3}, sleepStages{i})) = yValues(i);
        end

        nonZeroIndices = find(yData ~= 0);
        startIndex = nonZeroIndices(1); 
        endIndex = nonZeroIndices(end); 

        yDataTrimmed = yData(startIndex:endIndex);
        timeDataTrimmed = data{startIndex:endIndex, 1}; 

        % hypnogram
        figure;
        plot(timeDataTrimmed, yDataTrimmed, '-k', 'MarkerSize', 4, 'LineWidth', 1.5);
        ylim([1 5]); 
        
        % Adjust xticks and labels
        xticks([timeDataTrimmed(1), timeDataTrimmed(end)]);
        xticklabels({'22:00', '06:00'});

        yticks([1, 2, 3, 4, 5]);
        yticklabels({'Wake', 'REM', 'N1', 'N2', 'N3'});
        
        set(gca, 'YDir', 'reverse');
        
        % Save the plot
        group_save_path = fullfile(path_save, groups{g});
        if ~exist(group_save_path, 'dir') 
            mkdir(group_save_path);
        end
        save_name = fullfile(group_save_path, [subjects(s).name, '.png']); 
        saveas(gcf, save_name);
        close(gcf); 
    end
end
