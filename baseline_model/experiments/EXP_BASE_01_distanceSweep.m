clc;
clear;
close all;


%% Project path setup

experimentFolder = fileparts(mfilename('fullpath'));
baselineFolder = fileparts(experimentFolder);

addpath(baselineFolder);
%% =========================================================
% EXP-BASE-01
% EFFECT OF HAPS-GROUND DISTANCE ON RECEIVED POWER
% ==========================================================

%% Parameters

Pt = 1;

lambda = 1550e-9;

theta = 0.01e-3;

RxDiameter = 0.2;

alpha = 0.1;

%% Distance range

distances = (1:1:30) * 1e3;

powerGeo = zeros(size(distances));

powerTotal = zeros(size(distances));

%% =========================================================
% DISTANCE SWEEP
% ==========================================================

for k = 1:length(distances)

    L = distances(k);

    %% Geometrical propagation

    H_geo = geometryModel( ...
        lambda, ...
        theta, ...
        RxDiameter, ...
        L);

    %% Atmospheric attenuation

    H_atm = atmosphericAttenuation( ...
        alpha, ...
        L);

    %% Received power

    powerGeo(k) = Pt * H_geo;

    powerTotal(k) = Pt * H_geo * H_atm;

end

%% =========================================================
% PLOT RESULTS
% ==========================================================

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

title('Received Optical Power vs HAPS-Ground Distance');

legend( ...
    'Geometrical Loss Only', ...
    'Geometry + Atmospheric Attenuation');

grid on;