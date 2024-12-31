%% init
clc; clear; close all;

rng(1); 

%% path setting
temp = pwd;
list = split(temp, '\');

path = [];
for i = 1:length(list)-2
    path = [path, list{i}, '\'];
end
path = [path 'Analysis\Sleep\TFR\'];

path_save = [];
for i = 1:length(list)-2
    path_save = [path_save, list{i}, '\'];
end
path_save = [path_save 'Analysis\Sleep\Classification\'];

%% data load
groups = {'Adaptive_TMR', 'TMR', 'CNT'}; 
data = struct('Adaptive_TMR', struct('All', {{}}, 'L3', {{}}), ...
              'TMR', struct('All', {{}}, 'L3', {{}}), ...
              'CNT', {{}});

for g = 1:length(groups)
    group_path = fullfile(path, groups{g});
    subjects = dir(fullfile(group_path, '*.mat')); 
    
    for s = 1:length(subjects)
        file_path = fullfile(group_path, subjects(s).name);
        loadedData = load(file_path); 
    
        if isfield(loadedData, 'Adaptive_TMR_ALL_spindle')
            if isfield(loadedData, 'Adaptive_TMR_ALL_trial_spindle')
                data.Adaptive_TMR.All{end+1} = loadedData.Adaptive_TMR_ALL_trial_spindle;  % freq x time x trial x ch
            end
            if isfield(loadedData, 'Adaptive_TMR_ALL_trial_spindle')
                data.Adaptive_TMR.L3{end+1} = loadedData.Adaptive_TMR_L3_trial_spindle;
            end
        end
        
        if isfield(loadedData, 'TMR_ALL_spindle')
            if isfield(loadedData, 'TMR_ALL_trial_spindle')
                data.TMR.All{end+1} = loadedData.TMR_ALL_trial_spindle;
            end
            if isfield(loadedData, 'TMR_ALL_trial_spindle')
                data.TMR.L3{end+1} = loadedData.TMR_L3_trial_spindle;
            end
        end
        
        if isfield(loadedData, 'CNT_spindle')
            if isfield(loadedData, 'CNT_trial_spindle')
                data.CNT{end+1} = loadedData.CNT_trial_spindle;  
            end
        end
    end
end

%% Parameters
levels = {'All', 'Level_3'};
timePoints = 53; 
numFolds = 5; 
numRepeats = 2; 
numSurrogate = 250; 
numPermutations = 1000; 

%% Analysis Loop
results = struct();
for idx = 1:length(levels)
    condition = levels{idx};
    AdaptiveTMRData = [];
    TMRData = [];
    CNTData = [data.CNT];  % Always include CNT

    if strcmp(condition, 'All')
        AdaptiveTMRData = [data.Adaptive_TMR.All];
        TMRData = [data.TMR.All];
    elseif strcmp(condition, 'Level_3')
        AdaptiveTMRData = [data.Adaptive_TMR.L3];
        TMRData = [data.TMR.L3];
    end

    groupData = {AdaptiveTMRData, TMRData, CNTData};

    %% Observed Decoding
    observedAccMatrix = zeros(numRepeats, numFolds, timePoints);
    observedAUCMatrix = zeros(numRepeats, numFolds, timePoints);

    for t = 1:timePoints
        [allData, allLabels] = prepareData(groupData, t);
        [accMatrix, aucMatrix] = performDecoding(allData, allLabels, numFolds, numRepeats);
        observedAccMatrix(:, :, t) = accMatrix;
        observedAUCMatrix(:, :, t) = aucMatrix;
    end

    observedAccMean = mean(observedAccMatrix, [1, 2]);
    observedAccSTE = std(observedAccMatrix, 0, [1, 2]) / sqrt(numRepeats * numFolds); 
    observedAUCMean = mean(observedAUCMatrix, [1, 2]);
    observedAUCSTE = std(observedAUCMatrix, 0, [1, 2]) / sqrt(numRepeats * numFolds); 

    %% Surrogate Decoding
    surrogateAccMatrix = zeros(numRepeats, numFolds, numSurrogate, timePoints);
    surrogateAUCMatrix = zeros(numRepeats, numFolds, numSurrogate, timePoints);

    for s = 1:numSurrogate
        for t = 1:timePoints
            shuffledLabels = shuffleLabels(allLabels);
            [accMatrix, aucMatrix] = performDecoding(allData, shuffledLabels, numFolds, numRepeats);
            surrogateAccMatrix(:, :, s, t) = accMatrix;
            surrogateAUCMatrix(:, :, s, t) = aucMatrix;
        end
    end

    surrogateAccMean = mean(surrogateAccMatrix, [1, 2, 3]);
    surrogateAccSTE = std(surrogateAccMatrix, 0, [1, 2, 3]) / sqrt(numRepeats * numFolds * numSurrogate);
    surrogateAUCMean = mean(surrogateAUCMatrix, [1, 2, 3]);
    surrogateAUCSTE = std(surrogateAUCMatrix, 0, [1, 2, 3]) / sqrt(numRepeats * numFolds * numSurrogate);

    %% Cluster-Based Permutation Test (1000)
    permutationAcc = zeros(numPermutations, timePoints);
    permutationAUC = zeros(numPermutations, timePoints);
    
    for p = 1:numPermutations
        for t = 1:timePoints
            shuffledLabels = shuffleLabels(allLabels);
            [accMatrix, aucMatrix] = performDecoding(allData, shuffledLabels, numFolds, numRepeats);
            permutationAcc(p, t) = mean(accMatrix, 'all'); 
            permutationAUC(p, t) = mean(aucMatrix, 'all');
        end
    end

    %% Cluster-Based Correction
    clusterPAcc = calculateClusterP(squeeze(observedAccMean), permutationAcc);
    clusterPAUC = calculateClusterP(squeeze(observedAUCMean), permutationAUC);

    %% Save Results
    results.(condition).accuracyMean = observedAccMean;
    results.(condition).accuracySTE = observedAccSTE;
    results.(condition).aucMean = observedAUCMean;
    results.(condition).aucSTE = observedAUCSTE;
    results.(condition).surrogateAccuracyMean = surrogateAccMean;
    results.(condition).surrogateAccuracySTE = surrogateAccSTE;
    results.(condition).surrogateAUCMean = surrogateAUCMean;
    results.(condition).surrogateAUCSTE = surrogateAUCSTE;
    results.(condition).clusterPAcc = clusterPAcc;
    results.(condition).clusterPAUC = clusterPAUC;
end

%% Save Results
savePath = fullfile(path_save, 'SS_SVM_rbf.mat'); 
save(savePath, 'results'); 

%% Helper Functions
function [data, labels] = prepareData(groupData, t)
    data = []; labels = [];
    for g = 1:length(groupData)
        for s = 1:length(groupData{g})
            trialData = squeeze(mean(groupData{g}{s}(:, t, :, :), 3)); % avg trial
            % avg freq
            trialData = squeeze(mean(trialData,1)); % avg freq

            % freq
            % trialData = reshape(trialData, 1, []);
            data = [data; trialData];
            labels = [labels; g];
        end
    end
end

function [accMatrix, aucMatrix] = performDecoding(data, labels, folds, repeats)
    accMatrix = zeros(repeats, folds);
    aucMatrix = zeros(repeats, folds);
    for r = 1:repeats
        cv = cvpartition(labels, 'KFold', folds);
        for f = 1:folds
            trainIdx = training(cv, f);
            testIdx = test(cv, f);

            % SVM-rbf
            model = fitcecoc(data(trainIdx, :), labels(trainIdx), ...
                'Learners', templateSVM('KernelFunction', 'rbf', 'KernelScale', 'auto', 'Standardize', true), ...
                'Coding', 'onevsall');
            
            [predLabels, scores] = predict(model, data(testIdx, :));
            accMatrix(r, f) = mean(predLabels == labels(testIdx));
            aucTemp = zeros(1, numel(model.ClassNames));
            for c = 1:numel(model.ClassNames)
                [~, ~, ~, AUC] = perfcurve(labels(testIdx) == c, scores(:, c), true);
                aucTemp(c) = AUC;
            end
            aucMatrix(r, f) = mean(aucTemp); 
        end
    end
end

function shuffled = shuffleLabels(labels)
    shuffled = labels(randperm(length(labels)));
end

function clusterP = calculateClusterP(observedMean, permutation)
    tThreshold = tinv(0.975, size(permutation, 1) - 1); 
    permutationStd = std(permutation, [], 1);
    tObserved = (observedMean - mean(permutation, 1)') ./ (permutationStd' / sqrt(size(permutation, 1)));

    observedMask = tObserved > tThreshold;
    observedClusters = bwconncomp(observedMask);
    clusterP = ones(size(observedMean));
    for c = 1:length(observedClusters.PixelIdxList)
        clusterSize = numel(observedClusters.PixelIdxList{c});
        clusterP(observedClusters.PixelIdxList{c}) = mean(max(permutation, [], 1) >= clusterSize);
    end
end