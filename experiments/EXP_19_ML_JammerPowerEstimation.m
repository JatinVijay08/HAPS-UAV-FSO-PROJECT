clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 19
% ML JAMMER POWER ESTIMATION
%
% Goal:
%
% Learn the relationship:
%
%   Receiver features -> Jammer Power
%
% using Random Forest Regression.
%
% IMPORTANT:
% Features are extracted from the PRE-SATURATION
% receiver current.
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

% Receiver saturation current

I_sat = 0.25;


%% =========================================================
% DATASET PARAMETERS
%% =========================================================

numSamples = 1000;

% Jammer power range

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
% PREALLOCATE DATASET
%% =========================================================

X = zeros(numSamples, numFeatures);

Y = zeros(numSamples, 1);


%% =========================================================
% DISPLAY
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 19 - ML JAMMER POWER ESTIMATION\n');
fprintf('============================================\n\n');

fprintf('Samples = %d\n', numSamples);
fprintf('Jammer Power Range = %.2f to %.2f W\n', ...
    minJammerPower, maxJammerPower);

fprintf('\nGenerating dataset...\n\n');


%% =========================================================
% DATASET GENERATION
%% =========================================================

for k = 1:numSamples


    %% -----------------------------------------------------
    % RANDOM JAMMER POWER
    % ------------------------------------------------------

    jammerPower = ...
        minJammerPower + ...
        (maxJammerPower - minJammerPower) * rand;


    %% -----------------------------------------------------
    % CHANGE RANDOM SEED
    %
    % Each simulation gets a different channel/noise
    % realization.
    % ------------------------------------------------------

    params.rngSeed = 1000 + k;


    %% -----------------------------------------------------
    % GENERATE BASELINE FSO COMMUNICATION
    %
    % No jammer is enabled here.
    %
    % We use this only to obtain:
    %
    %   transmitted bits
    %   received optical waveform
    %   channel realization
    %   receiver noise
    % ------------------------------------------------------

    params.enableJammer = false;

    resultsBase = runBaseline(params);


    %% -----------------------------------------------------
    % GENERATE CONSTANT JAMMER
    % ------------------------------------------------------

    jammerSignal = jammerModel( ...
        jammerPower, ...
        params.Nbits, ...
        params.samplesPerBit, ...
        true);


    %% -----------------------------------------------------
    % ADD JAMMER AT OPTICAL DOMAIN
    % ------------------------------------------------------

    rxOpticalJammed = ...
        resultsBase.rxOpticalSignal + jammerSignal;


    %% -----------------------------------------------------
    % PRE-SATURATION RECEIVER CURRENT
    %
    % Optical power -> electrical current
    %
    % I(t) = R * P(t)
    % ------------------------------------------------------

    rxCurrentPreSat = ...
        params.R * rxOpticalJammed;


    %% -----------------------------------------------------
    % ADD SAME RECEIVER NOISE
    % ------------------------------------------------------

    rxCurrentPreSat = ...
        rxCurrentPreSat + resultsBase.receiverNoise;


    %% -----------------------------------------------------
    % EXTRACT FEATURES
    %
    % IMPORTANT:
    %
    % We DO NOT pass this signal through:
    %
    %   min(I, I_sat)
    %
    % ------------------------------------------------------

    features = extractFeatures( ...
        rxCurrentPreSat, ...
        I_sat);


    %% -----------------------------------------------------
    % STORE FEATURES
    % ------------------------------------------------------

    X(k,1) = features.meanCurrent;

    X(k,2) = features.stdCurrent;

    X(k,3) = features.minCurrent;

    X(k,4) = features.maxCurrent;

    X(k,5) = features.currentRange;

    X(k,6) = features.saturationFraction;


    %% -----------------------------------------------------
    % TARGET
    % ------------------------------------------------------

    Y(k) = jammerPower;


    %% -----------------------------------------------------
    % PROGRESS
    % ------------------------------------------------------

    if mod(k,100) == 0

        fprintf('%d / %d complete\n', ...
            k, numSamples);

    end

end


%% =========================================================
% CONVERT TO TABLE
%% =========================================================

dataset = array2table(X, ...
    'VariableNames', featureNames);

dataset.JammerPower = Y;


%% =========================================================
% DATASET SUMMARY
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' DATASET GENERATION COMPLETE\n');
fprintf('============================================\n');

fprintf('\nTotal Samples = %d\n', height(dataset));

fprintf('Number of Features = %d\n', numFeatures);


%% =========================================================
% TRAIN / TEST SPLIT
%% =========================================================

rng(42);

randomIndices = randperm(numSamples);

numTrain = round(0.80 * numSamples);

trainIndices = ...
    randomIndices(1:numTrain);

testIndices = ...
    randomIndices(numTrain+1:end);


XTrain = X(trainIndices,:);

YTrain = Y(trainIndices);


XTest = X(testIndices,:);

YTest = Y(testIndices);


fprintf('\nTraining Samples = %d\n', ...
    length(YTrain));

fprintf('Testing Samples  = %d\n', ...
    length(YTest));


%% =========================================================
% TRAIN RANDOM FOREST REGRESSOR
%% =========================================================

fprintf('\n');
fprintf('Training Random Forest regression model...\n');


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
% PREDICTION
%% =========================================================

YPred = predict(model, XTest);


% Convert cell output if necessary

if iscell(YPred)

    YPred = str2double(YPred);

end


%% =========================================================
% ERROR METRICS
%% =========================================================

errors = YTest - YPred;


MAE = mean(abs(errors));


RMSE = sqrt(mean(errors.^2));


SSres = sum(errors.^2);

SStot = sum((YTest - mean(YTest)).^2);


R2 = 1 - SSres / SStot;


%% =========================================================
% DISPLAY RESULTS
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' ML JAMMER POWER ESTIMATION RESULTS\n');
fprintf('============================================\n');

fprintf('\nMean Absolute Error  = %.6f W\n', MAE);

fprintf('Root Mean Square Error = %.6f W\n', RMSE);

fprintf('R^2 Score             = %.6f\n', R2);


%% =========================================================
% SAMPLE PREDICTIONS
%% =========================================================

fprintf('\n');
fprintf('Sample Predictions:\n');

fprintf('\n');

fprintf('Actual Pj (W)    Predicted Pj (W)    Error (W)\n');

fprintf('------------------------------------------------\n');


numDisplay = min(10, length(YTest));


for k = 1:numDisplay

    fprintf( ...
        '%10.4f       %12.4f       %9.4f\n', ...
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


% Perfect prediction line

plot( ...
    [min(YTest) max(YTest)], ...
    [min(YTest) max(YTest)], ...
    '--');


grid on;

xlabel('Actual Jammer Power (W)');

ylabel('Predicted Jammer Power (W)');

title('Experiment 19: ML Jammer Power Estimation');

legend( ...
    'ML Prediction', ...
    'Perfect Estimation', ...
    'Location', 'best');


%% =========================================================
% FIGURE 2
%
% PREDICTION ERROR
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

title('Experiment 19: Jammer Power Estimation Error');


%% =========================================================
% FIGURE 3
%
% FEATURE IMPORTANCE
%% =========================================================

figure;

importance = model.OOBPermutedPredictorDeltaError;


bar(importance);

grid on;

xticks(1:numFeatures);

xticklabels(featureNames);

xtickangle(30);

ylabel('Predictor Importance');

title('Experiment 19: ML Feature Importance');


%% =========================================================
% SAVE DATASET
%% =========================================================

save( ...
    'jammerPowerDataset.mat', ...
    'dataset');


%% =========================================================
% SAVE MODEL
%% =========================================================

save( ...
    'jammerPowerEstimationModel.mat', ...
    'model', ...
    'featureNames', ...
    'I_sat');


%% =========================================================
% FINAL MESSAGE
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 19 COMPLETE\n');
fprintf('============================================\n');

fprintf('\nDataset saved as:\n');

fprintf('jammerPowerDataset.mat\n');

fprintf('\nModel saved as:\n');

fprintf('jammerPowerEstimationModel.mat\n');

fprintf('\nThe ML model now estimates jammer power\n');

fprintf('from receiver waveform features.\n');

fprintf('\nNext step:\n');

fprintf('Use the estimated jammer power for\n');

fprintf('pre-saturation cancellation.\n');

fprintf('\n');