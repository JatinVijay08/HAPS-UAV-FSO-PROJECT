clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 12
% FEATURE EXTRACTION VALIDATION
%
% Compare:
%
%   1. Normal communication
%   2. Constant jammer
%   3. Random intermittent jammer
%
% IMPORTANT:
%
% All three scenarios use the SAME:
%
%   - Transmitted bits
%   - FSO channel realization
%   - Pointing error realization
%   - Turbulence realization
%   - Receiver noise realization
%
% Therefore, differences in extracted features are caused
% primarily by the jammer.
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


% Use enough bits for meaningful statistics

params.Nbits = 10000;


% Keep simulation repeatable

params.rngSeed = 42;


% Receiver saturation current
%
% This should match the saturation threshold used by
% receiverModel.

I_sat = 0.25;


%% =========================================================
% GENERATE COMMON BASELINE
%
% This creates ONE common realization of:
%
%   - OOK bits
%   - FSO channel
%   - Pointing error
%   - Atmospheric turbulence
%   - Receiver noise
%
% All jammer cases are built from this same baseline.
%
%% =========================================================

params.enableJammer = false;

resultsBase = runBaseline(params);


%% =========================================================
% CASE 1 — NORMAL COMMUNICATION
%
% No jammer added.
%% =========================================================

rxCurrentNormal = resultsBase.rxCurrent;


featuresNormal = extractFeatures( ...
    rxCurrentNormal, ...
    I_sat);


%% =========================================================
% CASE 2 — CONSTANT JAMMER
%
% Constant optical jammer:
%
% P_j(t) = constantJammerPower
%
%% =========================================================


% Constant jammer power

constantJammerPower = 0.20;


% Generate constant jammer signal

jammerSignalConstant = jammerModel( ...
    constantJammerPower, ...
    params.Nbits, ...
    params.samplesPerBit, ...
    true);


% Add jammer to legitimate received optical signal

rxOpticalConstant = ...
    resultsBase.rxOpticalSignal + ...
    jammerSignalConstant;


% Re-run receiver
%
% Use SAME:
%
%   - transmitted bits
%   - receiver noise
%   - channel parameters

[detectedBitsConstant, ...
 BERConstant, ...
 rxCurrentConstant, ...
 rxSamplesConstant, ...
 thresholdConstant] = receiverModel( ...
    rxOpticalConstant, ...
    resultsBase.bits, ...
    params.Pt, ...
    resultsBase.H_total, ...
    params.R, ...
    params.samplesPerBit, ...
    resultsBase.receiverNoise, ...
    params.enableSaturation);


% Extract receiver features

featuresConstant = extractFeatures( ...
    rxCurrentConstant, ...
    I_sat);


%% =========================================================
% CASE 3 — RANDOM INTERMITTENT JAMMER
%
% Random jammer:
%
% P_j(k) =
%
%   0 W          jammer OFF
%
%   P_peak       jammer ON
%
% Jammer activity is random for every bit.
%
%% =========================================================


% Peak jammer power

randomJammerPeakPower = 0.40;


% Probability jammer is active

activityProbability = 0.50;


% Expected average jammer power:
%
% P_avg = P_peak × activityProbability
%
%       = 0.40 × 0.50
%
%       = 0.20 W
%
% Therefore this is approximately a fair comparison with
% the constant jammer.

expectedRandomAveragePower = ...
    randomJammerPeakPower * activityProbability;


% Generate random intermittent jammer

[jammerSignalRandom, jammerBits] = randomJammerModel( ...
    randomJammerPeakPower, ...
    params.Nbits, ...
    params.samplesPerBit, ...
    true, ...
    activityProbability);


% Calculate actual activity

actualActivity = mean(jammerBits);


% Calculate actual average jammer power

actualRandomAveragePower = ...
    randomJammerPeakPower * actualActivity;


% Add jammer to legitimate received optical signal

rxOpticalRandom = ...
    resultsBase.rxOpticalSignal + ...
    jammerSignalRandom;


% Re-run receiver using SAME noise realization

[detectedBitsRandom, ...
 BERRandom, ...
 rxCurrentRandom, ...
 rxSamplesRandom, ...
 thresholdRandom] = receiverModel( ...
    rxOpticalRandom, ...
    resultsBase.bits, ...
    params.Pt, ...
    resultsBase.H_total, ...
    params.R, ...
    params.samplesPerBit, ...
    resultsBase.receiverNoise, ...
    params.enableSaturation);


% Extract receiver features

featuresRandom = extractFeatures( ...
    rxCurrentRandom, ...
    I_sat);


%% =========================================================
% DISPLAY EXPERIMENT RESULTS
%% =========================================================

fprintf('\n');

fprintf('============================================\n');

fprintf(' EXPERIMENT 12 - FEATURE EXTRACTION TEST\n');

fprintf('============================================\n\n');


%% =========================================================
% JAMMER CONFIGURATION
%% =========================================================

fprintf('JAMMER CONFIGURATION\n\n');


fprintf('Constant Jammer Power = %.4f W\n', ...
    constantJammerPower);


fprintf('\n');


fprintf('Random Jammer Peak Power = %.4f W\n', ...
    randomJammerPeakPower);


fprintf('Requested Activity Probability = %.3f\n', ...
    activityProbability);


fprintf('Actual Activity Probability = %.3f\n', ...
    actualActivity);


fprintf('Expected Average Power = %.4f W\n', ...
    expectedRandomAveragePower);


fprintf('Actual Average Power = %.4f W\n\n', ...
    actualRandomAveragePower);


%% =========================================================
% NORMAL FEATURES
%% =========================================================

fprintf('----- NORMAL -----\n');

displayFeatures(featuresNormal);


%% =========================================================
% CONSTANT JAMMER FEATURES
%% =========================================================

fprintf('\n----- CONSTANT JAMMER -----\n');

displayFeatures(featuresConstant);


%% =========================================================
% RANDOM JAMMER FEATURES
%% =========================================================

fprintf('\n----- RANDOM JAMMER -----\n');

displayFeatures(featuresRandom);


%% =========================================================
% OPTIONAL RECEIVER PERFORMANCE
%% =========================================================

fprintf('\n============================================\n');

fprintf(' RECEIVER PERFORMANCE\n');

fprintf('============================================\n\n');


fprintf('Normal BER           = %.6f\n', ...
    resultsBase.BER);


fprintf('Constant Jammer BER  = %.6f\n', ...
    BERConstant);


fprintf('Random Jammer BER    = %.6f\n', ...
    BERRandom);


%% =========================================================
% VISUAL COMPARISON
%% =========================================================

figure;


featureNames = { ...
    'Mean', ...
    'Std', ...
    'Min', ...
    'Max', ...
    'Range', ...
    'Sat Fraction'};


%% NORMAL FEATURE VECTOR

normalVector = [ ...
    featuresNormal.meanCurrent ...
    featuresNormal.stdCurrent ...
    featuresNormal.minCurrent ...
    featuresNormal.maxCurrent ...
    featuresNormal.currentRange ...
    featuresNormal.saturationFraction];


%% CONSTANT JAMMER FEATURE VECTOR

constantVector = [ ...
    featuresConstant.meanCurrent ...
    featuresConstant.stdCurrent ...
    featuresConstant.minCurrent ...
    featuresConstant.maxCurrent ...
    featuresConstant.currentRange ...
    featuresConstant.saturationFraction];


%% RANDOM JAMMER FEATURE VECTOR

randomVector = [ ...
    featuresRandom.meanCurrent ...
    featuresRandom.stdCurrent ...
    featuresRandom.minCurrent ...
    featuresRandom.maxCurrent ...
    featuresRandom.currentRange ...
    featuresRandom.saturationFraction];


%% FEATURE MATRIX

featureMatrix = [ ...
    normalVector;
    constantVector;
    randomVector];


%% PLOT

bar(featureMatrix');

grid on;


xticks(1:length(featureNames));

xticklabels(featureNames);


legend( ...
    'Normal', ...
    'Constant Jammer', ...
    'Random Jammer', ...
    'Location', 'best');


title('Receiver Feature Comparison');


ylabel('Feature Value');


%% =========================================================
% LOCAL FUNCTION
% DISPLAY FEATURES
%% =========================================================

function displayFeatures(features)

fprintf('Mean Current        = %.6f\n', ...
    features.meanCurrent);


fprintf('Std Current         = %.6f\n', ...
    features.stdCurrent);


fprintf('Min Current         = %.6f\n', ...
    features.minCurrent);


fprintf('Max Current         = %.6f\n', ...
    features.maxCurrent);


fprintf('Current Range       = %.6f\n', ...
    features.currentRange);


fprintf('Saturation Fraction = %.6f\n', ...
    features.saturationFraction);

end


%% =========================================================
% LOCAL FUNCTION
% CONSTANT JAMMER MODEL
%% =========================================================

function jammerSignal = jammerModel( ...
    jammerPower, ...
    Nbits, ...
    samplesPerBit, ...
    enableJammer)

%% =========================================================
% CONSTANT OPTICAL JAMMER MODEL
%
% When enabled:
%
%       P_jammer(t) = Pj
%
% When disabled:
%
%       P_jammer(t) = 0
%
%% =========================================================


%% TOTAL NUMBER OF SAMPLES

Nsamples = Nbits * samplesPerBit;


%% JAMMER OFF

if ~enableJammer

    jammerSignal = zeros(1, Nsamples);

    return;

end


%% CONSTANT OPTICAL JAMMER

jammerSignal = ...
    jammerPower * ones(1, Nsamples);

end