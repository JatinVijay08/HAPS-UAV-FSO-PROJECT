clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 20
% ML JAMMER POWER ESTIMATION - ROBUSTNESS TEST
%
% Goal:
%
% Test whether the ML jammer power estimator remains
% accurate when legitimate FSO channel conditions vary.
%
% Variables:
%
%   1. Turbulence
%   2. Pointing error
%   3. Atmospheric attenuation
%   4. Receiver noise
%   5. Jammer power
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


%% =========================================================
% RECEIVER SATURATION
%% =========================================================

I_sat = 0.25;


%% =========================================================
% DATASET SIZE
%% =========================================================

numTrainSamples = 1200;

numTestSamples = 400;


%% =========================================================
% JAMMER POWER RANGE
%% =========================================================

minJammerPower = 0.02;

maxJammerPower = 0.40;


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
fprintf(' EXPERIMENT 20 - ML ROBUSTNESS TEST\n');
fprintf('============================================\n\n');

fprintf('Training Samples = %d\n', ...
    numTrainSamples);

fprintf('Testing Samples  = %d\n', ...
    numTestSamples);

fprintf('\nChannel parameters will vary.\n');


%% =========================================================
% =========================================================
% TRAINING DATA
% =========================================================
% =========================================================

XTrain = zeros( ...
    numTrainSamples, ...
    numFeatures);

YTrain = zeros( ...
    numTrainSamples, ...
    1);


fprintf('\n');
fprintf('============================================\n');
fprintf(' GENERATING TRAINING DATA\n');
fprintf('============================================\n\n');


for k = 1:numTrainSamples


    %% -----------------------------------------------------
    % JAMMER POWER
    % ------------------------------------------------------

    jammerPower = ...
        minJammerPower + ...
        (maxJammerPower - minJammerPower) * rand;


    %% -----------------------------------------------------
    % RANDOM CHANNEL CONDITIONS
    %
    % These ranges are intentionally varied around the
    % nominal system parameters.
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


    %% -----------------------------------------------------
    % UNIQUE RANDOM SEED
    % ------------------------------------------------------

    params.rngSeed = 10000 + k;


    %% -----------------------------------------------------
    % BASELINE FSO SIGNAL
    % ------------------------------------------------------

    params.enableJammer = false;

    resultsBase = runBaseline(params);


    %% -----------------------------------------------------
    % CONSTANT JAMMER
    % ------------------------------------------------------

    jammerSignal = jammerModel( ...
        jammerPower, ...
        params.Nbits, ...
        params.samplesPerBit, ...
        true);


    %% -----------------------------------------------------
    % JAMMED OPTICAL SIGNAL
    % ------------------------------------------------------

    rxOpticalJammed = ...
        resultsBase.rxOpticalSignal + ...
        jammerSignal;


    %% -----------------------------------------------------
    % PRE-SATURATION CURRENT
    % ------------------------------------------------------

    rxCurrentPreSat = ...
        params.R * rxOpticalJammed;


    %% -----------------------------------------------------
    % ADD RECEIVER NOISE
    % ------------------------------------------------------

    rxCurrentPreSat = ...
        rxCurrentPreSat + ...
        resultsBase.receiverNoise;


    %% -----------------------------------------------------
    % FEATURE EXTRACTION
    % ------------------------------------------------------

    features = extractFeatures( ...
        rxCurrentPreSat, ...
        I_sat);


    %% -----------------------------------------------------
    % STORE FEATURES
    % ------------------------------------------------------

    XTrain(k,1) = features.meanCurrent;

    XTrain(k,2) = features.stdCurrent;

    XTrain(k,3) = features.minCurrent;

    XTrain(k,4) = features.maxCurrent;

    XTrain(k,5) = features.currentRange;

    XTrain(k,6) = features.saturationFraction;


    %% -----------------------------------------------------
    % TARGET
    % ------------------------------------------------------

    YTrain(k) = jammerPower;


    %% -----------------------------------------------------
    % PROGRESS
    % ------------------------------------------------------

    if mod(k,200) == 0

        fprintf( ...
            'Training data: %d / %d complete\n', ...
            k, ...
            numTrainSamples);

    end

end


%% =========================================================
% =========================================================
% TEST DATA
% =========================================================
% =========================================================

XTest = zeros( ...
    numTestSamples, ...
    numFeatures);

YTest = zeros( ...
    numTestSamples, ...
    1);


fprintf('\n');
fprintf('============================================\n');
fprintf(' GENERATING UNSEEN TEST DATA\n');
fprintf('============================================\n\n');


for k = 1:numTestSamples


    %% -----------------------------------------------------
    % JAMMER POWER
    % ------------------------------------------------------

    jammerPower = ...
        minJammerPower + ...
        (maxJammerPower - minJammerPower) * rand;


    %% -----------------------------------------------------
    % INDEPENDENT CHANNEL CONDITIONS
    %
    % These are newly generated and were NOT used to
    % construct the training samples.
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


    %% -----------------------------------------------------
    % DIFFERENT RANDOM SEED RANGE
    % ------------------------------------------------------

    params.rngSeed = 50000 + k;


    %% -----------------------------------------------------
    % BASELINE
    % ------------------------------------------------------

    params.enableJammer = false;

    resultsBase = runBaseline(params);


    %% -----------------------------------------------------
    % JAMMER
    % ------------------------------------------------------

    jammerSignal = jammerModel( ...
        jammerPower, ...
        params.Nbits, ...
        params.samplesPerBit, ...
        true);


    %% -----------------------------------------------------
    % ADD JAMMER
    % ------------------------------------------------------

    rxOpticalJammed = ...
        resultsBase.rxOpticalSignal + ...
        jammerSignal;


    %% -----------------------------------------------------
    % PRE-SATURATION CURRENT
    % ------------------------------------------------------

    rxCurrentPreSat = ...
        params.R * rxOpticalJammed;


    %% -----------------------------------------------------
    % ADD RECEIVER NOISE
    % ------------------------------------------------------

    rxCurrentPreSat = ...
        rxCurrentPreSat + ...
        resultsBase.receiverNoise;


    %% -----------------------------------------------------
    % FEATURES
    % ------------------------------------------------------

    features = extractFeatures( ...
        rxCurrentPreSat, ...
        I_sat);


    %% -----------------------------------------------------
    % STORE
    % ------------------------------------------------------

    XTest(k,1) = features.meanCurrent;

    XTest(k,2) = features.stdCurrent;

    XTest(k,3) = features.minCurrent;

    XTest(k,4) = features.maxCurrent;

    XTest(k,5) = features.currentRange;

    XTest(k,6) = features.saturationFraction;


    YTest(k) = jammerPower;


    %% -----------------------------------------------------
    % PROGRESS
    % ------------------------------------------------------

    if mod(k,100) == 0

        fprintf( ...
            'Test data: %d / %d complete\n', ...
            k, ...
            numTestSamples);

    end

end


%% =========================================================
% TRAIN RANDOM FOREST
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' TRAINING ROBUST ML MODEL\n');
fprintf('============================================\n\n');


numTrees = 200;


model = TreeBagger( ...
    numTrees, ...
    XTrain, ...
    YTrain, ...
    'Method', 'regression', ...
    'OOBPrediction', 'On', ...
    'OOBPredictorImportance', 'On');


fprintf('Training complete.\n');


%% =========================================================
% PREDICT TEST DATA
%% =========================================================

YPred = predict( ...
    model, ...
    XTest);


if iscell(YPred)

    YPred = str2double(YPred);

end


%% =========================================================
% CALCULATE ERRORS
%% =========================================================

errors = ...
    YTest - YPred;


MAE = ...
    mean(abs(errors));


RMSE = ...
    sqrt(mean(errors.^2));


SSres = ...
    sum(errors.^2);


SStot = ...
    sum((YTest - mean(YTest)).^2);


R2 = ...
    1 - SSres / SStot;


%% =========================================================
% DISPLAY RESULTS
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' ROBUSTNESS TEST RESULTS\n');
fprintf('============================================\n\n');


fprintf('Mean Absolute Error   = %.6f W\n', ...
    MAE);


fprintf('Root Mean Square Error = %.6f W\n', ...
    RMSE);


fprintf('R^2 Score              = %.6f\n', ...
    R2);


%% =========================================================
% COMPARISON WITH EXP 19
%% =========================================================

fprintf('\n');
fprintf('Interpretation:\n\n');

fprintf(['The model is now tested while turbulence,\n' ...
         'pointing error, atmospheric attenuation,\n' ...
         'and receiver noise vary.\n']);


%% =========================================================
% SAMPLE PREDICTIONS
%% =========================================================

fprintf('\n');
fprintf('Sample Predictions:\n\n');

fprintf('Actual Pj    Predicted Pj    Error\n');

fprintf('(W)          (W)             (W)\n');

fprintf('--------------------------------------\n');


numDisplay = ...
    min(10, numTestSamples);


for k = 1:numDisplay

    fprintf( ...
        '%.4f       %.4f          %.4f\n', ...
        YTest(k), ...
        YPred(k), ...
        errors(k));

end


%% =========================================================
% FIGURE 1
%
% ACTUAL VS PREDICTED
%% =========================================================

figure;


scatter( ...
    YTest, ...
    YPred, ...
    35, ...
    'filled');


hold on;


plot( ...
    [min(YTest) max(YTest)], ...
    [min(YTest) max(YTest)], ...
    '--');


grid on;


xlabel('Actual Jammer Power (W)');

ylabel('Predicted Jammer Power (W)');


title( ...
    'Experiment 20: ML Robustness — Actual vs Predicted');


legend( ...
    'ML Prediction', ...
    'Perfect Estimation', ...
    'Location', ...
    'best');


%% =========================================================
% FIGURE 2
%
% ERROR DISTRIBUTION
%% =========================================================

figure;


scatter( ...
    YTest, ...
    errors, ...
    35, ...
    'filled');


hold on;


yline(0, '--');


grid on;


xlabel('Actual Jammer Power (W)');

ylabel('Prediction Error (W)');


title( ...
    'Experiment 20: ML Estimation Error Under Channel Variation');


%% =========================================================
% FIGURE 3
%
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
    'Experiment 20: Feature Importance Under Channel Variation');


%% =========================================================
% SAVE ROBUSTNESS DATA
%% =========================================================

save( ...
    'jammerPowerRobustnessDataset.mat', ...
    'XTrain', ...
    'YTrain', ...
    'XTest', ...
    'YTest', ...
    'featureNames');


%% =========================================================
% SAVE ROBUST MODEL
%% =========================================================

save( ...
    'jammerPowerRobustModel.mat', ...
    'model', ...
    'featureNames', ...
    'I_sat');


%% =========================================================
% FINAL
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 20 COMPLETE\n');
fprintf('============================================\n\n');


fprintf('Robustness dataset saved as:\n');

fprintf('jammerPowerRobustnessDataset.mat\n\n');


fprintf('Robust ML model saved as:\n');

fprintf('jammerPowerRobustModel.mat\n\n');


fprintf('The model has now been tested under\n');

fprintf('varying FSO channel conditions.\n\n');


fprintf('Next step:\n');

fprintf('ML random jammer state detection.\n\n');