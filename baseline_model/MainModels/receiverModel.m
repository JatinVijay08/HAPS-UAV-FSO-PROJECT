function [detectedBits, BER, rxCurrent, rxSamples, threshold] = ...
    receiverModel( ...
    rxOpticalSignal, ...
    bits, ...
    Pt, ...
    H_total, ...
    R, ...
    samplesPerBit, ...
    sigmaNoise, ...
    enableSaturation)

%% =========================================================
% RECEIVER MODEL
%
% Includes:
%
% 1. Photodetection
% 2. Additive receiver noise
% 3. Optional receiver saturation
% 4. Sampling once per bit
% 5. Threshold detection
% 6. BER calculation
%% =========================================================


%% =========================================================
% 1. PHOTODETECTION
%
% Optical power → Electrical current
%
% I(t) = R × P_rx(t)
%% =========================================================

rxCurrent = R * rxOpticalSignal;


%% =========================================================
% 2. RECEIVER NOISE
%
% Additive Gaussian electrical noise
%% =========================================================

noise = sigmaNoise * randn(size(rxCurrent));

rxCurrent = rxCurrent + noise;


%% =========================================================
% 3. OPTIONAL RECEIVER SATURATION
%% =========================================================

if enableSaturation

    I_sat = 0.25;   % Saturation current (A)

    rxCurrent = min(rxCurrent, I_sat);

end


%% =========================================================
% 4. SAMPLE ONCE PER BIT
%
% Sample at the middle of each bit period
%% =========================================================

sampleIndices = ...
    samplesPerBit/2 : ...
    samplesPerBit : ...
    length(rxCurrent);

rxSamples = rxCurrent(sampleIndices);


%% =========================================================
% 5. DECISION THRESHOLD
%
% Nominal OOK midpoint threshold
%% =========================================================

threshold = R * Pt * H_total / 2;


%% =========================================================
% 6. BIT DECISION
%% =========================================================

detectedBits = rxSamples > threshold;


%% =========================================================
% 7. BER CALCULATION
%% =========================================================

numErrors = sum(bits ~= detectedBits);

BER = numErrors / length(bits);

end