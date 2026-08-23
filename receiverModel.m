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

%% Receiver noise

sigmaNoise = 0.005;     % Noise standard deviation (A)

noise = sigmaNoise * randn(size(rxCurrent)); % randn -> generates zero mean Gaussian Values

rxCurrent = rxCurrent + noise;

%% Receiver saturation model

I_sat = 0.25;    % Photodetector saturation current (A)
% Maximum current is 0.25 that can be produced by the photodetector
% A strong Jammer could cause the nominal current to go beyond or be pushed
% towards saturation current when corrupting /jamming the signal

rxCurrent = min(rxCurrent, I_sat);


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