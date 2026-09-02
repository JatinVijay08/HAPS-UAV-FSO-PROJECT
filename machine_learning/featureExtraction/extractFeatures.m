function features = extractFeatures(rxCurrent, I_sat)

%% =========================================================
% FEATURE EXTRACTION FOR ML-BASED JAMMER DETECTION
%
% Input:
%   rxCurrent -> observed receiver current waveform
%   I_sat     -> receiver saturation current
%
% Output:
%   features  -> structure containing receiver features
%
%% =========================================================


%% =========================================================
% BASIC STATISTICAL FEATURES
%% =========================================================

features.meanCurrent = mean(rxCurrent);

features.stdCurrent = std(rxCurrent);

features.minCurrent = min(rxCurrent);

features.maxCurrent = max(rxCurrent);


%% =========================================================
% CURRENT RANGE
%% =========================================================

features.currentRange = ...
features.maxCurrent - features.minCurrent;


%% =========================================================
% SATURATION FRACTION
%
% Fraction of samples at the saturation level
%% =========================================================

features.saturationFraction = ...
mean(rxCurrent >= I_sat);


end