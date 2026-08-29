function [jammerSignal, jammerBits] = randomJammerModel( ...
    jammerPower, ...
    Nbits, ...
    samplesPerBit, ...
    enableJammer, ...
    activityProbability)

%% =========================================================
% RANDOM INTERMITTENT JAMMER MODEL
%
% The jammer randomly decides whether to attack each bit.
%
% jammerBits(k) = 1  -> jammer ON during bit k
% jammerBits(k) = 0  -> jammer OFF during bit k
%
% Probability of jammer being active:
%
% P(jammer ON) = activityProbability
%
%% =========================================================


%% =========================================================
% VALIDATE ACTIVITY PROBABILITY
%% =========================================================

if activityProbability < 0 || activityProbability > 1

    error('activityProbability must be between 0 and 1');

end


%% =========================================================
% JAMMER OFF
%% =========================================================

if ~enableJammer

    jammerBits = zeros(1, Nbits);

    jammerSignal = zeros( ...
        1, ...
        Nbits * samplesPerBit);

    return;

end


%% =========================================================
% RANDOM JAMMER ACTIVITY PER BIT
%
% rand < activityProbability
%
% Example:
%
% activityProbability = 0.30
%
% Approximately 30 percent of bits are jammed
%% =========================================================

jammerBits = ...
rand(1, Nbits) < activityProbability;


%% =========================================================
% JAMMER POWER PER BIT
%
% OFF bit -> 0 W
% ON bit  -> jammerPower W
%% =========================================================

jammerPowerBits = ...
jammerPower .* jammerBits;


%% =========================================================
% EXPAND EACH BIT TO ITS SAMPLES
%
% Bit-level jammer state is repeated across all samples
% belonging to that bit.
%% =========================================================

jammerSignal = repelem( ...
jammerPowerBits, ...
    samplesPerBit);


end