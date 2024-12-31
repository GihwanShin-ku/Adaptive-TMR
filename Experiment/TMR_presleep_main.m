%% init
clear all; close all; clc

%% trigger setting
global IO_LIB IO_ADDR;
IO_LIB=which('inpoutx64.dll');
IO_ADDR=hex2dec('D010');       

%% ID
ID = 'sub1';

%% Resting-state (5min)
ppTrigger(91); 
RS_timer
ppTrigger(92);

%% 
% learning
word_pair_learning([ID '_learn']); 

%% Resting-state (5min)
ppTrigger(93);
RS_timer
ppTrigger(94);

%% 
% test before sleep
word_pair_test_presleep([ID '_presleep']); %30Ка
      
%% Resting-state (5min)
ppTrigger(95);
RS_timer
ppTrigger(96);
