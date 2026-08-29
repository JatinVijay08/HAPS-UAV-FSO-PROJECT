clc;
clear;
close all;

%% =========================================================
% EXPERIMENT 05
%
% CONSTANT OPTICAL JAMMER
%
% FAIR CLEAN vs JAMMED COMPARISON
%
% Same:
%   - transmitted bits
%   - pointing realization
%   - turbulence realization
%   - receiver noise
%
% Only jammer power changes
%% =========================================================


%% =========================================================
% PATHS
%% =========================================================


currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);

addpath(genpath(projectFolder));


%% =========================================================
% PARAMETERS
%% =========================================================

params = defaultParameters();

Pj = 0.1;      % Jammer optical power (W)


%% =========================================================
% FIX RANDOM SEED
%
% This guarantees reproducibility
%% =========================================================

rng(params.rngSeed);


%% =========================================================
% TRANSMITTER
%% =========================================================

[bits, txSignal, t] = generateOOK( ...
    params.Nbits, ...
    params.Pt, ...
    params.Rb, ...
    params.samplesPerBit);


%% =========================================================
% GEOMETRICAL PROPAGATION
%% =========================================================

[H_geo, wRx, w0, zR] = geometryModel( ...
    params.lambda, ...
    params.theta, ...
    params.RxDiameter, ...
    params.L);


%% =========================================================
% ATMOSPHERIC ATTENUATION
%% =========================================================

H_atm = atmosphericAttenuation( ...
    params.alpha, ...
    params.L);


%% =========================================================
% DETERMINISTIC CHANNEL
%% =========================================================

H_total = H_geo * H_atm;


%% =========================================================
% POINTING ERROR
%
% Generate ONCE
%% =========================================================

H_point_bits = pointingErrorModel( ...
    wRx, ...
    params.sigmaPoint, ...
    params.Nbits);

H_point_signal = repelem( ...
    H_point_bits, ...
    params.samplesPerBit);


%% =========================================================
% TURBULENCE
%
% Generate ONCE
%% =========================================================

[H_turb_bits, alphaGG, betaGG, sigmaR2] = ...
    gammaGammaTurbulence( ...
    params.lambda, ...
    params.L, ...
    params.Cn2, ...
    params.Nbits);

H_turb_signal = repelem( ...
    H_turb_bits, ...
    params.samplesPerBit);


%% =========================================================
% CLEAN RECEIVED OPTICAL SIGNAL
%% =========================================================

rxOpticalClean = ...
    H_total .* ...
    H_point_signal .* ...
    H_turb_signal .* ...
    txSignal;


%% =========================================================
% CONSTANT JAMMER
%% =========================================================

enableJammer = true;

P_jammer = jammerModel( ...
    Pj, ...
    params.Nbits, ...
    params.samplesPerBit, ...
    enableJammer);

%% =========================================================
% JAMMED OPTICAL SIGNAL
%% =========================================================

rxOpticalJammed = ...
    rxOpticalClean + P_jammer;

%% =========================================================
% SHARED RECEIVER NOISE
%
% Generate ONCE.
%
% The exact same noise realization will be used for:
%   1. Clean case
%   2. Jammed case
%% =========================================================

receiverNoise = ...
params.sigmaNoise * randn(size(rxOpticalClean));

%% =========================================================
% RECEIVER - CLEAN CASE
%% =========================================================

[detectedBitsClean, BERClean, ...
    rxCurrentClean, ...
    rxSamplesClean, ...
    thresholdClean] = receiverModel( ...
rxOpticalClean, ...
    bits, ...
    params.Pt, ...
    H_total, ...
    params.R, ...
    params.samplesPerBit, ...
    receiverNoise, ...
    params.enableSaturation);

%% =========================================================
% RECEIVER - JAMMED CASE
%% =========================================================

[detectedBitsJammed, BERJammed, ...
    rxCurrentJammed, ...
    rxSamplesJammed, ...
    thresholdJammed] = receiverModel( ...
rxOpticalJammed, ...
    bits, ...
    params.Pt, ...
    H_total, ...
    params.R, ...
    params.samplesPerBit, ...
    receiverNoise, ...
    params.enableSaturation);
%% =========================================================
% IMPORTANT:
%
% For a perfectly fair comparison, we must also use
% the SAME RECEIVER NOISE realization.
%
% We will handle this in the next small modification
% to receiverModel.
%% =========================================================
%% =========================================================
% EXPERIMENT RESULTS
%% =========================================================

cleanErrors = sum(bits ~= detectedBitsClean);

jammedErrors = sum(bits ~= detectedBitsJammed);

errors10Clean = sum(bits == 1 & detectedBitsClean == 0);

errors01Clean = sum(bits == 0 & detectedBitsClean == 1);

errors10Jammed = sum(bits == 1 & detectedBitsJammed == 0);

errors01Jammed = sum(bits == 0 & detectedBitsJammed == 1);


fprintf('\n');

fprintf('============================================\n');

fprintf('   EXPERIMENT 05 - CONSTANT JAMMER\n');

fprintf('============================================\n');


%% JAMMER

fprintf('\n----- JAMMER PARAMETERS -----\n');

fprintf('Jammer optical power = %.4f W\n', Pj);


%% CLEAN CASE

fprintf('\n----- WITHOUT JAMMER -----\n');

fprintf('Bit errors = %d\n', cleanErrors);

fprintf('BER        = %.6f\n', BERClean);

fprintf('Errors (1 -> 0) = %d\n', errors10Clean);

fprintf('Errors (0 -> 1) = %d\n', errors01Clean);


%% JAMMED CASE

fprintf('\n----- WITH CONSTANT JAMMER -----\n');

fprintf('Bit errors = %d\n', jammedErrors);

fprintf('BER        = %.6f\n', BERJammed);

fprintf('Errors (1 -> 0) = %d\n', errors10Jammed);

fprintf('Errors (0 -> 1) = %d\n', errors01Jammed);