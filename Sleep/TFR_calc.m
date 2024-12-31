%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Sleep\ERP\'];

path_save = [];
for i=1:length(list)-2
    path_save = [path_save,list{i},'\'];
end
path_save = [path_save 'Analysis\Sleep\TFR\'];

%% TFR Parameter
band = [1 20];
fs = 100; 
window_length = 32; 
overlap = 24; 
FFT_length = 200; 
baselineDuration = 0.5 * fs;

%% data load
so_band = [1 4]; % Slow wave
spindle_band = [12 16]; % Spindle 

groups = {'Adaptive_TMR', 'TMR', 'CNT'}; % Group definitions

for g = 1:length(groups)
    group_path = fullfile(path, groups{g}); % Group folder path
    subjects = dir(fullfile(group_path, 'sub*')); % Subject folders

    for s = 1:length(subjects)
        subject_path = fullfile(group_path, subjects(s).name); % Subject folder path
        loadedData = load(subject_path); % Load data

        %% Adaptive_TMR
        if isfield(loadedData, 'Adaptive_TMR_TFR')
            Level = str2double(loadedData.Level);
            DATA_Adaptive_TMR_ALL = []; DATA_Adaptive_TMR_L3 = [];
            DATA_Adaptive_TMR_All_trials = []; DATA_Adaptive_TMR_L3_trials = [];
            for c = 1:6
                DATA_Adaptive_TMR_t = [];
                for j = 1:size(loadedData.Adaptive_TMR_TFR, 3)
                    data = loadedData.Adaptive_TMR_TFR(c, :, j)';

                    [S, frequencie, time, ps] = spectrogram(data, hamming(window_length, 'periodic'), overlap, FFT_length, fs, 'yaxis');
                    time = time * fs;

                    [~, idxMin] = min(abs(frequencie - band(1)));
                    [~, idxMax] = min(abs(frequencie - band(2)));
                    freqIndices = idxMin:idxMax;

                    powerSpectrum = ps(freqIndices, :);
                    frequencies = frequencie(freqIndices);

                    baselineIndices = time >= 0 & time <= baselineDuration;
                    baselinePower = mean(powerSpectrum(:, baselineIndices), 2);
                    baselinePower(baselinePower==0) = 1e-10;

                    normalized_power_spectrum = powerSpectrum ./ baselinePower;
                    DATA_Adaptive_TMR_t(:,:,j) = 10 * log10(normalized_power_spectrum + 1e-10);
                end
                DATA_Adaptive_TMR_ALL(:,:,c) = mean(DATA_Adaptive_TMR_t, 3);
                DATA_Adaptive_TMR_L3(:,:,c) = mean(DATA_Adaptive_TMR_t(:,:,Level == 3), 3);

                DATA_Adaptive_TMR_All_trials(:,:,:,c) = DATA_Adaptive_TMR_t; 
                DATA_Adaptive_TMR_L3_trials(:,:,:,c) = DATA_Adaptive_TMR_t(:,:,Level == 3);
            end
            Adaptive_TMR_ALL = DATA_Adaptive_TMR_ALL; 
            Adaptive_TMR_L3 = DATA_Adaptive_TMR_L3;

            [~, idxMin_SO] = min(abs(frequencies - so_band(1)));
            [~, idxMax_SO] = min(abs(frequencies - so_band(2)));
            freqIndices_SO = idxMin_SO:idxMax_SO;

            [~, idxMin_spindle] = min(abs(frequencies - spindle_band(1)));
            [~, idxMax_spindle] = min(abs(frequencies - spindle_band(2)));
            freqIndices_spindle = idxMin_spindle:idxMax_spindle;

            CueIndices = time >= baselineDuration+1 & time <= 450;

            Adaptive_TMR_ALL_SO = squeeze(mean(mean(mean(Adaptive_TMR_ALL(freqIndices_SO,CueIndices,:), 2), 1), 3));
            Adaptive_TMR_L3_SO = squeeze(mean(mean(mean(Adaptive_TMR_L3(freqIndices_SO,CueIndices,:), 2), 1), 3));

            Adaptive_TMR_ALL_spindle = squeeze(mean(mean(mean(Adaptive_TMR_ALL(freqIndices_spindle,CueIndices,:), 2), 1), 3));
            Adaptive_TMR_L3_spindle = squeeze(mean(mean(mean(Adaptive_TMR_L3(freqIndices_spindle,CueIndices,:), 2), 1), 3));

            Adaptive_TMR_ALL_trial_SO = DATA_Adaptive_TMR_All_trials(freqIndices_SO,:,:,:);
            Adaptive_TMR_L3_trial_SO = DATA_Adaptive_TMR_L3_trials(freqIndices_SO,:,:,:);

            Adaptive_TMR_ALL_trial_spindle = DATA_Adaptive_TMR_All_trials(freqIndices_spindle,:,:,:);
            Adaptive_TMR_L3_trial_spindle = DATA_Adaptive_TMR_L3_trials(freqIndices_spindle,:,:,:);

            save(fullfile(path_save, groups{g}, subjects(s).name), 'Adaptive_TMR_ALL', 'Adaptive_TMR_L3', ...
                'Adaptive_TMR_ALL_SO', 'Adaptive_TMR_L3_SO', ...
                'Adaptive_TMR_ALL_spindle', 'Adaptive_TMR_L3_spindle', ...
                'Adaptive_TMR_ALL_trial_SO', 'Adaptive_TMR_L3_trial_SO', ...
                'Adaptive_TMR_ALL_trial_spindle', 'Adaptive_TMR_L3_trial_spindle', ...
                'time', 'frequencies');
        end

        %% TMR
        if isfield(loadedData, 'TMR_TFR')
            Level = str2double(loadedData.Level);
            DATA_TMR_ALL = [];  DATA_TMR_L3 = [];
            DATA_TMR_All_trials = []; DATA_TMR_L3_trials = [];
            for c = 1:6
                DATA_TMR_t = [];
                for j = 1:size(loadedData.TMR_TFR, 3)
                    data = loadedData.TMR_TFR(c, :, j)';

                    [S, frequencie, time, ps] = spectrogram(data, hamming(window_length, 'periodic'), overlap, FFT_length, fs, 'yaxis');
                    time = time * fs;  

                    [~, idxMin] = min(abs(frequencie - band(1)));
                    [~, idxMax] = min(abs(frequencie - band(2)));
                    freqIndices = idxMin:idxMax;

                    powerSpectrum = ps(freqIndices, :);
                    frequencies = frequencie(freqIndices);

                    baselineIndices = time >= 0 & time <= baselineDuration;  
                    baselinePower = mean(powerSpectrum(:, baselineIndices), 2); 
                    baselinePower(baselinePower==0) = 1e-10;

                    normalized_power_spectrum = powerSpectrum ./ baselinePower;
                    DATA_TMR_t(:,:,j) = 10 * log10(normalized_power_spectrum + 1e-10);
                end
                DATA_TMR_ALL(:,:,c) = mean(DATA_TMR_t, 3);
                DATA_TMR_L3(:,:,c) = mean(DATA_TMR_t(:,:,Level==3), 3);

                DATA_TMR_All_trials(:,:,:,c) = DATA_TMR_t; 
                DATA_TMR_L3_trials(:,:,:,c) = DATA_TMR_t(:,:,Level == 3);
            end
            TMR_ALL = DATA_TMR_ALL; 
            TMR_L3 = DATA_TMR_L3;

            [~, idxMin_SO] = min(abs(frequencies - so_band(1)));
            [~, idxMax_SO] = min(abs(frequencies - so_band(2)));
            freqIndices_SO = idxMin_SO:idxMax_SO;

            [~, idxMin_spindle] = min(abs(frequencies - spindle_band(1)));
            [~, idxMax_spindle] = min(abs(frequencies - spindle_band(2)));
            freqIndices_spindle = idxMin_spindle:idxMax_spindle;

            CueIndices = time >= baselineDuration+1 & time <= 450;

            TMR_ALL_SO = squeeze(mean(mean(mean(TMR_ALL(freqIndices_SO,CueIndices,:), 2), 1), 3));
            TMR_L3_SO = squeeze(mean(mean(mean(TMR_L3(freqIndices_SO,CueIndices,:), 2), 1), 3));

            TMR_ALL_spindle = squeeze(mean(mean(mean(TMR_ALL(freqIndices_spindle,CueIndices,:), 2), 1), 3));
            TMR_L3_spindle = squeeze(mean(mean(mean(TMR_L3(freqIndices_spindle,CueIndices,:), 2), 1), 3));

            TMR_ALL_trial_SO = DATA_TMR_All_trials(freqIndices_SO,:,:,:);
            TMR_L3_trial_SO = DATA_TMR_L3_trials(freqIndices_SO,:,:,:);

            TMR_ALL_trial_spindle = DATA_TMR_All_trials(freqIndices_spindle,:,:,:);
            TMR_L3_trial_spindle = DATA_TMR_L3_trials(freqIndices_spindle,:,:,:);

            save(fullfile(path_save, groups{g}, subjects(s).name), 'TMR_ALL', 'TMR_L3', ...
                'TMR_ALL_SO', 'TMR_L3_SO', ...
                'TMR_ALL_spindle', 'TMR_L3_spindle', ...
                'TMR_ALL_trial_SO', 'TMR_L3_trial_SO', ...
                'TMR_ALL_trial_spindle', 'TMR_L3_trial_spindle', ...
                'time', 'frequencies');
        end

        %% CNT
        if isfield(loadedData, 'CNT_TFR')
            DATA_CNT_All_trials = [];  
            for c = 1:6
                DATA_CNT_t = [];
                for j = 1:size(loadedData.CNT_TFR, 3)
                    data = loadedData.CNT_TFR(c, :, j)';

                    [S, frequencie, time, ps] = spectrogram(data, hamming(window_length, 'periodic'), overlap, FFT_length, fs, 'yaxis');
                    time = time * fs;

                    [~, idxMin] = min(abs(frequencie - band(1)));
                    [~, idxMax] = min(abs(frequencie - band(2)));
                    freqIndices = idxMin:idxMax;

                    powerSpectrum = ps(freqIndices, :);
                    frequencies = frequencie(freqIndices);

                    baselineIndices = time >= 0 & time <= baselineDuration;  
                    baselinePower = mean(powerSpectrum(:, baselineIndices), 2);
                    baselinePower(baselinePower==0) = 1e-10;

                    normalized_power_spectrum = powerSpectrum ./ baselinePower;

                    DATA_CNT_t(:, :, j) = 10 * log10(normalized_power_spectrum + 1e-10);
                end
                DATA_CNT_c(:, :, c) = mean(DATA_CNT_t, 3);

                DATA_CNT_All_trials(:,:,:,c) = DATA_CNT_t; 
            end

            DATA_ALL = DATA_CNT_c; 

            [~, idxMin_SO] = min(abs(frequencies - so_band(1)));
            [~, idxMax_SO] = min(abs(frequencies - so_band(2)));
            freqIndices_SO = idxMin_SO:idxMax_SO;

            [~, idxMin_spindle] = min(abs(frequencies - spindle_band(1)));
            [~, idxMax_spindle] = min(abs(frequencies - spindle_band(2)));
            freqIndices_spindle = idxMin_spindle:idxMax_spindle;

            CueIndices = time >= baselineDuration+1 & time <= 450;

            CNT_SO = squeeze(mean(mean(mean(DATA_ALL(freqIndices_SO,CueIndices,:), 2), 1), 3));
            CNT_spindle = squeeze(mean(mean(mean(DATA_ALL(freqIndices_spindle,CueIndices,:), 2), 1), 3));

            CNT_trial_SO = DATA_CNT_All_trials(freqIndices_SO,:,:,:);
            CNT_trial_spindle = DATA_CNT_All_trials(freqIndices_spindle,:,:,:);

            save(fullfile(path_save, groups{g}, subjects(s).name), 'DATA_ALL', 'CNT_SO', 'CNT_spindle', ...
                'CNT_trial_SO', 'CNT_trial_spindle', ...
                'time', 'frequencies');
        end
    end
end
