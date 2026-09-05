%% EXPERIMENT 25C - STATE-CONDITIONED ML RANDOM JAMMER CANCELLATION
%
% Optimized implementation:
%   - Extract features per bit
%   - Perform ONE TreeBagger prediction for all bits
%   - Estimate common jammer power from predicted ON bits
%   - Cancel jammer before saturation
%
% Output:
%   randomJammerStateConditionedResults.mat

clear;
clc;
close all;

fprintf('============================================\n');
fprintf(' EXPERIMENT 25C - STATE-CONDITIONED ML\n');
fprintf(' RANDOM JAMMER CANCELLATION\n');
fprintf('============================================\n\n');

%% ============================================================
% LOAD STATE MODEL
% ============================================================

fprintf('Loading per-bit ML state model...\n');

stateData = load('jammerPerBitStateModel.mat');

stateModel = stateData.model;
I_sat = stateData.I_sat;

fprintf('State model loaded successfully.\n');
fprintf('I_sat = %.3f A\n\n',I_sat);

%% ============================================================
% RECEIVER PARAMETERS
% ============================================================

Pt = 0.30;
H_total = 0.85;
R = 0.80;

samplesPerBit = 20;
sigmaNoise = 0.005;

numBits = 2000;

threshold = R * Pt * H_total / 2;

fprintf('============================================\n');
fprintf(' RECEIVER OPERATING POINT\n');
fprintf('============================================\n');

fprintf('Pt                 = %.3f W\n',Pt);
fprintf('H_total            = %.3f\n',H_total);
fprintf('Responsivity       = %.3f A/W\n',R);
fprintf('I(1)               = %.6f A\n',R*Pt*H_total);
fprintf('Threshold          = %.6f A\n',threshold);
fprintf('Saturation Current = %.6f A\n\n',I_sat);

%% ============================================================
% JAMMER
% ============================================================

jammerPower = 0.40;

activityValues = 0.10:0.10:1.00;

numActivityValues = length(activityValues);

%% ============================================================
% STORAGE
% ============================================================

BER_fixed = zeros(1,numActivityValues);
BER_ML = zeros(1,numActivityValues);
BER_ideal = zeros(1,numActivityValues);

sat_fixed = zeros(1,numActivityValues);
sat_ML = zeros(1,numActivityValues);
sat_ideal = zeros(1,numActivityValues);

actualAveragePower = zeros(1,numActivityValues);
estimatedPower = zeros(1,numActivityValues);

stateAccuracy = zeros(1,numActivityValues);

%% ============================================================
% MAIN LOOP
% ============================================================

fprintf('============================================\n');
fprintf(' RANDOM JAMMER TEST\n');
fprintf('============================================\n');

for a = 1:numActivityValues

    activityProbability = activityValues(a);

    fprintf('Processing activity = %.2f...\n', ...
        activityProbability);

    %% --------------------------------------------------------
    % Reproducible seed
    % ---------------------------------------------------------

    rng(2500 + a);

    %% --------------------------------------------------------
    % Generate legitimate bits
    % ---------------------------------------------------------

    bits = randi([0 1],1,numBits);

    %% --------------------------------------------------------
    % Generate random jammer state
    % ---------------------------------------------------------

    jammerStateTrue = ...
        rand(1,numBits) < activityProbability;

    %% --------------------------------------------------------
    % Legitimate received optical power
    % ---------------------------------------------------------

    legitPower = ...
        Pt .* bits .* H_total;

    %% --------------------------------------------------------
    % Jammer received optical power
    % ---------------------------------------------------------

    jammerPowerReceived = ...
        jammerPower .* jammerStateTrue .* H_total;

    %% --------------------------------------------------------
    % Total received optical power
    % ---------------------------------------------------------

    totalOpticalPower = ...
        legitPower + jammerPowerReceived;

    %% --------------------------------------------------------
    % Photodetection BEFORE saturation
    % ---------------------------------------------------------

    rxCurrentBits = ...
        R .* totalOpticalPower;

    %% --------------------------------------------------------
    % Expand to waveform samples
    % ---------------------------------------------------------

    rxCurrentPreSat = ...
        repelem(rxCurrentBits,samplesPerBit);

    %% --------------------------------------------------------
    % Receiver noise
    % ---------------------------------------------------------

    receiverNoise = ...
        sigmaNoise .* randn( ...
            1, ...
            numBits*samplesPerBit);

    rxCurrentPreSat = ...
        rxCurrentPreSat + receiverNoise;

    %% ========================================================
    % FIXED RECEIVER
    % ========================================================

    rxFixed = min(rxCurrentPreSat,I_sat);

    sampleIndices = ...
        samplesPerBit/2 : ...
        samplesPerBit : ...
        length(rxFixed);

    rxSamplesFixed = ...
        rxFixed(sampleIndices);

    detectedFixed = ...
        rxSamplesFixed > threshold;

    BER_fixed(a) = ...
        mean(bits ~= detectedFixed);

    sat_fixed(a) = ...
        mean(rxFixed >= I_sat);

    %% ========================================================
    % BUILD ALL PER-BIT FEATURES
    % ========================================================

    XBits = zeros(numBits,6);

    for k = 1:numBits

        startIndex = ...
            (k-1)*samplesPerBit + 1;

        endIndex = ...
            k*samplesPerBit;

        bitCurrent = ...
            rxCurrentPreSat(startIndex:endIndex);

        features = ...
            extractFeatures(bitCurrent,I_sat);

        XBits(k,:) = [ ...
            features.meanCurrent, ...
            features.stdCurrent, ...
            features.minCurrent, ...
            features.maxCurrent, ...
            features.currentRange, ...
            features.saturationFraction ...
        ];

    end

    %% ========================================================
    % ONE ML PREDICTION FOR ALL BITS
    % ========================================================

    prediction = predict(stateModel,XBits);

    predictedState = str2double(string(prediction));

    predictedState = round(predictedState(:))';

    %% ========================================================
    % STATE ACCURACY
    % ========================================================

    stateAccuracy(a) = ...
        mean(predictedState == jammerStateTrue);
    %% ========================================================
    % STATE ACCURACY
    % ========================================================

    stateAccuracy(a) = ...
        mean(predictedState == jammerStateTrue);

    %% ========================================================
    % STATE-CONDITIONED POWER ESTIMATION
    % ========================================================

    onIndices = ...
        find(predictedState == 1);

    if isempty(onIndices)

        estimatedJammerCurrent = 0;

    else

        %% Mean current for every predicted ON bit

        onBitCurrents = ...
            zeros(1,length(onIndices));

        for m = 1:length(onIndices)

            k = onIndices(m);

            startIndex = ...
                (k-1)*samplesPerBit + 1;

            endIndex = ...
                k*samplesPerBit;

            bitCurrent = ...
                rxCurrentPreSat(startIndex:endIndex);

            onBitCurrents(m) = ...
                mean(bitCurrent);

        end

        %% ====================================================
        % ESTIMATE JAMMER-ONLY CURRENT
        % ====================================================
        %
        % When jammer is ON, there are two possible current
        % levels:
        %
        %   jammer + legitimate 0
        %   jammer + legitimate 1
        %
        % Therefore the ON-bit observations form two clusters.
        %
        % The LOWER cluster corresponds to:
        %
        %   jammer only
        %
        % We estimate the jammer current from the lower cluster.
        % ====================================================

        if length(onBitCurrents) >= 4

            %% Two-cluster separation

            clusterIdx = ...
                kmeans(onBitCurrents(:),2, ...
                'Replicates',5);

            cluster1 = ...
                onBitCurrents(clusterIdx == 1);

            cluster2 = ...
                onBitCurrents(clusterIdx == 2);

            %% Calculate cluster centers

            center1 = mean(cluster1);

            center2 = mean(cluster2);

            %% Lower cluster = jammer + legitimate zero

            estimatedJammerCurrent = ...
                min(center1,center2);

        else

            %% Not enough ON bits for clustering

            estimatedJammerCurrent = ...
                min(onBitCurrents);

        end

        %% Prevent negative estimate

        estimatedJammerCurrent = ...
            max(estimatedJammerCurrent,0);

    end

    %% --------------------------------------------------------
    % Convert current → optical jammer power
    % ---------------------------------------------------------

    estimatedPj = ...
        estimatedJammerCurrent / (R * H_total);

    estimatedPj = ...
        max(estimatedPj,0);

    estimatedPower(a) = estimatedPj;

    %% ========================================================
    % ML JAMMER CANCELLATION
    % ========================================================

    %% Jammer current estimate per bit

    estimatedJammerCurrentBits = ...
        predictedState .* estimatedJammerCurrent;

    %% Expand to samples

    estimatedJammerCurrentWaveform = ...
        repelem( ...
            estimatedJammerCurrentBits, ...
            samplesPerBit);

    %% --------------------------------------------------------
    % CANCEL BEFORE SATURATION
    % ---------------------------------------------------------

    rxMLPreSat = ...
        rxCurrentPreSat ...
        - estimatedJammerCurrentWaveform;

    %% Physical receiver cannot have negative current

    rxMLPreSat = ...
        max(rxMLPreSat,0);

    %% --------------------------------------------------------
    % SATURATION AFTER CANCELLATION
    % ---------------------------------------------------------

    rxML = ...
        min(rxMLPreSat,I_sat);

    %% --------------------------------------------------------
    % DETECTION
    % ---------------------------------------------------------

    rxSamplesML = ...
        rxML(sampleIndices);

    detectedML = ...
        rxSamplesML > threshold;

    BER_ML(a) = ...
        mean(bits ~= detectedML);

    sat_ML(a) = ...
        mean(rxML >= I_sat);

    %% ========================================================
    % IDEAL CANCELLATION
    % ========================================================

    idealJammerCurrentBits = ...
        R .* jammerPowerReceived;

    idealJammerCurrentWaveform = ...
        repelem( ...
            idealJammerCurrentBits, ...
            samplesPerBit);

    rxIdealPreSat = ...
        rxCurrentPreSat ...
        - idealJammerCurrentWaveform;

    rxIdealPreSat = ...
        max(rxIdealPreSat,0);

    rxIdeal = ...
        min(rxIdealPreSat,I_sat);

    rxSamplesIdeal = ...
        rxIdeal(sampleIndices);

    detectedIdeal = ...
        rxSamplesIdeal > threshold;

    BER_ideal(a) = ...
        mean(bits ~= detectedIdeal);

    sat_ideal(a) = ...
        mean(rxIdeal >= I_sat);

    %% ========================================================
    % ACTUAL AVERAGE JAMMER POWER
    % ========================================================

    actualAveragePower(a) = ...
        mean(jammerStateTrue) * jammerPower;

    %% ========================================================
    % PRINT RESULTS
    % ========================================================

    fprintf( ...
        ['Activity = %.2f | Actual Avg Pj = %.4f W | ' ...
         'Estimated ON Pj = %.4f W | State Acc = %.4f | ' ...
         'Fixed BER = %.4f | ML BER = %.4f | ' ...
         'Ideal BER = %.4f | Fixed Sat = %.3f | ' ...
         'ML Sat = %.3f\n'], ...
        activityProbability, ...
        actualAveragePower(a), ...
        estimatedPower(a), ...
        stateAccuracy(a), ...
        BER_fixed(a), ...
        BER_ML(a), ...
        BER_ideal(a), ...
        sat_fixed(a), ...
        sat_ML(a));

end

%% ============================================================
% BER PLOT
% ============================================================

figure;

plot( ...
    activityValues, ...
    BER_fixed, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    activityValues, ...
    BER_ML, ...
    '-s', ...
    'LineWidth',1.5);

plot( ...
    activityValues, ...
    BER_ideal, ...
    '--', ...
    'LineWidth',1.5);

grid on;

xlabel('Jammer Activity Probability');

ylabel('BER');

title( ...
    'Experiment 25C - Random Jammer BER');

legend( ...
    'Fixed Receiver', ...
    'ML State-Conditioned Cancellation', ...
    'Ideal Cancellation', ...
    'Location','best');

%% ============================================================
% SATURATION PLOT
% ============================================================

figure;

plot( ...
    activityValues, ...
    sat_fixed, ...
    '-o', ...
    'LineWidth',1.5);

hold on;

plot( ...
    activityValues, ...
    sat_ML, ...
    '-s', ...
    'LineWidth',1.5);

plot( ...
    activityValues, ...
    sat_ideal, ...
    '--', ...
    'LineWidth',1.5);

grid on;

xlabel('Jammer Activity Probability');

ylabel('Saturation Fraction');

title( ...
    'Experiment 25C - Random Jammer Saturation');

legend( ...
    'Fixed Receiver', ...
    'ML State-Conditioned Cancellation', ...
    'Ideal Cancellation', ...
    'Location','best');

%% ============================================================
% POWER ESTIMATION PLOT
% ============================================================

figure;

plot( ...
    activityValues, ...
    actualAveragePower, ...
    '--', ...
    'LineWidth',1.5);

hold on;

plot( ...
    activityValues, ...
    estimatedPower, ...
    '-o', ...
    'LineWidth',1.5);

grid on;

xlabel('Jammer Activity Probability');

ylabel('Jammer Power (W)');

title( ...
    'Experiment 25C - State-Conditioned Jammer Power');

legend( ...
    'Actual Average Jammer Power', ...
    'Estimated ON Jammer Power', ...
    'Location','best');

%% ============================================================
% STATE ACCURACY PLOT
% ============================================================

figure;

plot( ...
    activityValues, ...
    stateAccuracy, ...
    '-o', ...
    'LineWidth',1.5);

grid on;

xlabel('Jammer Activity Probability');

ylabel('State Detection Accuracy');

title( ...
    'Experiment 25C - Per-Bit Jammer State Detection');

ylim([0 1.05]);

%% ============================================================
% SAVE
% ============================================================

save( ...
    'randomJammerStateConditionedResults.mat', ...
    'activityValues', ...
    'BER_fixed', ...
    'BER_ML', ...
    'BER_ideal', ...
    'sat_fixed', ...
    'sat_ML', ...
    'sat_ideal', ...
    'actualAveragePower', ...
    'estimatedPower', ...
    'stateAccuracy', ...
    'jammerPower', ...
    'Pt', ...
    'H_total', ...
    'R', ...
    'I_sat', ...
    'threshold');

%% ============================================================
% COMPLETE
% ============================================================

fprintf('\n============================================\n');
fprintf(' EXPERIMENT 25C COMPLETE\n');
fprintf('============================================\n\n');

fprintf('Integrated ML pipeline:\n');
fprintf('  1. Per-bit jammer state detection\n');
fprintf('  2. State-conditioned common power estimation\n');
fprintf('  3. Per-bit jammer-current reconstruction\n');
fprintf('  4. Pre-saturation cancellation\n');
fprintf('  5. Receiver saturation\n');
fprintf('  6. Threshold detection\n');
fprintf('  7. BER evaluation\n\n');

fprintf('Results saved as:\n');
fprintf('randomJammerStateConditionedResults.mat\n');