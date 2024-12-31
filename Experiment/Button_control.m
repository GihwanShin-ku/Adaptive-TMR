classdef Button_control < matlab.apps.AppBase

    % Properties
    properties (Access = public)
        UIFigure         matlab.ui.Figure
        ONButton         matlab.ui.control.Button
        OFFButton        matlab.ui.control.Button
        EndSaveButton    matlab.ui.control.Button  % Combined "End & Save" button
        % TimeLabel        matlab.ui.control.Label
        DisaledLabel     matlab.ui.control.Label
        TimeRecord       cell  % Cell array to store recorded times and states
        FilePath char  % File path to the saved text file
    end

    properties (Access = private)
        ExperimentStartButton  matlab.ui.control.Button
        % ExperimentEndButton    matlab.ui.control.Button
    end

    methods (Access = private)

        function createExperimentStartButton(app)
            % Create the "Start" button
            app.ExperimentStartButton = uibutton(app.UIFigure);
            app.ExperimentStartButton.Text = 'Start';
            app.ExperimentStartButton.Position = [50, 280, 200, 40];  % Adjusted width
            app.ExperimentStartButton.ButtonPushedFcn = @app.startExperiment;
        end
        
        function createONButton(app)
            % Create the "ON" button (with desired labels)
            app.ONButton = uibutton(app.UIFigure);
            app.ONButton.ButtonPushedFcn = @app.ONButtonPushed;
            app.ONButton.Position = [50, 160, 100, 90];  % Adjusted width
            app.ONButton.Text = {'ON'; 'N2 & N3'};
            app.ONButton.FontWeight = 'bold';  % Bold text
        end
        
        function createOFFButton(app)
            % Create the "OFF" button (with desired labels)
            app.OFFButton = uibutton(app.UIFigure);
            app.OFFButton.ButtonPushedFcn = @app.OFFButtonPushed;
            app.OFFButton.Position = [160, 160, 100, 90];  % Adjusted width
            app.OFFButton.Text = {'OFF'; 'W & N1 & R'};
            app.OFFButton.FontWeight = 'bold';  % Bold text
        end

        function createEndSaveButton(app)
            % Create the "End & Save" button
            buttonWidth = 200;  % Set the desired width
            app.EndSaveButton = uibutton(app.UIFigure);
            app.EndSaveButton.Text = {'End & Save'; '클릭 시 10초 후 닫힘'};  % Modify the button text
            app.EndSaveButton.Position = [50, 80, buttonWidth, 40];  % Same width as "Start" button
            app.EndSaveButton.ButtonPushedFcn = @app.endSaveExperiment;  % Use a new callback function
        end
        
        function startExperiment(app, ~, ~)
            app.ONButton.BackgroundColor = [0.94 0.94 0.94];
            app.OFFButton.BackgroundColor = [0.94 0.94 0.94];
            app.ExperimentStartButton.BackgroundColor = [0.53 0.81 0.98];
            app.EndSaveButton.BackgroundColor = [0.94 0.94 0.94];

            % Callback function for the "Start" button
            currentTime = datestr(now, 'HHMMSS.FFF');
            app.TimeRecord{end+1} = ['Start_' currentTime];  % Modified here
            % app.updateTimeLabel();
        end

        % function updateTimeLabel(app)
        %     if ~isempty(app.TimeRecord)
        %         latestEvent = app.TimeRecord{end};
        %         app.TimeLabel.Text = ['Current Status: ' latestEvent];
        %     else
        %         app.TimeLabel.Text = 'Current Status: ';
        %     end
        % end

        function ONButtonPushed(app, ~, ~)
            app.ONButton.BackgroundColor = [0.53 0.81 0.98];
            app.OFFButton.BackgroundColor = [0.94 0.94 0.94];
            app.ExperimentStartButton.BackgroundColor = [0.94 0.94 0.94];
            app.EndSaveButton.BackgroundColor = [0.94 0.94 0.94];

            currentTime = datestr(now, 'HHMMSS.FFF');
            app.TimeRecord{end+1} = ['ON_' currentTime];
            % app.updateTimeLabel();
        end

        function OFFButtonPushed(app, ~, ~)
            app.ONButton.BackgroundColor = [0.94 0.94 0.94];
            app.OFFButton.BackgroundColor = [0.53 0.81 0.98];
            app.ExperimentStartButton.BackgroundColor = [0.94 0.94 0.94];
            app.EndSaveButton.BackgroundColor = [0.94 0.94 0.94]; 
            
            currentTime = datestr(now, 'HHMMSS.FFF');
            app.TimeRecord{end+1} = ['OFF_' currentTime];
            
            app.ONButton.Enable = 'off';
            
            t=timer('StartDelay',8,'TimerFcn',@(x,y) enableONButton(app));
            start(t)
            
            app.DisaledLabel.FontWeight = 'bold';
            app.DisaledLabel.Text = '<8초 이후 ON 버튼 클릭 가능>';
            app.DisaledLabel.Visible = 'on';
            % app.updateTimeLabel();
        end

        function enableONButton(app)
            app.ONButton.Enable = 'on';
            app.DisaledLabel.Visible = 'off';
        end

        function endSaveExperiment(app, ~, ~)
            app.ONButton.BackgroundColor = [0.94 0.94 0.94];
            app.OFFButton.BackgroundColor = [0.94 0.94 0.94];
            app.ExperimentStartButton.BackgroundColor = [0.94 0.94 0.94];
            app.EndSaveButton.BackgroundColor = [0.53 0.81 0.98];

            app.ONButton.Enable = 'off';
            app.OFFButton.Enable = 'off';
            app.ExperimentStartButton.Enable = 'off';

            % Callback function for the "End & Save" button
            currentTime = datestr(now, 'HHMMSS.FFF');
            app.TimeRecord{end+1} = ['End_Save_' currentTime];  % Modified here
            
            % Get the file path after saving
            currentDate = datestr(now, 'yyyymmdd');
            folderPath = 'TMR_button';  % Specify the folder path
            
            % Initialize a counter for suffix
            suffix = 1;
            
            % Construct the initial file name
            baseFileName = fullfile(folderPath, ['TMR_' currentDate '_control']);
            fileName = baseFileName;
            
            % Check if the file already exists, if so, increment the suffix
            while exist([fileName '.txt'], 'file')
                suffix = suffix + 1;
                fileName = [baseFileName '_' num2str(suffix)];
            end
            
            % Add the ".txt" extension
            fileName = [fileName '.txt'];
            
            % Save the times and states to the file
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

    end

    methods (Access = public)

        function app = Button_control
            app.createComponents();
            registerApp(app, app.UIFigure);

            if nargout == 0
                clear app;
            end
        end

        function createComponents(app)
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100, 100, 300, 380];  % Adjusted figure size
            app.UIFigure.Name = 'Button';

            app.createExperimentStartButton();
            app.createONButton();  % Create the "ON" button
            app.createOFFButton();  % Create the "OFF" button
            app.createEndSaveButton();  % Create the "End & Save" button

            app.DisaledLabel = uilabel(app.UIFigure);
            app.DisaledLabel.Position = [50, 250, 200, 20];
            app.DisaledLabel.Text = '';
            app.DisaledLabel.Visible = 'off';
            % Adjusted position and text for "Current Time" label
            % app.TimeLabel = uilabel(app.UIFigure);
            % app.TimeLabel.Position = [50, 340, 200, 30];  % Adjusted position
            % app.TimeLabel.Text = 'Current Status: ';  % Modified here to align with the "Start" button

            app.TimeRecord = {};
        end
    end
end