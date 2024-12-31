function word_pair_learning(subID)
% Psychtoolbox setting
backgroundColor = 255;
textColor = 0;
responseKeys_1 = {'f1','f2'};

% trigger
tr_starting = 11;
tr_fixation = 12;
tr_show = 13;
tr_cue1 = 14;
tr_cue2 = 15;
tr_end = 16;

tr_pause = 111;
tr_restart = 222;

% Start
ppTrigger(tr_starting);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up the experiment (don't modify this section)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rand('state', sum(100*clock)); % Initialize the random number generator

% Keyboard setup
KbName('UnifyKeyNames');
KbCheckList = [KbName('space'),KbName('ESCAPE'),KbName('Return'),KbName('BackSpace')];
for i = 1:length(responseKeys_1)
    KbCheckList = [KbName(responseKeys_1{i}),KbCheckList];
end
RestrictKeysForKbCheck(KbCheckList);

% Screen setup
clear screen
whichScreen = max(Screen('Screens'));
[window1, rect] = Screen('Openwindow',whichScreen,backgroundColor,[],[],2);
Screen(window1,'FillRect',backgroundColor);
Screen('Flip', window1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up stimuli lists and results file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~,Data] = xlsread('words.xlsx','A1:C104');
nTrials = 104;
% Set up the output file
resultsFolder = 'results';
outputfile = fopen([resultsFolder '/' num2str(subID) '.txt'],'a');
fprintf(outputfile, 'subID\t trial\t order\t Data_first\t Data_second\n');

% Randomize the trial list
randomizedTrials = randperm(nTrials);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run experiment

% Start screen
Screen('TextSize',window1,80);
DrawFormattedText(window1, 'Word-pairs learning \n\n Press spacebar button to start', 'center', 'center', textColor);
Screen('Flip',window1);

% Wait for subject to press spacebar
while 1
     [keyIsDown,secs,keyCode] = KbCheck;
    if keyCode(KbName('space'))==1
        break
    end
end

Screen('TextSize',window1,100);
DrawFormattedText(window1,'3','center','center',textColor);
Screen('Flip',window1);
WaitSecs(1);

Screen('TextSize',window1,100);
DrawFormattedText(window1,'2','center','center',textColor);
Screen('Flip',window1);
WaitSecs(1);

Screen('TextSize',window1,100);
DrawFormattedText(window1,'1','center','center',textColor);
Screen('Flip',window1);
WaitSecs(1);

cnt = 0;

% Initialize pause flag
isPaused = false;
pauseNextTrial = false;  % Flag to indicate pausing at the next trial

for t = randomizedTrials
    cnt = cnt + 1;
    disp(['current trial: ' num2str(cnt)]);  % Display current trial

    % Screen priority
    Priority(MaxPriority(window1));
    Priority(2);

    % Show fixation cross
    ppTrigger(tr_fixation);

    DrawFormattedText(window1, '+', 'center', 'center', textColor);
    Screen('Flip', window1);
    WaitSecs(1);

    % Show word-pair
    ppTrigger(tr_show);

    Screen('TextSize', window1, 100);
    DrawFormattedText(window1, [char(Data(t,1)) '\n\n' char(Data(t,2))], 'center', 'center', textColor);
    startTime = Screen('Flip', window1);

    cue1_tts_played = false;  % Flag to track if cue 1 tts has been played
    cue2_tts_played = false;  % Flag to track if cue 2 tts has been played

    % Initialize restart request flag
    restartRequested = false;

    while GetSecs - startTime < 4
        [keyIsDown, secs, keyCode] = KbCheck;

        % Check for pause (f1)
        if keyCode(KbName('f1')) == 1 && ~pauseNextTrial
            ppTrigger(tr_pause);
            pauseNextTrial = true;  % Set flag to pause at the next trial
            disp(['Pause requested before current trial ' num2str(cnt)]);
        end

        % cue1
        if ~cue1_tts_played && GetSecs - startTime >= 0.0
            ppTrigger(tr_cue1);
            tts(char(Data(t, 1)), 'Microsoft Zira Desktop - English (United States)');
            cue1_tts_played = true;  % Set the flag to indicate cue 1 tts has been played
        end
        
        % cue2
        if ~cue2_tts_played && GetSecs - startTime >= 2.0
            ppTrigger(tr_cue2);
            tts(char(Data(t, 2)), 'Microsoft Zira Desktop - English (United States)');  
            cue2_tts_played = true;  % Set the flag to indicate cue 2 tts has been played
        end

        % ESC key quits the experiment
        if keyCode(KbName('ESCAPE')) == 1
            clear all
            close all
            sca
            return;
        end
    end
 
    % Check for a restart request
    if pauseNextTrial
        disp(['Pausing before current trial ' num2str(cnt)]);
        isPaused = true;  % Set the pause flag
        DrawFormattedText(window1, 'Paused. Press F2 to restart current trial.', 'center', 'center', textColor);
        Screen('Flip', window1);
        
        while isPaused
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyCode(KbName('f2'))
                isPaused = false;
                disp('Restarting current trial.');
                ppTrigger(tr_restart);
            end
            WaitSecs(0.1);
        end
        
        % Reset the pause flag and the flag for the next trial
        isPaused = false;
        pauseNextTrial = false;
    end

    % Save results to file
    fprintf(outputfile, '%d\t %d\t %s\t %s\n',...
        cnt, t, string(Data(t,1)), string(Data(t,2)));
end
ppTrigger(tr_end);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% End the experiment (don't change anything in this section)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RestrictKeysForKbCheck([]);
fclose(outputfile);
Screen(window1,'Close');
close all
sca;
return

end