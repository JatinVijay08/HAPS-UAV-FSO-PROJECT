%% =========================================================
% EXPERIMENT 24
% ML JAMMER STATE + POWER ESTIMATION + MITIGATION
%
% Purpose:
%   Integrate:
%       1. ML jammer state detection
%       2. ML jammer power estimation
%       3. Pre-saturation jammer cancellation
%
% Comparison:
%       Fixed Receiver
%       ML Cancellation
%       Ideal Cancellation
%
% IMPORTANT:
%   ML cancellation occurs BEFORE receiver saturation.
%
%% =========================================================

clear;
clc;
close all;


fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 24 - ML INTEGRATED MITIGATION\n');
fprintf('============================================\n\n');


%% =========================================================
% 1. PATH SETTINGS
%% =========================================================

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(genpath(projectRoot));


%% =========================================================
% 2. LOAD ML STATE DETECTION MODEL
%% =========================================================

fprintf('Loading ML models...\n');

stateFile = 'randomJammerRobustStateModel.mat';

if ~isfile(stateFile)

    error(['State model not found: ', stateFile]);

end


stateData = load(stateFile);


% The trained TreeBagger is stored as "model"

stateModel = stateData.model;


% Use the saturation level used during training

I_sat = stateData.I_sat;


fprintf('State model loaded successfully.\n');


%% =========================================================
% 3. LOAD ML POWER ESTIMATION MODEL
%% =========================================================

powerFile = 'jammerPowerRobustModel.mat';

if ~isfile(powerFile)

    error(['Power model not found: ', powerFile]);

end


powerData = load(powerFile);


% The trained TreeBagger is stored as "model"

powerModel = powerData.model;


fprintf('Power model loaded successfully.\n');


fprintf('I_sat used by ML models = %.3f A\n',I_sat);


%% =========================================================
% 4. SYSTEM PARAMETERS
%% =========================================================

% Transmitted optical power

Pt = 0.30;


% Deterministic FSO channel gain

H_total = 0.85;


% Photodetector responsivity

R = 0.80;


% Number of samples representing one bit

samplesPerBit = 20;


% Number of transmitted bits

numBits = 2000;


% Receiver noise standard deviation

sigmaNoise = 0.005;


% Random jammer peak power

randomJammerPeak = 0.40;


% ML state detector observation window

windowBits = 20;


rng(100);


%% =========================================================
% 5. RECEIVER OPERATING POINT
%% =========================================================

% Current corresponding to transmitted optical "1"

I_one = R * Pt * H_total;


% Current corresponding to transmitted optical "0"

I_zero = 0;


% Nominal OOK threshold

threshold = I_one / 2;


fprintf('\n');
fprintf('============================================\n');
fprintf(' RECEIVER OPERATING POINT\n');
fprintf('============================================\n');

fprintf('Pt                 = %.3f W\n',Pt);

fprintf('H_total            = %.3f\n',H_total);

fprintf('Responsivity       = %.3f A/W\n',R);

fprintf('I(0)               = %.6f A\n',I_zero);

fprintf('I(1)               = %.6f A\n',I_one);

fprintf('Threshold          = %.6f A\n',threshold);

fprintf('Saturation Current = %.6f A\n',I_sat);


if threshold >= I_sat

    error(['Invalid receiver configuration: threshold is above ', ...
           'or equal to saturation current.']);

end


if I_one >= I_sat

    fprintf('\nWARNING:\n');
    fprintf('Nominal bit-1 current is at/above saturation.\n');
    fprintf('Normal communication may already be clipped.\n\n');

else

    fprintf('\nNormal bit-1 current is below saturation.\n');

end


%% =========================================================
% 6. TEST CONDITIONS
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


%% =========================================================
% 7. STORAGE
%% =========================================================

fixedBERConstant = zeros(size(constantPowers));

mlBERConstant = zeros(size(constantPowers));

idealBERConstant = zeros(size(constantPowers));


fixedSatConstant = zeros(size(constantPowers));

mlSatConstant = zeros(size(constantPowers));

idealSatConstant = zeros(size(constantPowers));


estimatedConstant = zeros(size(constantPowers));

detectedConstant = zeros(size(constantPowers));


fixedBERRandom = zeros(size(randomActivities));

mlBERRandom = zeros(size(randomActivities));

idealBERRandom = zeros(size(randomActivities));


fixedSatRandom = zeros(size(randomActivities));

mlSatRandom = zeros(size(randomActivities));

idealSatRandom = zeros(size(randomActivities));


estimatedRandom = zeros(size(randomActivities));


%% =========================================================
% 8. BASELINE COMMUNICATION
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' BASELINE COMMUNICATION\n');
fprintf('============================================\n');


% Generate random OOK bits

bits = randi([0 1],1,numBits);


% Optical signal

txOpticalBits = Pt * bits;


% Expand bits to samples

txOpticalSignal = ...
    repelem(txOpticalBits,samplesPerBit);


% Receiver noise

receiverNoise = ...
    sigmaNoise * randn(size(txOpticalSignal));


% Photodetection

baselineCurrent = ...
    R * H_total * txOpticalSignal;


% Add receiver noise

baselineCurrent = ...
    baselineCurrent + receiverNoise;


% Apply physical receiver saturation

baselineCurrent = ...
    min(baselineCurrent,I_sat);


% Sampling indices

sampleIndices = ...
    samplesPerBit/2 : ...
    samplesPerBit : ...
    length(baselineCurrent);


% Sample once per bit

baselineSamples = ...
    baselineCurrent(sampleIndices);


% Detection

baselineDetected = ...
    baselineSamples > threshold;


% BER

baselineBER = ...
    sum(bits ~= baselineDetected) / numBits;


% Saturation fraction

baselineSat = ...
    mean(baselineCurrent >= I_sat);


fprintf('Baseline BER       = %.6f\n',baselineBER);

fprintf('Baseline Saturation = %.6f\n',baselineSat);

fprintf('Baseline Threshold = %.6f A\n',threshold);


%% =========================================================
% 9. CONSTANT JAMMER EXPERIMENT
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' CONSTANT JAMMER\n');
fprintf('============================================\n');


for k = 1:length(constantPowers)


    %% =====================================================
    % TRUE JAMMER POWER
    %% =====================================================

    Pj = constantPowers(k);


    %% =====================================================
    % GENERATE CONSTANT JAMMER
    %% =====================================================

    jammerOpticalSignal = ...
        Pj * ones(size(txOpticalSignal));


    %% =====================================================
    % RECEIVED OPTICAL SIGNAL
    %
    % Signal:
    %
    %   Pt * bit * H_total
    %
    % Jammer:
    %
    %   Pj * H_total
    %
    %% =====================================================

    receivedOpticalSignal = ...
        H_total * ...
        (txOpticalSignal + jammerOpticalSignal);


    %% =====================================================
    % RECEIVER BEFORE SATURATION
    %% =====================================================

    rawCurrent = ...
        R * receivedOpticalSignal + receiverNoise;


    %% =====================================================
    % FIXED RECEIVER
    %
    % No mitigation.
    %% =====================================================

    fixedCurrent = ...
        min(rawCurrent,I_sat);


    fixedSamples = ...
        fixedCurrent(sampleIndices);


    fixedDetected = ...
        fixedSamples > threshold;


    fixedBERConstant(k) = ...
        sum(bits ~= fixedDetected) / numBits;


    fixedSatConstant(k) = ...
        mean(fixedCurrent >= I_sat);


    %% =====================================================
    % IDEAL CANCELLATION
    %
    % Perfect knowledge of the jammer.
    %
    % The jammer contribution at receiver is:
    %
    % I_j = R * H_total * Pj
    %% =====================================================

    trueJammerCurrent = ...
        R * H_total * Pj;


    idealRawCurrent = ...
        rawCurrent - trueJammerCurrent;


    % Saturation happens AFTER cancellation

    idealCurrent = ...
        min(idealRawCurrent,I_sat);


    idealSamples = ...
        idealCurrent(sampleIndices);


    idealDetected = ...
        idealSamples > threshold;


    idealBERConstant(k) = ...
        sum(bits ~= idealDetected) / numBits;


    idealSatConstant(k) = ...
        mean(idealCurrent >= I_sat);


    %% =====================================================
    % ML FEATURE EXTRACTION
    %
    % IMPORTANT:
    %
    % These are exactly the six features used during
    % ML training.
    %% =====================================================

    features = ...
        extractFeatures(rawCurrent,I_sat);


    featureVector = [ ...

        features.meanCurrent, ...
        features.stdCurrent, ...
        features.minCurrent, ...
        features.maxCurrent, ...
        features.currentRange, ...
        features.saturationFraction];


    %% =====================================================
    % ML JAMMER STATE DETECTION
    %% =====================================================

    statePrediction = ...
        predict(stateModel,featureVector);


    % TreeBagger classifier can return cell/string output

    detectedState = ...
        convertStatePrediction(statePrediction);


    detectedConstant(k) = ...
        detectedState;


    %% =====================================================
    % ML JAMMER POWER ESTIMATION
    %% =====================================================

    powerPrediction = ...
        predict(powerModel,featureVector);


    % Handle possible cell output

    if iscell(powerPrediction)

        powerPrediction = ...
            str2double(powerPrediction{1});

    end


    estimatedPj = ...
        double(powerPrediction);


    % Jammer power cannot be negative

    estimatedPj = ...
        max(0,estimatedPj);


    estimatedConstant(k) = ...
        estimatedPj;


    %% =====================================================
    % ML JAMMER CANCELLATION
    %
    % IMPORTANT:
    %
    % Cancellation happens BEFORE saturation.
    %% =====================================================

    if detectedState == 1


        estimatedJammerCurrent = ...
            R * H_total * estimatedPj;


        mlRawCurrent = ...
            rawCurrent - estimatedJammerCurrent;


    else


        % No detected jammer

        mlRawCurrent = ...
            rawCurrent;


    end


    %% =====================================================
    % ML RECEIVER SATURATION
    %
    % Saturation occurs AFTER cancellation.
    %% =====================================================

    mlCurrent = ...
        min(mlRawCurrent,I_sat);


    %% =====================================================
    % ML SAMPLING
    %% =====================================================

    mlSamples = ...
        mlCurrent(sampleIndices);


    %% =====================================================
    % ML DETECTION
    %% =====================================================

    mlDetected = ...
        mlSamples > threshold;


    %% =====================================================
    % ML BER
    %% =====================================================

    mlBERConstant(k) = ...
        sum(bits ~= mlDetected) / numBits;


    %% =====================================================
    % ML SATURATION
    %% =====================================================

    mlSatConstant(k) = ...
        mean(mlCurrent >= I_sat);


    %% =====================================================
    % PRINT RESULT
    %% =====================================================

    fprintf([ ...
        'Pj = %.3f W | State = %d | ' ...
        'Estimated = %.4f W | ' ...
        'Fixed BER = %.4f | ' ...
        'ML BER = %.4f | ' ...
        'Ideal BER = %.4f | ' ...
        'Fixed Sat = %.3f | ' ...
        'ML Sat = %.3f\n'], ...
        Pj, ...
        detectedState, ...
        estimatedPj, ...
        fixedBERConstant(k), ...
        mlBERConstant(k), ...
        idealBERConstant(k), ...
        fixedSatConstant(k), ...
        mlSatConstant(k));

end


%% =========================================================
% 10. RANDOM JAMMER EXPERIMENT
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' RANDOM JAMMER\n');
fprintf('============================================\n');


for k = 1:length(randomActivities)


    %% =====================================================
    % JAMMER ACTIVITY
    %% =====================================================

    activityProbability = ...
        randomActivities(k);


    %% =====================================================
    % GENERATE RANDOM JAMMER STATE
    %
    % One jammer state per bit.
    %% =====================================================

    jammerBits = ...
        rand(1,numBits) < activityProbability;


    %% =====================================================
    % RANDOM JAMMER POWER
    %% =====================================================

    jammerPowerBits = ...
        randomJammerPeak * jammerBits;


    %% =====================================================
    % EXPAND TO SAMPLES
    %% =====================================================

    jammerOpticalSignal = ...
        repelem(jammerPowerBits,samplesPerBit);


    %% =====================================================
    % ACTUAL AVERAGE JAMMER POWER
    %% =====================================================

    actualAveragePower = ...
        mean(jammerPowerBits);


    %% =====================================================
    % RECEIVED OPTICAL SIGNAL
    %% =====================================================

    receivedOpticalSignal = ...
        H_total * ...
        (txOpticalSignal + jammerOpticalSignal);


    %% =====================================================
    % RECEIVER BEFORE SATURATION
    %% =====================================================

    rawCurrent = ...
        R * receivedOpticalSignal + receiverNoise;


    %% =====================================================
    % FIXED RECEIVER
    %% =====================================================

    fixedCurrent = ...
        min(rawCurrent,I_sat);


    fixedSamples = ...
        fixedCurrent(sampleIndices);


    fixedDetected = ...
        fixedSamples > threshold;


    fixedBERRandom(k) = ...
        sum(bits ~= fixedDetected) / numBits;


    fixedSatRandom(k) = ...
        mean(fixedCurrent >= I_sat);


    %% =====================================================
    % IDEAL CANCELLATION
    %
    % We know the true jammer state and power.
    %% =====================================================

    trueJammerCurrent = ...
        R * H_total * jammerOpticalSignal;


    idealRawCurrent = ...
        rawCurrent - trueJammerCurrent;


    idealCurrent = ...
        min(idealRawCurrent,I_sat);


    idealSamples = ...
        idealCurrent(sampleIndices);


    idealDetected = ...
        idealSamples > threshold;


    idealBERandom(k) = ...
        sum(bits ~= idealDetected) / numBits;


    idealSatRandom(k) = ...
        mean(idealCurrent >= I_sat);


    %% =====================================================
    % ML FEATURE EXTRACTION
    %% =====================================================

    features = ...
        extractFeatures(rawCurrent,I_sat);


    featureVector = [ ...

        features.meanCurrent, ...
        features.stdCurrent, ...
        features.minCurrent, ...
        features.maxCurrent, ...
        features.currentRange, ...
        features.saturationFraction];


    %% =====================================================
    % ML STATE DETECTION
    %% =====================================================

    statePrediction = ...
        predict(stateModel,featureVector);


    detectedState = ...
        convertStatePrediction(statePrediction);


    %% =====================================================
    % ML POWER ESTIMATION
    %% =====================================================

    powerPrediction = ...
        predict(powerModel,featureVector);


    if iscell(powerPrediction)

        powerPrediction = ...
            str2double(powerPrediction{1});

    end


    estimatedPj = ...
        double(powerPrediction);


    estimatedPj = ...
        max(0,estimatedPj);


    estimatedRandom(k) = ...
        estimatedPj;


    %% =====================================================
    % ML CANCELLATION
    %
    % First version:
    %
    % If jammer detected:
    %       subtract estimated jammer power.
    %
    % Otherwise:
    %       no subtraction.
    %
    % This is deliberately a window-level estimate.
    %% =====================================================

    if detectedState == 1


        estimatedJammerCurrent = ...
            R * H_total * estimatedPj;


        mlRawCurrent = ...
            rawCurrent - estimatedJammerCurrent;


    else


        mlRawCurrent = ...
            rawCurrent;


    end


    %% =====================================================
    % SATURATION AFTER ML CANCELLATION
    %% =====================================================

    mlCurrent = ...
        min(mlRawCurrent,I_sat);


    %% =====================================================
    % ML SAMPLING
    %% =====================================================

    mlSamples = ...
        mlCurrent(sampleIndices);


    %% =====================================================
    % ML DETECTION
    %% =====================================================

    mlDetected = ...
        mlSamples > threshold;


    %% =====================================================
    % ML BER
    %% =====================================================

    mlBERRandom(k) = ...
        sum(bits ~= mlDetected) / numBits;


    %% =====================================================
    % ML SATURATION
    %% =====================================================

    mlSatRandom(k) = ...
        mean(mlCurrent >= I_sat);


    %% =====================================================
    % PRINT
    %% =====================================================

    fprintf([ ...
        'Activity = %.2f | Actual Avg Pj = %.4f W | ' ...
        'State = %d | Estimated = %.4f W | ' ...
        'Fixed BER = %.4f | ' ...
        'ML BER = %.4f | ' ...
        'Ideal BER = %.4f | ' ...
        'Fixed Sat = %.3f | ' ...
        'ML Sat = %.3f\n'], ...
        activityProbability, ...
        actualAveragePower, ...
        detectedState, ...
        estimatedPj, ...
        fixedBERRandom(k), ...
        mlBERRandom(k), ...
        idealBERandom(k), ...
        fixedSatRandom(k), ...
        mlSatRandom(k));

end


%% =========================================================
% 11. CONSTANT JAMMER BER GRAPH
%% =========================================================

figure;

plot( ...
    constantPowers, ...
    fixedBERConstant, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    constantPowers, ...
    mlBERConstant, ...
    '-s', ...
    'LineWidth',1.5);

plot( ...
    constantPowers, ...
    idealBERConstant, ...
    '--', ...
    'LineWidth',1.5);

grid on;

xlabel('Constant Jammer Power (W)');

ylabel('BER');

title('Experiment 24 - Constant Jammer BER');

legend( ...
    'Fixed Receiver', ...
    'ML Cancellation', ...
    'Ideal Cancellation', ...
    'Location','best');


%% =========================================================
% 12. CONSTANT JAMMER SATURATION GRAPH
%% =========================================================

figure;

plot( ...
    constantPowers, ...
    fixedSatConstant, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    constantPowers, ...
    mlSatConstant, ...
    '-s', ...
    'LineWidth',1.5);

plot( ...
    constantPowers, ...
    idealSatConstant, ...
    '--', ...
    'LineWidth',1.5);

grid on;

xlabel('Constant Jammer Power (W)');

ylabel('Saturation Fraction');

title('Experiment 24 - Constant Jammer Saturation');

legend( ...
    'Fixed Receiver', ...
    'ML Cancellation', ...
    'Ideal Cancellation', ...
    'Location','best');


%% =========================================================
% 13. RANDOM JAMMER BER GRAPH
%% =========================================================

figure;

plot( ...
    randomActivities, ...
    fixedBERRandom, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    randomActivities, ...
    mlBERRandom, ...
    '-s', ...
    'LineWidth',1.5);

plot( ...
    randomActivities, ...
    idealBERandom, ...
    '--', ...
    'LineWidth',1.5);

grid on;

xlabel('Jammer Activity Probability');

ylabel('BER');

title('Experiment 24 - Random Jammer BER');

legend( ...
    'Fixed Receiver', ...
    'ML Cancellation', ...
    'Ideal Cancellation', ...
    'Location','best');


%% =========================================================
% 14. RANDOM JAMMER SATURATION GRAPH
%% =========================================================

figure;

plot( ...
    randomActivities, ...
    fixedSatRandom, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    randomActivities, ...
    mlSatRandom, ...
    '-s', ...
    'LineWidth',1.5);

plot( ...
    randomActivities, ...
    idealSatRandom, ...
    '--', ...
    'LineWidth',1.5);

grid on;

xlabel('Jammer Activity Probability');

ylabel('Saturation Fraction');

title('Experiment 24 - Random Jammer Saturation');

legend( ...
    'Fixed Receiver', ...
    'ML Cancellation', ...
    'Ideal Cancellation', ...
    'Location','best');


%% =========================================================
% 15. JAMMER POWER ESTIMATION GRAPH
%% =========================================================

figure;

plot( ...
    constantPowers, ...
    constantPowers, ...
    '--', ...
    'LineWidth',1.5);

hold on;

plot( ...
    constantPowers, ...
    estimatedConstant, ...
    '-o', ...
    'LineWidth',1.5);

grid on;

xlabel('Actual Jammer Power (W)');

ylabel('Estimated Jammer Power (W)');

title('Experiment 24 - ML Jammer Power Estimation');

legend( ...
    'Actual / Perfect Estimation', ...
    'ML Estimate', ...
    'Location','best');


%% =========================================================
% 16. SAVE RESULTS
%% =========================================================

save( ...
    'mlIntegratedMitigationResults.mat', ...
    'constantPowers', ...
    'randomActivities', ...
    'fixedBERConstant', ...
    'mlBERConstant', ...
    'idealBERConstant', ...
    'fixedSatConstant', ...
    'mlSatConstant', ...
    'idealSatConstant', ...
    'fixedBERRandom', ...
    'mlBERRandom', ...
    'idealBERRandom', ...
    'fixedSatRandom', ...
    'mlSatRandom', ...
    'idealSatRandom', ...
    'estimatedConstant', ...
    'estimatedRandom');


%% =========================================================
% 17. FINAL SUMMARY
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 24 COMPLETE\n');
fprintf('============================================\n\n');

fprintf('Integrated ML pipeline:\n');

fprintf('  1. Jammer state detection\n');
fprintf('  2. Jammer power estimation\n');
fprintf('  3. Pre-saturation cancellation\n');
fprintf('  4. Receiver saturation\n');
fprintf('  5. Threshold detection\n');
fprintf('  6. BER evaluation\n\n');

fprintf('Comparison performed against:\n');

fprintf('  Fixed receiver\n');
fprintf('  Ideal jammer cancellation\n');
fprintf('  ML-based cancellation\n\n');

fprintf('Results saved as:\n');

fprintf('  mlIntegratedMitigationResults.mat\n\n');


%% =========================================================
% LOCAL FUNCTION
%% =========================================================

function state = convertStatePrediction(prediction)

    %% -----------------------------------------------------
    % Convert TreeBagger classification output into:
    %
    %       0 = jammer OFF
    %       1 = jammer ON
    %% -----------------------------------------------------


    if iscell(prediction)

        value = prediction{1};

    else

        value = prediction;

    end


    %% -----------------------------------------------------
    % String / character output
    %% -----------------------------------------------------

    if ischar(value) || isstring(value)

        value = string(value);


        if value == "1" || ...
           lower(value) == "on"

            state = 1;

        else

            state = 0;

        end


    %% -----------------------------------------------------
    % Numeric output
    %% -----------------------------------------------------

    else

        state = double(value);

    end


    %% -----------------------------------------------------
    % Force binary output
    %% -----------------------------------------------------

    state = state ~= 0;

end