clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 21
% ML RANDOM JAMMER STATE DETECTION
%
% Goal:
%
% Detect whether a random jammer is currently:
%
%   0 -> OFF
%   1 -> ON
%
% using receiver waveform features.
%
%% =========================================================


%% =========================================================
% PATH SETTINGS
%% =========================================================

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(genpath(projectRoot));


%% =========================================================
% COMMON PARAMETERS
%% =========================================================

params = defaultParameters();

params.Nbits = 10000;

params.rngSeed = 42;


%% =========================================================
% RECEIVER SATURATION
%% =========================================================

I_sat = 0.25;


%% =========================================================
% JAMMER POWER
%% =========================================================

jammerPower = 0.40;


%% =========================================================
% WINDOW SIZE
%
% Number of bits used to determine jammer state.
%% =========================================================

windowBits = 20;


%% =========================================================
% NUMBER OF WINDOWS
%% =========================================================

numTrainWindows = 2000;

numTestWindows = 600;


%% =========================================================
% FEATURE NAMES
%% =========================================================

featureNames = { ...
    'MeanCurrent', ...
    'StdCurrent', ...
    'MinCurrent', ...
    'MaxCurrent', ...
    'CurrentRange', ...
    'SaturationFraction'};


numFeatures = length(featureNames);


%% =========================================================
% DISPLAY
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 21 - ML RANDOM JAMMER STATE\n');
fprintf('============================================\n\n');

fprintf('Jammer Power = %.2f W\n', ...
    jammerPower);

fprintf('Window Size  = %d bits\n', ...
    windowBits);

fprintf('Training Windows = %d\n', ...
    numTrainWindows);

fprintf('Testing Windows  = %d\n', ...
    numTestWindows);


%% =========================================================
% =========================================================
% TRAINING DATA
% =========================================================
% =========================================================

XTrain = zeros( ...
    numTrainWindows, ...
    numFeatures);

YTrain = zeros( ...
    numTrainWindows, ...
    1);


fprintf('\n');
fprintf('============================================\n');
fprintf(' GENERATING TRAINING DATA\n');
fprintf('============================================\n\n');


for k = 1:numTrainWindows


    %% -----------------------------------------------------
    % RANDOM JAMMER STATE
    %
    % 0 = OFF
    % 1 = ON
    % ------------------------------------------------------

    jammerState = randi([0 1]);


    %% -----------------------------------------------------
    % RANDOM CHANNEL CONDITIONS
    %
    % Add variation so the classifier does not simply
    % memorize one fixed receiver condition.
    % ------------------------------------------------------

    params.Cn2 = ...
        5e-15 + ...
        (5e-14 - 5e-15) * rand;


    params.sigmaPoint = ...
        0.05 + ...
        (0.20 - 0.05) * rand;


    params.alpha = ...
        0.05 + ...
        (0.20 - 0.05) * rand;


    params.sigmaNoise = ...
        0.005 + ...
        (0.015 - 0.005) * rand;


    params.rngSeed = ...
        100000 + k;


    %% -----------------------------------------------------
    % BASELINE COMMUNICATION
    % ------------------------------------------------------

    params.enableJammer = false;

    resultsBase = runBaseline(params);


    %% -----------------------------------------------------
    % CREATE JAMMER FOR THIS WINDOW
    % ------------------------------------------------------

    if jammerState == 1

        jammerSignal = jammerModel( ...
            jammerPower, ...
            windowBits, ...
            params.samplesPerBit, ...
            true);

    else

        jammerSignal = jammerModel( ...
            0, ...
            windowBits, ...
            params.samplesPerBit, ...
            false);

    end


    %% -----------------------------------------------------
    % EXTRACT SAME-SIZED SIGNAL FROM BASELINE
    % ------------------------------------------------------

    samplesPerWindow = ...
        windowBits * params.samplesPerBit;


    rxBase = ...
        resultsBase.rxOpticalSignal( ...
            1:samplesPerWindow);


    receiverNoiseWindow = ...
        resultsBase.receiverNoise( ...
            1:samplesPerWindow);


    %% -----------------------------------------------------
    % ADD JAMMER
    % ------------------------------------------------------

    rxOpticalWindow = ...
        rxBase + jammerSignal;


    %% -----------------------------------------------------
    % PHOTODETECTION
    % ------------------------------------------------------

    rxCurrent = ...
        params.R * rxOpticalWindow;


    %% -----------------------------------------------------
    % ADD RECEIVER NOISE
    % ------------------------------------------------------

    rxCurrent = ...
        rxCurrent + receiverNoiseWindow;


    %% -----------------------------------------------------
    % FEATURE EXTRACTION
    %
    % IMPORTANT:
    %
    % Features are extracted from the current window,
    % NOT the complete communication waveform.
    % ------------------------------------------------------

    features = extractFeatures( ...
        rxCurrent, ...
        I_sat);


    %% -----------------------------------------------------
    % STORE FEATURES
    % ------------------------------------------------------

    XTrain(k,1) = ...
        features.meanCurrent;

    XTrain(k,2) = ...
        features.stdCurrent;

    XTrain(k,3) = ...
        features.minCurrent;

    XTrain(k,4) = ...
        features.maxCurrent;

    XTrain(k,5) = ...
        features.currentRange;

    XTrain(k,6) = ...
        features.saturationFraction;


    %% -----------------------------------------------------
    % STORE LABEL
    % ------------------------------------------------------

    YTrain(k) = jammerState;


    %% -----------------------------------------------------
    % PROGRESS
    % ------------------------------------------------------

    if mod(k,200) == 0

        fprintf( ...
            'Training windows: %d / %d complete\n', ...
            k, ...
            numTrainWindows);

    end

end


%% =========================================================
% =========================================================
% TEST DATA
% =========================================================
% =========================================================

XTest = zeros( ...
    numTestWindows, ...
    numFeatures);

YTest = zeros( ...
    numTestWindows, ...
    1);


fprintf('\n');
fprintf('============================================\n');
fprintf(' GENERATING TEST DATA\n');
fprintf('============================================\n\n');


for k = 1:numTestWindows


    %% -----------------------------------------------------
    % RANDOM JAMMER STATE
    % ------------------------------------------------------

    jammerState = randi([0 1]);


    %% -----------------------------------------------------
    % RANDOM CHANNEL
    % ------------------------------------------------------

    params.Cn2 = ...
        5e-15 + ...
        (5e-14 - 5e-15) * rand;


    params.sigmaPoint = ...
        0.05 + ...
        (0.20 - 0.05) * rand;


    params.alpha = ...
        0.05 + ...
        (0.20 - 0.05) * rand;


    params.sigmaNoise = ...
        0.005 + ...
        (0.015 - 0.005) * rand;


    params.rngSeed = ...
        200000 + k;


    %% -----------------------------------------------------
    % BASELINE
    % ------------------------------------------------------

    params.enableJammer = false;

    resultsBase = runBaseline(params);


    %% -----------------------------------------------------
    % WINDOW SIZE
    % ------------------------------------------------------

    samplesPerWindow = ...
        windowBits * params.samplesPerBit;


    rxBase = ...
        resultsBase.rxOpticalSignal( ...
            1:samplesPerWindow);


    receiverNoiseWindow = ...
        resultsBase.receiverNoise( ...
            1:samplesPerWindow);


    %% -----------------------------------------------------
    % JAMMER
    % ------------------------------------------------------

    if jammerState == 1

        jammerSignal = jammerModel( ...
            jammerPower, ...
            windowBits, ...
            params.samplesPerBit, ...
            true);

    else

        jammerSignal = zeros( ...
            1, ...
            samplesPerWindow);

    end


    %% -----------------------------------------------------
    % JAMMED OPTICAL SIGNAL
    % ------------------------------------------------------

    rxOpticalWindow = ...
        rxBase + jammerSignal;


    %% -----------------------------------------------------
    % PHOTODETECTION
    % ------------------------------------------------------

    rxCurrent = ...
        params.R * rxOpticalWindow;


    %% -----------------------------------------------------
    % RECEIVER NOISE
    % ------------------------------------------------------

    rxCurrent = ...
        rxCurrent + receiverNoiseWindow;


    %% -----------------------------------------------------
    % FEATURES
    % ------------------------------------------------------

    features = extractFeatures( ...
        rxCurrent, ...
        I_sat);


    %% -----------------------------------------------------
    % STORE
    % ------------------------------------------------------

    XTest(k,1) = ...
        features.meanCurrent;

    XTest(k,2) = ...
        features.stdCurrent;

    XTest(k,3) = ...
        features.minCurrent;

    XTest(k,4) = ...
        features.maxCurrent;

    XTest(k,5) = ...
        features.currentRange;

    XTest(k,6) = ...
        features.saturationFraction;


    YTest(k) = jammerState;


    %% -----------------------------------------------------
    % PROGRESS
    % ------------------------------------------------------

    if mod(k,100) == 0

        fprintf( ...
            'Test windows: %d / %d complete\n', ...
            k, ...
            numTestWindows);

    end

end


%% =========================================================
% =========================================================
% TRAIN RANDOM FOREST CLASSIFIER
% =========================================================
% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' TRAINING RANDOM FOREST CLASSIFIER\n');
fprintf('============================================\n\n');


numTrees = 200;


model = TreeBagger( ...
    numTrees, ...
    XTrain, ...
    YTrain, ...
    'Method', 'classification', ...
    'OOBPrediction', 'On', ...
    'OOBPredictorImportance', 'On');


fprintf('Training complete.\n');


%% =========================================================
% PREDICTION
%% =========================================================

YPredCell = predict( ...
    model, ...
    XTest);


YPred = ...
    str2double(YPredCell);


%% =========================================================
% CONFUSION MATRIX
%% =========================================================

confusionMatrix = ...
    confusionmat( ...
        YTest, ...
        YPred);


%% =========================================================
% ACCURACY
%% =========================================================

accuracy = ...
    sum(YPred == YTest) / ...
    length(YTest);


%% =========================================================
% PRECISION / RECALL / F1
%
% Treat JAMMER ON = positive class.
%% =========================================================

TP = confusionMatrix(2,2);

TN = confusionMatrix(1,1);

FP = confusionMatrix(1,2);

FN = confusionMatrix(2,1);


precision = ...
    TP / max(TP + FP, eps);


recall = ...
    TP / max(TP + FN, eps);


F1 = ...
    2 * precision * recall / ...
    max(precision + recall, eps);


%% =========================================================
% DISPLAY
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' ML JAMMER STATE DETECTION RESULTS\n');
fprintf('============================================\n\n');


fprintf('Accuracy  = %.2f %%\n', ...
    100 * accuracy);


fprintf('Precision = %.4f\n', ...
    precision);


fprintf('Recall    = %.4f\n', ...
    recall);


fprintf('F1 Score  = %.4f\n', ...
    F1);


fprintf('\n');
fprintf('Confusion Matrix:\n');

fprintf('\n');

fprintf('              Pred OFF    Pred ON\n');

fprintf('Actual OFF    %8d    %8d\n', ...
    TN, FP);

fprintf('Actual ON     %8d    %8d\n', ...
    FN, TP);


%% =========================================================
% FIGURE 1
% CONFUSION MATRIX
%% =========================================================

figure;


confusionchart( ...
    YTest, ...
    YPred, ...
    'RowSummary', ...
    'row-normalized', ...
    'ColumnSummary', ...
    'column-normalized');


title( ...
    'Experiment 21: ML Random Jammer State Detection');


%% =========================================================
% FIGURE 2
% FEATURE IMPORTANCE
%% =========================================================

figure;


importance = ...
    model.OOBPermutedPredictorDeltaError;


bar(importance);


grid on;


xticks(1:numFeatures);

xticklabels(featureNames);

xtickangle(30);


ylabel('Predictor Importance');


title( ...
    'Experiment 21: Jammer State Feature Importance');


%% =========================================================
% SAVE DATASET
%% =========================================================

save( ...
    'randomJammerStateDataset.mat', ...
    'XTrain', ...
    'YTrain', ...
    'XTest', ...
    'YTest', ...
    'featureNames');


%% =========================================================
% SAVE MODEL
%% =========================================================

save( ...
    'randomJammerStateModel.mat', ...
    'model', ...
    'featureNames', ...
    'I_sat', ...
    'windowBits');


%% =========================================================
% FINAL
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 21 COMPLETE\n');
fprintf('============================================\n\n');


fprintf('Dataset saved as:\n');

fprintf('randomJammerStateDataset.mat\n\n');


fprintf('Model saved as:\n');

fprintf('randomJammerStateModel.mat\n\n');


fprintf('The ML classifier now detects whether\n');

fprintf('the jammer is currently ON or OFF.\n\n');


fprintf('Next step:\n');

fprintf('Integrate jammer state detection with\n');

fprintf('ML jammer power estimation.\n\n');