%% EXPERIMENT 25A - PER-BIT ML JAMMER STATE TRAINING
%
% Train a Random Forest classifier to detect whether an optical jammer
% is active during an individual bit.
%
% Output:
%   jammerPerBitStateModel.mat

clear;
clc;
close all;

fprintf('============================================\n');
fprintf(' EXPERIMENT 25A - PER-BIT JAMMER STATE ML\n');
fprintf('============================================\n\n');

%% PARAMETERS

rng(25);

numSamples = 4000;

Pt = 0.30;
H_total = 0.85;
R = 0.80;

samplesPerBit = 20;

sigmaNoise = 0.005;
I_sat = 0.25;

% Strong random jammer for initial state-learning experiment
jammerPower = 0.40;

%% STORAGE

X = zeros(numSamples,6);
Y = zeros(numSamples,1);

fprintf('Generating %d per-bit training samples...\n',numSamples);

%% DATASET GENERATION

for n = 1:numSamples

    % Random legitimate OOK bit
    bit = randi([0 1]);

    % Random jammer state
    jammerState = randi([0 1]);

    % Legitimate optical power
    legitPower = Pt * bit * H_total;

    % Jammer optical power
    jammerOpticalPower = jammerState * jammerPower * H_total;

    % Total optical power
    totalOpticalPower = legitPower + jammerOpticalPower;

    % Photodetection
    rxCurrent = R * totalOpticalPower;

    % Add receiver noise
    rxCurrent = rxCurrent + ...
        sigmaNoise * randn(1,samplesPerBit);

    % Saturation
    rxCurrent = min(rxCurrent,I_sat);

    % Extract features
    features = extractFeatures(rxCurrent,I_sat);

    X(n,:) = [ ...
        features.meanCurrent, ...
        features.stdCurrent, ...
        features.minCurrent, ...
        features.maxCurrent, ...
        features.currentRange, ...
        features.saturationFraction ...
    ];

    % True jammer state
    Y(n) = jammerState;
end

%% TRAIN / TEST SPLIT

cv = cvpartition(Y,'HoldOut',0.20);

trainIdx = training(cv);
testIdx = test(cv);

XTrain = X(trainIdx,:);
YTrain = Y(trainIdx);

XTest = X(testIdx,:);
YTest = Y(testIdx);

fprintf('Training samples = %d\n',sum(trainIdx));
fprintf('Testing samples  = %d\n\n',sum(testIdx));

%% RANDOM FOREST CLASSIFIER

fprintf('Training Random Forest...\n');

model = TreeBagger(100, ...
    XTrain, ...
    YTrain, ...
    'Method','classification', ...
    'OOBPrediction','On');

%% TEST

YPred = predict(model,XTest);

% TreeBagger may return strings/cells
if iscell(YPred)
    YPred = str2double(YPred);
else
    YPred = str2double(string(YPred));
end

YPred = round(YPred);

accuracy = mean(YPred == YTest);

TP = sum((YPred == 1) & (YTest == 1));
TN = sum((YPred == 0) & (YTest == 0));
FP = sum((YPred == 1) & (YTest == 0));
FN = sum((YPred == 0) & (YTest == 1));

precision = TP / max(TP + FP,1);
recall = TP / max(TP + FN,1);
F1 = 2 * precision * recall / max(precision + recall,eps);

fprintf('\n============================================\n');
fprintf(' PER-BIT STATE DETECTOR RESULTS\n');
fprintf('============================================\n');

fprintf('Accuracy  = %.4f\n',accuracy);
fprintf('Precision = %.4f\n',precision);
fprintf('Recall    = %.4f\n',recall);
fprintf('F1 Score  = %.4f\n',F1);

fprintf('\nConfusion Matrix:\n');
fprintf('              Pred OFF    Pred ON\n');
fprintf('Actual OFF    %8d    %8d\n',TN,FP);
fprintf('Actual ON     %8d    %8d\n',FN,TP);

%% FEATURE NAMES

featureNames = { ...
    'MeanCurrent', ...
    'StdCurrent', ...
    'MinCurrent', ...
    'MaxCurrent', ...
    'CurrentRange', ...
    'SaturationFraction' ...
};

%% SAVE

save('jammerPerBitStateModel.mat', ...
    'model', ...
    'I_sat', ...
    'featureNames');

fprintf('\nModel saved as:\n');
fprintf('jammerPerBitStateModel.mat\n');

fprintf('\n============================================\n');
fprintf(' EXPERIMENT 25A COMPLETE\n');
fprintf('============================================\n');