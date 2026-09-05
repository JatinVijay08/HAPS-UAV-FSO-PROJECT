clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 22
% ROBUST ML RANDOM JAMMER STATE DETECTION
%
% Goal:
%
% Detect whether the jammer is currently:
%
%       0 -> OFF
%       1 -> ON
%
% under:
%
%   1. Random jammer power
%   2. Random FSO channel conditions
%   3. Random receiver noise
%   4. Random jammer state
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

params.Nbits = 20;

params.rngSeed = 42;


%% =========================================================
% RECEIVER
%% =========================================================

I_sat = 0.25;


%% =========================================================
% WINDOW
%% =========================================================

windowBits = 20;


%% =========================================================
% JAMMER POWER RANGE
%% =========================================================

minJammerPower = 0.05;

maxJammerPower = 0.40;


%% =========================================================
% DATASET SIZE
%% =========================================================

numTrainWindows = 2500;

numTestWindows = 1000;


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
fprintf(' EXPERIMENT 22 - ROBUST ML RANDOM JAMMER\n');
fprintf(' STATE DETECTION\n');
fprintf('============================================\n\n');

fprintf('Jammer Power Range = %.2f to %.2f W\n', ...
    minJammerPower, ...
    maxJammerPower);

fprintf('Window Size        = %d bits\n', ...
    windowBits);

fprintf('Training Windows   = %d\n', ...
    numTrainWindows);

fprintf('Testing Windows    = %d\n', ...
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

trainPower = zeros( ...
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
    % Approximately 50% OFF
    % Approximately 50% ON
    % -----------------------------------------------------

    jammerState = randi([0 1]);


    %% -----------------------------------------------------
    % RANDOM JAMMER POWER
    %
    % Only relevant when jammer is ON.
    % -----------------------------------------------------

    jammerPower = ...
        minJammerPower + ...
        (maxJammerPower - minJammerPower) * rand;


    if jammerState == 0

        jammerPower = 0;

    end


    %% -----------------------------------------------------
    % RANDOM FSO CHANNEL
    % -----------------------------------------------------

    params.Cn2 = ...
        5e-15 + ...
        (5e-14 - 5e-15) * rand;


    params.sigmaPoint = ...
        0.05 + ...
        (0.20 - 0.05) * rand;


    params.alpha = ...
        0.05 + ...
        (0.20 - 0.05) * rand;


    %% -----------------------------------------------------
    % RANDOM RECEIVER NOISE
    % -----------------------------------------------------

    params.sigmaNoise = ...
        0.005 + ...
        (0.015 - 0.005) * rand;


    %% -----------------------------------------------------
    % UNIQUE RANDOM SEED
    % -----------------------------------------------------

    params.rngSeed = ...
        100000 + k;


    %% -----------------------------------------------------
    % GENERATE CLEAN BASELINE SIGNAL
    % -----------------------------------------------------

    params.enableJammer = false;

    resultsBase = runBaseline(params);


    %% -----------------------------------------------------
    % GENERATE JAMMER
    % -----------------------------------------------------

    if jammerState == 1

        jammerSignal = jammerModel( ...
            jammerPower, ...
            windowBits, ...
            params.samplesPerBit, ...
            true);

    else

        jammerSignal = zeros( ...
            1, ...
            windowBits * params.samplesPerBit);

    end


    %% -----------------------------------------------------
    % ADD JAMMER TO OPTICAL SIGNAL
    % -----------------------------------------------------

    rxOpticalWindow = ...
        resultsBase.rxOpticalSignal + ...
        jammerSignal;


    %% -----------------------------------------------------
    % RECEIVER
    %
    % We use the receiver only to generate the observed
    % electrical waveform and apply the physical receiver
    % effects.
    % -----------------------------------------------------

    [~, ~, rxCurrent, ~, ~] = ...
        receiverModel( ...
            rxOpticalWindow, ...
            resultsBase.bits, ...
            params.Pt, ...
            resultsBase.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            resultsBase.receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % EXTRACT FEATURES
    % -----------------------------------------------------

    features = extractFeatures( ...
        rxCurrent, ...
        I_sat);


    %% -----------------------------------------------------
    % STORE FEATURES
    % -----------------------------------------------------

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
    % -----------------------------------------------------

    YTrain(k) = jammerState;


    %% -----------------------------------------------------
    % STORE POWER FOR ANALYSIS
    % -----------------------------------------------------

    trainPower(k) = jammerPower;


    %% -----------------------------------------------------
    % PROGRESS
    % -----------------------------------------------------

    if mod(k,250) == 0

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

testPower = zeros( ...
    numTestWindows, ...
    1);


fprintf('\n');
fprintf('============================================\n');
fprintf(' GENERATING UNSEEN TEST DATA\n');
fprintf('============================================\n\n');


for k = 1:numTestWindows


    %% -----------------------------------------------------
    % RANDOM STATE
    % -----------------------------------------------------

    jammerState = randi([0 1]);


    %% -----------------------------------------------------
    % RANDOM JAMMER POWER
    % -----------------------------------------------------

    jammerPower = ...
        minJammerPower + ...
        (maxJammerPower - minJammerPower) * rand;


    if jammerState == 0

        jammerPower = 0;

    end


    %% -----------------------------------------------------
    % RANDOM CHANNEL
    % -----------------------------------------------------

    params.Cn2 = ...
        5e-15 + ...
        (5e-14 - 5e-15) * rand;


    params.sigmaPoint = ...
        0.05 + ...
        (0.20 - 0.05) * rand;


    params.alpha = ...
        0.05 + ...
        (0.20 - 0.05) * rand;


    %% -----------------------------------------------------
    % RANDOM NOISE
    % -----------------------------------------------------

    params.sigmaNoise = ...
        0.005 + ...
        (0.015 - 0.005) * rand;


    %% -----------------------------------------------------
    % DIFFERENT SEED FROM TRAINING
    % -----------------------------------------------------

    params.rngSeed = ...
        200000 + k;


    %% -----------------------------------------------------
    % CLEAN BASELINE
    % -----------------------------------------------------

    params.enableJammer = false;

    resultsBase = runBaseline(params);


    %% -----------------------------------------------------
    % JAMMER
    % -----------------------------------------------------

    if jammerState == 1

        jammerSignal = jammerModel( ...
            jammerPower, ...
            windowBits, ...
            params.samplesPerBit, ...
            true);

    else

        jammerSignal = zeros( ...
            1, ...
            windowBits * params.samplesPerBit);

    end


    %% -----------------------------------------------------
    % JAMMED OPTICAL SIGNAL
    % -----------------------------------------------------

    rxOpticalWindow = ...
        resultsBase.rxOpticalSignal + ...
        jammerSignal;


    %% -----------------------------------------------------
    % RECEIVER
    % -----------------------------------------------------

    [~, ~, rxCurrent, ~, ~] = ...
        receiverModel( ...
            rxOpticalWindow, ...
            resultsBase.bits, ...
            params.Pt, ...
            resultsBase.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            resultsBase.receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % FEATURES
    % -----------------------------------------------------

    features = extractFeatures( ...
        rxCurrent, ...
        I_sat);


    %% -----------------------------------------------------
    % STORE
    % -----------------------------------------------------

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


    %% -----------------------------------------------------
    % LABEL
    % -----------------------------------------------------

    YTest(k) = jammerState;


    %% -----------------------------------------------------
    % POWER
    % -----------------------------------------------------

    testPower(k) = jammerPower;


    %% -----------------------------------------------------
    % PROGRESS
    % -----------------------------------------------------

    if mod(k,100) == 0

        fprintf( ...
            'Test windows: %d / %d complete\n', ...
            k, ...
            numTestWindows);

    end

end


%% =========================================================
% =========================================================
% TRAIN RANDOM FOREST
% =========================================================
% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' TRAINING ROBUST RANDOM FOREST\n');
fprintf('============================================\n\n');


numTrees = 250;


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
% =========================================================

YPredCell = predict( ...
    model, ...
    XTest);


YPred = str2double(YPredCell);


%% =========================================================
% CONFUSION MATRIX
% =========================================================

confusionMatrix = ...
    confusionmat( ...
        YTest, ...
        YPred);


%% =========================================================
% PERFORMANCE
% =========================================================

accuracy = ...
    mean(YPred == YTest);


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
% FALSE ALARM RATE
%% =========================================================

falseAlarmRate = ...
    FP / max(FP + TN, eps);


%% =========================================================
% MISS RATE
%% =========================================================

missRate = ...
    FN / max(FN + TP, eps);


%% =========================================================
% DISPLAY RESULTS
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' ROBUST ML JAMMER STATE RESULTS\n');
fprintf('============================================\n\n');


fprintf('Accuracy        = %.2f %%\n', ...
    100 * accuracy);


fprintf('Precision       = %.4f\n', ...
    precision);


fprintf('Recall          = %.4f\n', ...
    recall);


fprintf('F1 Score        = %.4f\n', ...
    F1);


fprintf('False Alarm Rate = %.4f\n', ...
    falseAlarmRate);


fprintf('Miss Rate        = %.4f\n', ...
    missRate);


fprintf('\n');
fprintf('Confusion Matrix:\n\n');


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
    'Experiment 22: Robust ML Random Jammer State Detection');


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
    'Experiment 22: Robust Jammer State Feature Importance');


%% =========================================================
% FIGURE 3
% JAMMER POWER DISTRIBUTION
%
% Shows the range of jammer powers used in the
% test dataset.
%% =========================================================

figure;


histogram( ...
    testPower(testPower > 0), ...
    20);


grid on;


xlabel('Jammer Power (W)');

ylabel('Number of Windows');


title( ...
    'Experiment 22: Test Jammer Power Distribution');


%% =========================================================
% SAVE DATASET
%% =========================================================

save( ...
    'randomJammerRobustStateDataset.mat', ...
    'XTrain', ...
    'YTrain', ...
    'XTest', ...
    'YTest', ...
    'trainPower', ...
    'testPower', ...
    'featureNames');


%% =========================================================
% SAVE MODEL
%% =========================================================

save( ...
    'randomJammerRobustStateModel.mat', ...
    'model', ...
    'featureNames', ...
    'I_sat', ...
    'windowBits');


%% =========================================================
% FINAL
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 22 COMPLETE\n');
fprintf('============================================\n\n');


fprintf('Dataset saved as:\n');

fprintf('randomJammerRobustStateDataset.mat\n\n');


fprintf('Model saved as:\n');

fprintf('randomJammerRobustStateModel.mat\n\n');


fprintf('The classifier was tested under:\n');

fprintf('  - Random jammer power\n');

fprintf('  - Random jammer state\n');

fprintf('  - Turbulence variation\n');

fprintf('  - Pointing variation\n');

fprintf('  - Atmospheric attenuation variation\n');

fprintf('  - Receiver noise variation\n\n');


fprintf('Next step:\n');

fprintf('Integrate jammer state detection with\n');

fprintf('ML jammer power estimation.\n\n');