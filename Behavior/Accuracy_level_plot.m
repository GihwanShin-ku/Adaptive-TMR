%% init
clear; clc; close all

%% path setting
temp = pwd;
list = split(temp,'\');

path_new = [];
for i=1:length(list)-2
    path_new = [path_new,list{i},'\'];
end

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Data\Behavior\'];

%% data load
groups = {'Adaptive_TMR', 'TMR', 'CNT'};
Time = {'retrieval_1.txt', 'retrieval_2.txt'};

presleepRates = cell(3,3);
postsleepRates = cell(3,3);
presleepCounts = cell(3,3); 
postsleepCounts = cell(3,3);

for g = 1:length(groups)
    groupPath = fullfile(path, groups{g});
    subjects = dir(fullfile(groupPath, 'sub*')); 
    subjectNames = {subjects.name};

    for n = 1:length(subjectNames)
        subPath = fullfile(groupPath, subjectNames{n});
    
        % Loop through both presleep and postsleep
        for t = 1:length(Time)
            filePath = fullfile(subPath, Time{t});

            WM_recall = textscan(fopen(filePath), '%s %s %s %s %s %s %s %s %s');
            WM_recall = [WM_recall{:}];
            totalQuestions = size(WM_recall, 1) - 1;  

            correctCounts = zeros(3, 1);
            totalCounts = zeros(3, 1);
            buttonCounts = zeros(3, 1); 
    
            for i = 2:size(WM_recall, 1)  
                level = str2double(WM_recall{i, 8});
                correctNum = str2double(WM_recall{i, 1});
                buttonCounts(level) = buttonCounts(level) + 1;
    
                correctCounts(level) = correctCounts(level) + correctNum;
                totalCounts(level) = totalCounts(level) + 1;
            end
    
            rates = correctCounts ./ totalCounts * 100; 
    
            % Store the rates and button counts in the appropriate cell arrays
            if g == 1
                groupIdx = 1;
            elseif g == 2
                groupIdx = 2;
            else
                groupIdx = 3;
            end
            if t == 1
                for i = 1:3
                    presleepRates{i, groupIdx} = [presleepRates{i, groupIdx}; rates(i)];
                    presleepCounts{i, groupIdx} = [presleepCounts{i, groupIdx}; buttonCounts(i)];
                end
            else
                for i = 1:3
                    postsleepRates{i, groupIdx} = [postsleepRates{i, groupIdx}; rates(i)];
                    postsleepCounts{i, groupIdx} = [postsleepCounts{i, groupIdx}; buttonCounts(i)];
                end
            end
        end
    end
end

%% plot
colors = {[0.6, 0.8, 1], [0, 0.4470, 0.7410], [0.9, 0.6, 0.2], [0.8500, 0.3250, 0.0980], [0.8 0.8 0.8], [0.5 0.5 0.5]};
% Colors for TMR Presleep, TMR Postsleep, CNT Presleep, CNT Postsleep
y_lim = {[50 100], [0 100], [0 16]};
y_ticks = {[50 60 70 80 90 100], [0 20 40 60 80 100], [0 4 8 12 16]};

for i = 1:3  % For each level
    figure; % New figure for each level
    hold on;
    
    % Extract data for presleep and postsleep for all groups
    presleepLevelTMRData = presleepRates{i, 1};
    postsleepLevelTMRData = postsleepRates{i, 1};
    presleepTMRData = presleepRates{i, 2};
    postsleepTMRData = postsleepRates{i, 2};
    presleepCNTData = presleepRates{i, 3};
    postsleepCNTData = postsleepRates{i, 3};

    % Remove NaN values for accurate statistical analysis
    presleepLevelTMRData = presleepLevelTMRData(~isnan(presleepLevelTMRData));
    postsleepLevelTMRData = postsleepLevelTMRData(~isnan(postsleepLevelTMRData));
    presleepTMRData = presleepTMRData(~isnan(presleepTMRData));
    postsleepTMRData = postsleepTMRData(~isnan(postsleepTMRData));
    presleepCNTData = presleepCNTData(~isnan(presleepCNTData));
    postsleepCNTData = postsleepCNTData(~isnan(postsleepCNTData));

    all_acc_data = [presleepLevelTMRData; postsleepLevelTMRData; presleepTMRData; postsleepTMRData; presleepCNTData; postsleepCNTData];
    all_groups = [ones(size(presleepLevelTMRData)); ones(size(postsleepLevelTMRData)); 2*ones(size(presleepTMRData)); 2*ones(size(postsleepTMRData)); 3*ones(size(presleepCNTData)); 3*ones(size(postsleepCNTData))];
    all_times = [ones(size(presleepLevelTMRData)); 2*ones(size(postsleepLevelTMRData)); ones(size(presleepTMRData)); 2*ones(size(postsleepTMRData)); ones(size(presleepCNTData)); 2*ones(size(postsleepCNTData))];

    [p_acc, tbl_acc, stats_acc] = anovan(all_acc_data, {all_groups, all_times}, 'model', 'interaction', 'varnames', {'Group', 'Time'}, 'display', 'off');

    fprintf('Two-way ANOVA for Accuracy - Level %d:\n', i);
    fprintf('Group effect: F(%d, %d) = %.3f, p = %.4f\n', tbl_acc{2,3}, tbl_acc{4,3}, tbl_acc{2,6}, tbl_acc{2,7});
    fprintf('Time effect: F(%d, %d) = %.3f, p = %.4f\n', tbl_acc{3,3}, tbl_acc{4,3}, tbl_acc{3,6}, tbl_acc{3,7});
    fprintf('Interaction effect: F(%d, %d) = %.3f, p = %.4f\n\n', tbl_acc{4,3}, tbl_acc{4,3}, tbl_acc{4,6}, tbl_acc{4,7});
     
    if p_acc(1) < 0.05  
        fprintf('Significant Group effect found for Accuracy at Level %d. Performing group comparisons...\n', i);
        
        [hPre1, pPre1, ci, statsPre1] = ttest2(presleepLevelTMRData, presleepTMRData);
        [hPost1, pPost1, ci, statsPost1] = ttest2(postsleepLevelTMRData, postsleepTMRData);
        [hPre2, pPre2, ci, statsPre2] = ttest2(presleepLevelTMRData, presleepCNTData);
        [hPost2, pPost2, ci, statsPost2] = ttest2(postsleepLevelTMRData, postsleepCNTData);
        [hPre3, pPre3, ci, statsPre3] = ttest2(presleepTMRData, presleepCNTData);
        [hPost3, pPost3, ci, statsPost3] = ttest2(postsleepTMRData, postsleepCNTData);
        
        fprintf('Level %d: LTMR vs. TMR Presleep comparison, t-value = %.4f, p-value = %.4f\n', i, statsPre1.tstat, pPre1);
        fprintf('Level %d: LTMR vs. TMR Postsleep comparison, t-value = %.4f, p-value = %.4f\n', i, statsPost1.tstat, pPost1);
        fprintf('Level %d: LTMR vs. CNT Presleep comparison, t-value = %.4f, p-value = %.4f\n', i, statsPre2.tstat, pPre2);
        fprintf('Level %d: LTMR vs. CNT Postsleep comparison, t-value = %.4f, p-value = %.4f\n', i, statsPost2.tstat, pPost2);
        fprintf('Level %d: TMR vs. CNT Presleep comparison, t-value = %.4f, p-value = %.4f\n', i, statsPre3.tstat, pPre3);
        fprintf('Level %d: TMR vs. CNT Postsleep comparison, t-value = %.4f, p-value = %.4f\n\n', i, statsPost3.tstat, pPost3);
    end

    if p_acc(2) < 0.05 
        fprintf('Significant Time effect found for Accuracy at Level %d. Performing paired t-tests for each group...\n', i);
        
        [h_acc_lvl, p_acc_lvl, ~, stats_acc_lvl] = ttest(presleepLevelTMRData, postsleepLevelTMRData);
        fprintf('Adaptive TMR group: t(%d) = %.3f, p = %.4f\n', stats_acc_lvl.df, stats_acc_lvl.tstat, p_acc_lvl);
        
        [h_acc_tmr, p_acc_tmr, ~, stats_acc_tmr] = ttest(presleepTMRData, postsleepTMRData);
        fprintf('TMR group: t(%d) = %.3f, p = %.4f\n', stats_acc_tmr.df, stats_acc_tmr.tstat, p_acc_tmr);
        
        [h_acc_con, p_acc_con, ~, stats_acc_con] = ttest(presleepCNTData, postsleepCNTData);
        fprintf('Control group: t(%d) = %.3f, p = %.4f\n\n', stats_acc_con.df, stats_acc_con.tstat, p_acc_con);
    end
    
    if p_acc(3) < 0.05 
        fprintf('Significant Interaction effect found for Accuracy at Level %d. Performing further analysis...\n', i);
        
        [h_lvl, p_lvl, ~, stats_lvl] = ttest(presleepLevelTMRData, postsleepLevelTMRData);
        fprintf('Adaptive TMR group: t(%d) = %.3f, p = %.4f\n', stats_lvl.df, stats_lvl.tstat, p_lvl);
        
        [h_tmr, p_tmr, ~, stats_tmr] = ttest(presleepTMRData, postsleepTMRData);
        fprintf('TMR group: t(%d) = %.3f, p = %.4f\n', stats_tmr.df, stats_tmr.tstat, p_tmr);
        
        [h_con, p_con, ~, stats_con] = ttest(presleepCNTData, postsleepCNTData);
        fprintf('Control group: t(%d) = %.3f, p = %.4f\n\n', stats_con.df, stats_con.tstat, p_con);
        
        diff_LevelTMR = postsleepLevelTMRData - presleepLevelTMRData;
        diff_TMR = postsleepTMRData - presleepTMRData;
        diff_CNT = postsleepCNTData - presleepCNTData;
        
        % Adaptive TMR vs TMR
        [h_diff1, p_diff1, ~, stats_diff1] = ttest2(diff_LevelTMR, diff_TMR);
        fprintf('Difference between Adaptive TMR and TMR: t(%d) = %.3f, p = %.4f\n', stats_diff1.df, stats_diff1.tstat, p_diff1);
        
        % Adaptive TMR vs CNT
        [h_diff2, p_diff2, ~, stats_diff2] = ttest2(diff_LevelTMR, diff_CNT);
        fprintf('Difference between Adaptive TMR and CNT: t(%d) = %.3f, p = %.4f\n', stats_diff2.df, stats_diff2.tstat, p_diff2);
        
        % TMR vs CNT
        [h_diff3, p_diff3, ~, stats_diff3] = ttest2(diff_TMR, diff_CNT);
        fprintf('Difference between TMR and CNT: t(%d) = %.3f, p = %.4f\n\n', stats_diff3.df, stats_diff3.tstat, p_diff3);
    end

    % Combine data for boxplot
    groupData = [presleepLevelTMRData; postsleepLevelTMRData; presleepTMRData; postsleepTMRData; presleepCNTData; postsleepCNTData];
    groups = [1*ones(size(presleepLevelTMRData)); 2*ones(size(postsleepLevelTMRData)); 3*ones(size(presleepTMRData)); 4*ones(size(postsleepTMRData)); 5*ones(size(presleepCNTData)); 6*ones(size(postsleepCNTData))];

    % Define positions to narrow the gaps within and between TMR and CNT groups
    positions = [1, 1.4, 2.1, 2.5, 3.2, 3.6];  % Further adjust positions to narrow the gaps

    % Boxplot with custom positions and colors
    boxplot(groupData, groups, 'Positions', positions, 'Colors', 'k', 'Widths', 0.4);

    % Apply colors using patches
    h = findobj(gca,'Tag','Box');
    for j=1:length(h)
        patch(get(h(j),'XData'),get(h(j),'YData'),colors{mod(length(h)-j,6)+1},'FaceAlpha',.5); 
    end
    
    box off;
    ax = gca;
    ax.XColor = 'none';

    % Adding scatter points directly on top of the corresponding boxplot
    for j = 1:6
        scatterData = groupData(groups == j);
        scatter(positions(j) * ones(size(scatterData, 1), 1), scatterData, 20, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors{j});
    end
    
    % Adjusting x-axis to center the boxplots and control gaps
    xMiddle = mean(positions); 
    xWidth = positions(end) - positions(1) + 1;
    set(gca, 'XLim', [xMiddle - xWidth/2, xMiddle + xWidth/2]);

    % Customize plot
    set(gca, 'XTick', [1.2, 2.3, 3.4], 'XTickLabel', {'Adaptive TMR', 'TMR', 'CNT'});  
    ylabel('Accuracy (%)');
    ylim(y_lim{i});
    yticks(y_ticks{i});
    % title(sprintf('Level %d', i));
    hold off;

    set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);
    set(gca,'YLabel',[]);
end

%% Statistical Testing: Presleep vs. Postsleep difference
for i = 1:3 % For each level
    % Calculate differences for TMR and CNT
    differencesLTMR = postsleepRates{i, 1} - presleepRates{i, 1};
    differencesTMR = postsleepRates{i, 2} - presleepRates{i, 2};
    differencesCNT = postsleepRates{i, 3} - presleepRates{i, 3};

    validIndicesLTMR = ~isnan(differencesLTMR);
    validDifferencesLTMR = differencesLTMR(validIndicesLTMR); 

    validIndicesTMR = ~isnan(differencesTMR); 
    validDifferencesTMR = differencesTMR(validIndicesTMR); 

    validIndicesCNT = ~isnan(differencesCNT);
    validDifferencesCNT = differencesCNT(validIndicesCNT);


    all_diff_data = [validDifferencesLTMR; validDifferencesTMR; validDifferencesCNT];
    group_labels = [ones(size(validDifferencesLTMR)); 2*ones(size(validDifferencesTMR)); 3*ones(size(validDifferencesCNT))];

    [p_anova, tbl_anova, stats_anova] = anova1(all_diff_data, group_labels, 'off');
    fprintf('Level %d: ANOVA1 for group differences, F(%d, %d) = %.3f, p = %.4f\n\n', i, tbl_anova{2,3}, tbl_anova{3,3}, tbl_anova{2,5}, p_anova);

    % Post-hoc analysis if ANOVA is significant
    if p_anova < 0.05
        fprintf('Level %d: Performing post-hoc t-tests for significant ANOVA...\n', i);
        
        % Post-hoc t-test comparisons
        [h1, p1, ci1, stat1] = ttest2(validDifferencesLTMR, validDifferencesTMR);
        [h2, p2, ci2, stat2] = ttest2(validDifferencesLTMR, validDifferencesCNT);
        [h3, p3, ci3, stat3] = ttest2(validDifferencesTMR, validDifferencesCNT);
        
        % Print results with t-value and p-value
        fprintf('Level %d: LTMR vs. TMR difference comparison, t-value = %.4f, p-value = %.4f\n', i, stat1.tstat, p1);
        fprintf('Level %d: LTMR vs. CNT difference comparison, t-value = %.4f, p-value = %.4f\n', i, stat2.tstat, p2);
        fprintf('Level %d: TMR vs. CNT difference comparison, t-value = %.4f, p-value = %.4f\n\n', i, stat3.tstat, p3);
    end

    if i == 3
        Adaptive_TMR = differencesLTMR;
        TMR = differencesTMR;
        CNT = differencesCNT;
   
        save([path_new 'Analysis\Sleep\Correlation\BA_Diff_Level' num2str(i) '.mat'], 'Adaptive_TMR', 'TMR', 'CNT');
    end
end

%% Plot
y_lim = {[-15 35], [-20 80], [-5 15]};
y_ticks = {[-15 -5 5 15 25 35], [-20 0 20 40 60 80], [-5 0 5 10 15]};

for i = 1:3  % For each level
    figure; % New figure for each level
    hold on;
    
    % Calculate differences for TMR and CNT
    differencesLevelTMR = postsleepRates{i, 1} - presleepRates{i, 1};
    differencesTMR = postsleepRates{i, 2} - presleepRates{i, 2};
    differencesCNT = postsleepRates{i, 3} - presleepRates{i, 3};
    
    validDifferencesLevelTMR = differencesLevelTMR(~isnan(differencesLevelTMR)); 
    validDifferencesTMR = differencesTMR(~isnan(differencesTMR)); 
    validDifferencesCNT = differencesCNT(~isnan(differencesCNT)); 

    % Combine data for boxplot
    groupData = [validDifferencesLevelTMR; validDifferencesTMR; validDifferencesCNT];
    groups = [ones(size(validDifferencesLevelTMR)); 2*ones(size(validDifferencesTMR)); 3*ones(size(validDifferencesCNT))];
    bp = boxplot(groupData, groups, 'Colors', 'k', 'Widths', 0.4);

    % Apply colors using patches
    h = findobj(gca,'Tag','Box');
    colors = {[0.315 0.315 0.315], [0.7 0.2 0.1], [0 0.3 0.6]}; 
    for j = 1:length(h)
        patchColor = colors{j};  % Color cycling between the defined colors
        patch(get(h(j),'XData'),get(h(j),'YData'),patchColor,'FaceAlpha',.5);
    end
    
    box off; 
    ax = gca;
    ax.XColor = 'none';

    % Adjust the x-axis to center the boxplots in the figure
    set(gca, 'XLim', [0.5 3.5], 'XTick', [1, 2, 3], 'XTickLabel', {'Adaptive TMR', 'TMR', 'CNT'});
    
    colors = {[0 0.3 0.6], [0.7 0.2 0.1],[0.315 0.315 0.315]}; 
    % Adding scatter plot on the same figure
    scatter(ones(size(validDifferencesLevelTMR)), validDifferencesLevelTMR, 20, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors{1});
    scatter(2*ones(size(validDifferencesTMR)), validDifferencesTMR, 20, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors{2});
    scatter(3*ones(size(validDifferencesCNT)), validDifferencesCNT, 20, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors{3});
    
    % Customize plot
    ylabel('Difference in accuracy (%)');
    ylim(y_lim{i});
    yticks(y_ticks{i});
    % title(sprintf('Level %d', i));
    hold off;

    set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);
    set(gca,'YLabel',[]);

end
