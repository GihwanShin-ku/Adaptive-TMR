%% init
clc; clear; close all;

%% Data
% TST, SOL, WASO, SE, N1, N2, N3, R
Adaptive_TMR = [426	13.5	40.5	88.8	13.8	64.9	1.9	19.4
461.5	0	5.5	98.8	4	59.4	10.3	26.3
468.5	0.5	11.5	97.5	11.8	65.2	0.2	22.7
445.5	13.5	21	92.8	9.3	64.3	6.3	20.1
424.5	8.5	47	88.4	12.2	66.3	6.5	15
364	11.5	104	75.9	42.4	41.6	0	15.9
454.4	4.5	20.5	94.8	23.4	44.7	0	31.9
430.6	6	37	90.9	13.8	65	7.9	13.3
454.8	3.5	22	94.7	14.3	58.3	6.7	20.7
425.4	6.5	48.5	88.6	27.6	55.5	3.6	13.3
425	5.5	50.5	88.4	21.3	61.3	0	17.4
347	12.5	119.5	72.4	38.3	40.1	12.1	9.5
];

TMR = [465.3	4	11.5	96.8	10.5	57.2	11.6	20.7
471	7	4.5	97.6	6.5	62.3	12.3	18.9
440.2	4	37	91.5	19.2	56.8	0.1	23.9
426.5	8.5	45.5	88.8	23	47.5	9.8	19.7
320.8	4	81	79.1	53.6	35.6	0	10.8
430.5	9.5	40.5	89.6	15.1	57.1	8.7	19
411	6	63	85.6	12.5	63.6	0.2	23.6
439.5	13.5	27.5	91.5	4.1	64.2	15.5	16.3
410	6.5	64	85.3	44.9	38.7	0	67.5
457.5	5.5	17.5	95.2	38	36.7	0	25.2
463	0.5	16.5	96.5	27.9	55.2	0	78.5
373	7.5	99.6	77.7	30.2	48.4	4.3	17.2
];

CNT = [351.5	5.5	125.5	72.8	33.1	54.3	2.6	10
460.2	2	18	95.8	14.4	60.5	4.1	21
465.7	0.5	15	96.8	14.2	44.4	21.8	19.6
365.6	32	82.5	76.2	28.9	45.8	10	15.3
449.2	17	13.5	93.6	16.7	43	13.2	27
469.5	0.5	10.3	97.8	13.5	61.7	8.3	16.5
468	2.5	10	97.4	12.5	50.4	7.1	30.3
400.6	8	72	83.4	16.8	53.5	3.7	25.9
453.9	7	19.5	94.5	17.3	56.5	8.4	17.8
469.3	3	10.5	97.2	22.8	44.7	11.5	21
451.4	14.5	14.5	94	21.9	56.5	4.2	17.4
417	3.5	59.5	86.9	30.9	46.3	9	13.8
];

Adaptive_TMR_mean = round(mean(Adaptive_TMR,1), 2);
TMR_mean = round(mean(TMR,1), 2);
CNT_mean = round(mean(CNT,1), 2);

Adaptive_TMR_std = round(std(Adaptive_TMR, 0, 1), 2);
TMR_std = round(std(TMR, 0, 1), 2);
CNT_std = round(std(CNT, 0, 1), 2);

%% Statistical analysis
group_labels_Adaptive_TMR = repmat({'Adaptive_TMR'}, size(Adaptive_TMR, 1), 1);
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

