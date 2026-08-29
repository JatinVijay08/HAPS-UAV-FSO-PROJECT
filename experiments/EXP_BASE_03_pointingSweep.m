clc;
clear;
close all;

%% =========================================================
% EXPERIMENT 03
%
% POINTING ERROR SWEEP
%
% Objective:
% Investigate the effect of pointing error on
% HAPS FSO communication performance.
%% =========================================================


%% =========================================================
% ADD PROJECT PATH
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);

addpath(projectFolder);

addpath(fullfile(projectFolder, ...
    'baseline_model'));

addpath(fullfile(projectFolder, ...
    'baseline_model', ...
    'MainModels'));


%% =========================================================
% LOAD BASELINE PARAMETERS
%% =========================================================

params = defaultParameters();


%% =========================================================
% FIXED CONDITIONS
%% =========================================================

params.Nbits = 10000;

params.L = 20e3;

params.Cn2 = 1e-16;

params.sigmaNoise = 0.005;


%% =========================================================
% POINTING ERROR VALUES
%% =========================================================

sigmaPointValues = [ ...
    0 ...
    0.005 ...
    0.01 ...
    0.02 ...
    0.03 ...
    0.05 ...
    0.08 ...
    0.10];


%% =========================================================
% STORAGE
%% =========================================================

BER_values = zeros( ...
    size(sigmaPointValues));

meanPointGain = zeros( ...
    size(sigmaPointValues));


%% =========================================================
% SWEEP
%% =========================================================

fprintf('\n');

fprintf('============================================\n');

fprintf('     EXPERIMENT 03 - POINTING ERROR SWEEP\n');

fprintf('============================================\n');


for i = 1:length(sigmaPointValues)

    %% Set pointing error

    params.sigmaPoint = ...
        sigmaPointValues(i);


    %% Run simulation

    results = runBaseline(params);


    %% Store results

    BER_values(i) = results.BER;

    meanPointGain(i) = ...
        mean(results.H_point_bits);


    %% Display

    fprintf('\n');

    fprintf( ...
        'Pointing sigma = %.4f m\n', ...
        params.sigmaPoint);

    fprintf( ...
        'Mean pointing gain = %.6f\n', ...
        meanPointGain(i));

    fprintf( ...
        'BER = %.6f\n', ...
        BER_values(i));

    fprintf( ...
        'Bit Errors = %d\n', ...
        results.bitErrors);

end


%% =========================================================
% PLOT 1
%
% Mean Pointing Gain vs Pointing Error
%% =========================================================

figure;

plot( ...
    sigmaPointValues, ...
    meanPointGain, ...
    '-o', ...
    'LineWidth', 1.5);

xlabel('Pointing Error Standard Deviation, \sigma_{point} (m)');

ylabel('Mean Pointing Gain');

title('Mean Pointing Gain vs Pointing Error');

grid on;


%% =========================================================
% PLOT 2
%
% BER vs Pointing Error
%% =========================================================

figure;

semilogy( ...
    sigmaPointValues, ...
    BER_values, ...
    '-o', ...
    'LineWidth', 1.5);

xlabel('Pointing Error Standard Deviation, \sigma_{point} (m)');

ylabel('Bit Error Rate (BER)');

title('BER vs Pointing Error');

grid on;