function [detectedBits, BER, rxCurrent, rxSamples, threshold] = ...
    receiverModel( ...
    rxOpticalSignal, ...
    bits, ...
    Pt, ...
    H_total, ...
    R, ...
    samplesPerBit)

%% =========================================================
% Photodetector
% ==========================================================

rxCurrent = R * rxOpticalSignal;


%% =========================================================
% Sample once per bit
% ==========================================================

sampleIndices = ...
    samplesPerBit/2 : ...
    samplesPerBit : ...
    length(rxCurrent);

rxSamples = rxCurrent(sampleIndices);


%% =========================================================
% Decision threshold
% ==========================================================

threshold = R * Pt * H_total / 2;


%% =========================================================
% Bit decision
% ==========================================================

detectedBits = rxSamples > threshold;


%% =========================================================
% BER
% ==========================================================

numErrors = sum(bits ~= detectedBits);

BER = numErrors / length(bits);

end