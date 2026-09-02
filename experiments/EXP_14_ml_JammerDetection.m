clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 14
% ML-BASED JAMMER DETECTION
%
% Classes:
%
%   1. Normal
%   2. Constant Jammer
%   3. Random Jammer
%
%% =========================================================


%% =========================================================
% PATH SETTINGS
%% =========================================================

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(genpath(projectRoot));


%% =========================================================
% LOAD DATASET
%% =========================================================

load('jammerDataset.mat');


%% =========================================================
% DISPLAY DATASET INFORMATION
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 14 - ML JAMMER DETECTION\n');
fprintf('============================================\n\n');

fprintf('Dataset successfully loaded.\n\n');

fprintf('Total Samples = %d\n', height(dataset));

fprintf('\nClass Distribution:\n');

disp(countcats(categorical(dataset.Label)));


%% =========================================================
% EXTRACT FEATURE MATRIX
%% =========================================================

featureNames = { ...
    'MeanCurrent', ...
    'StdCurrent', ...
    'MinCurrent', ...
    'MaxCurrent', ...
    'CurrentRange', ...
    'SaturationFraction'};


X = dataset{:, featureNames};


%% =========================================================
% EXTRACT LABELS
%% =========================================================

Y = categorical(dataset.Label);


%% =========================================================
% DISPLAY FEATURE INFORMATION
%% =========================================================

fprintf('\nFeatures Used:\n');

for k = 1:length(featureNames)

    fprintf('  %d. %s\n', ...
        k, featureNames{k});

end


%% =========================================================
% TRAIN / TEST SPLIT
%
% 80 percent Training
% 20 percent Testing
%% =========================================================

rng(42);


cv = cvpartition(Y, ...
    'HoldOut', ...
    0.20);


XTrain = X(training(cv), :);

YTrain = Y(training(cv));


XTest = X(test(cv), :);

YTest = Y(test(cv));


fprintf('\n');
fprintf('Training Samples = %d\n', length(YTrain));

fprintf('Testing Samples  = %d\n', length(YTest));


%% =========================================================
% FEATURE NORMALIZATION
%
% Calculate normalization using TRAINING DATA ONLY
%
% X_normalized =
%
% (X - mean(XTrain)) / std(XTrain)
%% =========================================================

mu = mean(XTrain);

sigma = std(XTrain);


% Prevent division by zero

sigma(sigma == 0) = 1;


XTrainNorm = ...
    (XTrain - mu) ./ sigma;


XTestNorm = ...
    (XTest - mu) ./ sigma;


%% =========================================================
% TRAIN RANDOM FOREST CLASSIFIER
%% =========================================================

fprintf('\nTraining Random Forest classifier...\n');


numTrees = 100;


model = TreeBagger( ...
    numTrees, ...
    XTrainNorm, ...
    YTrain, ...
    'Method', 'classification', ...
    'OOBPrediction', 'on', ...
    'OOBPredictorImportance', 'on');


fprintf('Training complete.\n');


%% =========================================================
% PREDICT TEST DATA
%% =========================================================

[predictedLabels, scores] = predict( ...
    model, ...
    XTestNorm);


predictedLabels = ...
    categorical(predictedLabels);


%% =========================================================
% CALCULATE ACCURACY
%% =========================================================

accuracy = ...
    mean(predictedLabels == YTest);


fprintf('\n');
fprintf('============================================\n');
fprintf(' TEST PERFORMANCE\n');
fprintf('============================================\n\n');

fprintf('Classification Accuracy = %.2f %%\n', ...
    accuracy * 100);


%% =========================================================
% CONFUSION MATRIX
%% =========================================================

figure;

confusionchart( ...
    YTest, ...
    predictedLabels);

title('Experiment 14: Jammer Detection Confusion Matrix');


%% =========================================================
% FEATURE IMPORTANCE
%% =========================================================

importance = model.OOBPermutedPredictorDeltaError;


figure;

bar(importance);

grid on;

xticks(1:length(featureNames));

xticklabels(featureNames);

xtickangle(30);

ylabel('Predictor Importance');

title('Experiment 14: Feature Importance');


%% =========================================================
% SAVE MODEL
%% =========================================================

save( ...
    'jammerDetectionModel.mat', ...
    'model', ...
    'mu', ...
    'sigma', ...
    'featureNames');


fprintf('\n');
fprintf('============================================\n');
fprintf(' MODEL SAVED SUCCESSFULLY\n');
fprintf('============================================\n');

fprintf('File: jammerDetectionModel.mat\n');