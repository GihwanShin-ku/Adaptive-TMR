%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp, '\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Sleep\PP\Adaptive_TMR'];

TMR_path = [];
for i=1:length(list)-2
    TMR_path = [TMR_path,list{i},'\'];
end
TMR_path = [TMR_path 'Data\Sleep\Adaptive_TMR'];

path_save = [];
for i=1:length(list)-2
    path_save = [path_save,list{i},'\'];
end
path_save = [path_save 'Analysis\Sleep\PRES'];

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

for n = 1:length(TMRNames)
    load(fullfile(fileNames{n})); % 

    DATA_TO_ms = (DATA_TO(4) * 3600 + DATA_TO(5) * 60 + DATA_TO(6)) * fs;
    
    % TMR
    txtFiles = dir(fullfile(TMRNames{n}, '*.txt'));
    tmrFilePath = fullfile(TMRNames{n}, txtFiles(1).name);
    fid = fopen(tmrFilePath, 'r');
    TMR_cue = textscan(fid, '%s');
    fclose(fid);
    TMR_cue = TMR_cue{:};

    consecutiveOnThreshold = 8;
    consecutiveOnCount = 0;
    validConsecutiveEvents = {}; 
    currentConsecutiveEvents = {};
    
    for i = 1:length(TMR_cue)
        eventStr = TMR_cue{i};
        
        if contains(eventStr, 'ON_') && contains(eventStr, 'L3')
            consecutiveOnCount = consecutiveOnCount + 1;
            currentConsecutiveEvents{end + 1} = eventStr;
        else
            consecutiveOnCount = 0;
            currentConsecutiveEvents = {}; 
        end
        
        if consecutiveOnCount == consecutiveOnThreshold
            validConsecutiveEvents = [validConsecutiveEvents; currentConsecutiveEvents(:)];
            consecutiveOnCount = 0; 
            currentConsecutiveEvents = {}; 
        end
    end

    relativeTimesMs = zeros(length(validConsecutiveEvents), 1); 
    
    for i = 1:length(validConsecutiveEvents) 
        eventStr = validConsecutiveEvents{i};
        timeStr = eventStr(4:13); % 'HHMMSS.SSS'
        [hh, mm, ss] = deal(str2num(timeStr(1:2)), str2num(timeStr(3:4)), str2num(timeStr(5:end)));
        eventTime_ms = ((hh * 3600) + (mm * 60) + ss) * fs;
        
        if hh < DATA_TO(4) || (hh == DATA_TO(4) && mm < DATA_TO(5)) || (hh == DATA_TO(4) && mm == DATA_TO(5) && ss < DATA_TO(6))
            eventTime_ms = eventTime_ms + (24 * 3600 * fs);
        end
    

        relativeTimesMs(i) = eventTime_ms - DATA_TO_ms;
    end
    eventSampleIndices = round(relativeTimesMs);

    numChannels = size(DATA, 1);
    numTrials = length(eventSampleIndices)/2; 
    
    CuedData = zeros(numChannels, totalDuration, numTrials);
    
    for i = 1:numTrials
        startIdxCue1 = eventSampleIndices(i*2-1) - baselineDuration;
        endIdxCue1 = startIdxCue1 + totalDuration - 1;
        if startIdxCue1 > 0 && endIdxCue1 <= size(DATA, 2)
            CuedData(:, :, i) = DATA(:, startIdxCue1:endIdxCue1);
        end
    end
    
    validTrials = true(1, numTrials);
    
    for i = 1:numTrials
        trialData = CuedData(:, :, i);
        if any(trialData > voltageThreshold(2), 'all') || any(trialData < voltageThreshold(1), 'all')
            groupStartIdx = max(1, i - mod(i - 1, 4)); 
            groupEndIdx = min(numTrials, groupStartIdx + 3); 
            validTrials(groupStartIdx:groupEndIdx) = false;
        end
    end
    
    CuedData = CuedData(:, :, validTrials);
    
    Adaptive_TMR_PRES = CuedData;

    fprintf('Number of Level 3 for subject %d: %d\n', n, size(CuedData,3)/4);
    fprintf('\n');
    save(fullfile(path_save, matFiles(n).name), 'Adaptive_TMR_PRES');
end
