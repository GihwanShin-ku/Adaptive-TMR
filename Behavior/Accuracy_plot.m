%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Behavior\'];

%% Load Data
load([path 'ACC.mat']);  % Working Memory accuracy

%% Prepare Data for ANOVA
% Extract and organize accuracy and reaction time data by group and time
acc_Adaptive_TMR = ACC.Adaptive_TMR;
acc_TMR = ACC.TMR;
acc_con = ACC.CNT;

%% Two-Way ANOVA Setup
subjects_per_group = size(acc_Adaptive_TMR, 1);
num_groups = 3;  % Number of groups: Adaptive TMR, TMR, Control

% Combine all accuracy data into one vector
all_acc_data = [acc_Adaptive_TMR(:, 1); acc_TMR(:, 1); acc_con(:, 1);  % Pre
                acc_Adaptive_TMR(:, 2); acc_TMR(:, 2); acc_con(:, 2)]; % Post

% Create group vector (1: Adaptive_TMR, 2: TMR, 3: Control)
all_groups = [ones(size(acc_Adaptive_TMR, 1), 1); ...  % Pre for Adaptive_TMR
              2 * ones(size(acc_TMR, 1), 1); ...    % Pre for TMR
              3 * ones(size(acc_con, 1), 1); ...    % Pre for Control
              ones(size(acc_Adaptive_TMR, 1), 1); ...  % Post for Adaptive_TMR
              2 * ones(size(acc_TMR, 1), 1); ...    % Post for TMR
              3 * ones(size(acc_con, 1), 1)];       % Post for Control

% Create time vector (1: Pre, 2: Post)
all_times = [ones(size(acc_Adaptive_TMR, 1) + size(acc_TMR, 1) + size(acc_con, 1), 1); ... % Pre
             2 * ones(size(acc_Adaptive_TMR, 1) + size(acc_TMR, 1) + size(acc_con, 1), 1)]; % Post

%% Two-Way ANOVA for Pre vs. Post Analysis
% Perform ANOVA
[p_acc, tbl_acc, stats_acc] = anovan(all_acc_data, {all_groups, all_times}, ...
    'model', 'interaction', 'varnames', {'Group', 'Time'}, 'display', 'off');

% Display Results
fprintf('Two-way ANOVA for Accuracy:\n');
fprintf('Group effect: F(%d, %d) = %.3f, p = %.4f\n', tbl_acc{2,3}, tbl_acc{4,3}, tbl_acc{2,6}, tbl_acc{2,7});
fprintf('Time effect: F(%d, %d) = %.3f, p = %.4f\n', tbl_acc{3,3}, tbl_acc{4,3}, tbl_acc{3,6}, tbl_acc{3,7});
fprintf('Interaction effect: F(%d, %d) = %.3f, p = %.4f\n', tbl_acc{4,3}, tbl_acc{4,3}, tbl_acc{4,6}, tbl_acc{4,7});
fprintf('\n');

if p_acc(1) < 0.05  
    fprintf('Significant Group effect found for Accuracy. Performing pairwise t-tests between groups...\n');
    
    % Pre-sleep 
    [hPre1, pPre1, ciPre1, statsPre1] = ttest2(acc_Adaptive_TMR(:, 1), acc_TMR(:, 1));
    [hPre2, pPre2, ciPre2, statsPre2] = ttest2(acc_Adaptive_TMR(:, 1), acc_con(:, 1));
    [hPre3, pPre3, ciPre3, statsPre3] = ttest2(acc_TMR(:, 1), acc_con(:, 1));
    
    % Post-sleep 
    [hPost1, pPost1, ciPost1, statsPost1] = ttest2(acc_Adaptive_TMR(:, 2), acc_TMR(:, 2));
    [hPost2, pPost2, ciPost2, statsPost2] = ttest2(acc_Adaptive_TMR(:, 2), acc_con(:, 2));
    [hPost3, pPost3, ciPost3, statsPost3] = ttest2(acc_TMR(:, 2), acc_con(:, 2));
    
    fprintf('Pre-sleep comparisons:\n');
    fprintf('LTMR vs. TMR: t(%d) = %.3f, p = %.4f\n', statsPre1.df, statsPre1.tstat, pPre1);
    fprintf('LTMR vs. Control: t(%d) = %.3f, p = %.4f\n', statsPre2.df, statsPre2.tstat, pPre2);
    fprintf('TMR vs. Control: t(%d) = %.3f, p = %.4f\n', statsPre3.df, statsPre3.tstat, pPre3);
    
    fprintf('Post-sleep comparisons:\n');
    fprintf('LTMR vs. TMR: t(%d) = %.3f, p = %.4f\n', statsPost1.df, statsPost1.tstat, pPost1);
    fprintf('LTMR vs. Control: t(%d) = %.3f, p = %.4f\n', statsPost2.df, statsPost2.tstat, pPost2);
    fprintf('TMR vs. Control: t(%d) = %.3f, p = %.4f\n', statsPost3.df, statsPost3.tstat, pPost3);
end

fprintf('\n');

if p_acc(2) < 0.05
    fprintf('Significant Time effect found for Accuracy. Performing paired t-tests for each group...\n');
    
    % Paired t-test for each group with t-value
    [h_acc_lvl, p_acc_lvl, ci_acc_lvl, stats_acc_lvl] = ttest(acc_Adaptive_TMR(:, 1), acc_Adaptive_TMR(:, 2));
    fprintf('Adaptive TMR group: t(%d) = %.3f, p = %.4f\n', stats_acc_lvl.df, stats_acc_lvl.tstat, p_acc_lvl);
    
    [h_acc_tmr, p_acc_tmr, ci_acc_tmr, stats_acc_tmr] = ttest(acc_TMR(:, 1), acc_TMR(:, 2));
    fprintf('TMR group: t(%d) = %.3f, p = %.4f\n', stats_acc_tmr.df, stats_acc_tmr.tstat, p_acc_tmr);
    
    [h_acc_con, p_acc_con, ci_acc_con, stats_acc_con] = ttest(acc_con(:, 1), acc_con(:, 2));
    fprintf('Control group: t(%d) = %.3f, p = %.4f\n', stats_acc_con.df, stats_acc_con.tstat, p_acc_con);
end

fprintf('\n');

%% Calculate Differences for One-Way ANOVA
acc_diff_Adaptive_TMR = acc_Adaptive_TMR(:, 2) - acc_Adaptive_TMR(:, 1);
acc_diff_TMR = acc_TMR(:, 2) - acc_TMR(:, 1);
acc_diff_Control = acc_con(:, 2) - acc_con(:, 1);

acc_diff = [acc_diff_Adaptive_TMR; acc_diff_TMR; acc_diff_Control];

Adaptive_TMR = acc_diff_Adaptive_TMR;
TMR = acc_diff_TMR;
CNT = acc_diff_Control;

save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'BA_Diff_ALL'], 'Adaptive_TMR','TMR','CNT');

%% One-Way ANOVA for Differences
group_ids_for_diff = [ones(size(acc_diff_Adaptive_TMR, 1), 1); 2 * ones(size(acc_diff_TMR, 1), 1); 3 * ones(size(acc_diff_Control, 1), 1)];

[p_diff_acc, tbl_diff_acc, stats_diff_acc] = anova1(acc_diff, group_ids_for_diff, 'off');
fprintf('One-way ANOVA for Difference in Accuracy: F(%d, %d) = %.3f, p = %.4f\n', tbl_diff_acc{2,3}, tbl_diff_acc{3,3}, tbl_diff_acc{2,5}, p_diff_acc);

if p_diff_acc < 0.05
    fprintf('ANOVA significant for Differences in Accuracy. Performing pairwise t-tests...\n');
    
    % Pairwise t-tests between groups
    [h12, p12, ci12, stat12] = ttest2(acc_diff_Adaptive_TMR, acc_diff_TMR);
    fprintf('Adaptive TMR vs TMR: t-value = %.4f, p-value = %.4f\n', stat12.tstat, p12);
    
    [h13, p13, ci13, stat13] = ttest2(acc_diff_Adaptive_TMR, acc_diff_Control);
    fprintf('Adaptive TMR vs Control: t-value = %.4f, p-value = %.4f\n', stat13.tstat, p13);
    
    [h23, p23, ci23, stat23] = ttest2(acc_diff_TMR, acc_diff_Control);
    fprintf('TMR vs Control: t-value = %.4f, p-value = %.4f\n', stat23.tstat, p23);
end

fprintf('\n');

%% plot
%% 1. Accuracy for TMR and Control (Pre-sleep vs Post-sleep)

data = [acc_Adaptive_TMR(:,1); acc_Adaptive_TMR(:,2); acc_TMR(:,1); acc_TMR(:,2); acc_con(:,1); acc_con(:,2)];
groups = [repmat(1, size(acc_Adaptive_TMR,1), 1); repmat(2, size(acc_Adaptive_TMR,1), 1);
          repmat(3, size(acc_TMR,1), 1); repmat(4, size(acc_TMR,1), 1);
          repmat(5, size(acc_con,1), 1); repmat(6, size(acc_con,1), 1)];
boxColors = [0.6 0.8 1.0; 0 0.4470 0.7410; 0.9, 0.6, 0.2; 0.8500 0.3250 0.0980; 0.8 0.8 0.8; 0.5 0.5 0.5]; % 색상 지정

positions = [1, 1.5, 2.5, 3.0, 4.0, 4.5];

figure;
h = boxplot(data, groups, 'Widths', 0.4, 'Colors', 'k', 'Positions', positions);
set(gca, 'XTick', [1.25, 2.75, 4.25], 'XTickLabel', {'Adaptive TMR', 'TMR', 'CNT'});
hold on;

for i = 1:6
    patch(get(h(5,i), 'XData'), get(h(5,i), 'YData'), boxColors(i,:), 'FaceAlpha', .5);
end

box off;
ax = gca;
ax.XColor = 'none';

for i = 1:6
    scatter(repmat(positions(i), size(data(groups == i), 1), 1), data(groups == i), 'o', 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', boxColors(i,:));
end

ylabel('Accuracy (%)');
ylim([0 70]);
yticks([0 35 70]);
hold off;
set(gca, 'FontSize', 15); 

set(gca,'YTickLabel',[]);
set(gca,'XTickLabel',[]);
set(gca,'YLabel',[]);


%% 2. Accuracy Difference (Post-sleep - Pre-sleep)
groupLabels = {'Adaptive TMR', 'TMR', 'CNT'};
boxColorsDiff = [0 0.3 0.6; 0.7 0.2 0.1; 0.315 0.315 0.315];

figure;
dataAD = [acc_diff_Adaptive_TMR; acc_diff_TMR; acc_diff_Control];
groupsAD = [ones(length(acc_diff_Adaptive_TMR), 1); 2*ones(length(acc_diff_TMR), 1); 3*ones(length(acc_diff_Control), 1)]; 

hAD = boxplot(dataAD, groupsAD, 'Widths', 0.4, 'Colors', 'k');
set(gca, 'XTickLabel', groupLabels, 'XTick', 1:3);
hold on;

for i = 1:3
    patch(get(hAD(5,i), 'XData'), get(hAD(5,i), 'YData'), boxColorsDiff(i,:), 'FaceAlpha', .5);
end

box off;
ax = gca;
ax.XColor = 'none';

for i = 1:3
    xDataAD = repmat(i, size(dataAD(groupsAD == i), 1), 1);
    scatter(xDataAD, dataAD(groupsAD == i), 'o', 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', boxColorsDiff(i,:));
end

ylabel('Difference in accuracy (%)');
ylim([0 40]);
yticks([0 10 20 30 40]);
hold off;
set(gca, 'FontSize', 15); 

set(gca,'YTickLabel',[]);
set(gca,'XTickLabel',[]);
set(gca,'YLabel',[]);

