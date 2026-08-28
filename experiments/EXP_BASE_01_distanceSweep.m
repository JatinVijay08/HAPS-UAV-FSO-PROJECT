clc;
clear;
close all;

rng(1);

%% =========================================================
% EXPERIMENT 01
% DISTANCE SWEEP
%
% Investigate the effect of HAPS-Ground distance on:
%   1. Received optical power
%   2. BER
%   3. Channel gain
%% =========================================================


%% =========================================================
% ADD BASELINE MODELS TO PATH
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);

baselineFolder = fullfile(projectFolder, 'baseline_model');

addpath(baselineFolder);

addpath(fullfile(baselineFolder, 'MainModels'));


%% =========================================================
% LOAD BASELINE PARAMETERS
%% =========================================================

params = defaultParameters();


%% =========================================================
% DISTANCE SWEEP SETTINGS
%% =========================================================

distance_km = 1:1:30;

Ndistances = length(distance_km);


%% =========================================================
% PREALLOCATE RESULTS
%% =========================================================

BER = zeros(1, Ndistances);

receivedPower = zeros(1, Ndistances);

H_geo_values = zeros(1, Ndistances);

H_atm_values = zeros(1, Ndistances);

H_total_values = zeros(1, Ndistances);


%% =========================================================
% RUN DISTANCE SWEEP
%% =========================================================

for i = 1:Ndistances

    %% Change ONLY distance

    params.L = distance_km(i) * 1e3;


    %% Reset random seed
    %
    % Keeps the stochastic conditions reproducible

    rng(1);


    %% Run complete baseline

    results = runBaseline(params);


    %% Store BER

    BER(i) = results.BER;


    %% Store deterministic channel parameters

    H_geo_values(i) = results.H_geo;

    H_atm_values(i) = results.H_atm;

    H_total_values(i) = results.H_total;


    %% Store nominal received power

    receivedPower(i) = ...
        params.Pt * results.H_total;

end


%% =========================================================
% DISPLAY RESULTS
%% =========================================================

fprintf('\n');

fprintf('============================================\n');

fprintf('       EXPERIMENT 01 - DISTANCE SWEEP\n');

fprintf('============================================\n');


for i = 1:Ndistances

    fprintf('\n');

    fprintf('Distance = %.1f km\n', ...
        distance_km(i));

    fprintf('Geometrical Gain = %.6f\n', ...
        H_geo_values(i));

    fprintf('Atmospheric Gain = %.6f\n', ...
        H_atm_values(i));

    fprintf('Received Power = %.6f W\n', ...
        receivedPower(i));

    fprintf('BER = %.6f\n', ...
        BER(i));

end


%% =========================================================
% PLOT 1
% RECEIVED POWER VS DISTANCE
%% =========================================================

figure;

plot(distance_km, ...
    receivedPower, ...
    '-o', ...
    'LineWidth', 1.5);

xlabel('HAPS-Ground Distance (km)');

ylabel('Nominal Received Optical Power (W)');

title('Received Optical Power vs HAPS-Ground Distance');

grid on;


%% =========================================================
% PLOT 2
% CHANNEL GAIN COMPONENTS
%% =========================================================

figure;

semilogy(distance_km, ...
    H_geo_values, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

semilogy(distance_km, ...
    H_atm_values, ...
    '-s', ...
    'LineWidth', 1.5);

semilogy(distance_km, ...
    H_total_values, ...
    '-^', ...
    'LineWidth', 1.5);

xlabel('HAPS-Ground Distance (km)');

ylabel('Channel Gain');

title('FSO Channel Gain vs Distance');

legend( ...
    'Geometrical Gain', ...
    'Atmospheric Gain', ...
    'Total Deterministic Gain', ...
    'Location', 'southwest');

grid on;


%% =========================================================
% PLOT 3
% BER VS DISTANCE
%% =========================================================

figure;

semilogy(distance_km, ...
    max(BER, 1e-6), ...
    '-o', ...
    'LineWidth', 1.5);

xlabel('HAPS-Ground Distance (km)');

ylabel('Bit Error Rate (BER)');

title('BER vs HAPS-Ground Distance');

grid on;