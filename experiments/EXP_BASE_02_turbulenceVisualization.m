clc;
clear;
close all;

%% =========================================================
% EXP_BASE_02
%
% ATMOSPHERIC TURBULENCE SWEEP under fixed Pointing Error conditions
%
% Objective:
% Study the effect of atmospheric turbulence strength
% on HAPS FSO BER.
%
% Variable:
%       Cn^2
%
% Measurements:
%       Rytov variance
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


% Keep pointing fixed during turbulence experiment

sigmaPoint = 0.02;


%% =========================================================
% GENERATE TRANSMITTED SIGNAL
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
% TURBULENCE CONDITIONS
%% =========================================================

Cn2_values = [ ...
    1e-17 ...
    3e-17 ...
    1e-16 ...
    3e-16 ...
    1e-15];


BER_values = zeros(size(Cn2_values));

Rytov_values = zeros(size(Cn2_values));


%% =========================================================
% TURBULENCE SWEEP
%% =========================================================

for k = 1:length(Cn2_values)


    %% Current turbulence strength

    Cn2 = Cn2_values(k);


    %% Generate turbulence
    %
    % One turbulence realization per bit

    [H_turb_bits, ~, ~, sigmaR2] = ...
        gammaGammaTurbulence( ...
        lambda, ...
        L, ...
        Cn2, ...
        Nbits);


    %% Generate pointing error
    %
    % Keep pointing conditions present and fixed

    H_point_bits = pointingErrorModel( ...
        wRx, ...
        sigmaPoint, ...
        Nbits);


    %% Expand gains to signal samples

    H_turb_signal = repelem( ...
        H_turb_bits, ...
        samplesPerBit);


    H_point_signal = repelem( ...
        H_point_bits, ...
        samplesPerBit);


    %% Apply complete channel
    %
    % P_rx =
    %
    % P_tx
    % × H_geo
    % × H_atm
    % × H_turb
    % × H_point

    rxOpticalSignal = ...
        H_total .* ...
        H_turb_signal .* ...
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

    BER_values(k) = BER_current;

    Rytov_values(k) = sigmaR2;


    %% Display

    fprintf('\nCn^2 = %.2e\n', Cn2);

    fprintf('Rytov variance = %.4f\n', ...
        sigmaR2);

    fprintf('BER = %.6f\n', ...
        BER_current);

end


%% =========================================================
% PLOT BER VS TURBULENCE STRENGTH
%% =========================================================

figure;

loglog( ...
    Cn2_values, ...
    BER_values, ...
    'o-', ...
    'LineWidth', 1.5);


xlabel( ...
    'Refractive Index Structure Parameter C_n^2 (m^{-2/3})');

ylabel('BER');

title('FSO BER versus Atmospheric Turbulence Strength');

grid on;


%% =========================================================
% PLOT BER VS RYTOV VARIANCE
%% =========================================================

figure;

semilogy( ...
    Rytov_values, ...
    BER_values, ...
    'o-', ...
    'LineWidth', 1.5);


xlabel('Rytov Variance');

ylabel('BER');

title('FSO BER versus Rytov Variance');

grid on;