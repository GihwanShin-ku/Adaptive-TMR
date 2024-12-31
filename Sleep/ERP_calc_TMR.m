%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Sleep\PP\TMR'];

TMR_path = [];
for i=1:length(list)-2
    TMR_path = [TMR_path,list{i},'\'];
end
TMR_path = [TMR_path 'Data\Sleep\TMR'];

path_WM = [];
for i=1:length(list)-2
    path_WM = [path_WM,list{i},'\'];
end
path_WM = [path_WM 'Data\Behavior\TMR'];

path_save = [];
for i=1:length(list)-2
    path_save = [path_save,list{i},'\'];
end
path_save = [path_save 'Analysis\Sleep\ERP\TMR'];

%% data load
fs = 100;  
baselineDuration = 0.5 * fs; 
cueDuration = 4 * fs; 
totalDuration = baselineDuration + cueDuration;
voltageThreshold = [-500 500]; 

matFiles = dir(fullfile(path, '*.mat'));
fileNames = fullfile(path, {matFiles.name});

TMRFiles = dir(fullfile(TMR_path, '*sub*'));
TMRNames = fullfile(TMR_path, {TMRFiles.name});

numSubjects = length(fileNames); 
allCuedData = cell(1, numSubjects);

for n = 1:numSubjects
    % .mat 
    load(fullfile(fileNames{n}));

    DATA_TO_ms = (DATA_TO(4) * 3600 + DATA_TO(5) * 60 + DATA_TO(6)) * fs;

    % TMR
    txtFiles = dir(fullfile(TMRNames{n}, '*.txt'));
    tmrFilePath = fullfile(TMRNames{n}, txtFiles(1).name);
    fid = fopen(tmrFilePath, 'r');
    TMR_cue = textscan(fid, '%s');
    fclose(fid);
    TMR_cue = TMR_cue{:};
    
    % .txt 
    filePath = fullfile(path_WM, TMRFiles(n).name, 'retrieval_1.txt');

    fid = fopen(filePath);
    WM_recall = textscan(fid, '%s %s %s %s %s %s %s %s %s');
    fclose(fid);
    WM_recall = [WM_recall{:}];
    WM_recall = WM_recall(2:end,:);

    isOnEvent = contains(TMR_cue, 'ON_');
    filteredEvents = TMR_cue(isOnEvent);

    relativeTimesMs = zeros(length(filteredEvents), 1);
    eventWords = cell(length(filteredEvents), 1);
    for i = 1:length(filteredEvents)
        eventStr = filteredEvents{i};
        timeStr = char(regexp(eventStr, '\d+\.\d+', 'match')); % 'HHMMSS.SSS'
        [hh, mm, ss] = deal(str2num(timeStr(1:2)), str2num(timeStr(3:4)), str2num(timeStr(5:end)));
        eventTime_ms = ((hh * 3600) + (mm * 60) + ss) * fs;
        
        if hh < DATA_TO(4) || (hh == DATA_TO(4) && mm < DATA_TO(5)) || (hh == DATA_TO(4) && mm == DATA_TO(5) && ss < DATA_TO(6))
            eventTime_ms = eventTime_ms + (24 * 3600 * fs);
        end

        relativeTimeMs = eventTime_ms - DATA_TO_ms;
        relativeTimesMs(i) = relativeTimeMs;
        
        tokens = strsplit(eventStr, '_');
        eventWords{i} = tokens{3};
    end
    eventSampleIndices = round(relativeTimesMs);

    numChannels = size(DATA, 1);
    numTrials = length(eventSampleIndices) / 2;

    CuedData = zeros(numChannels, totalDuration, numTrials);
    validTrials = true(1, numTrials);

    initialValidTrials = validTrials;
    for i = 1:numTrials
        startIdxCue1 = eventSampleIndices(i*2-1) - baselineDuration; 
        endIdxCue1 = startIdxCue1 + totalDuration - 1;
        if startIdxCue1 > 0 && endIdxCue1 <= size(DATA, 2)
            CuedData(:, :, i) = DATA(:, startIdxCue1:endIdxCue1);
        else
            validTrials(i) = false; 
        end
    end

    for i = 1:numTrials
        if any(CuedData(:, :, i) > voltageThreshold(2), 'all') || any(CuedData(:, :, i) < voltageThreshold(1), 'all')
            validTrials(i) = false;
        end
    end

    numRemovedByThreshold = sum(initialValidTrials) - sum(validTrials);
    fprintf('Number of trials removed by voltage threshold for subject %d: %d\n', n, numRemovedByThreshold);

    CuedData = CuedData(:, :, validTrials);

    CuedBLData = zeros(size(CuedData));
    for i = 1:size(CuedData, 3)
        baselineData = mean(CuedData(:, 1:baselineDuration, i), 2);
        CuedBLData(:, :, i) = CuedData(:, :, i) - baselineData;
    end

    validEventIndices = reshape([validTrials; validTrials], [], 1);
    filteredEventWords = eventWords(validEventIndices); 

    eventLevels = cell(sum(validTrials), 1);
    for i = 1:sum(validTrials)
        word1 = filteredEventWords{i*2-1};
        word2 = filteredEventWords{i*2};
        idx1 = find(strcmp(WM_recall(:,4), word1) | strcmp(WM_recall(:,5), word1), 1);
        idx2 = find(strcmp(WM_recall(:,4), word2) | strcmp(WM_recall(:,5), word2), 1); 
        if ~isempty(idx1) && ~isempty(idx2)
            eventLevels{i} = WM_recall{idx1, 8}; 
        else
            eventLevels{i} = 'Level not found';
        end
    end  

    % Ori
    TMR_ERP = CuedBLData;
    TMR_TFR = CuedData;
    TMR_PAC = CuedData;

    Level = eventLevels; 

    numLevel1 = sum(strcmp(Level, '1'));
    numLevel2 = sum(strcmp(Level, '2'));
    numLevel3 = sum(strcmp(Level, '3'));

    fprintf('Number of Level 1 for subject %d: %d\n', n, numLevel1);
    fprintf('Number of Level 2 for subject %d: %d\n', n, numLevel2);
    fprintf('Number of Level 3 for subject %d: %d\n', n, numLevel3);
    fprintf('\n');
    save(fullfile(path_save, matFiles(n).name), 'TMR_ERP', 'TMR_TFR', 'TMR_PAC', 'Level');
end

