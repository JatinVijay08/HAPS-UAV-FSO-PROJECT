clc;
clear;
close all;

%% =========================================================
% EXPERIMENT 04
% CHANNEL REALIZATION VISUALIZATION
%
% Visualizes:
%
% 1. Pointing gain per bit
% 2. Turbulence gain per bit
% 3. Combined instantaneous channel gain
% 4. Received optical power
%
%% =========================================================


%% =========================================================
% ADD PROJECT PATHS
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);

addpath(projectFolder);

addpath(fullfile(projectFolder, 'baseline_model'));

addpath(fullfile(projectFolder, 'baseline_model', 'MainModels'));


%% =========================================================
% LOAD PARAMETERS
%% =========================================================

params = defaultParameters();


%% =========================================================
% RUN BASELINE
%% =========================================================

results = runBaseline(params);

%% =========================================================
% CHANNEL COMPONENTS
%% =========================================================

H_deterministic = results.H_geo * results.H_atm;

H_point = results.H_point_bits;

H_turb = results.H_turb_bits;

H_channel = ...
    H_deterministic .* ...
    H_point .* ...
    H_turb;

%% =========================================================
% PLOT 1
% POINTING GAIN
%% =========================================================

figure;

plot(H_point, 'LineWidth', 1.2);

xlabel('Bit Index');

ylabel('Pointing Gain');

title('Instantaneous Pointing Gain per Bit');

grid on;

%% =========================================================
% PLOT 2
% TURBULENCE GAIN
%% =========================================================

figure;

plot(H_turb, 'LineWidth', 1.2);

xlabel('Bit Index');

ylabel('Turbulence Gain');

title('Gamma-Gamma Turbulence Gain per Bit');

grid on;
%% =========================================================
% PLOT 3
% COMBINED CHANNEL GAIN
%% =========================================================

figure;

plot(H_channel, 'LineWidth', 1.2);

xlabel('Bit Index');

ylabel('Channel Gain');

title('Instantaneous Combined FSO Channel Gain');

grid on;

%% =========================================================
% RECEIVED POWER PER BIT
%% =========================================================

txPowerBits = params.Pt * results.bits;

rxPowerBits = txPowerBits .* H_channel;

figure;

stem(rxPowerBits, 'filled');

xlabel('Bit Index');

ylabel('Received Optical Power (W)');

title('Received Optical Power per Bit');

grid on;

%% =========================================================
% CHANNEL STATISTICS
%% =========================================================

fprintf('\n');

fprintf('============================================\n');

fprintf(' EXPERIMENT 04 - CHANNEL REALIZATION\n');

fprintf('============================================\n');

fprintf('\n');

fprintf('Deterministic Gain = %.6f\n', ...
    H_deterministic);

fprintf('Mean Pointing Gain = %.6f\n', ...
    mean(H_point));

fprintf('Mean Turbulence Gain = %.6f\n', ...
    mean(H_turb));

fprintf('Mean Channel Gain = %.6f\n', ...
    mean(H_channel));

fprintf('Minimum Channel Gain = %.6f\n', ...
    min(H_channel));

fprintf('Maximum Channel Gain = %.6f\n', ...
    max(H_channel));

fprintf('\n');

fprintf('BER = %.6f\n', ...
    results.BER);

fprintf('Bit Errors = %d\n', ...
    results.bitErrors);