clc;
clear;
close all;

%% =========================================================
% EXPERIMENT 10
% RANDOM JAMMER BLINDING ATTACK
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 10 - RANDOM JAMMER BLINDING ATTACK\n');
fprintf('============================================\n\n');


%% =========================================================
% PATH SETUP
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);


%% =========================================================
% ADD BASELINE MODEL
%% =========================================================

addpath(fullfile( ...
    projectFolder, ...
    'baseline_model'));


%% =========================================================
% ADD MAIN MODELS
%% =========================================================

addpath(fullfile( ...
    projectFolder, ...
    'baseline_model', ...
    'MainModels'));


%% =========================================================
% ADD JAMMER MODELS
%% =========================================================

addpath(fullfile( ...
    projectFolder, ...
    'baseline with jammer'));


%% =========================================================
% BASELINE PARAMETERS
%% =========================================================

params = defaultParameters();

params.Nbits = 10000;


%% =========================================================
% RANDOM JAMMER ATTACK PARAMETERS
%% =========================================================

params.enableJammer = true;

params.jammerPower = 0.4;

activitySweep = 0:0.1:1;


%% =========================================================
% RESULT STORAGE
%% =========================================================

numPoints = length(activitySweep);

BER = zeros(1, numPoints);

errors10 = zeros(1, numPoints);

errors01 = zeros(1, numPoints);

saturationFraction = zeros(1, numPoints);

actualActivity = zeros(1, numPoints);

averageJammerPower = zeros(1, numPoints);

%% =========================================================
% RANDOM JAMMER BLINDING ATTACK SWEEP
%% =========================================================

fprintf('\n');

for k = 1:numPoints


    %% =====================================================
    % CURRENT ACTIVITY PROBABILITY
    %% =====================================================

    activityProbability = activitySweep(k);


    %% =====================================================
    % RESET RANDOM SEED
    %
    % Ensures fair/reproducible comparisons
    %% =====================================================

    rng(params.rngSeed);


    %% =====================================================
    % RUN NORMAL FSO SYSTEM
    %% =====================================================

    results = runBaseline(params);


    %% =====================================================
    % GENERATE RANDOM JAMMER
    %% =====================================================

    [jammerSignal, jammerBits] = ...
        randomJammerModel( ...
        params.jammerPower, ...
        params.Nbits, ...
        params.samplesPerBit, ...
        params.enableJammer, ...
        activityProbability);


    %% =====================================================
    % COMBINE LEGITIMATE SIGNAL + JAMMER
    %
    % P_total(t) =
    %
    % P_legitimate(t)
    % +
    % P_jammer(t)
    %% =====================================================

    attackedOpticalSignal = ...
        results.rxOpticalSignal + jammerSignal;


    %% =====================================================
    % RECEIVER PROCESSING
    %
    % Use SAME receiver noise realization
    % for a fair comparison
    %% =====================================================

    [detectedBits, BER_current, ...
        rxCurrent, ...
        rxSamples, ...
        threshold] = receiverModel( ...
        attackedOpticalSignal, ...
        results.bits, ...
        params.Pt, ...
        results.H_total, ...
        params.R, ...
        params.samplesPerBit, ...
        results.receiverNoise, ...
        params.enableSaturation);


    %% =====================================================
    % ERROR ANALYSIS
    %% =====================================================

    errors10_current = sum( ...
        (results.bits == 1) & ...
        (detectedBits == 0));

    errors01_current = sum( ...
        (results.bits == 0) & ...
        (detectedBits == 1));


    %% =====================================================
    % SATURATION FRACTION
    %% =====================================================

    I_sat = 0.25;

    saturationFraction(k) = ...
        mean(rxCurrent >= I_sat);


    %% =====================================================
    % STORE RESULTS
    %% =====================================================

    BER(k) = BER_current;

    errors10(k) = errors10_current;

    errors01(k) = errors01_current;

    actualActivity(k) = mean(jammerBits);

    averageJammerPower(k) = mean(jammerSignal);


    %% =====================================================
    % DISPLAY
    %% =====================================================

    fprintf( ...
        ['Activity = %.1f | Actual = %.3f | ', ...
         'BER = %.6f | (1->0) = %d | ', ...
         '(0->1) = %d | Sat = %.3f | ', ...
         'Avg Pj = %.4f W\n'], ...
        activityProbability, ...
        actualActivity(k), ...
        BER(k), ...
        errors10(k), ...
        errors01(k), ...
        saturationFraction(k), ...
        averageJammerPower(k));

end