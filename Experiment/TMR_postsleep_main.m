%% init
clear all; close all; clc

%% trigger setting
global IO_LIB IO_ADDR;
IO_LIB=which('inpoutx64.dll');
IO_ADDR=hex2dec('D010');       

%% ID
ID = 'sub1';

%% Resting-state (5min)
ppTrigger(97);
RS_timer
ppTrigger(98);

%% 
% test after sleep 
word_pair_test_postsleep([ID '_postsleep']);

%% Resting-state (5min)
ppTrigger(99);
RS_timer
ppTrigger(100);
