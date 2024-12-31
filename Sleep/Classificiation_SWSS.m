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
path = [path, 'Analysis\Sleep\ERPAC\'];

path_save = [];
for i = 1:length(list)-2
    path_save = [path_save, list{i}, '\'];
end
path_save = [path_save, 'Analysis\Sleep\Classification\'];

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
            CNT(:,:,:,:,ccnt) = loadedData.ALL;
        end
    end
end

SP = 16:24; % Spindle band index

%% Parameters
levels = {'All', 'Level_3'}; 
timePoints = size(Adaptive_ALL, 4); 
numFolds = 5; 
numRepeats = 2; 
numSurrogate = 250;
numPermutations = 1000; 

averageFreq = true;

%% Analysis Loop
results = struct();
for condIdx = 1
    condition = levels{condIdx};

    if strcmp(condition, 'All')
        if averageFreq
            AdaptiveTMRData = squeeze(mean(Adaptive_ALL(:,:,SP,:,:), 3));  % ch x ch x time x subject
            TMRData = squeeze(mean(TMR_ALL(:,:,SP,:,:), 3));        
            CNTData = squeeze(mean(CNT(:,:,SP,:,:), 3));            
        else
            AdaptiveTMRData = Adaptive_ALL(:,:,SP,:,:);  % ch x ch x freq x time x subject
            TMRData = TMR_ALL(:,:,SP,:,:);         
            CNTData = CNT(:,:,SP,:,:);             
        end
    elseif strcmp(condition, 'Level_3')
        if averageFreq
            AdaptiveTMRData = squeeze(mean(Adaptive_L3(:,:,SP,:,:), 3));  % ch x ch x time x subject
            TMRData = squeeze(mean(TMR_L3(:,:,SP,:,:), 3));      
            CNTData = squeeze(mean(CNT(:,:,SP,:,:), 3));            
        else
            AdaptiveTMRData = Adaptive_L3(:,:,SP,:,:);  % ch x ch x freq x time x subject
            TMRData = TMR_L3(:,:,SP,:,:);        
            CNTData = CNT(:,:,SP,:,:);            
        end
    end

    groupData = {AdaptiveTMRData, TMRData, CNTData};

    %% Observed Decoding
    observedAccMatrix = zeros(numRepeats, numFolds, timePoints);
    observedAUCMatrix = zeros(numRepeats, numFolds, timePoints);

    for t = 1:timePoints
        [allData, allLabels] = prepareERPACData(groupData, t);
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
    surrogateAccSTE = std(surrogateAccMatrix, 0, [1, 2, 3]) / sqrt(numRepeats * numFolds * numSurrogate); % 표준오차
    surrogateAUCMean = mean(surrogateAUCMatrix, [1, 2, 3]);
    surrogateAUCSTE = std(surrogateAUCMatrix, 0, [1, 2, 3]) / sqrt(numRepeats * numFolds * numSurrogate); % 표준오차

    %% Cluster-Based Permutation Test
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
savePath = fullfile(path_save, 'SWSS_SVM_rbf.mat'); 
save(savePath, 'results'); 

%% Helper Functions
function [data, labels] = prepareERPACData(groupData, t)
    data = [];
    labels = [];
    for g = 1:length(groupData)
        group = groupData{g};
        for sub = 1:12
            % freq avg: (ch x ch)
            trialData = reshape(group(:,:,t,sub), [], 1); % (ch x ch) x 1
    
            % freq avg no: (freq x ch x ch)
            % trialData = reshape(group(:,:,:,t,sub), [], 1); % (freq x ch x ch) x 1
            
            data = [data; trialData'];
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
