%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path_eeglab = [];
for i=1:length(list)-2
    path_eeglab = [path_eeglab,list{i},'\'];
end

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Sleep\Merge\'];

path_save = [];
for i=1:length(list)-2
    path_save = [path_save,list{i},'\'];
end
path_save = [path_save 'Analysis\Sleep\PP\'];

%% addpath
addpath([path_eeglab,'Lib\eeglab_current\eeglab2021.1']);
eeglab

%% preprocessing
fs = 100;  
band_EEG = [1 20]; 
band_EOG = [1 20]; 
band_EMG = [10 20]; 

groups = {'Adaptive_TMR', 'TMR', 'CNT'}; % 그룹 정의

for g = 1:length(groups)
    group_path = fullfile(path, groups{g});
    matFiles = dir(fullfile(group_path, '*.mat'));
    fileNames = fullfile(group_path, {matFiles.name});

    for n = 1:length(fileNames)
        load(fileNames{n});  
        load('EEG_CH.mat');  
        EEG.chanlocs = EEG_ch;

        % Resampling
        EEG = pop_resample(EEG, fs); 
        EOG = pop_resample(EOG, fs); 
        EMG = pop_resample(EMG, fs); 

        % Band-pass filtering
        EEG = pop_eegfiltnew(EEG, band_EEG(1), band_EEG(2)); 
        EOG = pop_eegfiltnew(EOG, band_EOG(1), band_EOG(2));
        EMG = pop_eegfiltnew(EMG, band_EMG(1), band_EMG(2));

        % Run ICA
        EEG = pop_runica(EEG, 'icatype', 'runica', 'chanind', 1:EEG.nbchan);

        % Calculate ICA activations
        ica_weights = EEG.icaweights * EEG.icasphere;
        ica_activations = ica_weights * EEG.data;

        artifact_idx_eog = [];
        artifact_idx_emg = [];
        
        EOG.data = mean(EOG.data,1);

        % Correlation analysis for each ICA component with EOG and EMG data
        corr_values_eog = cell(1, size(ica_activations, 1));  
        corr_values_emg = cell(1, size(ica_activations, 1));

        for i = 1:size(ica_activations, 1)
            corr_eog = corrcoef(ica_activations(i, :), EOG.data);
            corr_emg = corrcoef(ica_activations(i, :), EMG.data);
            if abs(corr_eog(2, 1)) > 0.7 
                artifact_idx_eog = [artifact_idx_eog, i];
                corr_values_eog{i} = corr_eog(2, 1);  
            end
            if abs(corr_emg(2, 1)) > 0.6 
                artifact_idx_emg = [artifact_idx_emg, i];
                corr_values_emg{i} = corr_emg(2, 1);  
            end
        end

        % Combine artifact indices
        artifact_idx = unique([artifact_idx_eog, artifact_idx_emg]);

        % Remove artifacts and print the indices of removed components
        if ~isempty(artifact_idx)
            fprintf('Subject %d: Removed artifact components:\n', n);
            EEG = pop_subcomp(EEG, artifact_idx, 0);
            for i = 1:length(artifact_idx)
                idx = artifact_idx(i);

                % Check if the correlation values exist before printing
                if ~isempty(corr_values_eog{idx})
                    fprintf('  Component %d (EOG corr = %.2f)\n', idx, corr_values_eog{idx});
                end
                if ~isempty(corr_values_emg{idx})
                    fprintf('  Component %d (EMG corr = %.2f)\n', idx, corr_values_emg{idx});
                end
            end
        else
            fprintf('Subject %d: No artifact components removed.\n', n);
        end

        % Interpolate bad channels
        [~, badChannels] = pop_rejchan(EEG, 'elec', 1:EEG.nbchan, 'threshold', 5, 'norm', 'on', 'measure', 'kurt'); 
        if ~isempty(badChannels)
            EEG = pop_interp(EEG, badChannels, 'spherical');
        end 

        % Save the processed data
        DATA = EEG.data; 
        group_save_path = fullfile(path_save, groups{g}); 
        if ~exist(group_save_path, 'dir') 
            mkdir(group_save_path);
        end
        save(fullfile(group_save_path, matFiles(n).name), 'DATA', 'DATA_TO');
    end
end
