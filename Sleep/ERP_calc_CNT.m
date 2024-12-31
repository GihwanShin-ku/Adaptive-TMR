%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Sleep\PP\CNT'];

TMR_path = [];
for i=1:length(list)-2
    TMR_path = [TMR_path,list{i},'\'];
end
TMR_path = [TMR_path 'Data\Sleep\CNT'];

path_save = [];
for i=1:length(list)-2
    path_save = [path_save,list{i},'\'];
end
path_save = [path_save 'Analysis\Sleep\ERP\CNT'];

%% data load
fs = 100; 
baselineDuration = 0.5 * fs; 
cueDuration = 4 * fs; 
totalCueDuration = baselineDuration + cueDuration; 
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

    filteredEvents = TMR_cue(2:end);
    relativeTimesMs = zeros(length(filteredEvents), 1);
    eventTypes = cellfun(@(x) x(1:find(isletter(x), 1, 'last')), filteredEvents, 'UniformOutput', false);

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
    end

    CuedData = [];
    validEpochs = []; 

    for i = 1:length(eventTypes)
        if startsWith(eventTypes{i}, 'ON')
            for j = i+1:length(filteredEvents)
                if startsWith(eventTypes{j}, 'OFF') || startsWith(eventTypes{j}, 'End_Save')
                    startIdx = round(relativeTimesMs(i)); 
                    endIdx = round(relativeTimesMs(j)); 
                    
                    numSegments = floor((endIdx - startIdx + 1) / (fs*8));
                    
                    for k = 1:numSegments
                        segmentStartIdx = startIdx + (k-1) * (fs*8);
                        cuedStartIdx = segmentStartIdx - baselineDuration;
                        cuedEndIdx = cuedStartIdx + totalCueDuration - 1;
                        
                        if cuedStartIdx > 0 && cuedEndIdx <= size(DATA, 2)
                            epochDataCued = DATA(:, cuedStartIdx:cuedEndIdx);
                            
                            CuedData = cat(3, CuedData, epochDataCued);
                            if all(epochDataCued(:) >= voltageThreshold(1)) && all(epochDataCued(:) <= voltageThreshold(2))
                                validEpochs = [validEpochs, true]; 
                            else
                                validEpochs = [validEpochs, false]; 
                            end
                        end
                    end
                    
                    break; 
                end
            end
        end
    end

    validEpochs = logical(validEpochs);

    if ~isempty(CuedData)
        validCuedData = CuedData(:, :, validEpochs);
        validCuedBLData = zeros(size(validCuedData));

        for i = 1:size(validCuedData, 3)
            baselineData = mean(validCuedData(:, 1:baselineDuration, i), 2);
            validCuedBLData(:, :, i) = validCuedData(:, :, i) - baselineData;
        end

        % Ori
        CNT_ERP = validCuedBLData;
        CNT_TFR = validCuedData;
        CNT_PAC = validCuedData;
        save(fullfile(path_save, matFiles(n).name), 'CNT_ERP', 'CNT_TFR', 'CNT_PAC');
    else
        fprintf('Subject %d has no valid epochs.\n', n);
    end
end


