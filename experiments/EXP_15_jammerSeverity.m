clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 15
% JAMMER SEVERITY ANALYSIS
%
% Purpose:
%
% Determine the severity of a detected jamming attack
% using receiver saturation fraction.
%
% Severity levels:
%
%   Normal
%   Mild
%   Moderate
%   Severe
%
% This experiment validates the severity decision logic
% before implementing mitigation.
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
% SATURATION THRESHOLDS
%% =========================================================

mildThreshold = 0.25;

moderateThreshold = 0.60;


fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 15 - JAMMER SEVERITY ANALYSIS\n');
fprintf('============================================\n\n');

fprintf('Severity thresholds:\n');

fprintf('  Mild      : Sat < %.2f\n', ...
    mildThreshold);

fprintf('  Moderate  : %.2f <= Sat < %.2f\n', ...
    mildThreshold, moderateThreshold);

fprintf('  Severe    : Sat >= %.2f\n\n', ...
    moderateThreshold);


%% =========================================================
% CASE 1 - NORMAL
%% =========================================================

fprintf('============================================\n');
fprintf(' NORMAL COMMUNICATION\n');
fprintf('============================================\n');

params.enableJammer = false;

resultsNormal = runBaseline(params);

featuresNormal = extractFeatures( ...
    resultsNormal.rxCurrent, ...
    0.25);

severityNormal = estimateJammerSeverity( ...
    featuresNormal, ...
    'Normal');


fprintf('Saturation Fraction = %.4f\n', ...
    featuresNormal.saturationFraction);

fprintf('Severity            = %s\n\n', ...
    severityNormal);


%% =========================================================
% CASE 2 - CONSTANT JAMMER SWEEP
%% =========================================================

fprintf('============================================\n');
fprintf(' CONSTANT JAMMER SEVERITY\n');
fprintf('============================================\n');

constantPowers = [ ...
    0.00 ...
    0.05 ...
    0.10 ...
    0.15 ...
    0.20 ...
    0.25 ...
    0.30 ...
    0.40];


constantSat = zeros(size(constantPowers));

constantSeverity = cell(size(constantPowers));


for k = 1:length(constantPowers)

    %% -----------------------------------------------------
    % Generate identical baseline
    %% -----------------------------------------------------

    params.rngSeed = 42;

    params.enableJammer = false;

    resultsBase = runBaseline(params);


    %% -----------------------------------------------------
    % Generate constant jammer
    %% -----------------------------------------------------

    jammerSignal = jammerModel( ...
        constantPowers(k), ...
        params.Nbits, ...
        params.samplesPerBit, ...
        true);


    %% -----------------------------------------------------
    % Add jammer to received optical signal
    %% -----------------------------------------------------

    rxOpticalConstant = ...
        resultsBase.rxOpticalSignal + jammerSignal;


    %% -----------------------------------------------------
    % Run receiver
    %% -----------------------------------------------------

    [~, ~, rxCurrentConstant, ~, ~] = ...
        receiverModel( ...
            rxOpticalConstant, ...
            resultsBase.bits, ...
            params.Pt, ...
            resultsBase.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            resultsBase.receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % Extract features
    %% -----------------------------------------------------

    features = extractFeatures( ...
        rxCurrentConstant, ...
        0.25);


    %% -----------------------------------------------------
    % Determine severity
    %% -----------------------------------------------------

    if constantPowers(k) == 0

        predictedClass = 'Normal';

    else

        predictedClass = 'Constant';

    end


    severity = estimateJammerSeverity( ...
        features, ...
        predictedClass);


    %% -----------------------------------------------------
    % Store
    %% -----------------------------------------------------

    constantSat(k) = ...
        features.saturationFraction;

    constantSeverity{k} = severity;


    %% -----------------------------------------------------
    % Display
    %% -----------------------------------------------------

    fprintf( ...
        'Pj = %.3f W | Sat = %.3f | Severity = %s\n', ...
        constantPowers(k), ...
        constantSat(k), ...
        severity);

end


%% =========================================================
% CASE 3 - RANDOM JAMMER SWEEP
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' RANDOM JAMMER SEVERITY\n');
fprintf('============================================\n');


% Keep the peak power fixed.
%
% Average jammer power is controlled through
% activity probability.

randomPeakPower = 0.40;

activityProbabilities = [ ...
    0.00 ...
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


randomSat = zeros(size(activityProbabilities));

randomSeverity = cell(size(activityProbabilities));


for k = 1:length(activityProbabilities)

    %% -----------------------------------------------------
    % Generate identical baseline conditions
    %% -----------------------------------------------------

    params.rngSeed = 42;

    params.enableJammer = false;

    resultsBase = runBaseline(params);


    %% -----------------------------------------------------
    % Generate random jammer
    %% -----------------------------------------------------

    rng(1000 + k);


    [jammerSignal, jammerBits] = ...
        randomJammerModel( ...
            randomPeakPower, ...
            params.Nbits, ...
            params.samplesPerBit, ...
            true, ...
            activityProbabilities(k));


    %% -----------------------------------------------------
    % Add jammer
    %% -----------------------------------------------------

    rxOpticalRandom = ...
        resultsBase.rxOpticalSignal + ...
        jammerSignal;


    %% -----------------------------------------------------
    % Receiver
    %% -----------------------------------------------------

    [~, ~, rxCurrentRandom, ~, ~] = ...
        receiverModel( ...
            rxOpticalRandom, ...
            resultsBase.bits, ...
            params.Pt, ...
            resultsBase.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            resultsBase.receiverNoise, ...
            params.enableSaturation);


    %% -----------------------------------------------------
    % Extract features
    %% -----------------------------------------------------

    features = extractFeatures( ...
        rxCurrentRandom, ...
        0.25);


    %% -----------------------------------------------------
    % Determine severity
    %% -----------------------------------------------------

    if activityProbabilities(k) == 0

        predictedClass = 'Normal';

    else

        predictedClass = 'Random';

    end


    severity = estimateJammerSeverity( ...
        features, ...
        predictedClass);


    randomSat(k) = ...
        features.saturationFraction;


    randomSeverity{k} = severity;


    %% -----------------------------------------------------
    % Actual activity
    %% -----------------------------------------------------

    actualActivity = ...
        mean(jammerBits);


    fprintf( ...
        'Activity = %.2f | Actual = %.3f | Sat = %.3f | Severity = %s\n', ...
        activityProbabilities(k), ...
        actualActivity, ...
        randomSat(k), ...
        severity);

end


%% =========================================================
% VISUALIZATION
%% =========================================================


%% ---------------------------------------------------------
% CONSTANT JAMMER
%% ---------------------------------------------------------

figure;

plot( ...
    constantPowers, ...
    constantSat, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

yline( ...
    mildThreshold, ...
    '--', ...
    'Mild threshold');

yline( ...
    moderateThreshold, ...
    '--', ...
    'Moderate threshold');

grid on;

xlabel('Constant Jammer Power (W)');

ylabel('Saturation Fraction');

title('Experiment 15: Constant Jammer Severity');

legend( ...
    'Saturation Fraction', ...
    'Mild Boundary', ...
    'Severe Boundary', ...
    'Location', ...
    'best');


%% ---------------------------------------------------------
% RANDOM JAMMER
%% ---------------------------------------------------------

figure;

plot( ...
    activityProbabilities, ...
    randomSat, ...
    '-o', ...
    'LineWidth', 1.5);

hold on;

yline( ...
    mildThreshold, ...
    '--', ...
    'Mild threshold');

yline( ...
    moderateThreshold, ...
    '--', ...
    'Moderate threshold');

grid on;

xlabel('Jammer Activity Probability');

ylabel('Saturation Fraction');

title('Experiment 15: Random Jammer Severity');

legend( ...
    'Saturation Fraction', ...
    'Mild Boundary', ...
    'Severe Boundary', ...
    'Location', ...
    'best');


%% =========================================================
% SUMMARY
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 15 COMPLETE\n');
fprintf('============================================\n');

fprintf('\nNormal severity = %s\n', ...
    severityNormal);

fprintf('\nConstant jammer severity results:\n');

for k = 1:length(constantPowers)

    fprintf( ...
        'Pj = %.3f W -> %s\n', ...
        constantPowers(k), ...
        constantSeverity{k});

end


fprintf('\nRandom jammer severity results:\n');

for k = 1:length(activityProbabilities)

    fprintf( ...
        'Activity = %.2f -> %s\n', ...
        activityProbabilities(k), ...
        randomSeverity{k});

end