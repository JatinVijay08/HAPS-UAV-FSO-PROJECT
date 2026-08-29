clc;
clear;
close all;

%% =========================================================
% REPRODUCIBILITY
%% =========================================================

rng(42);

%% =========================================================
% HAPS FSO COMMUNICATION SYSTEM
%
% NORMAL BASELINE SIMULATION
%
% HAPS --> Ground Receiver
%
% Includes:
%   - OOK transmission
%   - Geometrical propagation
%   - Atmospheric attenuation
%   - Pointing error
%   - Gamma-Gamma turbulence
%   - Receiver noise
%   - Receiver saturation
%   - Direct detection
%
% NO JAMMER
%% =========================================================


%% =========================================================
% ADD PATHS
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

addpath(currentFolder);

addpath(fullfile(currentFolder, 'MainModels'));


%% =========================================================
% LOAD DEFAULT PARAMETERS
%% =========================================================

params = defaultParameters();



%% =========================================================
% RUN BASELINE SIMULATION
%% =========================================================

results = runBaseline(params);


%% =========================================================
% DISPLAY RESULTS
%% =========================================================

fprintf('\n');

fprintf('============================================\n');
fprintf('        HAPS FSO NORMAL BASELINE\n');
fprintf('============================================\n');


%% SYSTEM

fprintf('\n----- SYSTEM -----\n');

fprintf('Number of bits        = %d\n', ...
    params.Nbits);

fprintf('Bit rate              = %.2f Mbps\n', ...
    params.Rb / 1e6);

fprintf('Transmit power        = %.4f W\n', ...
    params.Pt);

fprintf('HAPS-Ground distance  = %.2f km\n', ...
    params.L / 1e3);


%% GEOMETRY

fprintf('\n----- GEOMETRY -----\n');

fprintf('Geometrical gain      = %.6f\n', ...
    results.H_geo);

fprintf('Beam radius at Rx     = %.4f m\n', ...
    results.wRx);

fprintf('Beam waist            = %.4f m\n', ...
    results.w0);

fprintf('Rayleigh range        = %.4f km\n', ...
    results.zR / 1e3);


%% ATMOSPHERE

fprintf('\n----- ATMOSPHERE -----\n');

fprintf('Atmospheric gain      = %.6f\n', ...
    results.H_atm);

fprintf('Deterministic gain    = %.6f\n', ...
    results.H_total);


%% POINTING

fprintf('\n----- POINTING -----\n');

fprintf('Pointing sigma        = %.4f m\n', ...
    params.sigmaPoint);

fprintf('Mean pointing gain    = %.6f\n', ...
    mean(results.H_point_bits));

fprintf('Std pointing gain     = %.6f\n', ...
    std(results.H_point_bits));


%% TURBULENCE

fprintf('\n----- TURBULENCE -----\n');

fprintf('Cn^2                  = %.2e m^(-2/3)\n', ...
    params.Cn2);

fprintf('Rytov variance        = %.6f\n', ...
    results.sigmaR2);

fprintf('Gamma-Gamma alpha     = %.4f\n', ...
    results.alphaGG);

fprintf('Gamma-Gamma beta      = %.4f\n', ...
    results.betaGG);

fprintf('Mean turbulence gain  = %.6f\n', ...
    mean(results.H_turb_bits));

fprintf('Std turbulence gain   = %.6f\n', ...
    std(results.H_turb_bits));


%% RECEIVER

fprintf('\n----- RECEIVER -----\n');

fprintf('Noise standard deviation = %.6f A\n', ...
    params.sigmaNoise);

fprintf('Decision threshold       = %.6f A\n', ...
    results.threshold);

fprintf('Bit errors               = %d\n', ...
    results.bitErrors);

fprintf('BER                      = %.6f\n', ...
    results.BER);
fprintf('Errors (1 -> 0)        = %d\n', ...
    results.errors10);

fprintf('Errors (0 -> 1)        = %d\n', ...
    results.errors01);


%% =========================================================
% PLOTS
%% =========================================================

%% Transmitted OOK signal

figure;

plot(results.t * 1e6, ...
    results.txSignal, ...
    'LineWidth', 1.5);

xlabel('Time (\mus)');

ylabel('Optical Power (W)');

title('Transmitted OOK Optical Signal');

grid on;


%% Received optical signal

figure;

plot(results.t * 1e6, ...
    results.rxOpticalSignal, ...
    'LineWidth', 1.2);

xlabel('Time (\mus)');

ylabel('Received Optical Power (W)');

title('Received Optical Signal - Normal FSO Baseline');

grid on;

%% =========================================================
% RECEIVER DECISION ANALYSIS
%% =========================================================

figure;

% Bit 0 received samples

histogram( ...
    results.rxSamplesBit0, ...
    40, ...
    'Normalization', 'probability');

hold on;


% Bit 1 received samples

histogram( ...
    results.rxSamplesBit1, ...
    40, ...
    'Normalization', 'probability');


% Decision threshold

xline( ...
    results.threshold, ...
    '--', ...
    'Decision Threshold', ...
    'LineWidth', 2);


xlabel('Sampled Photodetector Current (A)');

ylabel('Probability');

title('Receiver Decision Statistics: Bit 0 vs Bit 1');

legend( ...
    'Transmitted Bit 0', ...
    'Transmitted Bit 1', ...
    'Decision Threshold');

grid on;