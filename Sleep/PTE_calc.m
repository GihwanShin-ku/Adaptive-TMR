%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp, '\');

path_eeglab = [];
for i = 1:length(list)-2
    path_eeglab = [path_eeglab, list{i}, '\'];
end

path = [];
for i = 1:length(list)-2
    path = [path, list{i}, '\'];
end
path = [path, 'Analysis\Sleep\PRES\'];

path_save = [];
for i = 1:length(list)-2
    path_save = [path_save, list{i}, '\'];
end
path_save = [path_save, 'Analysis\Sleep\PTE\'];

%% addpath
addpath(([path_eeglab, 'Lib\eeglab_current\eeglab2021.1']));
addpath(genpath([path_eeglab, 'Lib\brainstorm3-master']));
eeglab;

%% Data load
fs = 100;
range = {[1 4], [12 16]}; % Frequency bands (Delta, Spindle)

matFiles = dir(fullfile(path, '*.mat'));
fileNames = fullfile(path, {matFiles.name});

method = {'scott', 'otnes'};

time_windows = {51:450}; 

for n = 1:length(fileNames)
    % Load .mat file data
    loadedData = load(fullfile(fileNames{n}));
    
    EEG = pop_importdata('dataformat', 'matlab', 'nbchan', [], ...
        'data', loadedData.Adaptive_TMR_PRES, 'srate', fs, 'pnts', 0, 'xmin', 0);

    numTrials = size(EEG.data, 3); % Number of trials

    % Initialize PTE storage for all trials and time windows
    dPTE = []; % ch x ch x trial x method x range x time_window
    PTE = [];

    for r = 1:size(range, 2)
        BandP = pop_eegfiltnew(EEG, range{r}(1), range{r}(2)); % Band-pass filter
        Data = BandP.data; 

        for t = 1:numTrials
            for tw = 1:length(time_windows)
                trialData = squeeze(Data(:, time_windows{tw}, t)); % Extract data for each time window
                
                for m = 1:size(method, 2)
                    [dPTE(:,:,t,m,r,tw), PTE(:,:,t,m,r,tw)] = PhaseTE_MF_re(trialData', [], method{m}); 
                end
            end
        end
    end

    % Save the results for each subject
    save(fullfile(path_save, matFiles(n).name), 'dPTE', 'PTE');
    fprintf('Sub %d Done!\n', n);
end
