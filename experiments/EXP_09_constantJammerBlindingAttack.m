%% =========================================================
% EXPERIMENT 09
%
% BLINDING ATTACK POWER SWEEP
%
% Purpose:
% Identify jammer operating regimes:
%
% 1. No attack
% 2. Helpful optical bias
% 3. Transition/interference
% 4. Receiver saturation / blinding
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
% LOAD PARAMETERS
%% =========================================================

params = defaultParameters();


%% =========================================================
% EXPERIMENT SETTINGS
%% =========================================================

params.Nbits = 10000;

params.enableJammer = true;

params.enableSaturation = true;

params.rngSeed = 42;


%% =========================================================
% JAMMER POWER SWEEP
%
% Start small and progressively move into
% the saturation region
%% =========================================================

jammerPowers = ...
    [0 ...
     0.01 ...
     0.03 ...
     0.05 ...
     0.07 ...
     0.10 ...
     0.12 ...
     0.15 ...
     0.20 ...
     0.25 ...
     0.30 ...
     0.40 ...
     0.50 ...
     0.75 ...
     1.00];


%% =========================================================
% RESULT STORAGE
%% =========================================================

BER_values = zeros(size(jammerPowers));

errors10 = zeros(size(jammerPowers));

errors01 = zeros(size(jammerPowers));

meanCurrent = zeros(size(jammerPowers));

maxCurrent = zeros(size(jammerPowers));

saturationFraction = zeros(size(jammerPowers));


%% =========================================================
% LOOP THROUGH JAMMER POWERS
%% =========================================================

for i = 1:length(jammerPowers)

    Pj = jammerPowers(i);


    %% =====================================================
    % FIXED RANDOM SEED
    %
    % Fair comparison:
    %
    % Same bits
    % Same pointing
    % Same turbulence
    % Same receiver noise
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

    legitimateSignal = ...
        H_total .* ...
        H_point_signal .* ...
        H_turb_signal .* ...
        txSignal;


    %% =====================================================
    % CONSTANT JAMMER
    %
    % Jammer active continuously
    %% =====================================================

    Nsamples = length(legitimateSignal);


    jammerSignal = ...
        Pj * ones(1, Nsamples);


    %% =====================================================
    % COMBINED OPTICAL SIGNAL
    %% =====================================================

    rxOpticalSignal = ...
        legitimateSignal + jammerSignal;


    %% =====================================================
    % RECEIVER NOISE
    %% =====================================================

    receiverNoise = ...
        params.sigmaNoise * ...
        randn(size(rxOpticalSignal));


    %% =====================================================
    % RECEIVER
    %% =====================================================

    [detectedBits, BER, ...
        rxCurrent, ...
        rxSamples, ...
        threshold] = ...
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
    % ERROR ANALYSIS
    %% =====================================================

    errors10(i) = sum( ...
        (bits == 1) & ...
        (detectedBits == 0));


    errors01(i) = sum( ...
        (bits == 0) & ...
        (detectedBits == 1));


    %% =====================================================
    % STORE PERFORMANCE
    %% =====================================================

    BER_values(i) = BER;

    meanCurrent(i) = mean(rxSamples);

    maxCurrent(i) = max(rxCurrent);


    %% =====================================================
    % SATURATION ANALYSIS
    %% =====================================================

    I_sat = 0.25;

    saturationFraction(i) = ...
        mean(rxCurrent >= I_sat);


    %% =====================================================
    % DISPLAY
    %% =====================================================

    fprintf( ...
        ['Pj = %.3f W | ' ...
         'BER = %.6f | ' ...
         '(1->0) = %d | ' ...
         '(0->1) = %d | ' ...
         'Sat = %.3f\n'], ...
        Pj, ...
        BER, ...
        errors10(i), ...
        errors01(i), ...
        saturationFraction(i));

end


%% =========================================================
% PLOT 1
%
% BER vs JAMMER POWER
%% =========================================================

figure;

plot( ...
    jammerPowers, ...
    BER_values, ...
    '-o', ...
    'LineWidth', 2);

grid on;

xlabel('Jammer Optical Power (W)');

ylabel('Bit Error Rate (BER)');

title('BER vs Constant Jammer Power');


%% =========================================================
% PLOT 2
%
% ERROR TYPES
%% =========================================================

figure;

plot( ...
    jammerPowers, ...
    errors10, ...
    '-o', ...
    'LineWidth', 2);

hold on;

plot( ...
    jammerPowers, ...
    errors01, ...
    '-s', ...
    'LineWidth', 2);

grid on;

xlabel('Jammer Optical Power (W)');

ylabel('Number of Errors');

title('Error Types vs Jammer Power');

legend( ...
    '1 -> 0 Errors', ...
    '0 -> 1 Errors');


%% =========================================================
% PLOT 3
%
% SATURATION FRACTION
%% =========================================================

figure;

plot( ...
    jammerPowers, ...
    saturationFraction, ...
    '-o', ...
    'LineWidth', 2);

grid on;

xlabel('Jammer Optical Power (W)');

ylabel('Fraction of Saturated Samples');

title('Receiver Saturation vs Jammer Power');


%% =========================================================
% END
%% =========================================================