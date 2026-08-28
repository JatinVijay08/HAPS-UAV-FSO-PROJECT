clc;
clear;
close all;

%% =========================================================
% EXP_BASE_03
%
% POINTING ERROR SWEEP
%
% Objective:
% Study the effect of HAPS pointing instability
% on channel gain and BER.
%
% Variable:
%       Pointing error standard deviation
%
% Measurements:
%       Mean pointing gain
%       BER
%% =========================================================


%% =========================================================
% ADD MAIN MODELS
%% =========================================================

experimentFolder = fileparts(mfilename('fullpath'));

baselineFolder = fileparts(experimentFolder);

addpath(fullfile(baselineFolder, 'MainModels'));


%% =========================================================
% SYSTEM PARAMETERS
%% =========================================================

Nbits = 10000;

Rb = 1e6;

Pt = 1;


samplesPerBit = 20;


lambda = 1550e-9;

theta = 0.01e-3;


RxDiameter = 0.2;

R = 0.8;


L = 20e3;


alpha = 0.1;


%% =========================================================
% TRANSMITTER
%% =========================================================

[bits, txSignal, ~] = generateOOK( ...
    Nbits, ...
    Pt, ...
    Rb, ...
    samplesPerBit);


%% =========================================================
% DETERMINISTIC CHANNEL
%% =========================================================

[H_geo, wRx, ~, ~] = geometryModel( ...
    lambda, ...
    theta, ...
    RxDiameter, ...
    L);


H_atm = atmosphericAttenuation( ...
    alpha, ...
    L);


H_total = H_geo * H_atm;


%% =========================================================
% POINTING ERROR CONDITIONS
%% =========================================================

sigmaPoint_values = [ ...
    0.001 ...
    0.005 ...
    0.010 ...
    0.020 ...
    0.030 ...
    0.050 ...
    0.080];


meanHpoint_values = zeros(size(sigmaPoint_values));

BER_values = zeros(size(sigmaPoint_values));


%% =========================================================
% POINTING ERROR SWEEP
%% =========================================================

for k = 1:length(sigmaPoint_values)


    %% Current pointing instability

    sigmaPoint = sigmaPoint_values(k);


    %% Generate one pointing realization per bit

    H_point_bits = pointingErrorModel( ...
        wRx, ...
        sigmaPoint, ...
        Nbits);


    %% Expand pointing gain across samples

    H_point_signal = repelem( ...
        H_point_bits, ...
        samplesPerBit);


    %% Apply channel

    rxOpticalSignal = ...
        H_total .* ...
        H_point_signal .* ...
        txSignal;


    %% Receiver detection

    [~, BER_current, ~, ~, ~] = ...
        receiverModel( ...
        rxOpticalSignal, ...
        bits, ...
        Pt, ...
        H_total, ...
        R, ...
        samplesPerBit);


    %% Store results

    meanHpoint_values(k) = ...
        mean(H_point_bits);

    BER_values(k) = BER_current;


    %% Display

    fprintf( ...
        'Pointing sigma = %.4f m | ', ...
        sigmaPoint);


    fprintf( ...
        'Mean H_point = %.4f | ', ...
        meanHpoint_values(k));


    fprintf( ...
        'BER = %.6f\n', ...
        BER_current);

end


%% =========================================================
% PLOT 1
%
% MEAN POINTING GAIN VS POINTING ERROR
%% =========================================================

figure;

plot( ...
    sigmaPoint_values, ...
    meanHpoint_values, ...
    'o-', ...
    'LineWidth', 1.5);


xlabel('Pointing Error Standard Deviation \sigma (m)');

ylabel('Mean Pointing Gain');

title('Effect of Pointing Error on FSO Channel Gain');

grid on;


%% =========================================================
% PLOT 2
%
% BER VS POINTING ERROR
%% =========================================================

figure;

semilogy( ...
    sigmaPoint_values, ...
    BER_values, ...
    'o-', ...
    'LineWidth', 1.5);


xlabel('Pointing Error Standard Deviation \sigma (m)');

ylabel('BER');

title('FSO BER versus Pointing Error');

grid on;