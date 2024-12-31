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
SP = 16:24; 
Interval = 51:450;

for g = 1:length(groups)
    group_path = fullfile(path, groups{g});
    subjects = dir(fullfile(group_path, '*.mat'));

    lnt = 0; cnt = 0; ccnt = 0;
    for s = 1:length(subjects)
        file_path = fullfile(group_path, subjects(s).name);
        loadedData = load(file_path); 
        
        if g == 1
            lnt = lnt+1;
            Adaptive_TMR_ALL(:,lnt) = squeeze(mean(mean(mean(mean(loadedData.ALL(:,:,SP,Interval),1),2),3),4)); % Freq x Time x N
            Adaptive_TMR_L3(:,lnt) = squeeze(mean(mean(mean(mean(loadedData.L3(:,:,SP,Interval),1),2),3),4));
        elseif g == 2
            cnt = cnt+1;
            TMR_ALL(:,cnt) = squeeze(mean(mean(mean(mean(loadedData.ALL(:,:,SP,Interval),1),2),3),4));
            TMR_L3(:,cnt) = squeeze(mean(mean(mean(mean(loadedData.L3(:,:,SP,Interval),1),2),3),4));
        else
            ccnt = ccnt+1;
            CNT_ALL(:,ccnt) = squeeze(mean(mean(mean(mean(loadedData.ALL(:,:,SP,Interval),1),2),3),4));
            CNT_L3(:,ccnt) = squeeze(mean(mean(mean(mean(loadedData.ALL(:,:,SP,Interval),1),2),3),4));
        end
    end
end

% Save - SO-SS couling
Adaptive_TMR = Adaptive_TMR_ALL'; TMR = TMR_ALL'; CNT = CNT_ALL';
save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'EEG_ERPAC_ALL'], 'Adaptive_TMR','TMR','CNT');

Adaptive_TMR = Adaptive_TMR_L3'; TMR = TMR_L3'; CNT = CNT_L3';
save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'EEG_ERPAC_Level3'], 'Adaptive_TMR','TMR','CNT');
%% boxplot
groups = {'ALL', 'L3'};
conditions = {'Adaptive_TMR', 'TMR', 'CNT'};

numGroups = length(conditions);

for g = 1:length(groups)
    figure;  
    hold on;

    all_data = [];  

    for j = 1:numGroups
        data = eval(sprintf('%s_%s', conditions{j}, groups{g}));
        all_data = [all_data; data(:)];  %

        % boxplot 
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

    colors = {[0 0.3 0.6], [0.7 0.2 0.1],[0.315 0.315 0.315]}; 
    scatter(ones(size(eval(sprintf('%s_%s', conditions{1}, groups{g})))), eval(sprintf('%s_%s', conditions{1}, groups{g})), 20, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors{1});
    scatter(2*ones(size(eval(sprintf('%s_%s', conditions{2}, groups{g})))), eval(sprintf('%s_%s', conditions{2}, groups{g})), 20, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors{2});
    scatter(3*ones(size(eval(sprintf('%s_%s', conditions{3}, groups{g})))), eval(sprintf('%s_%s', conditions{3}, groups{g})), 20, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors{3});

    hold off;
    set(gca, 'XTick', 1:numGroups, 'XTickLabel', conditions);
    xlim([0.5, numGroups + 0.5]);  

    if g == 1
        ylim([0.02 0.08]);
        yticks([0.02, 0.04, 0.06, 0.08]);
    else
        ylim([0 0.15]);
        yticks([0, 0.05, 0.1, 0.15]);
    end

    set(gca, 'YScale', 'linear');  

    set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);
    set(gca,'XLabel',[]);
    set(gca,'YLabel',[]); 
end

%% Statistical Analysis
for i = 1:length(groups)
    combinedData = [];
    groupLabels = [];
    for j = 1:length(conditions)
        tempData = eval(sprintf('%s_%s(:)', conditions{j}, groups{i}));
        combinedData = [combinedData; tempData];
        groupLabels = [groupLabels; repmat(j, length(tempData), 1)];
    end
    
    [p_anova, tbl, stats] = anova1(combinedData, groupLabels, 'off');

    df_between = tbl{2, 3};
    df_within = tbl{3, 3};  
    F_value = tbl{2, 5};    
    
    fprintf('One-way ANOVA for %s: F(%d, %d) = %.3f, p = %.4f\n', groups{i}, df_between, df_within, F_value, p_anova);

    if p_anova < 0.05
        for j = 1:length(conditions)
            for k = j+1:length(conditions)
                data1 = eval(sprintf('%s_%s(:)', conditions{j}, groups{i}));
                data2 = eval(sprintf('%s_%s(:)', conditions{k}, groups{i}));
                [h, p, ci, stat] = ttest2(data1, data2);
                
                fprintf('Post-hoc t-test p-value between %s and %s in %s: %.4f, t-value: %.4f\n', ...
                    conditions{j}, conditions{k}, groups{i}, p, stat.tstat);
            end
        end
    end
    fprintf('\n');
end
