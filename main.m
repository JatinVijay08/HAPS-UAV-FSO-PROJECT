clc;
clear;
close all;

%% =========================================================
%  HAPS FSO COMMUNICATION SYSTEM
%  Baseline deterministic model
%  HAPS -> Ground Receiver
% ==========================================================

%% Parameters

Nbits = 1000;              % Number of transmitted bits
Rb = 1e6;                % Bit rate (bits/s)
Pt = 1;                  % Optical transmit power (W)

samplesPerBit = 20;
Fs = Rb * samplesPerBit;

% Optical / receiver parameters
lambda = 1550e-9;        % Wavelength (m)
theta = 0.01e-3;         % Beam divergence half-angle (rad)

RxDiameter = 0.2;        % Receiver aperture diameter (m)
R = 0.8;                 % Photodetector responsivity (A/W)

% HAPS-ground distance
L = 20e3;                % 20 km

% Atmospheric attenuation
alpha = 0.1;             % dB/km


%% =========================================================
% 1. TRANSMITTER
% ==========================================================

[bits, txSignal, t] = generateOOK( ...
    Nbits, Pt, Rb, samplesPerBit);


%% Plot transmitted waveform

figure;

plot(t*1e6, txSignal, 'LineWidth', 1.5);

xlabel('Time (\mus)');
ylabel('Optical Power (W)');
title('HAPS Transmitted OOK Optical Signal');

grid on;
ylim([-0.1 1.1]);


%% =========================================================
% 2. GEOMETRICAL PROPAGATION
% ==========================================================

[H_geo, wRx, w0, zR] = geometryModel( ...
    lambda, theta, RxDiameter, L);


%% =========================================================
% 3. ATMOSPHERIC ATTENUATION
% ==========================================================

H_atm = atmosphericAttenuation(alpha, L);


%% =========================================================
% 4. TOTAL DETERMINISTIC CHANNEL
% ==========================================================

H_total = H_geo * H_atm;

rxOpticalSignal = H_total * txSignal;


%% =========================================================
% 5. RECEIVER
% ==========================================================

[detectedBits, BER, rxCurrent, rxSamples, threshold] = ...
    receiverModel( ...
    rxOpticalSignal, ...
    bits, ...
    Pt, ...
    H_total, ...
    R, ...
    samplesPerBit);


%% =========================================================
% 6. DISPLAY RESULTS
% ==========================================================

fprintf('\n===== HAPS FSO BASELINE =====\n');

fprintf('HAPS-Ground Distance = %.1f km\n', L/1e3);

fprintf('Geometrical Gain     = %.6f\n', H_geo);

fprintf('Atmospheric Gain     = %.6f\n', H_atm);

fprintf('Total Channel Gain   = %.6f\n', H_total);

fprintf('Beam Radius at Rx    = %.4f m\n', wRx);

fprintf('Beam Waist            = %.4f m\n', w0);

fprintf('Rayleigh Range        = %.4f km\n', zR/1e3);

fprintf('Received Power        = %.6f W\n', Pt*H_total);

fprintf('Decision Threshold    = %.6f A\n', threshold);

fprintf('Number of bit errors  = %d\n', sum(bits ~= detectedBits));

fprintf('BER                   = %.4f\n', BER);


%% =========================================================
% 7. DISTANCE SWEEP
% ==========================================================

distances = (1:1:30) * 1e3;

powerGeo = zeros(size(distances));
powerTotal = zeros(size(distances));

for k = 1:length(distances)

    distance = distances(k);

    % Geometrical gain
    H_geo_k = geometryModel( ...
        lambda, theta, RxDiameter, distance);

    % Atmospheric gain
    H_atm_k = atmosphericAttenuation( ...
        alpha, distance);

    % Received powers
    powerGeo(k) = Pt * H_geo_k;

    powerTotal(k) = Pt * H_geo_k * H_atm_k;

end


%% Plot distance sweep

figure;

semilogy( ...
    distances/1e3, ...
    powerGeo, ...
    'o-', ...
    'LineWidth', 1.5);

hold on;

semilogy( ...
    distances/1e3, ...
    powerTotal, ...
    's-', ...
    'LineWidth', 1.5);

xlabel('HAPS-Ground Distance (km)');
ylabel('Received Optical Power (W)');

title('Effect of Atmospheric Attenuation');

legend( ...
    'Geometrical Only', ...
    'Geometry + Atmospheric Attenuation');

grid on;

%% =========================================================
% TURBULENCE EXPERIMENT
% ==========================================================

Cn2 = 1e-15;

Nsamples = 10000;

[H_turb, alphaGG, betaGG, sigmaR2] = ...
    gammaGammaTurbulence( ...
    lambda, ...
    L, ...
    Cn2, ...
    Nsamples);


%% Turbulence statistics

fprintf('\n===== ATMOSPHERIC TURBULENCE =====\n');

fprintf('Cn^2            = %.2e m^(-2/3)\n', Cn2);

fprintf('Rytov variance  = %.6f\n', sigmaR2);

fprintf('Alpha           = %.4f\n', alphaGG);

fprintf('Beta            = %.4f\n', betaGG);

fprintf('Mean H_turb     = %.4f\n', mean(H_turb));

fprintf('Std H_turb      = %.4f\n', std(H_turb));


%% Plot turbulence gain

figure;

plot(H_turb, 'LineWidth', 1);

xlabel('Sample');

ylabel('Turbulence Gain');

title('Gamma-Gamma Atmospheric Turbulence');

grid on;

%% =========================================================
% TURBULENCE APPLIED TO RECEIVED SIGNAL
% Block-fading model: one turbulence value per bit
% ==========================================================

[H_turb_bits, ~, ~, ~] = ...
    gammaGammaTurbulence( ...
    lambda, ...
    L, ...
    Cn2, ...
    Nbits);


% Keep the same turbulence gain throughout each bit

H_turb_signal = repelem( ...
    H_turb_bits, ...
    samplesPerBit);


% Apply turbulence to received optical signal

rxOpticalSignalTurb = ...
    H_total .* H_turb_signal .* txSignal;
%% =========================================================
% COMPARE RECEIVED SIGNAL WITH AND WITHOUT TURBULENCE
% ==========================================================

figure;

plot(t*1e6, rxOpticalSignal, ...
    'LineWidth', 1.5);

hold on;

plot(t*1e6, rxOpticalSignalTurb, ...
    'LineWidth', 1.2);

xlabel('Time (\mus)');
ylabel('Received Optical Power (W)');

title('Effect of Atmospheric Turbulence on Received Signal');

legend( ...
    'Without Turbulence', ...
    'With Turbulence');

grid on;

%% =========================================================
% RECEIVER PERFORMANCE UNDER ATMOSPHERIC TURBULENCE
% ==========================================================

[detectedBitsTurb, BERTurb, rxCurrentTurb, ...
    rxSamplesTurb, thresholdTurb] = ...
    receiverModel( ...
    rxOpticalSignalTurb, ...
    bits, ...
    Pt, ...
    H_total, ...
    R, ...
    samplesPerBit);


%% Display turbulent-channel BER

fprintf('\n===== FSO WITH ATMOSPHERIC TURBULENCE =====\n');

fprintf('Cn^2                 = %.2e m^(-2/3)\n', Cn2);

fprintf('Rytov variance       = %.6f\n', sigmaR2);

fprintf('Alpha                 = %.4f\n', alphaGG);

fprintf('Beta                  = %.4f\n', betaGG);

fprintf('Decision Threshold    = %.6f A\n', thresholdTurb);

fprintf('Number of bit errors  = %d\n', ...
    sum(bits ~= detectedBitsTurb));

fprintf('BER                   = %.6f\n', BERTurb);

%% =========================================================
% BER VS ATMOSPHERIC TURBULENCE STRENGTH
% ==========================================================

% Use more bits for statistical BER estimation
NbitsSweep = 10000;

% Turbulence strength cases
Cn2_values = [1e-17 3e-17 1e-16 3e-16 1e-15];

BER_values = zeros(size(Cn2_values));
Rytov_values = zeros(size(Cn2_values));


for k = 1:length(Cn2_values)

    %% Current turbulence condition

    Cn2_current = Cn2_values(k);


    %% Generate a new OOK sequence for this experiment

    [bitsSweep, txSignalSweep, ~] = ...
        generateOOK( ...
        NbitsSweep, ...
        Pt, ...
        Rb, ...
        samplesPerBit);


    %% Generate turbulence gain: one value per bit

    [H_turb_bits, ~, ~, sigmaR2_current] = ...
        gammaGammaTurbulence( ...
        lambda, ...
        L, ...
        Cn2_current, ...
        NbitsSweep);


    %% Expand one turbulence value across each bit

    H_turb_signal = repelem( ...
        H_turb_bits, ...
        samplesPerBit);


    %% Apply turbulence to received signal

    rxOpticalSignalSweep = ...
        H_total .* H_turb_signal .* txSignalSweep;


    %% Receiver detection

    [detectedBitsSweep, BER_current, ~, ~, ~] = ...
        receiverModel( ...
        rxOpticalSignalSweep, ...
        bitsSweep, ...
        Pt, ...
        H_total, ...
        R, ...
        samplesPerBit);


    %% Store results

    BER_values(k) = BER_current;

    Rytov_values(k) = sigmaR2_current;


    %% Display current result

    fprintf('\nCn^2 = %.2e\n', Cn2_current);

    fprintf('Rytov variance = %.4f\n', sigmaR2_current);

    fprintf('BER = %.6f\n', BER_current);

end

%% Plot BER versus turbulence strength

figure;

loglog( ...
    Cn2_values, ...
    BER_values, ...
    'o-', ...
    'LineWidth', 1.5);

xlabel('Refractive Index Structure Parameter C_n^2 (m^{-2/3})');

ylabel('BER');

title('FSO BER versus Atmospheric Turbulence Strength');

grid on;