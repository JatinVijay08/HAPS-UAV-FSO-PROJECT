%% EXPERIMENT 25B - PRE-SATURATION PER-BIT JAMMER POWER TRAINING
%
% Train a Random Forest regression model to estimate jammer optical
% power from PRE-SATURATION receiver-current observations.
%
% Important:
%   ML features are extracted BEFORE receiver saturation.
%
% This avoids the information-loss problem identified in the previous
% version of Experiment 25B.
%
% Output:
%   jammerPerBitPowerModel.mat

clear;
clc;
close all;

fprintf('============================================\n');
fprintf(' EXPERIMENT 25B - PRE-SATURATION JAMMER POWER ML\n');
fprintf('============================================\n\n');

%% PARAMETERS

rng(250);

numSamples = 5000;

Pt = 0.30;
H_total = 0.85;
R = 0.80;

samplesPerBit = 20;

sigmaNoise = 0.005;
I_sat = 0.25;

%% JAMMER POWER RANGE

minJammerPower = 0.05;
maxJammerPower = 0.40;

%% STORAGE

X = zeros(numSamples,6);
Y = zeros(numSamples,1);

fprintf('Generating %d jammer-active bit samples...\n',numSamples);

%% DATASET GENERATION

for n = 1:numSamples

    %% Random legitimate OOK bit

    bit = randi([0 1]);

    %% Random jammer power

    jammerPower = minJammerPower + ...
        (maxJammerPower-minJammerPower)*rand;

    %% Legitimate received optical power

    legitPower = Pt * bit * H_total;

    %% Jammer received optical power

    jammerOpticalPower = jammerPower * H_total;

    %% Total received optical power

    totalOpticalPower = ...
        legitPower + jammerOpticalPower;

    %% Photodetection BEFORE SATURATION

    rxCurrentPreSat = ...
        R * totalOpticalPower;

    %% Add receiver noise

    rxCurrentPreSat = ...
        rxCurrentPreSat + ...
        sigmaNoise * randn(1,samplesPerBit);

    %% IMPORTANT:
    % Extract ML features BEFORE saturation.

    features = extractFeatures( ...
        rxCurrentPreSat, ...
        I_sat);

    %% Store features

    X(n,:) = [ ...
        features.meanCurrent, ...
        features.stdCurrent, ...
        features.minCurrent, ...
        features.maxCurrent, ...
        features.currentRange, ...
        features.saturationFraction ...
    ];

    %% Target

    Y(n) = jammerPower;

end

%% TRAIN / TEST SPLIT

cv = cvpartition(numSamples,'HoldOut',0.20);

trainIdx = training(cv);
testIdx = test(cv);

XTrain = X(trainIdx,:);
YTrain = Y(trainIdx);

XTest = X(testIdx,:);
YTest = Y(testIdx);

fprintf('Training samples = %d\n',sum(trainIdx));
fprintf('Testing samples  = %d\n\n',sum(testIdx));

%% RANDOM FOREST REGRESSION

fprintf('Training Random Forest regressor...\n');

model = TreeBagger(150, ...
    XTrain, ...
    YTrain, ...
    'Method','regression', ...
    'OOBPrediction','On');

%% PREDICTION

YPred = predict(model,XTest);

YPred = max(YPred,0);

%% METRICS

MAE = mean(abs(YPred-YTest));

RMSE = sqrt(mean((YPred-YTest).^2));

SSres = sum((YTest-YPred).^2);

SStot = sum((YTest-mean(YTest)).^2);

R2 = 1 - SSres/SStot;

%% RESULTS

fprintf('\n============================================\n');
fprintf(' PRE-SATURATION POWER ESTIMATOR RESULTS\n');
fprintf('============================================\n');

fprintf('MAE  = %.6f W\n',MAE);
fprintf('RMSE = %.6f W\n',RMSE);
fprintf('R^2  = %.6f\n',R2);

%% PREDICTION PLOT

figure;

scatter(YTest,YPred,20,'filled');

hold on;

plot( ...
    [min(YTest) max(YTest)], ...
    [min(YTest) max(YTest)], ...
    '--', ...
    'LineWidth',1.5);

grid on;

xlabel('Actual Jammer Power (W)');
ylabel('Estimated Jammer Power (W)');

title( ...
    'Experiment 25B - Pre-Saturation ML Jammer Power Estimation');

legend( ...
    'ML Estimate', ...
    'Perfect Estimation', ...
    'Location','best');

%% FEATURE NAMES

featureNames = { ...
    'MeanCurrent', ...
    'StdCurrent', ...
    'MinCurrent', ...
    'MaxCurrent', ...
    'CurrentRange', ...
    'SaturationFraction' ...
};

%% SAVE MODEL

save( ...
    'jammerPerBitPowerModel.mat', ...
    'model', ...
    'I_sat', ...
    'featureNames');

fprintf('\nModel saved as:\n');
fprintf('jammerPerBitPowerModel.mat\n');

fprintf('\n============================================\n');
fprintf(' EXPERIMENT 25B COMPLETE\n');
fprintf('============================================\n');