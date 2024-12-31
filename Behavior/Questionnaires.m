%% init
clc; clear; close all;

%% Data
% Age, BMI, PSQI, ISI, SDS, LESQ, SSS_pre, SSS_post, STAI_pre, STAI_post
Adaptive_TMR = [28	19.487	5	8	41	2	3	36	38
23	20.029	4	2	43	2	2	39	38
28	25.926	8	8	38	3	3	30	29
31	22.130	4	2	45	2	3	39	46
30	27.131	5	10	42	2	2	35	37
28	23.255	2	3	34	2	3	33	40
31	20.313	8	12	47	2	3	41	39
27	22.308	7	9	56	3	2	32	28
28	31.095	5	7	46	2	2	39	33
28	27.755	5	12	34	4	3	39	40
29	23.408	4	6	47	4	2	34	34
25	22.308	4	8	43	2	4	29	40];

TMR = [25	23.147	5	4	46	3	3	34	34
19	17.056	9	12	52	2	3	44	41
24	22.231	3	9	37	3	3	44	39
26	18.845	5	0	40	2	2	35	44
29	24.302	5	11	31	3	3	30	31
28	27.469	2	1	40	3	2	31	34
28	25.855	4	7	35	3	3	33	30
22	22.583	5	7	42	4	3	27	34
24	21.075	5	6	32	2	1	24	27
30	23.413	3	8	33	3	2	25	22
29	24.836	2	2	34	3	1	34	28
25	18.179	6	7	45	3	4	34	45];

CNT = [27	21.977	4	9	33	3	3	28	30
27	22.985	2	1	37	3	2	38	37
22	25.712	6	7	30	2	2	41	35
28	19.818	2	2	52	2	2	48	47
21	18.424	5	8	32	3	3	30	28
26	23.765	3	8	41	3	2	32	35
26	26.062	5	3	51	2	2	36	36
27	23.875	7	8	36	4	4	30	31
33	24.672	3	5	41	3	3	28	33
25	19.959	5	3	45	3	3	49	47
24	24.163	3	11	54	3	2	27	37
27	21.565	3	5	37	2	3	36	29];

T1_Q_Adaptive_TMR_mean = round(mean(Adaptive_TMR,1), 2);
T1_Q_TMR_mean = round(mean(TMR,1), 2);
T1_Q_CNT_mean = round(mean(CNT,1), 2);

T1_Q_Adaptive_std = round(std(Adaptive_TMR,0,1), 2);
T1_Q_TMR_std = round(std(TMR,0,1), 2);
T1_Q_CNT_std = round(std(CNT,0,1), 2);

%% Statistical analysis
group_labels_Adaptive_TMR = repmat({'Adapive_TMR'}, size(Adaptive_TMR, 1), 1);
group_labels_TMR = repmat({'TMR'}, size(TMR, 1), 1);
group_labels_CNT = repmat({'CNT'}, size(CNT, 1), 1);

all_data = [Adaptive_TMR; TMR; CNT];
all_labels = [group_labels_Adaptive_TMR; group_labels_TMR; group_labels_CNT];

for feature_idx = 1:size(all_data, 2)
    feature_data = all_data(:, feature_idx);
    [p, tbl, stats] = anova1(feature_data, all_labels, 'off');
    
    F_value = tbl{2,5}; 
    p_value = tbl{2,6}; 
    
    fprintf('Feature %d:\n', feature_idx);
    fprintf('F-value: %.2f, p-value: %.3f\n', F_value, p_value);
end

age = all_data(:,1);
[h12,p12,ci12,stat12] = ttest2(age(1:12,1),age(13:24));
[h13,p13,ci13,stat13] = ttest2(age(1:12,1),age(25:36));
[h23,p23,ci23,stat23] = ttest2(age(13:24,1),age(25:36));

%% SEX

% (1 = MALE, 0 = FEMALE)
Adaptive_TMR_SEX = [1,0,1,1,1,1,0,1,1,1,1,0]; %12
TMR_SEX = [0,0,1,0,1,1,1,0,1,1,1,0]; %12
CNT_SEX = [1,1,0,1,0,1,1,0,1,0,0,1]; %12

group_labels = [repmat({'Adaptive_TMR'}, length(Adaptive_TMR_SEX), 1); 
                repmat({'TMR'}, length(TMR_SEX), 1); 
                repmat({'CNT'}, length(CNT_SEX), 1)];

sex_data = [Adaptive_TMR_SEX'; TMR_SEX'; CNT_SEX'];

[tbl, chi2stat, p, labels] = crosstab(group_labels, sex_data);

fprintf('Chi-square statistic: %.2f\n', chi2stat);
fprintf('Degrees of Freedom: %d\n', (size(tbl, 1) - 1) * (size(tbl, 2) - 1));
fprintf('p-value: %.3f\n', p);
