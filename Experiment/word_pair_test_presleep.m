function word_pair_test_presleep(subID)
% Psychtoolbox setting
backgroundColor = 255;
textColor = 0;
responseKeys = {'a','b','c','d','e','f','g','h','i','j','k',...
    'l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'};
responseKeys_1 = {'1!','2@','3#','f1','f2'};

% trigger
tr_starting = 21;
tr_fixation = 22;
tr_show = 23;
tr_cue1 = 24;
tr_enter = 25;
tr_level = 26;
tr_rest = 27; % click
tr_ans = 28;
tr_cue2 = 29;
tr_cue3 = 30;
tr_end = 31;
tr_pause = 111;
tr_restart = 222;

% Start
ppTrigger(tr_starting);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Set up the experiment (don't modify this section)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Visuospatial; % Load all the settings from the file
rand('state', sum(100*clock)); % Initialize the random number generator

% Keyboard setup
KbName('UnifyKeyNames');
KbCheckList = [KbName('space'),KbName('ESCAPE'),KbName('Return'),KbName('BackSpace')];
for i = 1:length(responseKeys)
    KbCheckList = [KbName(responseKeys{i}),KbCheckList];
end
RestrictKeysForKbCheck(KbCheckList);

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
fprintf(outputfile, 'subID\t trial\t order\t Word_first\t Word_second\t Word_write\t ReponseTime\t Level\t ClickTime\n');

% Randomize the trial list
randomizedTrials = randperm(nTrials);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run experiment

% Start screen
Screen('TextSize',window1,80);
DrawFormattedText(window1, 'Test before sleep \n\n Press spacebar button to start', 'center', 'center', textColor);
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
isPaused = false;
pauseNextTrial = false;
for t = randomizedTrials
    cnt = cnt+1;
    disp(['current trial: ' num2str(cnt)]);
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

    Screen('TextSize',window1,100);
    DrawFormattedText(window1, [char(Data(t,1)) '\n\n' '?'], 'center', 'center', textColor);
    startTime=Screen('Flip', window1);
    
    rt = 0;
    rt_2 = 0;
    resp = ''; 
    resp_2 = 0;
    
    cue1_tts_played = false;
    enterKeyPressed = false;

    while GetSecs - startTime < 10            
        respTime = GetSecs;
        
        % cue1
        if ~cue1_tts_played && GetSecs - startTime >= 0.0
            ppTrigger(tr_cue1);
            tts(char(Data(t, 1)), 'Microsoft Zira Desktop - English (United States)');
            cue1_tts_played = true;  % Set the flag to indicate cue 1 tts has been played
        end 
        
        % Check for 'Enter' key only if it hasn't been pressed before
        if ~enterKeyPressed
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyCode(KbName('Return')) == 1
                enterKeyPressed = true;
                
                % Enter Trigger
                ppTrigger(tr_enter)
                % Reaction Time for 'Enter' key press
                rt = respTime - startTime;

                % Process 'Enter' key press here if needed
            end
        end
        
        % Rest of the code inside the while loop
        [keyIsDown,secs,keyCode] = KbCheck;
        pressedKeys = find(keyCode);
           
        % ESC key quits the experiment
        if keyCode(KbName('ESCAPE')) == 1
            clear all
            close all
            sca
            return;
        end
        
        % Check for backspace key
        if ~enterKeyPressed && keyCode(KbName('BackSpace')) == 1 && ~isempty(resp)
            % Remove the last character from the spelled-out text
            resp = resp(1:end-1);

            % Display the updated spelled-out text with the last character removed
            Screen('TextSize', window1, 100);
            DrawFormattedText(window1, [char(Data(t,1)) '\n\n' resp], 'center', 'center', textColor);
            Screen('Flip', window1);

            WaitSecs(0.2);
        end

        % Check for response keys
        if ~enterKeyPressed && ~isempty(pressedKeys)
            for i = 1:length(responseKeys)
                if KbName(responseKeys{i}) == pressedKeys(1)
                    tmp = responseKeys{i};
                    KbReleaseWait();

                    % Update the spelled-out text
                    resp = [resp tmp];

                    % Display the updated spelled-out text
                    Screen('TextSize', window1, 100);
                    DrawFormattedText(window1, [char(Data(t,1)) '\n\n' resp], 'center', 'center', textColor);
                    Screen('Flip', window1);
                end
            end
        end

        % Check for pause (F1)
        if keyCode(KbName('f1')) == 1 && ~pauseNextTrial
            ppTrigger(tr_pause);
            pauseNextTrial = true;
            disp(['Pause requested before current trial ' num2str(cnt)]);
        end
    end
    if rt==0
        rt=10.0;
    end   
    
    if isempty(resp)
        resp = 'None';
    end
    % show level
    ppTrigger(tr_level);
    
    Screen('TextSize',window1,100);
    DrawFormattedText(window1, ['Difficulty of Word Recall' '\n\n\n' 'Easy           Medium           Hard' '\n\n' ' 1                    2                   3'], 'center', 'center', textColor);
    Screen('Flip', window1);
    
    % Check for response keys
    rt_start = GetSecs;
    while 1
        [keyIsDown,secs,keyCode] = KbCheck;
        if keyCode(KbName('1!')) == 1
            resp_2 = '1';
            break
        elseif keyCode(KbName('2@')) == 1
            resp_2 = '2';
            break
        elseif keyCode(KbName('3#')) == 1
            resp_2 = '3';
            break
        end
    end
    rt_2 = GetSecs-rt_start;

    % Show fixation cross
    ppTrigger(tr_rest);
    
    Screen(window1,'FillRect',backgroundColor);
    DrawFormattedText(window1, ' ', 'center', 'center', textColor);
    Screen('Flip', window1);

    WaitSecs(1);

    % show answer
    ppTrigger(tr_ans);       

    Screen('TextSize',window1,100);
    DrawFormattedText(window1, [char(Data(t,1)) '\n\n' char(Data(t,2))], 'center', 'center', textColor);
    startTime2=Screen('Flip', window1);
    
    cue2_tts_played = false;  % Flag to track if cue 1 tts has been played
    cue3_tts_played = false;  % Flag to track if cue 2 tts has been played

    while GetSecs - startTime2 < 4
        [keyIsDown,secs,keyCode] = KbCheck;

        % cue1
        if ~cue2_tts_played && GetSecs - startTime2 >= 0.0
            ppTrigger(tr_cue2);
            tts(char(Data(t, 1)), 'Microsoft Zira Desktop - English (United States)');
            cue2_tts_played = true;  % Set the flag to indicate cue 1 tts has been played
        end

        % cue2
        if ~cue3_tts_played && GetSecs - startTime2 >= 2.0
            ppTrigger(tr_cue3);
            tts(char(Data(t, 2)), 'Microsoft Zira Desktop - English (United States)');
            cue3_tts_played = true;  % Set the flag to indicate cue 2 tts has been played
        end
    end

    % Save results to file
    resp_1 = resp';
    fprintf(outputfile, '%d\t %d\t %s\t %s\t %s\t %f\t %s\t %f\n',...
    cnt, t, string(Data(t,1)), string(Data(t,2)), resp_1, rt, resp_2, rt_2);      

    % Check for a restart request (F2)
    if pauseNextTrial
        disp(['Pausing before current trial ' num2str(cnt)]);
        isPaused = true;
        DrawFormattedText(window1, 'Paused. Press F2 to restart current trial.', 'center', 'center', textColor);
        Screen('Flip', window1);

        while isPaused
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyCode(KbName('f2'))
                isPaused = false;
                disp('Restarting current trial.');
                ppTrigger(tr_restart);  % Trigger 999 when restarting trial
            end
            WaitSecs(0.1);
        end

        % Reset the pause flag and the flag for the next trial
        isPaused = false;
        pauseNextTrial = false;
    end
end
ppTrigger(tr_end);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% End the experiment (don't change anything in this section)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RestrictKeysForKbCheck([]);
fclose(outputfile);
Screen(window1,'Close');
close all
sca;
return
end