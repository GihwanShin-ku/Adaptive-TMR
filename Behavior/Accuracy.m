%% init
clear; clc; close all

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Data\Behavior\'];

save_path = [];
for i=1:length(list)-2
    save_path = [save_path,list{i},'\'];
end
save_path = [save_path 'Analysis\Behavior\'];

groups = {'Adaptive_TMR', 'TMR', 'CNT'};
tasks = {'retrieval_1', 'retrieval_2'};

%% Process each group
ACC = struct(); 

for g = 1:length(groups)
    groupPath = fullfile(path, groups{g});
    subjects = dir(fullfile(groupPath, 'sub*')); 
    subjectNames = {subjects.name};

    groupAcc = []; 

    for s = 1:length(subjectNames)
        subPath = fullfile(groupPath, subjectNames{s});

        subjectAcc = []; 

        for t = 1:length(tasks)
            taskFile = fullfile(subPath, [tasks{t}, '.txt']);

            if exist(taskFile, 'file')
                data = readtable(taskFile, 'ReadVariableNames', true, 'Delimiter', '\t');

                ansValues = data{:, 1}; 
                correct = sum(ansValues == 1);
                total = length(ansValues); 

                taskAcc = (correct / total) * 100;
                subjectAcc = [subjectAcc, taskAcc];
            else
                fprintf('Task file not found: %s\n', taskFile);
                subjectAcc = [subjectAcc, NaN]; 
            end
        end

        groupAcc = [groupAcc; subjectAcc]; 
    end

    ACC.(groups{g}) = groupAcc; 
end

%% Save results
save(fullfile(save_path, 'ACC.mat'), 'ACC');
