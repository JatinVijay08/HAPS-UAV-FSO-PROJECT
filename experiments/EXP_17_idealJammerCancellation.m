clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 17
% IDEAL JAMMER CANCELLATION
%
% Compare:
%
%   1. Fixed receiver under jammer
%   2. Ideal jammer cancellation
%
% Two jammer scenarios:
%
%   A. Constant jammer
%   B. Random intermittent jammer
%
% IMPORTANT:
% This is NOT ML yet.
%
% We assume the jammer waveform is perfectly known.
% Therefore this experiment establishes the theoretical
% upper bound of cancellation performance.
%
%% =========================================================


%% =========================================================
% PATH SETTINGS
%% =========================================================

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(genpath(projectRoot));


%% =========================================================
% COMMON PARAMETERS
%% =========================================================

params = defaultParameters();

params.Nbits = 10000;

params.rngSeed = 42;

params.enableSaturation = true;


%% =========================================================
% JAMMER PARAMETERS
%% =========================================================

constantPowers = [ ...
    0.05 ...
    0.10 ...
    0.15 ...
    0.20 ...
    0.25 ...
    0.30 ...
    0.40];


randomActivities = [ ...
    0.10 ...
    0.20 ...
    0.30 ...
    0.40 ...
    0.50 ...
    0.60 ...
    0.70 ...
    0.80 ...
    0.90 ...
    1.00];


randomPeakPower = 0.40;


%% =========================================================
% BASELINE
%
% Generate one legitimate communication realization.
%
% This gives us:
%
%   bits
%   legitimate optical signal
%   receiver noise
%   channel
%
% The SAME legitimate signal/noise realization is used
% throughout the experiment.
%% =========================================================

params.enableJammer = false;

base = runBaseline(params);


bits = base.bits;

cleanOpticalSignal = base.rxOpticalSignal;

receiverNoise = base.receiverNoise;

H_total = base.H_total;


%% =========================================================
% BASELINE RECEIVER
%% =========================================================

[~, BER_baseline, ~, ~, threshold_baseline] = ...
    receiverModel( ...
        cleanOpticalSignal, ...
        bits, ...
        params.Pt, ...
        H_total, ...
        params.R, ...
        params.samplesPerBit, ...
        receiverNoise, ...
        params.enableSaturation);


%% =========================================================
% DISPLAY HEADER
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 17 - IDEAL JAMMER CANCELLATION\n');
fprintf('============================================\n\n');

fprintf('Baseline BER = %.6f\n', BER_baseline);

fprintf('Baseline Threshold = %.6f A\n\n', ...
    threshold_baseline);


%% =========================================================
% CONSTANT JAMMER
%% =========================================================

fprintf('============================================\n');
fprintf(' CONSTANT JAMMER\n');
fprintf('============================================\n');

BER_constant_fixed = zeros(size(constantPowers));

BER_constant_cancelled = zeros(size(constantPowers));

sat_constant_fixed = zeros(size(constantPowers));

sat_constant_cancelled = zeros(size(constantPowers));


for k = 1:length(constantPowers)

    Pj = constantPowers(k);


    %% -----------------------------------------------------
    % Construct exact constant jammer
    %% -----------------------------------------------------

    jammerSignal = jammerModel( ...
        Pj, ...
        params.Nbits, ...
        params.samplesPerBit, ...
        true);


    %% -----------------------------------------------------
    % ATTACKED SIGNAL
    %% -----------------------------------------------------

    attackedSignal = ...
        cleanOpticalSignal + jammerSignal;


    %% -----------------------------------------------------
    % FIXED RECEIVER
    %% -----------------------------------------------------

    [detectedFixed, BER_fixed, ...
        rxCurrentFixed, ~, ~] = ...
        receiverModel( ...
            attackedSignal, ...
            bits, ...
            params.Pt, ...
            H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % IDEAL CANCELLATION
    %
    % PERFECT KNOWLEDGE:
    %
    % jammer estimate = actual jammer
    %% -----------------------------------------------------

    estimatedJammer = jammerSignal;


    cancelledSignal = ...
        attackedSignal - estimatedJammer;


    %% -----------------------------------------------------
    % RECEIVER AFTER CANCELLATION
    %% -----------------------------------------------------

    [detectedCancelled, BER_cancelled, ...
        rxCurrentCancelled, ~, ~] = ...
        receiverModel( ...
            cancelledSignal, ...
            bits, ...
            params.Pt, ...
            H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % SATURATION FRACTION
    %% -----------------------------------------------------

    satFixed = mean( ...
        rxCurrentFixed >= 0.25);

    satCancelled = mean( ...
        rxCurrentCancelled >= 0.25);


    BER_constant_fixed(k) = BER_fixed;

    BER_constant_cancelled(k) = BER_cancelled;

    sat_constant_fixed(k) = satFixed;

    sat_constant_cancelled(k) = satCancelled;


    %% -----------------------------------------------------
    % DISPLAY
    %% -----------------------------------------------------

    fprintf( ...
        'Pj = %.3f W | Fixed BER = %.6f | Cancelled BER = %.6f | Fixed Sat = %.3f | Cancelled Sat = %.3f\n', ...
        Pj, ...
        BER_fixed, ...
        BER_cancelled, ...
        satFixed, ...
        satCancelled);

end


%% =========================================================
% RANDOM JAMMER
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' RANDOM JAMMER\n');
fprintf('============================================\n');

BER_random_fixed = zeros(size(randomActivities));

BER_random_cancelled = zeros(size(randomActivities));

sat_random_fixed = zeros(size(randomActivities));

sat_random_cancelled = zeros(size(randomActivities));


for k = 1:length(randomActivities)

    activity = randomActivities(k);


    %% -----------------------------------------------------
    % Generate exact random jammer
    %% -----------------------------------------------------

    [jammerSignal, jammerBits] = ...
        randomJammerModel( ...
            randomPeakPower, ...
            params.Nbits, ...
            params.samplesPerBit, ...
            true, ...
            activity);


    %% -----------------------------------------------------
    % ATTACKED SIGNAL
    %% -----------------------------------------------------

    attackedSignal = ...
        cleanOpticalSignal + jammerSignal;


    %% -----------------------------------------------------
    % FIXED RECEIVER
    %% -----------------------------------------------------

    [~, BER_fixed, ...
        rxCurrentFixed, ~, ~] = ...
        receiverModel( ...
            attackedSignal, ...
            bits, ...
            params.Pt, ...
            H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % IDEAL CANCELLATION
    %
    % Perfect knowledge of:
    %
    % jammer power
    % jammer state
    % jammer waveform
    %% -----------------------------------------------------

    estimatedJammer = jammerSignal;


    cancelledSignal = ...
        attackedSignal - estimatedJammer;


    %% -----------------------------------------------------
    % RECEIVER AFTER CANCELLATION
    %% -----------------------------------------------------

    [~, BER_cancelled, ...
        rxCurrentCancelled, ~, ~] = ...
        receiverModel( ...
            cancelledSignal, ...
            bits, ...
            params.Pt, ...
            H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % SATURATION
    %% -----------------------------------------------------

    satFixed = mean( ...
        rxCurrentFixed >= 0.25);

    satCancelled = mean( ...
        rxCurrentCancelled >= 0.25);


    BER_random_fixed(k) = BER_fixed;

    BER_random_cancelled(k) = BER_cancelled;

    sat_random_fixed(k) = satFixed;

    sat_random_cancelled(k) = satCancelled;


    %% -----------------------------------------------------
    % DISPLAY
    %% -----------------------------------------------------

    fprintf( ...
        'Activity = %.2f | Fixed BER = %.6f | Cancelled BER = %.6f | Fixed Sat = %.3f | Cancelled Sat = %.3f\n', ...
        activity, ...
        BER_fixed, ...
        BER_cancelled, ...
        satFixed, ...
        satCancelled);

end


%% =========================================================
% PLOT 1
% CONSTANT JAMMER BER
%% =========================================================

figure;

plot( ...
    constantPowers, ...
    BER_constant_fixed, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

plot( ...
    constantPowers, ...
    BER_constant_cancelled, ...
    '-s', ...
    'LineWidth', 1.5);

yline( ...
    BER_baseline, ...
    '--', ...
    'Baseline BER');


grid on;

xlabel('Constant Jammer Power (W)');

ylabel('Bit Error Rate (BER)');

title( ...
    'Experiment 17: Ideal Cancellation — Constant Jammer');

legend( ...
    'Fixed Receiver', ...
    'Ideal Cancellation', ...
    'Baseline');


%% =========================================================
% PLOT 2
% RANDOM JAMMER BER
%% =========================================================

figure;

plot( ...
    randomActivities, ...
    BER_random_fixed, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

plot( ...
    randomActivities, ...
    BER_random_cancelled, ...
    '-s', ...
    'LineWidth', 1.5);

yline( ...
    BER_baseline, ...
    '--', ...
    'Baseline BER');


grid on;

xlabel('Jammer Activity Probability');

ylabel('Bit Error Rate (BER)');

title( ...
    'Experiment 17: Ideal Cancellation — Random Jammer');

legend( ...
    'Fixed Receiver', ...
    'Ideal Cancellation', ...
    'Baseline');


%% =========================================================
% PLOT 3
% SATURATION
%% =========================================================

figure;

plot( ...
    constantPowers, ...
    sat_constant_fixed, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

plot( ...
    constantPowers, ...
    sat_constant_cancelled, ...
    '-s', ...
    'LineWidth', 1.5);

grid on;

xlabel('Constant Jammer Power (W)');

ylabel('Saturation Fraction');

title( ...
    'Experiment 17: Saturation — Constant Jammer');

legend( ...
    'Fixed Receiver', ...
    'Ideal Cancellation');


%% =========================================================
% PLOT 4
% RANDOM JAMMER SATURATION
%% =========================================================

figure;

plot( ...
    randomActivities, ...
    sat_random_fixed, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

plot( ...
    randomActivities, ...
    sat_random_cancelled, ...
    '-s', ...
    'LineWidth', 1.5);

grid on;

xlabel('Jammer Activity Probability');

ylabel('Saturation Fraction');

title( ...
    'Experiment 17: Saturation — Random Jammer');

legend( ...
    'Fixed Receiver', ...
    'Ideal Cancellation');


%% =========================================================
% FINAL SUMMARY
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 17 COMPLETE\n');
fprintf('============================================\n\n');

fprintf('Baseline BER = %.6f\n\n', BER_baseline);

fprintf('Ideal cancellation assumes PERFECT knowledge of\n');
fprintf('the jammer waveform and therefore represents an\n');
fprintf('upper-bound cancellation performance.\n\n');

fprintf('Next step:\n');
fprintf('Estimate jammer power/state without knowing the\n');
fprintf('true jammer waveform.\n');