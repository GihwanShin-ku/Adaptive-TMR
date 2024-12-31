%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Sleep\ERPAC\'];

%% data load
groups = {'Adaptive_TMR', 'TMR', 'CNT'}; 

for g = 1:length(groups)
    group_path = fullfile(path, groups{g});
    subjects = dir(fullfile(group_path, '*.mat')); 

    lnt = 0; cnt = 0; ccnt = 0;
    for s = 1:length(subjects)
        file_path = fullfile(group_path, subjects(s).name);
        loadedData = load(file_path); 
        
        if g == 1
            lnt = lnt + 1;
            Adaptive_ALL(:,:,:,:,lnt) = loadedData.ALL; % chxchxfreqxtimepointxsubject
            Adaptive_L3(:,:,:,:,lnt) = loadedData.L3; 
        elseif g == 2
            cnt = cnt + 1;
            TMR_ALL(:,:,:,:,cnt) = loadedData.ALL;
            TMR_L3(:,:,:,:,cnt) = loadedData.L3;
        else
            ccnt = ccnt + 1;
            CNT_ALL(:,:,:,:,ccnt) = loadedData.ALL;
            CNT_L3(:,:,:,:,ccnt) = loadedData.ALL;
        end
    end
end

%% Calculate the mean across channels and subjects
Adaptive_ALL_mean = squeeze(mean(mean(mean(Adaptive_ALL, 1), 2), 5)); % Average over channels and subjects
Adaptive_L3_mean = squeeze(mean(mean(mean(Adaptive_L3, 1), 2), 5));  

TMR_ALL_mean = squeeze(mean(mean(mean(TMR_ALL, 1), 2), 5));    
TMR_L3_mean = squeeze(mean(mean(mean(TMR_L3, 1), 2), 5));      

CNT_ALL_mean = squeeze(mean(mean(mean(CNT_ALL, 1), 2), 5));         
CNT_L3_mean = squeeze(mean(mean(mean(CNT_L3, 1), 2), 5));  
 
%% Concatenate data for easier looping (reordered)
data_labels_sub = {'Adaptive TMR', 'TMR', 'CNT'};
data_labels_main = {'ALL', 'L3'};
           
data_matrices = cat(3, Adaptive_ALL_mean, TMR_ALL_mean, CNT_ALL_mean, ...
                       Adaptive_L3_mean, TMR_L3_mean, CNT_L3_mean);

% Plotting using imagesc
mycolormap = customcolormap(linspace(0,1,11), {'#a60026','#d83023','#f66e44','#faac5d','#ffdf93','#ffffbd','#def4f9','#abd9e9','#73add2','#4873b5','#313691'});

x_ticks = [50, 150, 250, 350, 450];
x_labels = {'0', '1', '2', '3', '4'};

y_ticks = [1, 8, 16, 24, 32]; 
y_labels = {'4', '8', '12', '16', '20'};

% Calculate cmin and cmax for each group (ALL, L3)
for group_idx = 1:2
    group_range = (group_idx-1)*3 + (1:3); % Get index range for each group
    cmin_group = min(data_matrices(:,:,group_range), [], 'all');
    cmax_group = max(data_matrices(:,:,group_range), [], 'all');
    
    figure;
    cnt = 0;
    
    % Plot each matrix in the group
    for i = group_range
        cnt = cnt + 1;
        subplot(1, 3, cnt);
  
        imagesc(data_matrices(:,:,i));
        set(gca, 'YDir', 'normal'); 
        
        xlabel('Time (sec)');
        ylabel('Frequency (Hz)');
        colormap(mycolormap);

        cbar = colorbar;
        ylabel(cbar, 'PAC value');
        cbar.Location = 'eastoutside'; 
    
        set(gca, 'XTick', x_ticks, 'XTickLabel', x_labels);
        set(gca, 'YTick', y_ticks, 'YTickLabel', y_labels);

        % Apply caxis based on the group's min and max
        caxis([0.03, 0.07]);

        colorbar('off');
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        set(gca,'XLabel',[]);
        set(gca,'YLabel',[]);
    end 
end 


%% Statistical analysis (ANOVA and t-tests)
% Prepare matrices for ANOVA and t-tests (subject-based comparison)
% Data is in the format: ch x amplitude x timepoint x subject

% Simplify by first averaging across channels
Adaptive_data = {
    squeeze(mean(mean(Adaptive_ALL, 1),2)), ...  % Average over channels, result is amplitude x timepoint x subject
    squeeze(mean(mean(Adaptive_L3, 1),2))};      

tmr_data = {
    squeeze(mean(mean(TMR_ALL, 1),2)), ...
    squeeze(mean(mean(TMR_L3, 1),2))};        

cnt_data = {
    squeeze(mean(mean(CNT_ALL, 1),2)), ... 
    squeeze(mean(mean(CNT_L3, 1),2))};        

% Initialize t-value and p-value storage
n_amplitudes = size(Adaptive_data{1}, 1);
n_timepoints = size(Adaptive_data{1}, 2);
n_conditions = 3;  % Adaptive TMR, TMR, CNT
t_values = cell(2, n_conditions);
p_values = cell(2, n_conditions);

for level_idx = 1:2
    t_values{level_idx, 1} = nan(n_amplitudes, n_timepoints);  % Adaptive TMR vs TMR
    t_values{level_idx, 2} = nan(n_amplitudes, n_timepoints);  % Adaptive TMR vs CNT
    t_values{level_idx, 3} = nan(n_amplitudes, n_timepoints);  % TMR vs CNT

    p_values{level_idx, 1} = nan(n_amplitudes, n_timepoints);
    p_values{level_idx, 2} = nan(n_amplitudes, n_timepoints);
    p_values{level_idx, 3} = nan(n_amplitudes, n_timepoints);
end

% Loop over ALL, L3
for level_idx = 1:2
    Adaptive_mean_subject = Adaptive_data{level_idx};
    tmr_mean_subject = tmr_data{level_idx};
    cnt_mean_subject = cnt_data{level_idx};
    
    for a = 1:n_amplitudes  % Loop over amplitudes
        for t = 1:n_timepoints  % Loop over timepoints
            % ANOVA across groups (subject-wise) for each amplitude and timepoint
            group_data = cat(1, squeeze(Adaptive_mean_subject(a, t, :)), ...
                                 squeeze(tmr_mean_subject(a, t, :)), ...
                                 squeeze(cnt_mean_subject(a, t, :)));
            group_labels = cat(1, ones(size(Adaptive_mean_subject, 3), 1), ...
                                  2 * ones(size(tmr_mean_subject, 3), 1), ...
                                  3 * ones(size(cnt_mean_subject, 3), 1));
            
            [p, ~] = anova1(group_data, group_labels, 'off');
            
            % Perform pairwise t-tests if ANOVA is significant
            if p < 0.05
                % Adaptive TMR vs TMR
                [~, p1, ~, stats1] = ttest2(squeeze(Adaptive_mean_subject(a, t, :)), squeeze(tmr_mean_subject(a, t, :)));
                t_values{level_idx, 1}(a, t) = (p1 < 0.05/3) * stats1.tstat;
                p_values{level_idx, 1}(a, t) = p1;
                
                % Adaptive TMR vs CNT
                [~, p2, ~, stats2] = ttest2(squeeze(Adaptive_mean_subject(a, t, :)), squeeze(cnt_mean_subject(a, t, :)));
                t_values{level_idx, 2}(a, t) = (p2 < 0.05/3) * stats2.tstat;
                p_values{level_idx, 2}(a, t) = p2;
                
                % TMR vs CNT
                [~, p3, ~, stats3] = ttest2(squeeze(tmr_mean_subject(a, t, :)), squeeze(cnt_mean_subject(a, t, :)));
                t_values{level_idx, 3}(a, t) = (p3 < 0.05/3) * stats3.tstat;
                p_values{level_idx, 3}(a, t) = p3;
            else
                % If ANOVA is not significant, set all to 0
                t_values{level_idx, 1}(a, t) = 0;
                t_values{level_idx, 2}(a, t) = 0;
                t_values{level_idx, 3}(a, t) = 0;
                
                p_values{level_idx, 1}(a, t) = 1;
                p_values{level_idx, 2}(a, t) = 1;
                p_values{level_idx, 3}(a, t) = 1;
            end
        end
    end
end


% Plotting t-values using imagesc
subplot_titles = {'Adaptive TMR vs TMR', 'Adaptive TMR vs CNT', 'TMR vs CNT'};
comparison_groups = {'ALL', 'L3'};

mycolormap = customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});

% Pre-allocate for storing the max/min for each comparison group (ALL, L3)
group_max_t_value = zeros(1, 2);
group_min_t_value = zeros(1, 2);


% First pass: calculate max/min for each comparison group (ALL, L3)
for i = 1:2  % Loop over comparison groups: ALL, L3
    max_t_value = -inf;
    min_t_value = inf;
    
    for j = 1:3  % Loop over t-tests: Adaptive TMR vs TMR, Adaptive TMR vs CNT, TMR vs CNT
        % Get min and max from current t_values matrix
        max_t_value = max(max_t_value, max(t_values{i,j}, [], 'all'));
        min_t_value = min(min_t_value, min(t_values{i,j}, [], 'all'));
    end
    
    % Store max and min for each group
    group_max_t_value(i) = max_t_value;
    group_min_t_value(i) = min(min_t_value, 0);  % Ensure symmetric caxis
end

% Second pass: plot with group-specific caxis limits
for i = 1:2  % Loop over comparison groups: ALL, L3
    figure;
    cnt=0;
    abs_max_t_value = max(abs(group_max_t_value(i)), abs(group_min_t_value(i)));
    
    for j = 1:3  % Loop over t-tests: Adaptive TMR vs TMR, Adaptive TMR vs CNT, TMR vs CNT
        cnt=cnt+1;
        subplot(1,3,cnt);

        imagesc(t_values{i,j});
        xlabel('Time (sec)');
        ylabel('Amplitude');
        colormap(mycolormap);
        colorbar;

        set(gca, 'XTick', x_ticks, 'XTickLabel', x_labels);
        set(gca, 'YTick', y_ticks, 'YTickLabel', y_labels);

        caxis([-5, 5]);  % Set symmetric caxis per group

        colorbar('off');
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        set(gca,'XLabel',[]);
        set(gca,'YLabel',[]);
    end
end
