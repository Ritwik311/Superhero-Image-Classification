classdef superhero_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure        matlab.ui.Figure
        Label           matlab.ui.control.Label
        classifyButton  matlab.ui.control.Button
        selectButton    matlab.ui.control.Button
        trainButton     matlab.ui.control.Button
        UIAxes          matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: trainButton
        function trainButtonPushed(app, event)
            global net;
            net = googlenet;
            analyzeNetwork(net)
            Input_Layer_Size = net.Layers(1).InputSize(1:2);
            dataFolder = fullfile('C:\Users\Ritwik\Downloads\Superhero_Dataset_Final\Train');
            f = imageDatastore(dataFolder,'IncludeSubfolders',true,'LabelSource','foldernames');
            [Training_Dataset, Validation_Dataset, Testing_Dataset] = splitEachLabel(f, 0.7, 0.15, 0.15);
            augmenter = imageDataAugmenter('RandXReflection', true);
            Resized_Training_Dataset = augmentedImageDatastore(Input_Layer_Size ,Training_Dataset,'ColorPreprocessing', 'gray2rgb', 'DataAugmentation', augmenter);
            Resized_Validation_Dataset = augmentedImageDatastore(Input_Layer_Size ,Validation_Dataset);
            Resized_Testing_Dataset = augmentedImageDatastore(Input_Layer_Size ,Testing_Dataset);
            Feature_Learner = net.Layers(142).Name;
            Output_Classifier = net.Layers(144).Name;
            Number_of_Classes = numel(categories(Training_Dataset.Labels));

            New_Feature_Learner = fullyConnectedLayer(Number_of_Classes, ...
                                    'Name', 'Vehicle Feature Learner', ...
                                    'WeightLearnRateFactor', 10, ...
                                    'BiasLearnRateFactor', 10);
            New_Classifier_Layer = classificationLayer('Name', 'Vehicle Classifier');

            Network_Architecture = layerGraph(net);

            New_Network = replaceLayer(Network_Architecture, Feature_Learner, New_Feature_Learner);
            New_Network = replaceLayer(New_Network, Output_Classifier, New_Classifier_Layer);

            analyzeNetwork(New_Network)
            Minibatch_Size = 4;
            Validation_Frequency = floor(numel(Resized_Training_Dataset.Files)/Minibatch_Size);
            Training_Options = trainingOptions('sgdm', ...
                'MiniBatchSize', Minibatch_Size, ...
                'MaxEpochs', 6, ...
                'InitialLearnRate', 3e-4, ...
                'Shuffle', 'every-epoch', ...
                'ValidationData', Resized_Validation_Dataset, ...
                'ValidationFrequency', Validation_Frequency, ...
                'Verbose', false, ...
                'Plots', 'training-progress');
           
            net = trainNetwork(Resized_Training_Dataset, New_Network, Training_Options);
        end

        % Button pushed function: selectButton
        function selectButtonPushed(app, event)
            global im;
[rawname,rawpath]=uigetfile(('*.jpg'),'SelectImage');
fullname=[rawpath rawname];
im=imread(fullname);
app.UIAxes.Title.String = 'Input image';
imshow(im,'Parent',app.UIAxes);
        end

        % Button pushed function: classifyButton
        function classifyButtonPushed(app, event)
            global net;
            global im;
            sz = net.Layers(1).InputSize
            I = imresize(im, sz(1:2));
            label = classify(net, I)
            app.Label.Text = label;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Image')
            app.UIAxes.Position = [78 274 300 185];

            % Create trainButton
            app.trainButton = uibutton(app.UIFigure, 'push');
            app.trainButton.ButtonPushedFcn = createCallbackFcn(app, @trainButtonPushed, true);
            app.trainButton.Position = [78 238 100 23];
            app.trainButton.Text = 'train';

            % Create selectButton
            app.selectButton = uibutton(app.UIFigure, 'push');
            app.selectButton.ButtonPushedFcn = createCallbackFcn(app, @selectButtonPushed, true);
            app.selectButton.Position = [377 238 100 23];
            app.selectButton.Text = 'select';

            % Create classifyButton
            app.classifyButton = uibutton(app.UIFigure, 'push');
            app.classifyButton.ButtonPushedFcn = createCallbackFcn(app, @classifyButtonPushed, true);
            app.classifyButton.Position = [244 177 100 23];
            app.classifyButton.Text = 'classify';

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.Position = [276 118 102 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = superhero_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end