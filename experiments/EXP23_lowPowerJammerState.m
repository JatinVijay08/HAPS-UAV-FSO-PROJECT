clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 23
% LOW-POWER JAMMER STATE DETECTION
%
% Purpose:
%
% Determine whether ML can detect a weak jammer when:
%
%   1. Jammer power is low
%   2. FSO channel conditions vary
%   3. Receiver noise varies
%   4. Observation window is limited
%
% Observation windows:
%
%   5 bits
%   10 bits
%   20 bits
%
% Jammer power:
%
%   0.001 W -> 0.100 W
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

params.rngSeed = 42;

I_sat = 0.25;


%% =========================================================
% DATASET SIZE
%% =========================================================

numTrainingWindows = 2000;

numTestingWindows = 1000;


%% =========================================================
% JAMMER PARAMETERS
%% =========================================================

jammerMinPower = 0.001;

jammerMaxPower = 0.100;


%% =========================================================
% OBSERVATION WINDOWS
%% =========================================================

windowSizes = [5 10 20];


%% =========================================================
% CHANNEL VARIATION
%
% These ranges intentionally make detection harder.
%% =========================================================

turbulenceRange = [0.70 1.30];

pointingRange = [0.80 1.20];

attenuationRange = [0.70 1.00];

noiseScaleRange = [0.80 1.20];


%% =========================================================
% RESULT STORAGE
%% =========================================================

accuracyResults = zeros(length(windowSizes),1);

precisionResults = zeros(length(windowSizes),1);

recallResults = zeros(length(windowSizes),1);

f1Results = zeros(length(windowSizes),1);


%% =========================================================
% FEATURE NAMES
%% =========================================================

featureNames = { ...
    'MeanCurrent', ...
    'StdCurrent', ...
    'MinCurrent', ...
    'MaxCurrent', ...
    'CurrentRange', ...
    'SaturationFraction'};


%% =========================================================
% MAIN WINDOW-SIZE LOOP
%% =========================================================

for w = 1:length(windowSizes)


    windowSize = windowSizes(w);


    fprintf('\n');
    fprintf('============================================\n');
    fprintf(' WINDOW SIZE = %d BITS\n',windowSize);
    fprintf('============================================\n');


    %% =====================================================
    % TRAINING STORAGE
    %% =====================================================

    Xtrain = zeros(numTrainingWindows,6);

    Ytrain = zeros(numTrainingWindows,1);


    %% =====================================================
    % TRAINING DATA GENERATION
    %
    % Exactly half:
    %
    %   OFF
    %
    % Exactly half:
    %
    %   ON
    %
    %% =====================================================

    fprintf('\n');
    fprintf('Generating training data...\n');


    for k = 1:numTrainingWindows


        %% =================================================
        % FORCE BALANCED CLASSES
        %% =================================================

        if k <= numTrainingWindows/2

            jammerOn = false;

        else

            jammerOn = true;

        end


        %% =================================================
        % RANDOM JAMMER POWER
        %% =================================================

        if jammerOn

            jammerPower = ...
                jammerMinPower + ...
                rand * ...
                (jammerMaxPower - jammerMinPower);

        else

            jammerPower = 0;

        end


        %% =================================================
        % RANDOM CHANNEL CONDITIONS
        %% =================================================

        params.channelTurbulence = ...
            turbulenceRange(1) + ...
            rand * diff(turbulenceRange);


        params.pointingFactor = ...
            pointingRange(1) + ...
            rand * diff(pointingRange);


        params.atmosphericAttenuation = ...
            attenuationRange(1) + ...
            rand * diff(attenuationRange);


        %% =================================================
        % RANDOM RECEIVER NOISE
        %% =================================================

        noiseScale = ...
            noiseScaleRange(1) + ...
            rand * diff(noiseScaleRange);


        %% =================================================
        % IMPORTANT:
        %
        % The simulation itself is now ONLY windowSize bits.
        %
        % Therefore:
        %
        % 5-bit experiment -> receiver observes 5 bits
        % 10-bit experiment -> receiver observes 10 bits
        % 20-bit experiment -> receiver observes 20 bits
        %
        %% =================================================

        params.Nbits = windowSize;


        %% =================================================
        % GENERATE CLEAN FSO SIGNAL
        %% =================================================

        params.enableJammer = false;

        resultsBase = runBaseline(params);


        %% =================================================
        % GENERATE JAMMER
        %
        % For ON:
        %
        % jammer is active throughout this observation window.
        %
        % This isolates the fundamental low-power detection
        % problem before we introduce ON/OFF transitions
        % inside the window.
        %% =================================================

        if jammerOn

            [jammerSignal,~] = randomJammerModel( ...
                jammerPower, ...
                params.Nbits, ...
                params.samplesPerBit, ...
                true, ...
                1.0);

        else

            jammerSignal = zeros( ...
                1, ...
                params.Nbits * params.samplesPerBit);

        end


        %% =================================================
        % ADD JAMMER TO OPTICAL SIGNAL
        %% =================================================

        rxOptical = ...
            resultsBase.rxOpticalSignal + jammerSignal;


        %% =================================================
        % RECEIVER NOISE
        %% =================================================

        receiverNoise = ...
            resultsBase.receiverNoise * noiseScale;


        %% =================================================
        % RECEIVER
        %% =================================================

        [~,~,rxCurrent,~,~] = receiverModel( ...
            rxOptical, ...
            resultsBase.bits, ...
            params.Pt, ...
            resultsBase.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            receiverNoise, ...
            params.enableSaturation);


        %% =================================================
        % FEATURE EXTRACTION
        %
        % IMPORTANT:
        %
        % The features now come ONLY from the
        % W-bit observation window.
        %% =================================================

        features = extractFeatures( ...
            rxCurrent, ...
            I_sat);


        %% =================================================
        % STORE FEATURES
        %% =================================================

        Xtrain(k,:) = [ ...
            features.meanCurrent ...
            features.stdCurrent ...
            features.minCurrent ...
            features.maxCurrent ...
            features.currentRange ...
            features.saturationFraction];


        Ytrain(k) = jammerOn;


        %% =================================================
        % PROGRESS
        %% =================================================

        if mod(k,200) == 0

            fprintf( ...
                'Training: %d / %d\n', ...
                k, ...
                numTrainingWindows);

        end

    end


    %% =====================================================
    % TEST DATA
    %% =====================================================

    Xtest = zeros(numTestingWindows,6);

    Ytest = zeros(numTestingWindows,1);


    fprintf('\n');
    fprintf('Generating unseen test data...\n');


    for k = 1:numTestingWindows


        %% =================================================
        % BALANCED TEST CLASSES
        %% =================================================

        if k <= numTestingWindows/2

            jammerOn = false;

        else

            jammerOn = true;

        end


        %% =================================================
        % JAMMER POWER
        %% =================================================

        if jammerOn

            jammerPower = ...
                jammerMinPower + ...
                rand * ...
                (jammerMaxPower - jammerMinPower);

        else

            jammerPower = 0;

        end


        %% =================================================
        % RANDOM CHANNEL
        %% =================================================

        params.channelTurbulence = ...
            turbulenceRange(1) + ...
            rand * diff(turbulenceRange);


        params.pointingFactor = ...
            pointingRange(1) + ...
            rand * diff(pointingRange);


        params.atmosphericAttenuation = ...
            attenuationRange(1) + ...
            rand * diff(attenuationRange);


        %% =================================================
        % RANDOM NOISE
        %% =================================================

        noiseScale = ...
            noiseScaleRange(1) + ...
            rand * diff(noiseScaleRange);


        %% =================================================
        % ACTUAL OBSERVATION LENGTH
        %% =================================================

        params.Nbits = windowSize;


        %% =================================================
        % BASELINE
        %% =================================================

        params.enableJammer = false;

        resultsBase = runBaseline(params);


        %% =================================================
        % JAMMER
        %% =================================================

        if jammerOn

            [jammerSignal,~] = randomJammerModel( ...
                jammerPower, ...
                params.Nbits, ...
                params.samplesPerBit, ...
                true, ...
                1.0);

        else

            jammerSignal = zeros( ...
                1, ...
                params.Nbits * params.samplesPerBit);

        end


        %% =================================================
        % RECEIVED OPTICAL SIGNAL
        %% =================================================

        rxOptical = ...
            resultsBase.rxOpticalSignal + jammerSignal;


        %% =================================================
        % RECEIVER NOISE
        %% =================================================

        receiverNoise = ...
            resultsBase.receiverNoise * noiseScale;


        %% =================================================
        % RECEIVER
        %% =================================================

        [~,~,rxCurrent,~,~] = receiverModel( ...
            rxOptical, ...
            resultsBase.bits, ...
            params.Pt, ...
            resultsBase.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            receiverNoise, ...
            params.enableSaturation);


        %% =================================================
        % FEATURES
        %% =================================================

        features = extractFeatures( ...
            rxCurrent, ...
            I_sat);


        %% =================================================
        % STORE
        %% =================================================

        Xtest(k,:) = [ ...
            features.meanCurrent ...
            features.stdCurrent ...
            features.minCurrent ...
            features.maxCurrent ...
            features.currentRange ...
            features.saturationFraction];


        Ytest(k) = jammerOn;


        %% =================================================
        % PROGRESS
        %% =================================================

        if mod(k,200) == 0

            fprintf( ...
                'Testing: %d / %d\n', ...
                k, ...
                numTestingWindows);

        end

    end


    %% =====================================================
    % TRAIN RANDOM FOREST
    %% =====================================================

    fprintf('\n');
    fprintf('Training Random Forest...\n');


    model = TreeBagger( ...
        100, ...
        Xtrain, ...
        Ytrain, ...
        'Method','classification', ...
        'OOBPrediction','on', ...
        'OOBPredictorImportance','on');


    %% =====================================================
    % PREDICTION
    %% =====================================================

    [prediction,~] = predict( ...
        model, ...
        Xtest);


    %% =====================================================
    % CONVERT RANDOM FOREST OUTPUT
    %% =====================================================

    if iscell(prediction)

        prediction = str2double(prediction);

    end


    prediction = double(prediction);


    %% =====================================================
    % CONFUSION MATRIX
    %
    % Force both classes to exist.
    %% =====================================================

    C = confusionmat( ...
        Ytest, ...
        prediction, ...
        'Order',[0 1]);


    TN = C(1,1);

    FP = C(1,2);

    FN = C(2,1);

    TP = C(2,2);


    %% =====================================================
    % PERFORMANCE METRICS
    %% =====================================================

    accuracy = ...
        (TP + TN) / sum(C(:));


    precision = ...
        TP / max(TP + FP,1);


    recall = ...
        TP / max(TP + FN,1);


    f1 = ...
        2 * precision * recall / ...
        max(precision + recall,eps);


    falseAlarmRate = ...
        FP / max(FP + TN,1);


    missRate = ...
        FN / max(FN + TP,1);


    %% =====================================================
    % STORE RESULTS
    %% =====================================================

    accuracyResults(w) = accuracy;

    precisionResults(w) = precision;

    recallResults(w) = recall;

    f1Results(w) = f1;


    %% =====================================================
    % DISPLAY RESULTS
    %% =====================================================

    fprintf('\n');
    fprintf('============================================\n');
    fprintf(' RESULTS - %d BIT WINDOW\n',windowSize);
    fprintf('============================================\n');


    fprintf( ...
        'Accuracy         = %.2f %%\n', ...
        accuracy*100);


    fprintf( ...
        'Precision        = %.4f\n', ...
        precision);


    fprintf( ...
        'Recall           = %.4f\n', ...
        recall);


    fprintf( ...
        'F1 Score         = %.4f\n', ...
        f1);


    fprintf( ...
        'False Alarm Rate = %.4f\n', ...
        falseAlarmRate);


    fprintf( ...
        'Miss Rate        = %.4f\n', ...
        missRate);


    fprintf('\n');


    fprintf('Confusion Matrix:\n');

    fprintf('\n');

    fprintf( ...
        '              Pred OFF    Pred ON\n');


    fprintf( ...
        'Actual OFF    %8d    %8d\n', ...
        TN,FP);


    fprintf( ...
        'Actual ON     %8d    %8d\n', ...
        FN,TP);


    %% =====================================================
    % FEATURE IMPORTANCE
    %% =====================================================

    importance = ...
        model.OOBPermutedPredictorDeltaError;


    if windowSize == 20

        figure;

        bar(importance);

        grid on;

        xticks(1:6);

        xticklabels(featureNames);

        xtickangle(30);

        ylabel('Predictor Importance');

        title( ...
            'Experiment 23: Low-Power Jammer Feature Importance');

    end


end


%% =========================================================
% PERFORMANCE VS WINDOW SIZE
%% =========================================================

figure;

plot( ...
    windowSizes, ...
    accuracyResults*100, ...
    '-o');

hold on;

plot( ...
    windowSizes, ...
    precisionResults*100, ...
    '-s');

plot( ...
    windowSizes, ...
    recallResults*100, ...
    '-^');

plot( ...
    windowSizes, ...
    f1Results*100, ...
    '-d');

grid on;

xlabel('Observation Window (bits)');

ylabel('Performance (%)');

title( ...
    'Experiment 23: ML Detection vs Observation Window');

legend( ...
    'Accuracy', ...
    'Precision', ...
    'Recall', ...
    'F1 Score');


%% =========================================================
% LOW-POWER DETECTION LIMIT
%
% Train one final model using the largest window.
%
% We now sweep jammer power and calculate:
%
%       P(detect jammer ON)
%
% This is much more useful than accuracy alone.
%% =========================================================

windowSize = 20;


fprintf('\n');
fprintf('============================================\n');
fprintf(' LOW-POWER DETECTION LIMIT TEST\n');
fprintf('============================================\n');


%% =========================================================
% RETRAIN 20-BIT MODEL
%% =========================================================

Xtrain = zeros(numTrainingWindows,6);

Ytrain = zeros(numTrainingWindows,1);


for k = 1:numTrainingWindows


    if k <= numTrainingWindows/2

        jammerOn = false;

    else

        jammerOn = true;

    end


    if jammerOn

        jammerPower = ...
            jammerMinPower + ...
            rand * ...
            (jammerMaxPower - jammerMinPower);

    else

        jammerPower = 0;

    end


    %% Channel variation

    params.Nbits = windowSize;


    params.channelTurbulence = ...
        turbulenceRange(1) + ...
        rand * diff(turbulenceRange);


    params.pointingFactor = ...
        pointingRange(1) + ...
        rand * diff(pointingRange);


    params.atmosphericAttenuation = ...
        attenuationRange(1) + ...
        rand * diff(attenuationRange);


    noiseScale = ...
        noiseScaleRange(1) + ...
        rand * diff(noiseScaleRange);


    %% Baseline

    params.enableJammer = false;

    resultsBase = runBaseline(params);


    %% Jammer

    if jammerOn

        [jammerSignal,~] = randomJammerModel( ...
            jammerPower, ...
            params.Nbits, ...
            params.samplesPerBit, ...
            true, ...
            1.0);

    else

        jammerSignal = zeros( ...
            1, ...
            params.Nbits * params.samplesPerBit);

    end


    %% Optical signal

    rxOptical = ...
        resultsBase.rxOpticalSignal + jammerSignal;


    %% Receiver

    receiverNoise = ...
        resultsBase.receiverNoise * noiseScale;


    [~,~,rxCurrent,~,~] = receiverModel( ...
        rxOptical, ...
        resultsBase.bits, ...
        params.Pt, ...
        resultsBase.H_total, ...
        params.R, ...
        params.samplesPerBit, ...
        receiverNoise, ...
        params.enableSaturation);


    %% Features

    features = extractFeatures( ...
        rxCurrent, ...
        I_sat);


    Xtrain(k,:) = [ ...
        features.meanCurrent ...
        features.stdCurrent ...
        features.minCurrent ...
        features.maxCurrent ...
        features.currentRange ...
        features.saturationFraction];


    Ytrain(k) = jammerOn;

end


%% =========================================================
% FINAL MODEL
%% =========================================================

finalModel = TreeBagger( ...
    100, ...
    Xtrain, ...
    Ytrain, ...
    'Method','classification');


%% =========================================================
% JAMMER POWER SWEEP
%% =========================================================

powerSweep = ...
    0.001:0.005:0.100;


detectionProbability = ...
    zeros(size(powerSweep));


numTrialsPerPower = 200;


fprintf('\n');
fprintf('Testing detection probability...\n');


for p = 1:length(powerSweep)


    Pj = powerSweep(p);


    detectedCount = 0;


    for trial = 1:numTrialsPerPower


        %% Random channel

        params.Nbits = windowSize;


        params.channelTurbulence = ...
            turbulenceRange(1) + ...
            rand * diff(turbulenceRange);


        params.pointingFactor = ...
            pointingRange(1) + ...
            rand * diff(pointingRange);


        params.atmosphericAttenuation = ...
            attenuationRange(1) + ...
            rand * diff(attenuationRange);


        noiseScale = ...
            noiseScaleRange(1) + ...
            rand * diff(noiseScaleRange);


        %% Baseline

        params.enableJammer = false;

        resultsBase = runBaseline(params);


        %% Jammer ON

        [jammerSignal,~] = randomJammerModel( ...
            Pj, ...
            params.Nbits, ...
            params.samplesPerBit, ...
            true, ...
            1.0);


        %% Add jammer

        rxOptical = ...
            resultsBase.rxOpticalSignal + jammerSignal;


        %% Noise

        receiverNoise = ...
            resultsBase.receiverNoise * noiseScale;


        %% Receiver

        [~,~,rxCurrent,~,~] = receiverModel( ...
            rxOptical, ...
            resultsBase.bits, ...
            params.Pt, ...
            resultsBase.H_total, ...
            params.R, ...
            params.samplesPerBit, ...
            receiverNoise, ...
            params.enableSaturation);


        %% Features

        features = extractFeatures( ...
            rxCurrent, ...
            I_sat);


        X = [ ...
            features.meanCurrent ...
            features.stdCurrent ...
            features.minCurrent ...
            features.maxCurrent ...
            features.currentRange ...
            features.saturationFraction];


        %% Prediction

        prediction = predict( ...
            finalModel, ...
            X);


        if iscell(prediction)

            prediction = str2double(prediction);

        end


        %% Count detection

        if prediction == 1

            detectedCount = ...
                detectedCount + 1;

        end

    end


    detectionProbability(p) = ...
        detectedCount / numTrialsPerPower;


    fprintf( ...
        'Pj = %.3f W | Detection Probability = %.3f\n', ...
        Pj, ...
        detectionProbability(p));

end


%% =========================================================
% DETECTION PROBABILITY GRAPH
%% =========================================================

figure;

plot( ...
    powerSweep, ...
    detectionProbability, ...
    '-o');

hold on;

yline(0.90,'--');

grid on;

xlabel('Jammer Power (W)');

ylabel('Detection Probability');

title( ...
    'Experiment 23: ML Jammer Detection Probability');

legend( ...
    'ML Detection Probability', ...
    '90% Detection Target');


%% =========================================================
% FIND APPROXIMATE 90% DETECTION POWER
%% =========================================================

idx = ...
    find(detectionProbability >= 0.90,1);


fprintf('\n');


if ~isempty(idx)

    detectionLimit = ...
        powerSweep(idx);


    fprintf( ...
        'Approximate 90%% Detection Power = %.3f W\n', ...
        detectionLimit);

else

    fprintf( ...
        '90%% detection was not reached within\n');

    fprintf( ...
        'the tested jammer power range.\n');

end


%% =========================================================
% FINAL SUMMARY
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 23 COMPLETE\n');
fprintf('============================================\n');


fprintf('\n');

fprintf('Jammer power range:\n');

fprintf( ...
    '%.3f W -> %.3f W\n', ...
    jammerMinPower, ...
    jammerMaxPower);


fprintf('\n');

fprintf('Window-size performance:\n');


for w = 1:length(windowSizes)

    fprintf( ...
        '%2d bits | Accuracy = %6.2f %% | Precision = %.4f | Recall = %.4f | F1 = %.4f\n', ...
        windowSizes(w), ...
        accuracyResults(w)*100, ...
        precisionResults(w), ...
        recallResults(w), ...
        f1Results(w));

end


fprintf('\n');

fprintf('The experiment measures the ability of ML\n');

fprintf('to detect weak jamming under varying FSO\n');

fprintf('channel and receiver conditions.\n');


fprintf('\n');

fprintf('Next step:\n');

fprintf('Integrate ML jammer state detection with\n');

fprintf('ML jammer power estimation and mitigation.\n');