clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 18
% REALISTIC JAMMER ESTIMATION
%
% Purpose:
%
% Estimate jammer contribution using only receiver
% current statistics.
%
% Compare:
%
%   1. Fixed receiver
%   2. Estimated jammer cancellation
%   3. Ideal cancellation
%
% Two jammer types:
%
%   - Constant jammer
%   - Random jammer
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
% BASELINE REFERENCE
%% =========================================================

baseline = runBaseline(params);

baselineMeanCurrent = mean(baseline.rxCurrent);

baselineBER = baseline.BER;

baselineThreshold = baseline.threshold;

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 18 - REALISTIC JAMMER ESTIMATION\n');
fprintf('============================================\n\n');

fprintf('Baseline Mean Current = %.6f A\n', ...
    baselineMeanCurrent);

fprintf('Baseline BER          = %.6f\n', ...
    baselineBER);

fprintf('Baseline Threshold    = %.6f A\n\n', ...
    baselineThreshold);


%% =========================================================
% JAMMER CONFIGURATION
%% =========================================================

constantPowers = ...
    [0.05 0.10 0.15 0.20 0.25 0.30 0.40];

randomActivities = ...
    [0.10 0.20 0.30 0.40 0.50 ...
     0.60 0.70 0.80 0.90 1.00];

randomPeakPower = 0.40;


%% =========================================================
% RESULT STORAGE
%% =========================================================

constantTruePower = zeros(size(constantPowers));

constantEstimatedPower = zeros(size(constantPowers));

constantFixedBER = zeros(size(constantPowers));

constantEstimatedBER = zeros(size(constantPowers));

constantIdealBER = zeros(size(constantPowers));

constantFixedSat = zeros(size(constantPowers));

constantEstimatedSat = zeros(size(constantPowers));

constantIdealSat = zeros(size(constantPowers));


randomActualActivity = zeros(size(randomActivities));

randomTrueAveragePower = zeros(size(randomActivities));

randomEstimatedPower = zeros(size(randomActivities));

randomFixedBER = zeros(size(randomActivities));

randomEstimatedBER = zeros(size(randomActivities));

randomIdealBER = zeros(size(randomActivities));

randomFixedSat = zeros(size(randomActivities));

randomEstimatedSat = zeros(size(randomActivities));

randomIdealSat = zeros(size(randomActivities));


%% =========================================================
% =========================================================
% CONSTANT JAMMER
% =========================================================
% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' CONSTANT JAMMER ESTIMATION\n');
fprintf('============================================\n');


for k = 1:length(constantPowers)

    Pj = constantPowers(k);


    %% -----------------------------------------------------
    % Generate constant jammer
    %% -----------------------------------------------------

    jammerSignal = jammerModel( ...
        Pj, ...
        params.Nbits, ...
        params.samplesPerBit, ...
        true);


    %% -----------------------------------------------------
    % Attacked optical signal
    %% -----------------------------------------------------

    rxOpticalAttack = ...
        baseline.rxOpticalSignal + jammerSignal;


    %% -----------------------------------------------------
    % Fixed receiver
    %% -----------------------------------------------------

    [detectedFixed, BERfixed, ...
        rxCurrentFixed, ...
        ~, ~] = receiverModel( ...
            rxOpticalAttack, ...
            baseline.bits, ...
            params.Pt, ...
            baseline.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            baseline.receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % ESTIMATE JAMMER CURRENT
    %
    % Estimated jammer contribution:
    %
    % J_hat = mean(attacked) - mean(baseline)
    %% -----------------------------------------------------

    estimatedJammerCurrent = ...
        mean(rxCurrentFixed) - ...
        baselineMeanCurrent;


    estimatedJammerCurrent = ...
        max(0, estimatedJammerCurrent);


    %% -----------------------------------------------------
    % Convert current estimate to optical power
    %% -----------------------------------------------------

    estimatedJammerPower = ...
        estimatedJammerCurrent / params.R;


    %% -----------------------------------------------------
    % ESTIMATED CANCELLATION
    %
    % Work in electrical-current domain.
    %% -----------------------------------------------------

    rxCurrentEstimated = ...
        rxCurrentFixed - ...
        estimatedJammerCurrent;


    %% -----------------------------------------------------
    % Apply saturation lower bound
    %% -----------------------------------------------------

    rxCurrentEstimated = ...
        max(rxCurrentEstimated, -Inf);


    %% -----------------------------------------------------
    % Sample estimated-clean current
    %% -----------------------------------------------------

    sampleIndices = ...
        params.samplesPerBit/2 : ...
        params.samplesPerBit : ...
        length(rxCurrentEstimated);


    rxSamplesEstimated = ...
        rxCurrentEstimated(sampleIndices);


    %% -----------------------------------------------------
    % Use original nominal threshold
    %% -----------------------------------------------------

    threshold = baselineThreshold;


    detectedEstimated = ...
        rxSamplesEstimated > threshold;


    BERestimated = ...
        sum(baseline.bits ~= detectedEstimated) ...
        / length(baseline.bits);


    %% -----------------------------------------------------
    % Ideal cancellation
    %% -----------------------------------------------------

    rxOpticalIdeal = ...
        baseline.rxOpticalSignal;


    [detectedIdeal, BERideal, ...
        rxCurrentIdeal, ...
        ~, ~] = receiverModel( ...
            rxOpticalIdeal, ...
            baseline.bits, ...
            params.Pt, ...
            baseline.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            baseline.receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % Saturation statistics
    %% -----------------------------------------------------

    fixedSat = ...
        mean(rxCurrentFixed >= 0.25);


    estimatedSat = ...
        mean(rxCurrentEstimated >= 0.25);


    idealSat = ...
        mean(rxCurrentIdeal >= 0.25);


    %% -----------------------------------------------------
    % Store
    %% -----------------------------------------------------

    constantTruePower(k) = Pj;

    constantEstimatedPower(k) = ...
        estimatedJammerPower;

    constantFixedBER(k) = BERfixed;

    constantEstimatedBER(k) = BERestimated;

    constantIdealBER(k) = BERideal;

    constantFixedSat(k) = fixedSat;

    constantEstimatedSat(k) = estimatedSat;

    constantIdealSat(k) = idealSat;


    %% -----------------------------------------------------
    % Display
    %% -----------------------------------------------------

    fprintf( ...
        'Pj = %.3f W | Estimated = %.4f W | Fixed BER = %.4f | Estimated BER = %.4f | Ideal BER = %.4f\n', ...
        Pj, ...
        estimatedJammerPower, ...
        BERfixed, ...
        BERestimated, ...
        BERideal);

end


%% =========================================================
% =========================================================
% RANDOM JAMMER
% =========================================================
% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' RANDOM JAMMER ESTIMATION\n');
fprintf('============================================\n');


for k = 1:length(randomActivities)

    activity = randomActivities(k);


    %% -----------------------------------------------------
    % Generate random jammer
    %% -----------------------------------------------------

    [jammerSignal, jammerBits] = ...
        randomJammerModel( ...
            randomPeakPower, ...
            params.Nbits, ...
            params.samplesPerBit, ...
            true, ...
            activity);


    %% -----------------------------------------------------
    % Actual jammer statistics
    %% -----------------------------------------------------

    actualActivity = mean(jammerBits);

    actualAveragePower = ...
        randomPeakPower * actualActivity;


    %% -----------------------------------------------------
    % Attacked optical signal
    %% -----------------------------------------------------

    rxOpticalAttack = ...
        baseline.rxOpticalSignal + jammerSignal;


    %% -----------------------------------------------------
    % Fixed receiver
    %% -----------------------------------------------------

    [detectedFixed, BERfixed, ...
        rxCurrentFixed, ...
        ~, ~] = receiverModel( ...
            rxOpticalAttack, ...
            baseline.bits, ...
            params.Pt, ...
            baseline.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            baseline.receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % Estimate average jammer current
    %% -----------------------------------------------------

    estimatedJammerCurrent = ...
        mean(rxCurrentFixed) - ...
        baselineMeanCurrent;


    estimatedJammerCurrent = ...
        max(0, estimatedJammerCurrent);


    %% -----------------------------------------------------
    % Convert to equivalent average optical power
    %% -----------------------------------------------------

    estimatedAveragePower = ...
        estimatedJammerCurrent / params.R;


    %% -----------------------------------------------------
    % Average-power cancellation
    %% -----------------------------------------------------

    rxCurrentEstimated = ...
        rxCurrentFixed - ...
        estimatedJammerCurrent;


    %% -----------------------------------------------------
    % Sample
    %% -----------------------------------------------------

    sampleIndices = ...
        params.samplesPerBit/2 : ...
        params.samplesPerBit : ...
        length(rxCurrentEstimated);


    rxSamplesEstimated = ...
        rxCurrentEstimated(sampleIndices);


    %% -----------------------------------------------------
    % Detection
    %% -----------------------------------------------------

    detectedEstimated = ...
        rxSamplesEstimated > baselineThreshold;


    BERestimated = ...
        sum(baseline.bits ~= detectedEstimated) ...
        / length(baseline.bits);


    %% -----------------------------------------------------
    % Ideal cancellation
    %
    % Remove exact jammer waveform.
    %% -----------------------------------------------------

    rxOpticalIdeal = ...
        rxOpticalAttack - jammerSignal;


    [detectedIdeal, BERideal, ...
        rxCurrentIdeal, ...
        ~, ~] = receiverModel( ...
            rxOpticalIdeal, ...
            baseline.bits, ...
            params.Pt, ...
            baseline.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            baseline.receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % Saturation
    %% -----------------------------------------------------

    fixedSat = ...
        mean(rxCurrentFixed >= 0.25);


    estimatedSat = ...
        mean(rxCurrentEstimated >= 0.25);


    idealSat = ...
        mean(rxCurrentIdeal >= 0.25);


    %% -----------------------------------------------------
    % Store
    %% -----------------------------------------------------

    randomActualActivity(k) = ...
        actualActivity;

    randomTrueAveragePower(k) = ...
        actualAveragePower;

    randomEstimatedPower(k) = ...
        estimatedAveragePower;

    randomFixedBER(k) = BERfixed;

    randomEstimatedBER(k) = BERestimated;

    randomIdealBER(k) = BERideal;

    randomFixedSat(k) = fixedSat;

    randomEstimatedSat(k) = estimatedSat;

    randomIdealSat(k) = idealSat;


    %% -----------------------------------------------------
    % Display
    %% -----------------------------------------------------

    fprintf( ...
        'Activity = %.2f | Actual = %.3f | Actual Avg Pj = %.4f W | Estimated = %.4f W | Fixed BER = %.4f | Estimated BER = %.4f | Ideal BER = %.4f\n', ...
        activity, ...
        actualActivity, ...
        actualAveragePower, ...
        estimatedAveragePower, ...
        BERfixed, ...
        BERestimated, ...
        BERideal);

end


%% =========================================================
% =========================================================
% FIGURE 1 — JAMMER POWER ESTIMATION
% =========================================================
% =========================================================

figure;

plot( ...
    constantTruePower, ...
    constantEstimatedPower, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

plot( ...
    randomTrueAveragePower, ...
    randomEstimatedPower, ...
    '-s', ...
    'LineWidth', 1.5);

plot( ...
    [0 0.4], ...
    [0 0.4], ...
    '--', ...
    'LineWidth', 1.0);

grid on;

xlabel('True / Actual Average Jammer Power (W)');

ylabel('Estimated Jammer Power (W)');

title('Experiment 18: Jammer Power Estimation');

legend( ...
    'Constant Jammer', ...
    'Random Jammer', ...
    'Perfect Estimation', ...
    'Location', ...
    'northwest');


%% =========================================================
% =========================================================
% FIGURE 2 — BER COMPARISON
% =========================================================
% =========================================================

figure;

plot( ...
    constantTruePower, ...
    constantFixedBER, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

plot( ...
    constantTruePower, ...
    constantEstimatedBER, ...
    '-s', ...
    'LineWidth', 1.5);

plot( ...
    constantTruePower, ...
    constantIdealBER, ...
    '--', ...
    'LineWidth', 1.5);

grid on;

xlabel('Constant Jammer Power (W)');

ylabel('Bit Error Rate (BER)');

title('Experiment 18: Constant Jammer Mitigation');

legend( ...
    'Fixed Receiver', ...
    'Estimated Cancellation', ...
    'Ideal Cancellation', ...
    'Location', ...
    'best');


%% =========================================================
% RANDOM BER
%% =========================================================

figure;

plot( ...
    randomActualActivity, ...
    randomFixedBER, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

plot( ...
    randomActualActivity, ...
    randomEstimatedBER, ...
    '-s', ...
    'LineWidth', 1.5);

plot( ...
    randomActualActivity, ...
    randomIdealBER, ...
    '--', ...
    'LineWidth', 1.5);

grid on;

xlabel('Actual Jammer Activity Probability');

ylabel('Bit Error Rate (BER)');

title('Experiment 18: Random Jammer Mitigation');

legend( ...
    'Fixed Receiver', ...
    'Estimated Cancellation', ...
    'Ideal Cancellation', ...
    'Location', ...
    'best');


%% =========================================================
% FIGURE 3 — SATURATION
%% =========================================================

figure;

plot( ...
    constantTruePower, ...
    constantFixedSat, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

plot( ...
    constantTruePower, ...
    constantEstimatedSat, ...
    '-s', ...
    'LineWidth', 1.5);

plot( ...
    constantTruePower, ...
    constantIdealSat, ...
    '--', ...
    'LineWidth', 1.5);

grid on;

xlabel('Constant Jammer Power (W)');

ylabel('Saturation Fraction');

title('Experiment 18: Saturation Recovery');

legend( ...
    'Fixed Receiver', ...
    'Estimated Cancellation', ...
    'Ideal Cancellation', ...
    'Location', ...
    'best');


%% =========================================================
% COMPLETE
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 18 COMPLETE\n');
fprintf('============================================\n\n');

fprintf('The estimator uses only the change in\n');
fprintf('receiver mean current relative to baseline.\n\n');

fprintf('Constant jammer:\n');
fprintf('  Estimates approximately constant jammer power.\n\n');

fprintf('Random jammer:\n');
fprintf('  Estimates average jammer power only.\n');
fprintf('  It does NOT reconstruct the instantaneous\n');
fprintf('  jammer ON/OFF waveform.\n\n');

fprintf('This limitation motivates ML-based jammer\n');
fprintf('state/power estimation.\n');