%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path_eeglab = [];
for i=1:length(list)-2
    path_eeglab = [path_eeglab,list{i},'\'];
end

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Sleep\Correlation\'];

%% Load data using for loop
% Define filenames for ALL and Level3
BA_files_ALL = {'BA_Diff_ALL', 'BA_IC_ALL', 'BA_II_ALL'};
BA_files_Level3 = {'BA_Diff_Level3', 'BA_IC_Level3', 'BA_II_Level3'};
EEG_files_ALL = {'EEG_SO_ALL', 'EEG_SS_ALL', 'EEG_ERPAC_ALL'};
EEG_files_Level3 = {'EEG_SO_Level3', 'EEG_SS_Level3', 'EEG_ERPAC_Level3'};

% Define groups
groups = {'Adaptive_TMR', 'TMR', 'CNT'};

% Initialize structures to store correlation matrices for r and p values
corr_r_ALL = struct();
corr_p_ALL = struct();
corr_r_Level3 = struct();
corr_p_Level3 = struct();

% Loop through each group and compute correlations for ALL and Level3 conditions
for g = 1:length(groups)
    group = groups{g};
    
    % Initialize variables to store extracted group data
    BA_ALL = cell(1, 3);
    BA_Level3 = cell(1, 3);
    EEG_ALL = cell(1, 3);
    EEG_Level3 = cell(1, 3);
    
    % Load and extract data for ALL condition
    for i = 1:3
        all_data = load([path, BA_files_ALL{i}, '.mat']);
        BA_ALL{i} = all_data.(group);  % Extract the relevant group data
        
        eeg_data = load([path, EEG_files_ALL{i}, '.mat']);
        EEG_ALL{i} = eeg_data.(group);  % Extract the relevant group data
    end
    
    % Load and extract data for Level3 condition
    for i = 1:3
        level3_data = load([path, BA_files_Level3{i}, '.mat']);
        BA_Level3{i} = level3_data.(group);  % Extract the relevant group data
        
        eeg_level3_data = load([path, EEG_files_Level3{i}, '.mat']);
        EEG_Level3{i} = eeg_level3_data.(group);  % Extract the relevant group data
    end
    
    % Compute Pearson's Correlation (r and p values) for ALL condition
    corr_r_ALL.(group) = zeros(3, 3);
    corr_p_ALL.(group) = zeros(3, 3);
    for i = 1:3
        for j = 1:3
            [corr_r_ALL.(group)(i, j), corr_p_ALL.(group)(i, j)] = corr(EEG_ALL{j}, BA_ALL{i}, 'Type', 'Pearson');
            
            % If p-value is less than 0.05, plot scatter and line
            if corr_p_ALL.(group)(i, j) <= 0.05
                figure;
                scatter(EEG_ALL{j}, BA_ALL{i}, 50, [0 0.3 0.6], 'filled');
                hold on;
                % Fit line for visualization
                p = polyfit(EEG_ALL{j}, BA_ALL{i}, 1);
                yfit = polyval(p, EEG_ALL{j});
                plot(EEG_ALL{j}, yfit, '-r', 'LineWidth', 1.5);
                % xlabel(['EEG ', num2str(j), ' (ALL)']);
                % ylabel(['BA ', num2str(i), ' (ALL)']);
                % title(['Correlation for ', group, ' - ALL Condition (p <= 0.05)']);
                hold off;
            end
        end
    end
    
    % Compute Pearson's Correlation (r and p values) for Level3 condition
    corr_r_Level3.(group) = zeros(3, 3);
    corr_p_Level3.(group) = zeros(3, 3);
    for i = 1:3
        for j = 1:3
            [corr_r_Level3.(group)(i, j), corr_p_Level3.(group)(i, j)] = corr(EEG_Level3{j}, BA_Level3{i}, 'Type', 'Pearson');
            
            % If p-value is less than 0.05, plot scatter and line
            if corr_p_Level3.(group)(i, j) <= 0.05
                figure;
                scatter(EEG_Level3{j}, BA_Level3{i}, 50, [0 0.3 0.6], 'filled');
                hold on;
                % Fit line for visualization
                p = polyfit(EEG_Level3{j}, BA_Level3{i}, 1);
                yfit = polyval(p, EEG_Level3{j});
                plot(EEG_Level3{j}, yfit, '-r', 'LineWidth', 1.5);
                % xlabel(['EEG ', num2str(j), ' (Level3)']);
                % ylabel(['BA ', num2str(i), ' (Level3)']);
                % title(['Correlation for ', group, ' - Level3 Condition (p <= 0.05)']);
                hold off;
            end
        end
    end
end

%% Display results
mycolormap = customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});
for g = 1:length(groups)
    group = groups{g};
    disp(['Correlation Matrix (r values) for ', group, ' - ALL Condition:']);
    disp(corr_r_ALL.(group));
    
    disp(['Correlation Matrix (p values) for ', group, ' - ALL Condition:']);
    disp(corr_p_ALL.(group));
    
    disp(['Correlation Matrix (r values) for ', group, ' - Level3 Condition:']);
    disp(corr_r_Level3.(group));
    
    disp(['Correlation Matrix (p values) for ', group, ' - Level3 Condition:']);
    disp(corr_p_Level3.(group));

    % Plot heatmap for ALL condition
    figure;
    h=heatmap(corr_r_ALL.(group), 'Colormap', mycolormap, 'ColorLimits', [-1, 1]);
    h.CellLabelColor = 'none';
    h.XLabel = '';
    h.YLabel = '';
    h.Title = '';
    colorbar('off');

    h.XDisplayLabels = repmat({''}, size(h.XDisplayLabels));
    h.YDisplayLabels = repmat({''}, size(h.YDisplayLabels));
    h.CellLabelColor = 'none'; 

    % Plot heatmap for Level3 condition
    figure;
    h=heatmap(corr_r_Level3.(group), 'Colormap', mycolormap, 'ColorLimits', [-1, 1]);
    h.CellLabelColor = 'none';
    h.XLabel = '';
    h.YLabel = '';
    h.Title = '';
    colorbar('off');

    h.XDisplayLabels = repmat({''}, size(h.XDisplayLabels));
    h.YDisplayLabels = repmat({''}, size(h.YDisplayLabels));
    h.CellLabelColor = 'none'; 
end
