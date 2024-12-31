%% init
clear; clc; close all

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)
    path = [path,list{i},'\'];
end

%% Process
% Load
ID = 'Sub1'; % ID update
filePath = fullfile(path, ['results\', ID, '.txt']); 
fileID = fopen(filePath);
WM_recall = textscan(fileID, '%d %d %d %s %s %s %s %d %d', 'HeaderLines', 1);
fclose(fileID);

numWords = length(WM_recall{4});
randomIndices = randperm(numWords); 

stimulusCounts = struct('L2_1', 1, 'L2_0', 2, 'L3_1', 4, 'L3_0', 4);
stimulusCountTracker = struct('L1_1', 0, 'L1_0', 0, 'L2_1', 0, 'L2_0', 0, 'L3_1', 0, 'L3_0', 0);

wordPairs = {};

for i = 1:numWords
    idx = randomIndices(i);
    level = WM_recall{8}(idx);
    correctVal = WM_recall{1}(idx);
    conditionKey = sprintf('L%d_%d', level, correctVal);

    if isfield(stimulusCounts, conditionKey)
        numTimes = stimulusCounts.(conditionKey);
        for j = 1:numTimes
            wordPair = {WM_recall{4}{idx}, WM_recall{5}{idx}, conditionKey}; 
            wordPairs = [wordPairs; wordPair];  
        end
    end
    % count
    stimulusCountTracker.(conditionKey) = stimulusCountTracker.(conditionKey) + 1;
end

% count
disp('Stimulus counts per condition:');
disp(stimulusCountTracker);

% save
outputPath = fullfile('words_level.xlsx');
if exist(outputPath, 'file')
    delete(outputPath); 
end

writecell(wordPairs, outputPath);

writecell(wordPairs, [path, 'results\', ID, '_', outputPath]);
