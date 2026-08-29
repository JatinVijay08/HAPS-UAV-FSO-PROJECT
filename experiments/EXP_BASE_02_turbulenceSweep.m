clc;
clear;
close all;

%% =========================================================
% EXPERIMENT 02
%
% ATMOSPHERIC TURBULENCE SWEEP
%
% Study:
% Effect of turbulence strength (Cn^2)
% on HAPS FSO link BER
%
% Fixed conditions:
%   - Distance
%   - Pointing error
%   - Transmit power
%   - Receiver parameters
%% =========================================================


%% =========================================================
% ADD PROJECT PATHS
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);

addpath(projectFolder);

addpath(fullfile(projectFolder, 'baseline_model'));

addpath(fullfile(projectFolder, ...
    'baseline_model', 'MainModels'));


%% =========================================================
% LOAD DEFAULT PARAMETERS
%% =========================================================

params = defaultParameters();


%% =========================================================
% FIXED CONDITIONS
%% =========================================================

params.L = 20e3;

params.sigmaPoint = 0.02;


%% =========================================================
% TURBULENCE SWEEP VALUES
%% =========================================================

Cn2_values = [ ...
    1e-17 ...
    5e-17 ...
    1e-16 ...
    5e-16 ...
    1e-15 ...
    ];


%% =========================================================
% PREALLOCATE RESULTS
%% =========================================================

BER_values = zeros(size(Cn2_values));

sigmaR2_values = zeros(size(Cn2_values));

%% =========================================================
% RUN TURBULENCE SWEEP
%% =========================================================

for k = 1:length(Cn2_values)

    % Set turbulence strength
    params.Cn2 = Cn2_values(k);


    % Run baseline simulation
    results = runBaseline(params);


    % Store BER
    BER_values(k) = results.BER;


    % Store Rytov variance
    sigmaR2_values(k) = results.sigmaR2;


    %% Display result

    fprintf('\n');

    fprintf('Cn^2 = %.2e m^(-2/3)\n', ...
        params.Cn2);

    fprintf('Rytov Variance = %.6f\n', ...
        results.sigmaR2);

    fprintf('BER = %.6f\n', ...
        results.BER);

    fprintf('Bit Errors = %d\n', ...
        results.bitErrors);

end

%% =========================================================
% PLOT 1
%
% RYTOV VARIANCE VS TURBULENCE STRENGTH
%% =========================================================

figure;

semilogx( ...
    Cn2_values, ...
    sigmaR2_values, ...
    '-o', ...
    'LineWidth', 1.8, ...
    'MarkerSize', 7);

xlabel('Refractive Index Structure Parameter, C_n^2 (m^{-2/3})');

ylabel('Rytov Variance');

title('Atmospheric Turbulence Strength vs Rytov Variance');

grid on;

%% =========================================================
% PLOT 2
%
% BER VS TURBULENCE STRENGTH
%% =========================================================

figure;

semilogx( ...
    Cn2_values, ...
    BER_values, ...
    '-o', ...
    'LineWidth', 1.8, ...
    'MarkerSize', 7);

xlabel('Refractive Index Structure Parameter, C_n^2 (m^{-2/3})');

ylabel('Bit Error Rate (BER)');

title('BER vs Atmospheric Turbulence Strength');

grid on;