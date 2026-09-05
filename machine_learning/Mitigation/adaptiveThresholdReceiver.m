function [detectedBits, BER, threshold, estimatedJammerCurrent] = ...
    adaptiveThresholdReceiver( ...
    rxCurrent, ...
    bits, ...
    nominalThreshold, ...
    baselineMeanCurrent, ...
    samplesPerBit, ...
    gamma)

%% =========================================================
% ADAPTIVE THRESHOLD RECEIVER
%
% Compensates for the upward receiver-current shift caused
% by an optical jammer.
%
% T_adaptive = T0 + gamma * Ij_hat
%
%% =========================================================


%% =========================================================
% 1. ESTIMATE JAMMER CURRENT
%% =========================================================

meanReceivedCurrent = ...
    mean(rxCurrent);


estimatedJammerCurrent = ...
    max( ...
    0, ...
    meanReceivedCurrent - baselineMeanCurrent);


%% =========================================================
% 2. ADAPTIVE THRESHOLD
%% =========================================================

threshold = ...
    nominalThreshold + ...
    gamma * estimatedJammerCurrent;


%% =========================================================
% 3. SAMPLE ONCE PER BIT
%% =========================================================

sampleIndices = ...
    samplesPerBit/2 : ...
    samplesPerBit : ...
    length(rxCurrent);


rxSamples = ...
    rxCurrent(sampleIndices);


%% =========================================================
% 4. BIT DECISION
%% =========================================================

detectedBits = ...
    rxSamples > threshold;


%% =========================================================
% 5. BER
%% =========================================================

numErrors = ...
    sum(bits ~= detectedBits);


BER = ...
    numErrors / length(bits);


end