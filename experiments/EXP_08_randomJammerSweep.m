%% =========================================================
% EXPERIMENT 08
%
% RANDOM JAMMER ACTIVITY PROBABILITY SWEEP
%
% Purpose:
% Investigate how intermittent jammer activity affects BER
%% =========================================================

clear;
clc;
close all;


%% =========================================================
% PATH SETUP
%% =========================================================

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(genpath(projectRoot));


%% =========================================================
% LOAD DEFAULT PARAMETERS
%% =========================================================

params = defaultParameters();


%% =========================================================
% EXPERIMENT SETTINGS
%% =========================================================

params.Nbits = 10000;

params.enableJammer = false;

params.rngSeed = 42;


%% =========================================================
% JAMMER PARAMETERS
%% =========================================================

Pj = 0.10;


activityProbabilities = ...
    [0.0 ...
     0.1 ...
     0.2 ...
     0.3 ...
     0.4 ...
     0.5 ...
     0.6 ...
     0.7 ...
     0.8 ...
     0.9 ...
     1.0];


BER_values = zeros(size(activityProbabilities));

errors10 = zeros(size(activityProbabilities));

errors01 = zeros(size(activityProbabilities));


%% =========================================================
% GENERATE BASELINE REALIZATION
%
% Fixed seed ensures fair comparison
%% =========================================================

rng(params.rngSeed);


%% =========================================================
% RUN EACH JAMMER ACTIVITY LEVEL
%% =========================================================

for i = 1:length(activityProbabilities)

    activityProbability = activityProbabilities(i);


    %% =====================================================
    % RESET RANDOM SEED
    %
    % Same bits
    % Same pointing
    % Same turbulence
    % Same noise
    %% =====================================================

    rng(params.rngSeed);


    %% =====================================================
    % TRANSMITTER
    %% =====================================================

    [bits, txSignal, ~] = generateOOK( ...
        params.Nbits, ...
        params.Pt, ...
        params.Rb, ...
        params.samplesPerBit);


    %% =====================================================
    % GEOMETRY
    %% =====================================================

    [H_geo, wRx, ~, ~] = geometryModel( ...
        params.lambda, ...
        params.theta, ...
        params.RxDiameter, ...
        params.L);


    %% =====================================================
    % ATMOSPHERIC ATTENUATION
    %% =====================================================

    H_atm = atmosphericAttenuation( ...
        params.alpha, ...
        params.L);


    H_total = H_geo * H_atm;


    %% =====================================================
    % POINTING ERROR
    %% =====================================================

    H_point_bits = pointingErrorModel( ...
        wRx, ...
        params.sigmaPoint, ...
        params.Nbits);


    H_point_signal = repelem( ...
        H_point_bits, ...
        params.samplesPerBit);


    %% =====================================================
    % TURBULENCE
    %% =====================================================

    [H_turb_bits, ~, ~, ~] = ...
        gammaGammaTurbulence( ...
            params.lambda, ...
            params.L, ...
            params.Cn2, ...
            params.Nbits);


    H_turb_signal = repelem( ...
        H_turb_bits, ...
        params.samplesPerBit);


    %% =====================================================
    % LEGITIMATE FSO SIGNAL
    %% =====================================================

    rxOpticalSignal = ...
        H_total .* ...
        H_point_signal .* ...
        H_turb_signal .* ...
        txSignal;


    %% =====================================================
    % RANDOM JAMMER
    %
    % Generate jammer state per bit
    %% =====================================================

    jammerState = ...
        rand(1, params.Nbits) < activityProbability;


    %% =====================================================
    % CONVERT BIT-LEVEL JAMMER TO SAMPLE-LEVEL
    %% =====================================================

    jammerStateSignal = repelem( ...
        jammerState, ...
        params.samplesPerBit);


    jammerSignal = ...
        Pj .* jammerStateSignal;


    %% =====================================================
    % COMBINE SIGNAL + JAMMER
    %% =====================================================

    rxOpticalSignal = ...
        rxOpticalSignal + jammerSignal;


    %% =====================================================
    % RECEIVER NOISE
    %% =====================================================

    receiverNoise = ...
        params.sigmaNoise * ...
        randn(size(rxOpticalSignal));


    %% =====================================================
    % RECEIVER
    %% =====================================================

    [detectedBits, BER, ~, ~, ~] = ...
        receiverModel( ...
            rxOpticalSignal, ...
            bits, ...
            params.Pt, ...
            H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            receiverNoise, ...
            params.enableSaturation);


    %% =====================================================
    % STORE RESULTS
    %% =====================================================

    BER_values(i) = BER;


    errors10(i) = sum( ...
        (bits == 1) & ...
        (detectedBits == 0));


    errors01(i) = sum( ...
        (bits == 0) & ...
        (detectedBits == 1));


    %% =====================================================
    % DISPLAY RESULTS
    %% =====================================================

    fprintf( ...
        'Activity = %.1f | BER = %.6f | Errors = %d | (1->0) = %d | (0->1) = %d\n', ...
        activityProbability, ...
        BER, ...
        sum(bits ~= detectedBits), ...
        errors10(i), ...
        errors01(i));

end


%% =========================================================
% PLOT 1
%
% BER vs JAMMER ACTIVITY PROBABILITY
%% =========================================================

figure;

plot( ...
    activityProbabilities, ...
    BER_values, ...
    '-o', ...
    'LineWidth', 2);

grid on;

xlabel('Jammer Activity Probability');

ylabel('Bit Error Rate (BER)');

title('BER vs Random Jammer Activity Probability');


%% =========================================================
% PLOT 2
%
% ERROR TYPE ANALYSIS
%% =========================================================

figure;

plot( ...
    activityProbabilities, ...
    errors10, ...
    '-o', ...
    'LineWidth', 2);

hold on;

plot( ...
    activityProbabilities, ...
    errors01, ...
    '-s', ...
    'LineWidth', 2);

grid on;

xlabel('Jammer Activity Probability');

ylabel('Number of Errors');

title('Error Types vs Random Jammer Activity');

legend( ...
    '1 -> 0 Errors', ...
    '0 -> 1 Errors');


%% =========================================================
% END
%% =========================================================