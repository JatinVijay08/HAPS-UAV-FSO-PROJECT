clc;
clear;
close all;

%% =========================================================
% EXPERIMENT 06
%
% CONSTANT JAMMER POWER SWEEP
%
% Goal:
%
% Investigate how jammer optical power affects:
%
%   1. BER
%   2. 1 -> 0 errors
%   3. 0 -> 1 errors
%
% All channel conditions are kept fixed.
%% =========================================================


%% =========================================================
% PATH SETUP
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);

addpath(genpath(projectFolder));


%% =========================================================
% LOAD PARAMETERS
%% =========================================================

params = defaultParameters();


%% =========================================================
% JAMMER POWER VALUES
%% =========================================================

jammerPowers = [ ...
    0 ...
    0.01 ...
    0.03 ...
    0.05 ...
    0.07 ...
    0.10 ...
    0.12 ...
    0.15 ...
    0.20 ...
    0.30 ];

%% =========================================================
% GENERATE FIXED BASELINE CHANNEL REALIZATION
%
% This baseline is generated ONCE.
%
% The same:
%   - transmitted bits
%   - pointing realization
%   - turbulence realization
%
% will be used for every jammer power.
%% =========================================================

rng(params.rngSeed);

% Run the normal FSO baseline once

results = runBaseline(params);


%% =========================================================
% FIX RECEIVER NOISE REALIZATION
%
% Use the exact noise realization generated
% by the baseline simulation.
%% =========================================================

fixedNoise = results.receiverNoise;

%% =========================================================
% PREALLOCATE RESULTS
%% =========================================================

numPowers = length(jammerPowers);

BER_values = zeros(1, numPowers);

bitErrors = zeros(1, numPowers);

errors10 = zeros(1, numPowers);

errors01 = zeros(1, numPowers);


%% =========================================================
% JAMMER POWER SWEEP
%% =========================================================

for k = 1:numPowers

    %% Current jammer power

    Pj = jammerPowers(k);


    %% =====================================================
    % GENERATE CONSTANT JAMMER
    %% =====================================================

    enableJammer = true;

    jammerSignal = jammerModel( ...
        Pj, ...
        params.Nbits, ...
        params.samplesPerBit, ...
        enableJammer);


    %% =====================================================
    % ADD JAMMER TO FIXED FSO SIGNAL
    %% =====================================================

    rxOpticalSignalJammed = ...
        results.rxOpticalSignal + jammerSignal;


    %% =====================================================
    % RECEIVER
    %
    % Same fixed noise for every jammer power
    %% =====================================================

    [detectedBits, BER, ...
        rxCurrent, ...
        rxSamples, ...
        threshold] = receiverModel( ...
        rxOpticalSignalJammed, ...
        results.bits, ...
        params.Pt, ...
        results.H_total, ...
        params.R, ...
        params.samplesPerBit, ...
        fixedNoise, ...
        params.enableSaturation);


    %% =====================================================
    % STORE RESULTS
    %% =====================================================

    BER_values(k) = BER;

    bitErrors(k) = ...
        sum(results.bits ~= detectedBits);

    errors10(k) = ...
        sum(results.bits == 1 & detectedBits == 0);

    errors01(k) = ...
        sum(results.bits == 0 & detectedBits == 1);


    %% =====================================================
    % DISPLAY CURRENT RESULT
    %% =====================================================

    fprintf( ...
        'Pj = %.3f W | BER = %.6f | Errors = %d | ', ...
        Pj, BER, bitErrors(k));

    fprintf( ...
        '(1->0) = %d | (0->1) = %d\n', ...
        errors10(k), errors01(k));

end