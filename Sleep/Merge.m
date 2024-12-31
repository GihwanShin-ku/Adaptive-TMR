%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp, '\');

path = [];
for i = 1:length(list)-2
    path = [path, list{i}, '\'];
end

path_new = [];
for i = 1:length(list)-2
    path_new = [path_new, list{i}, '\'];
end
path_new = [path_new, 'Data\Sleep\'];

path_save = [];
for i = 1:length(list)-2
    path_save = [path_save, list{i}, '\'];
end
path_save = [path_save, 'Analysis\Sleep\Merge\'];

%% addpath
addpath([path, 'Lib\eeglab_current\eeglab2021.1']);
eeglab;

%% merge
groups = {'Adaptive_TMR', 'TMR', 'CNT'};
for g = 1:length(groups)
    group_path = fullfile(path_new, groups{g});
    subjects = dir(fullfile(group_path, 'sub*'));

    for s = 1:length(subjects)
        subject_path = fullfile(group_path, subjects(s).name);
        edffolders = dir(fullfile(subject_path, '**', '*.edf')); 
        edfNames = fullfile({edffolders.folder}, {edffolders.name}); 
        ALLEEG = []; ALLEOG = []; ALLEMG = [];

        for i = 1:size(edfNames, 2)
            DATA = pop_biosig(edfNames{i});

            if i == 1
                DATA_TO = DATA.etc.T0;
            end

            % channel select
            EEG = pop_select(DATA, 'channel', [1 2 4 5 6 7]);  % EEG channels
            EOG = pop_select(DATA, 'channel', [11 12]);       % EOG channels
            EMG = pop_select(DATA, 'channel', [8]);           % EMG channel

            [ALLEEG, EEG, ~] = eeg_store(ALLEEG, EEG);
            [ALLEOG, EOG, ~] = eeg_store(ALLEOG, EOG);
            [ALLEMG, EMG, ~] = eeg_store(ALLEMG, EMG);
        end

        % merge
        EEG = pop_mergeset(ALLEEG, 1:length(ALLEEG), 0);
        EOG = pop_mergeset(ALLEOG, 1:length(ALLEOG), 0); 
        EMG = pop_mergeset(ALLEMG, 1:length(ALLEMG), 0); 

        % save
        group_save_path = fullfile(path_save, groups{g}); 
        if ~exist(group_save_path, 'dir') 
            mkdir(group_save_path);
        end
        
        save(fullfile(group_save_path, [subjects(s).name, '.mat']), ...
            'EEG', 'EOG', 'EMG', 'DATA_TO');
    end
end
