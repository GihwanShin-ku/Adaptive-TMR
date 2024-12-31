%% init
clc; clear; close all;

%% path setting
temp = pwd;
list = split(temp,'\');

path = [];
for i=1:length(list)-2
    path = [path,list{i},'\'];
end
path = [path 'Analysis\Sleep\TFR\'];

%% data load
fs = 100;
baselineDuration = 0.5 * fs;
groups = {'Adaptive_TMR', 'TMR', 'CNT'}; 

for g = 1:length(groups)
    group_path = fullfile(path, groups{g});
    subjects = dir(fullfile(group_path, '*.mat')); 

    lnt = 0; cnt = 0; ccnt = 0;
    for s = 1:length(subjects)
        file_path = fullfile(group_path, subjects(s).name);
        loadedData = load(file_path); 
    
        if isfield(loadedData, 'Adaptive_TMR_ALL')
            lnt = lnt+1;
            Adaptive_ALL(:,:,:,lnt) = loadedData.Adaptive_TMR_ALL;
            Adaptive_L3(:,:,:,lnt) = loadedData.Adaptive_TMR_L3; 
        elseif isfield(loadedData, 'TMR_ALL')
            cnt = cnt+1;
            TMR_ALL(:,:,:,cnt) = loadedData.TMR_ALL;
            TMR_L3(:,:,:,cnt) = loadedData.TMR_L3;
        elseif isfield(loadedData, 'DATA_ALL')
            ccnt = ccnt+1;
            CNT_ALL(:,:,:,ccnt) = loadedData.DATA_ALL;
            CNT_L3(:,:,:,ccnt) = loadedData.DATA_ALL;
        end
    end
end

%% plot
Adaptive_TMR = cat(5, Adaptive_ALL, Adaptive_L3); % TimexFreqxCHxNxConditions
TMR = cat(5, TMR_ALL, TMR_L3);
CNT = cat(5, CNT_ALL, CNT_L3);

Adaptive_TMR_ = squeeze(mean(Adaptive_TMR, 4)); % TimexFreqxCHxConditions
TMR_ = squeeze(mean(TMR, 4));
CNT_ = squeeze(mean(CNT, 4));

ALL = cat(5, Adaptive_TMR_, TMR_, CNT_); % TimexFreqxCHxConditionsxGroup

plotTimeRange = loadedData.time;

channel_mean = squeeze(mean(ALL(:, :, :, :, :), 3));

mycolormap = customcolormap(linspace(0,1,11), {'#a60026','#d83023','#f66e44','#faac5d','#ffdf93','#ffffbd','#def4f9','#abd9e9','#73add2','#4873b5','#313691'});
for j = 1:size(ALL, 4) 
    figure
    cnt=0;
    max_t = max(channel_mean(:,:,j,:), [], 'all');
    min_t = min(channel_mean(:,:,j,:), [], 'all');
    for k = 1:size(ALL, 5) % Group(Level-TMR,TMR,CNT)
        cnt=cnt+1;
        subplot(1, 3, cnt);
        imagesc(plotTimeRange, loadedData.frequencies, channel_mean(:, :, j, k));

        set(gca, 'YDir', 'normal');
        colorbar;
        xlabel('Time (sec)');
        ylabel('Frequency (Hz)');
        
        xlim([32 416]);
        
        xticks(32 + (416 - 32) / 450 * [50, 150, 250, 350, 450]);
        
        xticklabels({'50', '150', '250', '350', '450'});
        
        yticks(0:5:20);
        yticklabels({'0', '5', '10', '15', '20'});

        colormap(mycolormap);

        caxis([-2.2, -1.0]);

        colorbar('off');
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        set(gca,'XLabel',[]);
        set(gca,'YLabel',[]);
    end
end

%% Statistical analysis
mycolormap = customcolormap(linspace(0,1,11), {'#68011d','#b5172f','#d75f4e','#f7a580','#fedbc9','#f5f9f3','#d5e2f0','#93c5dc','#4295c1','#2265ad','#062e61'});

Group = {Adaptive_TMR, TMR, CNT};

channel_mean_groups = cell(size(Group));
for idx = 1:length(Group)
    channel_mean_groups{idx} = squeeze(mean(Group{idx}(:,:,:,:,:), 3)); % TimexFreqxSamplesxConditions
end

for j = 1:size(Adaptive_TMR, 5) % Condition 
    figure;
    lnt = 0;
    cnt = 0;
    for g1 = 1:length(Group)
        for g2 = g1+1:length(Group)
            cnt = cnt + 1;
            lnt = lnt + 1;

            for row = 1:size(Group{g1}, 1)
                for col = 1:length(plotTimeRange)
                    all_data = [squeeze(channel_mean_groups{g1}(row, col, :, j)); squeeze(channel_mean_groups{g2}(row, col, :, j))];
                    group_labels = [ones(size(channel_mean_groups{g1}, 3), 1); 2*ones(size(channel_mean_groups{g2}, 3), 1)];

                    p_anova = anova1(all_data, group_labels, 'off');

                    if p_anova < 0.05
                        [h_mean, p_mean, ci_mean, stat_mean] = ttest2(squeeze(channel_mean_groups{g1}(row, col, :, j)), squeeze(channel_mean_groups{g2}(row, col, :, j)));
                        stat_mean_s(row, col, cnt) = stat_mean.tstat;
                        s_p_mean(row, col, cnt) = p_mean;
                    else
                        stat_mean_s(row, col, cnt) = 0;
                        s_p_mean(row, col, cnt) = 1;
                    end
                end
            end

            subplot(1,3,lnt)
            temp_mean = stat_mean_s(:,:,cnt);
            temp_mean(s_p_mean(:,:,cnt) > 0.05/3) = 0; 

            imagesc(plotTimeRange, loadedData.frequencies, temp_mean);

            set(gca, 'YDir', 'normal');
            colorbar;
            xlabel('Time (sec)');
            ylabel('Frequency (Hz)');
            
            xlim([32 416]);

            xticks(32 + (416 - 32) / 450 * [50, 150, 250, 350, 450]);

            xticklabels({'50', '150', '250', '350', '450'});

            yticks(0:5:20);
            yticklabels({'0', '5', '10', '15', '20'});
            colormap(mycolormap);
            caxis([-4.0, 4.0]);

            colorbar('off')
            set(gca,'YTickLabel',[]);
            set(gca,'XTickLabel',[]);
            set(gca,'XLabel',[]);
            set(gca,'YLabel',[]);     
        end
    end
end
