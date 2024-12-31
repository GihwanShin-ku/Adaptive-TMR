classdef Button_TMR < matlab.apps.AppBase

    % Properties
    properties (Access = public)
        UIFigure         matlab.ui.Figure
        ONButton         matlab.ui.control.Button
        OFFButton        matlab.ui.control.Button
        EndSaveButton    matlab.ui.control.Button
        % TimeLabel        matlab.ui.control.Label
        DisaledLabel     matlab.ui.control.Label
        TimeRecord       cell  % Cell array to store recorded times and states
    end

    properties (Access = private)
        ExperimentStartButton  matlab.ui.control.Button
        ExperimentEndButton    matlab.ui.control.Button
        originalWordList cell  % Original cell array for the list of words
        wordList cell  % Cell array for the list of words to be used
        isTTSActive logical = false;  % Control flag for TTS
        currentWordPairIndex = 1;  % To keep track of the current word pair index
        pausedIndex = 0;  % To keep track of the index where TTS was paused
        ttsStartTime = 0;  % To store TTS start time
        isFirstONButtonPush = true;  % Flag to indicate the first ON button push
        isPaused = false; % Flag to indicate if TTS is paused
    end

    % Private methods
    methods (Access = private)

        function createExperimentStartButton(app)
            % Create the "Start" button
            app.ExperimentStartButton = uibutton(app.UIFigure);
            app.ExperimentStartButton.Text = 'Start';
            app.ExperimentStartButton.Position = [50, 280, 200, 40];
            app.ExperimentStartButton.ButtonPushedFcn = @app.startExperiment;
        end

        function startExperiment(app, ~, ~)

            app.ONButton.BackgroundColor = [0.94 0.94 0.94];
            app.OFFButton.BackgroundColor = [0.94 0.94 0.94];
            app.ExperimentStartButton.BackgroundColor = [0.53 0.81 0.98];
            app.EndSaveButton.BackgroundColor = [0.94 0.94 0.94];

            currentTime = datestr(now, 'HHMMSS.FFF');
            app.TimeRecord{end+1} = ['Start_' currentTime];
            % app.updateTimeLabel('Start', currentTime);
            if app.isFirstONButtonPush
                % Shuffle wordList only on the first ON button push
                app.wordList = app.shuffleWordList(app.originalWordList);
                app.isFirstONButtonPush = false;
            end
        end

        function createONButton(app)
            % Create the "ON" button
            app.ONButton = uibutton(app.UIFigure);
            app.ONButton.ButtonPushedFcn = @app.ONButtonPushed;
            app.ONButton.Position = [50, 160, 100, 90];
            app.ONButton.Text = {'ON'; 'N2 & N3'};
            app.ONButton.FontWeight = 'bold';
        end

        function ONButtonPushed(app, ~, ~)
            if ~app.isTTSActive
                app.isTTSActive = true;
                % Check if TTS was paused and resume from the paused index

                app.ONButton.BackgroundColor = [0.53 0.81 0.98];
                app.OFFButton.BackgroundColor = [0.94 0.94 0.94];
                app.ExperimentStartButton.BackgroundColor = [0.94 0.94 0.94];
                app.EndSaveButton.BackgroundColor = [0.94 0.94 0.94];
                drawnow;

                if app.pausedIndex > 0
                    app.currentWordPairIndex = app.pausedIndex;
                    app.pausedIndex = 0;  % Reset the paused index
                end

                % Iterate through the wordList and use TTS for each word
                while true

                    % If all word pairs have been processed, reset the index
                    % and shuffle the wordList only on the first ON button push
                    if app.currentWordPairIndex > length(app.wordList)
                        app.currentWordPairIndex = 1;
                        if app.isFirstONButtonPush
                            app.wordList = app.shuffleWordList(app.originalWordList);
                        end
                    end

                    if ~app.isTTSActive
                        app.pausedIndex = app.currentWordPairIndex;
                        break;
                    end
                    
                    % Check if TTS was paused
                    if app.isPaused
                        app.isPaused = false; % Reset pause flag
                        continue;
                    end

                    wordPair = app.wordList{app.currentWordPairIndex};
                    selectedWord1 = wordPair{1};
                    selectedWord2 = wordPair{2};

                    % Update status and record for the first word
                    currentTime = datestr(now, 'HHMMSS.FFF');
                    % app.updateTimeLabel('ON', currentTime, selectedWord1);
                    app.TimeRecord{end+1} = ['ON_' currentTime '_' selectedWord1];
                    app.ttsStartTime = now;
                    tts(selectedWord1, 'Microsoft Zira Desktop - English (United States)');

                    % Calculate elapsed time and pause
                    elapsedTime = (now - app.ttsStartTime) * 24 * 3600;
                    pause(max(2 - elapsedTime, 0));               

                    % Update status and record for the second word
                    currentTime = datestr(now, 'HHMMSS.FFF');
                    % app.updateTimeLabel('ON', currentTime, selectedWord2);
                    app.TimeRecord{end+1} = ['ON_' currentTime '_' selectedWord2];
                    app.ttsStartTime = now;
                    tts(selectedWord2, 'Microsoft Zira Desktop - English (United States)');

                    % Calculate elapsed time and pause
                    elapsedTime = (now - app.ttsStartTime) * 24 * 3600;
                    pause(max(6 - elapsedTime, 0));

                    app.currentWordPairIndex = app.currentWordPairIndex + 1;
                end

                app.isTTSActive = false; % Reset the TTS flag at the end of the loop
            end
        end

        function createOFFButton(app)
            % Create the "OFF" button
            app.OFFButton = uibutton(app.UIFigure);
            app.OFFButton.ButtonPushedFcn = @app.OFFButtonPushed;
            app.OFFButton.Position = [160, 160, 100, 90];
            app.OFFButton.Text = {'OFF'; 'W & N1 & R'};
            app.OFFButton.FontWeight = 'bold';
        end

        function OFFButtonPushed(app, ~, ~)
            if app.isTTSActive
                app.ONButton.BackgroundColor = [0.94 0.94 0.94];
                app.OFFButton.BackgroundColor = [0.53 0.81 0.98];
                app.ExperimentStartButton.BackgroundColor = [0.94 0.94 0.94];
                app.EndSaveButton.BackgroundColor = [0.94 0.94 0.94]; 

                app.isTTSActive = false;
                app.isPaused = true; % Set pause flag

                % Stop the TTS
                drawnow;  % Ensure that TTS is stopped
                currentTime = datestr(now, 'HHMMSS.FFF');
                app.TimeRecord{end+1} = ['OFF_' currentTime];  % Record the OFF event
                % app.updateTimeLabel('OFF', currentTime);
                % Clear the TTS queue to stop the current TTS
                clear sound;
                
                app.ONButton.Enable = 'off';
                
                t=timer('StartDelay',8,'TimerFcn',@(x,y) enableONButton(app));
                start(t)
                
                app.DisaledLabel.FontWeight = 'bold';
                app.DisaledLabel.Text = '<8초 이후 ON 버튼 클릭 가능>';
                app.DisaledLabel.Visible = 'on';
            end
            app.pausedIndex = app.currentWordPairIndex;
        end

        function enableONButton(app)
            app.ONButton.Enable = 'on';
            app.DisaledLabel.Visible = 'off';
        end

        function createEndSaveButton(app)
            % Create the "End & Save" button
            app.EndSaveButton = uibutton(app.UIFigure);
            app.EndSaveButton.Text = {'End & Save'; '클릭 시 10초 후 닫힘'};
            app.EndSaveButton.Position = [50, 80, 200, 40];
            app.EndSaveButton.ButtonPushedFcn = @app.endSaveExperiment;
        end

        function endSaveExperiment(app, ~, ~)
            app.ONButton.BackgroundColor = [0.94 0.94 0.94];
            app.OFFButton.BackgroundColor = [0.94 0.94 0.94];
            app.ExperimentStartButton.BackgroundColor = [0.94 0.94 0.94];
            app.EndSaveButton.BackgroundColor = [0.53 0.81 0.98]; 
            
            app.isTTSActive = false;
            app.ONButton.Enable = 'off';
            app.OFFButton.Enable = 'off';
            app.ExperimentStartButton.Enable = 'off';
            
            app.ONButton.ButtonPushedFcn='';

            currentTime = datestr(now, 'HHMMSS.FFF');
            app.TimeRecord{end+1} = ['End_Save_' currentTime];
            % app.updateTimeLabel('End & Save', currentTime);
        
            % Save the time records
            folderPath = fullfile(pwd, 'TMR_button');
            currentDate = datestr(now, 'yyyymmdd');
            baseFileName = ['TMR_' currentDate '_TMR'];
            suffix = 1;
            fileName = fullfile(folderPath, baseFileName);
            while exist([fileName '.txt'], 'file')
                suffix = suffix + 1;
                fileName = fullfile(folderPath, [baseFileName '_' num2str(suffix)]);
            end
            fileName = [fileName '.txt'];
            fileID = fopen(fileName, 'w');
            for i = 1:numel(app.TimeRecord)
                fprintf(fileID, '%s\n', app.TimeRecord{i});
            end
            fclose(fileID);
            disp(['Times and states saved to file: ' fileName]);

            t = timer('StartDelay',10,'TimerFcn',@(x,y) closeApp(app, fileName));
            start(t)
        end

        function closeApp(app, fileName)
            edit(fileName);
            close(app.UIFigure);
        end

        % function updateTimeLabel(app, state, time, word)
        %     if nargin < 4
        %         app.TimeLabel.Text = ['Current Status: ' state '_' time];
        %     else
        %         app.TimeLabel.Text = ['Current Status: ' state '_' time '_' word];
        %     end
        % end

        % Shuffle the given cell array
        function shuffledArray = shuffleWordList(~, inputArray)
            n = length(inputArray);
            shuffledArray = inputArray(randperm(n));
        end
        
        % function doNothing(app,src,event)       
        % end
    end

    % Public methods
    methods (Access = public)

        function app = Button_TMR
            rng('shuffle');
            app.createComponents();
            registerApp(app, app.UIFigure);
            if nargout == 0
                clear app;
            end
        end

        function createComponents(app)
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100, 100, 300, 380];
            app.UIFigure.Name = 'Button TMR';
            % app.UIFigure.CloseRequestFcn = @app.doNothing;

            app.createExperimentStartButton();
            app.createONButton();
            app.createOFFButton();
            app.createEndSaveButton();
            
            app.DisaledLabel = uilabel(app.UIFigure);
            app.DisaledLabel.Position = [50, 250, 200, 20];
            app.DisaledLabel.Text = '';
            app.DisaledLabel.Visible = 'off';
            % app.TimeLabel = uilabel(app.UIFigure);
            % app.TimeLabel.Position = [50, 340, 200, 30];
            % app.TimeLabel.Text = 'Current Status: ';

            app.TimeRecord = {};
            app.originalWordList = { % Original cell array for the list of words
                {'event', 'festival'}
                {'flakes', 'rescue'}
                {'belief', 'restraint'}
                {'ruler', 'command'}
                {'avenue', 'thicket'}
                {'statement', 'witness'}
                {'uprising', 'shield'}
                {'assignment', 'work'}
                {'bridge', 'current'}
                {'treaty', 'pact'}
                {'factory', 'production'}
                {'machine', 'chain'}
                {'fleet', 'deck'}
                {'garden', 'gladiolus'}
                {'thought', 'saying'}
                {'joint', 'leg'}
                {'face', 'mask'}
                {'grain', 'barley'}
                {'glacier', 'bear'}
                {'group', 'person'}
                {'army', 'infantry'}
                {'pad', 'mark'}
                {'infection', 'pain'}
                {'instrument', 'oboe'}
                {'church', 'bells'}
                {'painter', 'canvas'}
                {'wall', 'balustrade'}
                {'furniture', 'backrest'}
                {'music', 'sheet'}
                {'farmer', 'contract'}
                {'plant', 'grass'}
                {'mail', 'bicycle'}
                {'travel', 'continent'}
                {'reptile', 'lizard'}
                {'play', 'expression'}
                {'ship', 'dock'}
                {'school', 'lumber'}
                {'pen', 'cap'}
                {'theory', 'practice'}
                {'animal', 'badger'}
                {'tropics', 'vaccine'}
                {'underworld', 'death'}
                {'injury', 'scab'}
                {'bird', 'claw'}
                {'weaver', 'comb'}
                {'advertisement', 'pillar'}
                {'apartment', 'room'}
                {'brake', 'turn'}
                {'celebration', 'beer'}
                {'giant', 'step'}
                {'sports', 'time'}
                {'road', 'tar'}
                {'insect', 'worm'}
                {'ocean', 'algae'}
                {'museum', 'finding'}
                {'waterside', 'dam'}
                {'decency', 'courtesy'}
                {'watercolors', 'gallery'}
                {'car', 'headlights'}
                {'hill', 'boulder'}
                {'job', 'butcher'}
                {'library', 'signature'}
                {'book', 'author'}
                {'railroad', 'train'}
                {'energy', 'oil'}
                {'earth', 'element'}
                {'outcome', 'achievement'}
                {'fire', 'stove'}
                {'bottle', 'paper'}
                {'airplane', 'ketchup'}
                {'friend', 'faithful'}
                {'building', 'shed'}
                {'mountains', 'flag'}
                {'jail', 'offense'}
                {'grill', 'summer'}
                {'store', 'doll'}
                {'cellar', 'grate'}
                {'clothes', 'fly'}
                {'body', 'tendon'}
                {'crisis', 'shortage'}
                {'kitchen', 'bucket'}
                {'shore', 'dune'}
                {'laboratory', 'pipette'}
                {'shop', 'commercial'}
                {'landscape', 'swamp'}
                {'force', 'fight'}
                {'girl', 'date'}
                {'cross-stitch', 'seam'}
                {'storm', 'air'}
                {'radio', 'voice'}
                {'rain', 'barrel'}
                {'gun', 'gauge'}
                {'chess', 'tower'}
                {'blacksmith', 'horseshoe'}
                {'toy', 'plastic'}
                {'bouquet', 'tulip'}
                {'theatre', 'line'}
                {'decree', 'notification'}
                {'forest', 'maple'}
                {'wine', 'flower'}
                {'wedding', 'altar'}
                {'fir', 'bark'}
                {'clock', 'gear'}
                {'winter', 'accident'}
            };
            app.wordList = app.shuffleWordList(app.originalWordList); % Initial shuffle
        end
    end
end
