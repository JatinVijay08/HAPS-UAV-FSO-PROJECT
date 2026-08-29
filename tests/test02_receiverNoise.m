clc;
clear;
close all;

%% =========================================================
% TEST 02 - RECEIVER NOISE VALIDATION
%
% Purpose:
% Validate that increasing receiver noise
% causes an increase in BER.
%
% Channel is kept perfect.
%% =========================================================


%% =========================================================
% ADD PROJECT PATHS
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);

baselineFolder = fullfile(projectFolder, 'baseline_model');

mainModelsFolder = fullfile(baselineFolder, 'MainModels');

addpath(baselineFolder);

addpath(mainModelsFolder);


%% =========================================================
% LOAD DEFAULT PARAMETERS
%% =========================================================

params = defaultParameters();

%% =========================================================
% TEST PARAMETERS
%% =========================================================

% Use more bits for more reliable BER statistics
params.Nbits = 100000;

% Fix random seed for reproducible results
rng(params.rngSeed);

%% =========================================================
% GENERATE TRANSMITTED SIGNAL
%% =========================================================

[bits, txSignal, t] = generateOOK( ...
    params.Nbits, ...
    params.Pt, ...
    params.Rb, ...
    params.samplesPerBit);
%% =========================================================
% PERFECT CHANNEL
%
% No geometrical loss
% No atmospheric attenuation
% No pointing error
% No turbulence
%% =========================================================

rxOpticalSignal = txSignal;

%% =========================================================
% RECEIVER NOISE SWEEP
%% =========================================================

noiseLevels = [ ...
    0 ...
    0.01 ...
    0.05 ...
    0.10 ...
    0.20 ...
    0.30 ...
    0.40];

BER_values = zeros(size(noiseLevels));

%% =========================================================
% RUN RECEIVER NOISE SWEEP
%% =========================================================

for k = 1:length(noiseLevels)

    % Current noise standard deviation
    sigmaNoise = noiseLevels(k);

    % Run receiver
    [detectedBits, BER, ...
        rxCurrent, ...
        rxSamples, ...
        threshold] = receiverModel( ...
        rxOpticalSignal, ...
        bits, ...
        params.Pt, ...
        1, ... % this 1 is H_total(Ideal Channel gain)
        params.R, ...
        params.samplesPerBit, ...
        sigmaNoise, ...
        false);

    % Store BER
    BER_values(k) = BER;

    % Display result
    fprintf( ...
        'Noise sigma = %.3f A | BER = %.6f | Errors = %d\n', ...
        sigmaNoise, ...
        BER, ...
        sum(bits ~= detectedBits));

end

%% =========================================================
% PLOT RESULTS
%% =========================================================

BER_plot = BER_values;

% Replace zero BER only for logarithmic visualization
BER_plot(BER_plot == 0) = 1e-6;

figure;

semilogy( ...
    noiseLevels, ...
    BER_plot, ...
    'o-', ...
    'LineWidth', 1.5, ...
    'MarkerSize', 7);

xlabel('Receiver Noise Standard Deviation, \sigma (A)');

ylabel('Bit Error Rate (BER)');

title('Receiver Noise Validation: BER vs Noise Level');

grid on;