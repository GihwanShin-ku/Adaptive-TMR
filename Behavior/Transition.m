%% init
clear; clc; close all

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Data\Behavior\'];

%% data load
groups = {'Adaptive_TMR', 'TMR', 'CNT'};
Time = {'retrieval_1.txt', 'retrieval_2.txt'};

changesCountLTMR = struct();
changesCountTMR = struct();
changesCountCNT = struct();
changesCountTotal = struct();  % Struct to track overall changes

% Predefine all possible transitions
levels = 1:3; % Assuming there are three levels: 1, 2, 3
correct = 0:1; % Assuming there are two states: correct (1) or incorrect (0)

% Generate all possible combinations for transitions
allTransitions = {};
for preLevel = levels
    for preCorrect = correct
        for postLevel = levels
            for postCorrect = correct
                transition = sprintf('L%d_%d_to_L%d_%d', preLevel, preCorrect, postLevel, postCorrect);
                allTransitions{end+1} = transition;
                changesCountTotal.(transition) = 0;  % Initialize all possible transitions to zero
                changesCountLTMR.(transition) = 0;
                changesCountTMR.(transition) = 0;
                changesCountCNT.(transition) = 0;
            end
        end
    end
end

ltmrIndex = 0;
tmrIndex = 0;
cntIndex = 0;

ltmrData = zeros(length(allTransitions), 1);
tmrData = zeros(length(allTransitions), 1);
cntData = zeros(length(allTransitions), 1);

for g = 1:length(groups)
    groupPath = fullfile(path, groups{g});
    subjects = dir(fullfile(groupPath, 'sub*')); 
    subjectNames = {subjects.name};

    for n = 1:length(subjectNames)
        subPath = fullfile(groupPath, subjectNames{n});
    
        % Initialize data before processing each file
        presleepData = [];
        postsleepData = [];
        
        tempLTMR = zeros(length(allTransitions), 1);
        tempTMR = zeros(length(allTransitions), 1);
        tempCNT = zeros(length(allTransitions), 1);
        
        % Load and process Presleep and Postsleep data
        for t = 1:length(Time)
            filePath = fullfile(subPath, Time{t});
            
            fileID = fopen(filePath);
            WM_recall = textscan(fileID, '%d %d %d %s %s %s %s %d %d', 'HeaderLines', 1);
            fclose(fileID);
            orders = WM_recall{3};
            levels = WM_recall{8};
            correctNums = WM_recall{1};
    
            for i = 1:length(orders)
                newStruct = struct('Order', orders(i), 'Level', levels(i), 'Correct', correctNums(i));
                if t == 1  % Presleep data
                    presleepData = [presleepData; newStruct];
                else  % Postsleep data
                    postsleepData = [postsleepData; newStruct];
                end
            end
        end
    
        % Calculate changes between Presleep and Postsleep data
        for i = 1:length(presleepData)
            pre = presleepData(i);
            postIndex = find([postsleepData.Order] == pre.Order, 1, 'first');
            if ~isempty(postIndex)
                post = postsleepData(postIndex);
                changeKey = sprintf('L%d_%d_to_L%d_%d', pre.Level, pre.Correct, post.Level, post.Correct);
                
                % Aggregate overall changes
                changesCountTotal.(changeKey) = changesCountTotal.(changeKey) + 1;
    
                index = find(strcmp(allTransitions, changeKey));
                % Group-specific changes
                if g == 1
                    tempLTMR(index) = tempLTMR(index) + 1;
                    changesCountLTMR.(changeKey) = changesCountLTMR.(changeKey) + 1;   
                elseif g == 2
                    tempTMR(index) = tempTMR(index) + 1;
                    changesCountTMR.(changeKey) = changesCountTMR.(changeKey) + 1;
                else
                    tempCNT(index) = tempCNT(index) + 1;
                    changesCountCNT.(changeKey) = changesCountCNT.(changeKey) + 1;         
                end
            end
        end
        
        if g == 1
            ltmrIndex = ltmrIndex + 1;
            ltmrData(:,ltmrIndex) = tempLTMR;
        elseif g == 2
            tmrIndex = tmrIndex + 1;
            tmrData(:,tmrIndex) = tempTMR;
        else
            cntIndex = cntIndex + 1;
            cntData(:,cntIndex) = tempCNT;
        end
    end
end
% Prepare data in 'X' format
X = cell(length(allTransitions), 4);  % Initialize cell array for conditions and counts

for i = 1:length(allTransitions)
    transition = allTransitions{i};
    X{i, 1} = transition;  % Condition name
    X{i, 2} = changesCountLTMR.(transition);  % Adaptive_TMR count
    X{i, 3} = changesCountTMR.(transition);  % TMR count
    X{i, 4} = changesCountCNT.(transition);  % CNT count
end

conditions = X(:,1);
Adaptive_TMR = cell2mat(X(:,2));
TMR = cell2mat(X(:,3));
CNT = cell2mat(X(:,4));

presleep = cellfun(@(x) x(1:4), conditions, 'UniformOutput', false); 
postsleep = cellfun(@(x) x(9:end), conditions, 'UniformOutput', false); 

uniquePresleep = unique(presleep);
uniquePostsleep = unique(postsleep);

Adaptive_TMR_matrix = zeros(length(uniquePresleep), length(uniquePostsleep));
TMR_matrix = zeros(length(uniquePresleep), length(uniquePostsleep));
CNT_matrix = zeros(length(uniquePresleep), length(uniquePostsleep));

for i = 1:length(presleep)
    presleepIdx = find(strcmp(uniquePresleep, presleep{i}));
    postsleepIdx = find(strcmp(uniquePostsleep, postsleep{i}));
    Adaptive_TMR_matrix(presleepIdx, postsleepIdx) = Adaptive_TMR(i);
    TMR_matrix(presleepIdx, postsleepIdx) = TMR(i);
    CNT_matrix(presleepIdx, postsleepIdx) = CNT(i);
end

totalLTMR = sum(Adaptive_TMR(:));
totalTMR = sum(TMR(:));
totalCNT = sum(CNT(:));

LTMR_ratio = (Adaptive_TMR_matrix / totalLTMR)*100;
TMR_ratio = (TMR_matrix / totalTMR)*100;
CNT_ratio = (CNT_matrix / totalCNT)*100;

Ratio_difference = TMR_ratio - CNT_ratio;

desiredOrder = {'L1_1', 'L2_1', 'L3_1', 'L1_0', 'L2_0', 'L3_0'};

[~, newOrderIdxPresleep] = ismember(desiredOrder, uniquePresleep);
[~, newOrderIdxPostsleep] = ismember(desiredOrder, uniquePostsleep);

LTMR_matrix_reordered = Adaptive_TMR_matrix(newOrderIdxPresleep, newOrderIdxPostsleep);
TMR_matrix_reordered = TMR_matrix(newOrderIdxPresleep, newOrderIdxPostsleep);
CNT_matrix_reordered = CNT_matrix(newOrderIdxPresleep, newOrderIdxPostsleep);

LTMR_ratio_reordered = LTMR_ratio(newOrderIdxPresleep, newOrderIdxPostsleep);
TMR_ratio_reordered = TMR_ratio(newOrderIdxPresleep, newOrderIdxPostsleep);
CNT_ratio_reordered = CNT_ratio(newOrderIdxPresleep, newOrderIdxPostsleep);

Ratio_difference_reordered = TMR_ratio_reordered - CNT_ratio_reordered;

%% Ratio
numSubjectsLTMR = size(ltmrData, 2);
numSubjectsTMR = size(tmrData, 2);
numSubjectsCNT = size(cntData, 2);

Adaptive_TMR_SubjectRatios = zeros(length(desiredOrder), length(desiredOrder), numSubjectsLTMR);
TMR_SubjectRatios = zeros(length(desiredOrder), length(desiredOrder), numSubjectsTMR);
CNT_SubjectRatios = zeros(length(desiredOrder), length(desiredOrder), numSubjectsCNT);

LTMR_QuadrantSums = zeros(2, 2, numSubjectsLTMR);
TMR_QuadrantSums = zeros(2, 2, numSubjectsTMR);
CNT_QuadrantSums = zeros(2, 2, numSubjectsCNT);

for s = 1:numSubjectsLTMR
    tempMatrix = zeros(length(uniquePresleep), length(uniquePostsleep));
    for i = 1:length(presleep)
        presleepIdx = find(strcmp(uniquePresleep, presleep{i}));
        postsleepIdx = find(strcmp(uniquePostsleep, postsleep{i}));
        tempMatrix(presleepIdx, postsleepIdx) = ltmrData(i, s);
    end
    total = sum(tempMatrix(:));
    tempRatio = (tempMatrix / total) * 100;
    Adaptive_TMR_SubjectRatios(:,:,s) = tempRatio(newOrderIdxPresleep, newOrderIdxPostsleep);

    LTMR_QuadrantSums(1, 1, s) = sum(sum(Adaptive_TMR_SubjectRatios(1:3, 1:3, s))); % hits
    LTMR_QuadrantSums(1, 2, s) = sum(sum(Adaptive_TMR_SubjectRatios(1:3, 4:6, s))); % miss
    LTMR_QuadrantSums(2, 1, s) = sum(sum(Adaptive_TMR_SubjectRatios(4:6, 1:3, s))); % correct rejections
    LTMR_QuadrantSums(2, 2, s) = sum(sum(Adaptive_TMR_SubjectRatios(4:6, 4:6, s))); % false alarms
end

for s = 1:numSubjectsTMR
    tempMatrix = zeros(length(uniquePresleep), length(uniquePostsleep));
    for i = 1:length(presleep)
        presleepIdx = find(strcmp(uniquePresleep, presleep{i}));
        postsleepIdx = find(strcmp(uniquePostsleep, postsleep{i}));
        tempMatrix(presleepIdx, postsleepIdx) = tmrData(i, s);
    end
    total = sum(tempMatrix(:));
    tempRatio = (tempMatrix / total) * 100;
    TMR_SubjectRatios(:,:,s) = tempRatio(newOrderIdxPresleep, newOrderIdxPostsleep);

    TMR_QuadrantSums(1, 1, s) = sum(sum(TMR_SubjectRatios(1:3, 1:3, s)));
    TMR_QuadrantSums(1, 2, s) = sum(sum(TMR_SubjectRatios(1:3, 4:6, s)));
    TMR_QuadrantSums(2, 1, s) = sum(sum(TMR_SubjectRatios(4:6, 1:3, s)));
    TMR_QuadrantSums(2, 2, s) = sum(sum(TMR_SubjectRatios(4:6, 4:6, s)));
end

for s = 1:numSubjectsCNT
    tempMatrix = zeros(length(uniquePresleep), length(uniquePostsleep));
    for i = 1:length(presleep)
        presleepIdx = find(strcmp(uniquePresleep, presleep{i}));
        postsleepIdx = find(strcmp(uniquePostsleep, postsleep{i}));
        tempMatrix(presleepIdx, postsleepIdx) = cntData(i, s);
    end
    total = sum(tempMatrix(:));
    tempRatio = (tempMatrix / total) * 100;
    CNT_SubjectRatios(:,:,s) = tempRatio(newOrderIdxPresleep, newOrderIdxPostsleep);

    CNT_QuadrantSums(1, 1, s) = sum(sum(CNT_SubjectRatios(1:3, 1:3, s)));
    CNT_QuadrantSums(1, 2, s) = sum(sum(CNT_SubjectRatios(1:3, 4:6, s)));
    CNT_QuadrantSums(2, 1, s) = sum(sum(CNT_SubjectRatios(4:6, 1:3, s)));
    CNT_QuadrantSums(2, 2, s) = sum(sum(CNT_SubjectRatios(4:6, 4:6, s)));
end

for q1 = 1:2
    for q2 = 1:2
        LTMR_avg(q1,q2) = mean(squeeze(LTMR_QuadrantSums(q1,q2,:)));
        TMR_avg(q1,q2) = mean(squeeze(TMR_QuadrantSums(q1,q2,:)));
        CNT_avg(q1,q2) = mean(squeeze(CNT_QuadrantSums(q1,q2,:)));

        all_data = [squeeze(LTMR_QuadrantSums(q1,q2,:)); squeeze(TMR_QuadrantSums(q1,q2,:)); squeeze(CNT_QuadrantSums(q1,q2,:))];
        group_labels = [ones(size(squeeze(LTMR_QuadrantSums(q1,q2,:)))); 2*ones(size(squeeze(TMR_QuadrantSums(q1,q2,:)))); 3*ones(size(squeeze(CNT_QuadrantSums(q1,q2,:))))];

        [p_anova, tbl_anova, stats_anova] = anova1(all_data, group_labels, 'off');
        fprintf('Quadrant (%d, %d): ANOVA1 for group differences, F(%d, %d) = %.3f, p = %.4f\n', q1, q2, tbl_anova{2,3}, tbl_anova{3,3}, tbl_anova{2,5}, p_anova);

        % Post-hoc analysis if ANOVA is significant
        if p_anova < 0.05
            fprintf('Quadrant (%d, %d): Performing post-hoc t-tests for significant ANOVA...\n', q1, q2);

            % Post-hoc t-test comparisons
            [h1, p1, ci1, stats1] = ttest2(squeeze(LTMR_QuadrantSums(q1,q2,:)),squeeze(TMR_QuadrantSums(q1,q2,:)));
            t_quad1(q1,q2) = stats1.tstat;
            p_quad1(q1,q2) = p1;
            fprintf('Quadrant (%d, %d): LTMR vs. TMR, t = %.3f, p = %.4f\n', q1, q2, t_quad1(q1,q2), p_quad1(q1,q2));

            [h2, p2, ci2, stats2] = ttest2(squeeze(LTMR_QuadrantSums(q1,q2,:)),squeeze(CNT_QuadrantSums(q1,q2,:)));
            t_quad2(q1,q2) = stats2.tstat;
            p_quad2(q1,q2) = p2;
            fprintf('Quadrant (%d, %d): LTMR vs. CNT, t = %.3f, p = %.4f\n', q1, q2, t_quad2(q1,q2), p_quad2(q1,q2));

            [h3, p3, ci3, stats3] = ttest2(squeeze(TMR_QuadrantSums(q1,q2,:)),squeeze(CNT_QuadrantSums(q1,q2,:)));
            t_quad3(q1,q2) = stats3.tstat;
            p_quad3(q1,q2) = p3;
            fprintf('Quadrant (%d, %d): TMR vs. CNT, t = %.3f, p = %.4f\n\n', q1, q2, t_quad3(q1,q2), p_quad3(q1,q2));
        end
    end
end

% SAVE
Adaptive_TMR = squeeze(LTMR_QuadrantSums(2,1,:));
TMR = squeeze(TMR_QuadrantSums(2,1,:));
CNT = squeeze(CNT_QuadrantSums(2,1,:));
save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'BA_IC_ALL'], 'Adaptive_TMR','TMR','CNT');

Adaptive_TMR = squeeze(LTMR_QuadrantSums(2,2,:));
TMR = squeeze(TMR_QuadrantSums(2,2,:));
CNT = squeeze(CNT_QuadrantSums(2,2,:));
save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'BA_II_ALL'], 'Adaptive_TMR','TMR','CNT');

for s = 1:numSubjectsLTMR
    for level = 1:3
        rowHitsMisses = level; 
        rowCRFA = level + 3;  

        Adaptive_TMR_Level_QuadrantSums(1, 1, level, s) = sum(sum(Adaptive_TMR_SubjectRatios(rowHitsMisses, 1:3, s))); % Hits
        Adaptive_TMR_Level_QuadrantSums(1, 2, level, s) = sum(sum(Adaptive_TMR_SubjectRatios(rowHitsMisses, 4:6, s))); % Misses
        Adaptive_TMR_Level_QuadrantSums(2, 1, level, s) = sum(sum(Adaptive_TMR_SubjectRatios(rowCRFA, 1:3, s))); % Correct Rejections
        Adaptive_TMR_Level_QuadrantSums(2, 2, level, s) = sum(sum(Adaptive_TMR_SubjectRatios(rowCRFA, 4:6, s))); % False Alarms
    end
end

for s = 1:numSubjectsTMR
    for level = 1:3
        rowHitsMisses = level;  
        rowCRFA = level + 3;  

        TMR_Level_QuadrantSums(1, 1, level, s) = sum(sum(TMR_SubjectRatios(rowHitsMisses, 1:3, s)));
        TMR_Level_QuadrantSums(1, 2, level, s) = sum(sum(TMR_SubjectRatios(rowHitsMisses, 4:6, s)));
        TMR_Level_QuadrantSums(2, 1, level, s) = sum(sum(TMR_SubjectRatios(rowCRFA, 1:3, s)));
        TMR_Level_QuadrantSums(2, 2, level, s) = sum(sum(TMR_SubjectRatios(rowCRFA, 4:6, s)));
    end
end

for s = 1:numSubjectsCNT
    for level = 1:3
        rowHitsMisses = level;  
        rowCRFA = level + 3;  

        CNT_Level_QuadrantSums(1, 1, level, s) = sum(sum(CNT_SubjectRatios(rowHitsMisses, 1:3, s)));
        CNT_Level_QuadrantSums(1, 2, level, s) = sum(sum(CNT_SubjectRatios(rowHitsMisses, 4:6, s)));
        CNT_Level_QuadrantSums(2, 1, level, s) = sum(sum(CNT_SubjectRatios(rowCRFA, 1:3, s)));
        CNT_Level_QuadrantSums(2, 2, level, s) = sum(sum(CNT_SubjectRatios(rowCRFA, 4:6, s)));
    end
end

numLevels = 3;
numQuadrants = 2;

t_LTMRTMR = zeros(numQuadrants, numQuadrants, numLevels);
p_LTMRTMR = zeros(numQuadrants, numQuadrants, numLevels);
t_LTMRCNT = zeros(numQuadrants, numQuadrants, numLevels);
p_LTMRCNT = zeros(numQuadrants, numQuadrants, numLevels);
t_TMRCNT = zeros(numQuadrants, numQuadrants, numLevels);
p_TMRCNT = zeros(numQuadrants, numQuadrants, numLevels);

% Level
for level = 1:numLevels
    for q1 = 1:numQuadrants
        for q2 = 1:numQuadrants
            L_LTMR_avg(q1,q2,level) = mean(squeeze(Adaptive_TMR_Level_QuadrantSums(q1,q2,level,:)));
            L_TMR_avg(q1,q2,level) = mean(squeeze(TMR_Level_QuadrantSums(q1,q2,level,:)));
            L_CNT_avg(q1,q2,level) = mean(squeeze(CNT_Level_QuadrantSums(q1,q2,level,:)));

            all_data = [squeeze(Adaptive_TMR_Level_QuadrantSums(q1, q2, level, :)); squeeze(TMR_Level_QuadrantSums(q1, q2, level, :)); squeeze(CNT_Level_QuadrantSums(q1, q2, level, :))];
            group_labels = [ones(size(squeeze(Adaptive_TMR_Level_QuadrantSums(q1, q2, level, :)))); 2*ones(size(squeeze(TMR_Level_QuadrantSums(q1, q2, level, :)))); 3*ones(size(squeeze(CNT_Level_QuadrantSums(q1, q2, level, :))))];

            [p_anova, tbl_anova, stats_anova] = anova1(all_data, group_labels, 'off');
            fprintf('Level %d, Quadrant (%d, %d): ANOVA1 for group differences, F(%d, %d) = %.3f, p = %.4f\n', level, q1, q2, tbl_anova{2,3}, tbl_anova{3,3}, tbl_anova{2,5}, p_anova);

            % Post-hoc analysis if ANOVA is significant
            if p_anova < 0.05
                fprintf('Level %d, Quadrant (%d, %d): Performing post-hoc t-tests for significant ANOVA...\n', level, q1, q2);

                % Post-hoc t-test comparisons
                [h1, p1, ci1, stats1] = ttest2(squeeze(Adaptive_TMR_Level_QuadrantSums(q1, q2, level, :)), squeeze(TMR_Level_QuadrantSums(q1, q2, level, :)));
                t_LTMRTMR(q1, q2, level) = stats1.tstat;
                p_LTMRTMR(q1, q2, level) = p1;
                fprintf('Level %d, Quadrant (%d, %d): LTMR vs. TMR, t = %.3f, p = %.4f\n', level, q1, q2, t_LTMRTMR(q1, q2, level), p_LTMRTMR(q1, q2, level));

                [h2, p2, ci2, stats2] = ttest2(squeeze(Adaptive_TMR_Level_QuadrantSums(q1, q2, level, :)), squeeze(CNT_Level_QuadrantSums(q1, q2, level, :)));
                t_LTMRCNT(q1, q2, level) = stats2.tstat;
                p_LTMRCNT(q1, q2, level) = p2;
                fprintf('Level %d, Quadrant (%d, %d): LTMR vs. CNT, t = %.3f, p = %.4f\n', level, q1, q2, t_LTMRCNT(q1, q2, level), p_LTMRCNT(q1, q2, level));

                [h3, p3, ci3, stats3] = ttest2(squeeze(TMR_Level_QuadrantSums(q1, q2, level, :)), squeeze(CNT_Level_QuadrantSums(q1, q2, level, :)));
                t_TMRCNT(q1, q2, level) = stats3.tstat;
                p_TMRCNT(q1, q2, level) = p3;
                fprintf('Level %d, Quadrant (%d, %d): TMR vs. CNT, t = %.3f, p = %.4f\n', level, q1, q2, t_TMRCNT(q1, q2, level), p_TMRCNT(q1, q2, level));
            end
        end
    end
    fprintf('\n');
end

% SAVE
Adaptive_TMR = squeeze(Adaptive_TMR_Level_QuadrantSums(2,1,3,:));
TMR = squeeze(TMR_Level_QuadrantSums(2,1,3,:));
CNT = squeeze(CNT_Level_QuadrantSums(2,1,3,:));
save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'BA_IC_Level3'], 'Adaptive_TMR','TMR','CNT');

Adaptive_TMR = squeeze(Adaptive_TMR_Level_QuadrantSums(2,2,3,:));
TMR = squeeze(TMR_Level_QuadrantSums(2,2,3,:));
CNT = squeeze(CNT_Level_QuadrantSums(2,2,3,:));
save(['D:\Dropbox\TMR\Analysis\Sleep\Correlation\' 'BA_II_Level3'], 'Adaptive_TMR','TMR','CNT');

%% Heatmap
mycolormap = customcolormap([1 0.5 0], [0 0 0; 1 0 0; 1 1 1]);

figure;
FS = 10;

desiredOrder = {'L1-O', 'L2-O', 'L3-O', 'L1-X', 'L2-X', 'L3-X'};

% Leve_TMR 
subplot(1, 3, 1);
h1= heatmap(desiredOrder, desiredOrder, LTMR_ratio_reordered);
% title('Adaptive TMR Ratio Heatmap');
% xlabel('Postsleep');
% ylabel('Presleep');
h1.XLabel = '';
h1.YLabel = '';
h1.Title = '';
colormap(h1, mycolormap);
colorbar('off')
h1.FontSize = FS; 
caxis([0,60])

h1.XDisplayLabels = repmat({''}, size(h1.XDisplayLabels));
h1.YDisplayLabels = repmat({''}, size(h1.YDisplayLabels));
h1.CellLabelColor = 'none'; 

% TMR 
subplot(1, 3, 2);
h2= heatmap(desiredOrder, desiredOrder, TMR_ratio_reordered);
% title('TMR Ratio Heatmap');
% xlabel('Postsleep');
% ylabel('Presleep');
h2.XLabel = '';
h2.YLabel = '';
h2.Title = '';
colormap(h2, mycolormap);
colorbar('off')
h2.FontSize = FS; 
caxis([0,60])

h2.XDisplayLabels = repmat({''}, size(h2.XDisplayLabels));
h2.YDisplayLabels = repmat({''}, size(h2.YDisplayLabels));
h2.CellLabelColor = 'none'; 

% CNT 
subplot(1, 3, 3);
h3= heatmap(desiredOrder, desiredOrder, CNT_ratio_reordered);
% title('CNT Ratio Heatmap');
% xlabel('Postsleep');
% ylabel('Presleep');
h3.XLabel = '';
h3.YLabel = '';
h3.Title = '';
colormap(h3, mycolormap);
colorbar('off')
h3.FontSize = FS; 
caxis([0,60])

h3.XDisplayLabels = repmat({''}, size(h3.XDisplayLabels));
h3.YDisplayLabels = repmat({''}, size(h3.YDisplayLabels));
h3.CellLabelColor = 'none'; 

%% Barplot
figure;
barWidth = 1;  
groupSpacing = 1;  
colors = {[0 0.3 0.6], [0.7 0.2 0.1],[0.315 0.315 0.315]};  

groupNames = {'Adaptive_TMR', 'TMR', 'CNT'};
numGroups = length(groupNames);

levelTransitionIndices = {
    {  % All
        [1 2 3; 1 2 3],  % CC
        [1 2 3; 4 5 6],  % CI
        [4 5 6; 1 2 3],  % IC
        [4 5 6; 4 5 6]   % II
    },
    {  % Level 1
        [1 1 1; 1 2 3],  % CC
        [1 1 1; 4 5 6],  % CI
        [4 4 4; 1 2 3],  % IC
        [4 4 4; 4 5 6]   % II
    },
    {  % Level 2
        [2 2 2; 1 2 3],  % CC
        [2 2 2; 4 5 6],  % CI
        [5 5 5; 1 2 3],  % IC
        [5 5 5; 4 5 6]   % II
    },
    {  % Level 3
        [3 3 3; 1 2 3],  % CC
        [3 3 3; 4 5 6],  % CI
        [6 6 6; 1 2 3],  % IC
        [6 6 6; 4 5 6]   % II
    }
};


levelNames = {'All', 'Level 1', 'Level 2', 'Level 3'};
transitionNames = {'Correct to Correct (CC)', 'Correct to Incorrect (CI)', 'Incorrect to Correct (IC)', 'Incorrect to Incorrect (II)'};

y_lim = {[0 25], [0 2.5], [0 30], [0 80]};
y_ticks = {[0 5 10 15 20 25],[0 0.5 1.0 1.5 2.0 2.5],[0 10 20 30],[0 20 40 60 80]};
for k = 1:length(transitionNames)  
    subplot(1, 4, k);
    hold on;
    % title(transitionNames{k});
    
    for j = 1:length(levelNames) 
        transIndices = levelTransitionIndices{j}{k};  
        for g = 1:numGroups 
            groupData = eval(sprintf('%s_SubjectRatios', groupNames{g}));
            numSubjects = size(groupData, 3);
            subjectRatios = zeros(numSubjects, 1);
            
            for s = 1:numSubjects
                if j == 1
                    transitionCount = sum(groupData(transIndices(1,:), transIndices(2,:), s), 'all'); 
                else
                    transitionCount = sum(groupData(transIndices(1,1), transIndices(2,:), s), 'all');  
                end
                totalTransitions = sum(groupData(:, :, s), 'all');  
                subjectRatios(s) = (transitionCount / totalTransitions) * 100; 
            end
            
            group_avg = mean(subjectRatios);  
            group_sem = std(subjectRatios) / sqrt(numSubjects);  
            
            x = (j-1) * (numGroups * barWidth + groupSpacing) + (g - 2) * barWidth + (numGroups - 2) * barWidth;
            bar(x, group_avg, barWidth, 'FaceColor', colors{g}, 'FaceAlpha', 0.5);
           
            eb = errorbar(x, group_avg, 0, group_sem, 'k', 'linestyle', 'none', 'LineWidth', 1.2);
            eb.Annotation.LegendInformation.IconDisplayStyle = 'off';  
        end
    end

    box off; 
    
    ax = gca;
    ax.XColor = 'none';    
    ax.XAxis.Color = 'none'; 
    ax.XAxis.TickLength = [0 0]; 

    set(gca, 'YTickLabel', []);
    set(gca, 'XTickLabel', []);
    ylabel('');

    ylim(y_lim{k});
    yticks(y_ticks{k});    
    % if k == 1
    %     legend('Adaptive TMR', 'TMR', 'CNT', 'Location', 'best'); 
    % end

    h = findobj(gca,'Type','line');
    set(h, 'LineStyle', 'none'); 
    hold off;
end
