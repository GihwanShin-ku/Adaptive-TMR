%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Sleep\TFR\'];

%% data load
groups = {'Adaptive_TMR', 'TMR', 'CNT'}; 

for g = 1:length(groups)
    group_path = fullfile(path, groups{g});
    subjects = dir(fullfile(group_path, '*.mat')); 

    lnt = 0; cnt = 0; ccnt = 0;
    for s = 1:length(subjects)
        % .mat file load
        file_path = fullfile(group_path, subjects(s).name);
        loadedData = load(file_path); 
    
        if isfield(loadedData, 'Adaptive_TMR_ALL')
            lnt = lnt+1;
            % SO
            Adaptive_TMR_ALL_SO(:,lnt) = loadedData.Adaptive_TMR_ALL_SO; 
            Adaptive_TMR_L3_SO(:,lnt) = loadedData.Adaptive_TMR_L3_SO; 
            % Spindle
            Adaptive_TMR_ALL_spindle(:,lnt) = loadedData.Adaptive_TMR_ALL_spindle; 
            Adaptive_TMR_L3_spindle(:,lnt) = loadedData.Adaptive_TMR_L3_spindle; 
        elseif isfield(loadedData, 'TMR_ALL')
            cnt = cnt+1;
            % SO
            TMR_ALL_SO(:,cnt) = loadedData.TMR_ALL_SO; 
            TMR_L3_SO(:,cnt) = loadedData.TMR_L3_SO; 
            % Spindle
            TMR_ALL_spindle(:,cnt) = loadedData.TMR_ALL_spindle;  
            TMR_L3_spindle(:,cnt) = loadedData.TMR_L3_spindle; 
        elseif isfield(loadedData, 'DATA_ALL')
            ccnt = ccnt+1;
            % SO
            CNT_ALL_SO(:,ccnt) = loadedData.CNT_SO; 
            CNT_L3_SO(:,ccnt) = loadedData.CNT_SO; 
            % Spindle
            CNT_ALL_spindle(:,ccnt) = loadedData.CNT_spindle; 
            CNT_L3_spindle(:,ccnt) = loadedData.CNT_spindle; 
        end
    end
end

% Correlation Save - SO
Adaptive_TMR = Adaptive_TMR_ALL_SO'; TMR = TMR_ALL_SO'; CNT = CNT_ALL_SO';
save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'EEG_SO_ALL'], 'Adaptive_TMR','TMR','CNT');
Adaptive_TMR = Adaptive_TMR_L3_SO'; TMR = TMR_L3_SO'; CNT = CNT_L3_SO';
save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'EEG_SO_Level3'], 'Adaptive_TMR','TMR','CNT');

% Correlation Save - SS
Adaptive_TMR = Adaptive_TMR_ALL_spindle'; TMR = TMR_ALL_spindle'; CNT = CNT_ALL_spindle';
save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'EEG_SS_ALL'], 'Adaptive_TMR','TMR','CNT');
Adaptive_TMR = Adaptive_TMR_L3_spindle'; TMR = TMR_L3_spindle'; CNT = CNT_L3_spindle';
save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'EEG_SS_Level3'], 'Adaptive_TMR','TMR','CNT');

%%
bands = {'SO', 'spindle'};
groups = {'ALL', 'L3'};
conditions = {'Adaptive_TMR', 'TMR', 'CNT'};

for b = 1:length(bands)
    for g = 1:length(groups)
        figure;
        hold on;

        for j = 1:length(conditions)
            data = eval(sprintf('%s_%s_%s', conditions{j}, groups{g}, bands{b}));

            % Boxplot
            positions = j;
            h = boxplot(data', 'Positions', positions, 'Widths', 0.4, 'Colors', 'k');
        end

        hPatch = findobj(gca, 'Tag', 'Box');
        colors = {[0 0.3 0.6], [0.7 0.2 0.1], [0.315 0.315 0.315]};
        for j = 1:length(hPatch)
            patchColor = colors{length(hPatch) - j + 1};
            patch(get(hPatch(j), 'XData'), get(hPatch(j), 'YData'), ...
                  patchColor, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
        end
        
        box off;
        ax = gca;
        ax.XColor = 'none';   

        scatter(ones(size(eval(sprintf('%s_%s_%s', conditions{1}, groups{g}, bands{b})))), eval(sprintf('%s_%s_%s', conditions{1}, groups{g}, bands{b})), 20, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors{1});
        scatter(2*ones(size(eval(sprintf('%s_%s_%s', conditions{2}, groups{g}, bands{b})))), eval(sprintf('%s_%s_%s', conditions{2}, groups{g}, bands{b})), 20, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors{2});
        scatter(3*ones(size(eval(sprintf('%s_%s_%s', conditions{3}, groups{g}, bands{b})))), eval(sprintf('%s_%s_%s', conditions{3}, groups{g}, bands{b})), 20, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors{3});

        hold off;
        set(gca, 'XTick', 1:length(conditions), 'XTickLabel', conditions);
        xlim([0.5, length(conditions) + 0.5]);

        if b == 1
            ylim([-2.0, 0.5]); 
            yticks([-2.0 -1.5 -1.0 -0.5 0.0 0.5]);
        elseif b == 2
            ylim([-2.5, -0.5]); 
            yticks([-2.5 -2.0 -1.5 -1.0 -0.5]);
        end

        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        set(gca,'XLabel',[]);
        set(gca,'YLabel',[]); 
    end
end

%% Statistical Analysis
for b = 1:length(bands)
    for i = 1:length(groups)
        all_data = [];
        group_labels = {};
        
        for j = 1:length(conditions)
            data = eval(sprintf('%s_%s_%s(:)', conditions{j}, groups{i}, bands{b}));
            
            all_data = [all_data; data];
            group_labels = [group_labels; repmat({conditions{j}}, length(data), 1)];
        end
        
        % ANOVA1
        [p_anova, tbl, stats] = anova1(all_data, group_labels, 'off');
        
        df_between = tbl{2, 3}; % Between-group degrees of freedom
        df_within = tbl{3, 3};  % Within-group degrees of freedom
        F_value = tbl{2, 5};    % F-value
        
        fprintf('One-way ANOVA for %s (%s): F(%d, %d) = %.3f, p = %.4f\n', groups{i}, bands{b}, df_between, df_within, F_value, p_anova);
        
        if p_anova < 0.05
            for j = 1:length(conditions)
                for k = j+1:length(conditions)
                    data1 = eval(sprintf('%s_%s_%s(:)', conditions{j}, groups{i}, bands{b}));
                    data2 = eval(sprintf('%s_%s_%s(:)', conditions{k}, groups{i}, bands{b}));
                    
                    [h, p, ci, stat] = ttest2(data1, data2);
                    
                    fprintf('T-test p-value between %s and %s in %s (%s): %.4f, t-value: %.4f\n', ...
                        conditions{j}, conditions{k}, groups{i}, bands{b}, p, stat.tstat);
                end
            end
        else
            fprintf('No significant ANOVA results for %s (%s), skipping t-tests.\n', groups{i}, bands{b});
        end
        
        fprintf('\n');
    end
end
