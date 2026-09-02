clear;
clc;
close all;

%% =========================================================
% EXPERIMENT 13
% ML DATASET GENERATION
%
% Generate labelled receiver-feature data for:
%
%   0 -> Normal Communication
%   1 -> Constant Jammer
%   2 -> Random Jammer
%
%% =========================================================


%% =========================================================
% PATH SETTINGS
%% =========================================================

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(genpath(projectRoot));


%% =========================================================
% DATASET CONFIGURATION
%% =========================================================

samplesPerClass = 200;

totalSamples = 3 * samplesPerClass;


%% =========================================================
% COMMON SIMULATION PARAMETERS
%% =========================================================

params = defaultParameters();

% Number of transmitted bits per simulation realization

params.Nbits = 5000;


% Receiver saturation current

I_sat = 0.25;


%% =========================================================
% PREALLOCATE FEATURE MATRIX
%
% Features:
%
% 1 -> Mean Current
% 2 -> Std Current
% 3 -> Min Current
% 4 -> Max Current
% 5 -> Current Range
% 6 -> Saturation Fraction
%
%% =========================================================

numFeatures = 6;

X = zeros(totalSamples, numFeatures);


%% =========================================================
% PREALLOCATE LABELS
%% =========================================================

Y = strings(totalSamples, 1);


%% =========================================================
% PREALLOCATE JAMMER METADATA
%% =========================================================

jammerPower = zeros(totalSamples, 1);

jammerPeakPower = zeros(totalSamples, 1);

activityProbability = zeros(totalSamples, 1);

actualActivity = zeros(totalSamples, 1);

actualAveragePower = zeros(totalSamples, 1);


%% =========================================================
% DATASET ROW COUNTER
%% =========================================================

row = 1;


%% =========================================================
% RANDOM SEED BASE
%% =========================================================

baseSeed = 1000;


%% =========================================================
% NORMAL COMMUNICATION DATA
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' GENERATING NORMAL DATA\n');
fprintf('============================================\n');


for k = 1:samplesPerClass

    %% ---------------------------------------------
    % UNIQUE RANDOM SEED
    %% ---------------------------------------------

    params.rngSeed = baseSeed + row;


    %% ---------------------------------------------
    % NO JAMMER
    %% ---------------------------------------------

    params.enableJammer = false;


    %% ---------------------------------------------
    % RUN BASELINE SIMULATION
    %% ---------------------------------------------

    results = runBaseline(params);


    %% ---------------------------------------------
    % EXTRACT FEATURES
    %% ---------------------------------------------

    features = extractFeatures( ...
        results.rxCurrent, ...
        I_sat);


    %% ---------------------------------------------
    % STORE FEATURE VECTOR
    %% ---------------------------------------------

    X(row, :) = [ ...

        features.meanCurrent, ...
        features.stdCurrent, ...
        features.minCurrent, ...
        features.maxCurrent, ...
        features.currentRange, ...
        features.saturationFraction];


    %% ---------------------------------------------
    % STORE LABEL
    %% ---------------------------------------------

    Y(row) = "Normal";


    %% ---------------------------------------------
    % DISPLAY PROGRESS
    %% ---------------------------------------------

    if mod(k, 25) == 0

        fprintf( ...
            'Normal: %d / %d complete\n', ...
            k, samplesPerClass);

    end


    row = row + 1;

end


%% =========================================================
% CONSTANT JAMMER DATA
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' GENERATING CONSTANT JAMMER DATA\n');
fprintf('============================================\n');


for k = 1:samplesPerClass

    %% ---------------------------------------------
    % UNIQUE RANDOM SEED
    %% ---------------------------------------------

    params.rngSeed = baseSeed + row;


    %% ---------------------------------------------
    % BASELINE WITHOUT INTERNAL JAMMER
    %% ---------------------------------------------

    params.enableJammer = false;


    %% ---------------------------------------------
    % RUN BASELINE
    %% ---------------------------------------------

    resultsBase = runBaseline(params);


    %% ---------------------------------------------
    % RANDOM CONSTANT JAMMER POWER
    %
    % Range:
    %
    % 0.02 W to 0.40 W
    %% ---------------------------------------------

    Pj = 0.02 + ...
        (0.40 - 0.02) * rand;


    %% ---------------------------------------------
    % GENERATE CONSTANT JAMMER
    %% ---------------------------------------------

    jammerSignal = jammerModel( ...
        Pj, ...
        params.Nbits, ...
        params.samplesPerBit, ...
        true);


    %% ---------------------------------------------
    % ADD JAMMER TO RECEIVED OPTICAL SIGNAL
    %% ---------------------------------------------

    rxOpticalJammed = ...
        resultsBase.rxOpticalSignal + ...
        jammerSignal;


    %% ---------------------------------------------
    % RE-RUN RECEIVER
    %% ---------------------------------------------

    [~, ~, rxCurrent, ~, ~] = receiverModel( ...
        rxOpticalJammed, ...
        resultsBase.bits, ...
        params.Pt, ...
        resultsBase.H_total, ...
        params.R, ...
        params.samplesPerBit, ...
        resultsBase.receiverNoise, ...
        params.enableSaturation);


    %% ---------------------------------------------
    % EXTRACT FEATURES
    %% ---------------------------------------------

    features = extractFeatures( ...
        rxCurrent, ...
        I_sat);


    %% ---------------------------------------------
    % STORE FEATURES
    %% ---------------------------------------------

    X(row, :) = [ ...

        features.meanCurrent, ...
        features.stdCurrent, ...
        features.minCurrent, ...
        features.maxCurrent, ...
        features.currentRange, ...
        features.saturationFraction];


    %% ---------------------------------------------
    % STORE LABEL
    %% ---------------------------------------------

    Y(row) = "Constant";


    %% ---------------------------------------------
    % STORE METADATA
    %% ---------------------------------------------

    jammerPower(row) = Pj;

    actualAveragePower(row) = Pj;


    %% ---------------------------------------------
    % DISPLAY PROGRESS
    %% ---------------------------------------------

    if mod(k, 25) == 0

        fprintf( ...
            'Constant: %d / %d complete\n', ...
            k, samplesPerClass);

    end


    row = row + 1;

end


%% =========================================================
% RANDOM JAMMER DATA
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' GENERATING RANDOM JAMMER DATA\n');
fprintf('============================================\n');


for k = 1:samplesPerClass

    %% ---------------------------------------------
    % UNIQUE RANDOM SEED
    %% ---------------------------------------------

    params.rngSeed = baseSeed + row;


    %% ---------------------------------------------
    % BASELINE WITHOUT JAMMER
    %% ---------------------------------------------

    params.enableJammer = false;


    %% ---------------------------------------------
    % RUN BASELINE
    %% ---------------------------------------------

    resultsBase = runBaseline(params);


    %% ---------------------------------------------
    % RANDOM PEAK JAMMER POWER
    %
    % Range:
    %
    % 0.05 W to 0.40 W
    %% ---------------------------------------------

    Ppeak = 0.05 + ...
        (0.40 - 0.05) * rand;


    %% ---------------------------------------------
    % RANDOM ACTIVITY PROBABILITY
    %
    % Range:
    %
    % 0.10 to 1.00
    %% ---------------------------------------------

    activity = 0.10 + ...
        (1.00 - 0.10) * rand;


    %% ---------------------------------------------
    % GENERATE RANDOM JAMMER
    %% ---------------------------------------------

    [jammerSignal, jammerBits] = ...
        randomJammerModel( ...
            Ppeak, ...
            params.Nbits, ...
            params.samplesPerBit, ...
            true, ...
            activity);


    %% ---------------------------------------------
    % ADD JAMMER
    %% ---------------------------------------------

    rxOpticalJammed = ...
        resultsBase.rxOpticalSignal + ...
        jammerSignal;


    %% ---------------------------------------------
    % RE-RUN RECEIVER
    %% ---------------------------------------------

    [~, ~, rxCurrent, ~, ~] = receiverModel( ...
        rxOpticalJammed, ...
        resultsBase.bits, ...
        params.Pt, ...
        resultsBase.H_total, ...
        params.R, ...
        params.samplesPerBit, ...
        resultsBase.receiverNoise, ...
        params.enableSaturation);


    %% ---------------------------------------------
    % EXTRACT FEATURES
    %% ---------------------------------------------

    features = extractFeatures( ...
        rxCurrent, ...
        I_sat);


    %% ---------------------------------------------
    % STORE FEATURES
    %% ---------------------------------------------

    X(row, :) = [ ...

        features.meanCurrent, ...
        features.stdCurrent, ...
        features.minCurrent, ...
        features.maxCurrent, ...
        features.currentRange, ...
        features.saturationFraction];


    %% ---------------------------------------------
    % STORE LABEL
    %% ---------------------------------------------

    Y(row) = "Random";


    %% ---------------------------------------------
    % STORE METADATA
    %% ---------------------------------------------

    jammerPeakPower(row) = Ppeak;

    activityProbability(row) = activity;

    actualActivity(row) = ...
        mean(jammerBits);


    actualAveragePower(row) = ...
        mean(jammerSignal);


    %% ---------------------------------------------
    % DISPLAY PROGRESS
    %% ---------------------------------------------

    if mod(k, 25) == 0

        fprintf( ...
            'Random: %d / %d complete\n', ...
            k, samplesPerClass);

    end


    row = row + 1;

end


%% =========================================================
% CREATE DATA TABLE
%% =========================================================

dataset = table( ...
    X(:,1), ...
    X(:,2), ...
    X(:,3), ...
    X(:,4), ...
    X(:,5), ...
    X(:,6), ...
    categorical(Y), ...
    jammerPower, ...
    jammerPeakPower, ...
    activityProbability, ...
    actualActivity, ...
    actualAveragePower, ...
    'VariableNames', { ...
    'MeanCurrent', ...
    'StdCurrent', ...
    'MinCurrent', ...
    'MaxCurrent', ...
    'CurrentRange', ...
    'SaturationFraction', ...
    'Label', ...
    'ConstantJammerPower', ...
    'RandomPeakPower', ...
    'ActivityProbability', ...
    'ActualActivity', ...
    'ActualAveragePower'});


%% =========================================================
% SAVE DATASET
%% =========================================================

save( ...
    'exp13_ml_dataset.mat', ...
    'dataset');


%% =========================================================
% DISPLAY SUMMARY
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' DATASET GENERATION COMPLETE\n');
fprintf('============================================\n\n');


fprintf( ...
    'Total Samples = %d\n\n', ...
    height(dataset));


disp(groupcounts(dataset.Label));


%% =========================================================
% DISPLAY FIRST FEW ROWS
%% =========================================================

disp(dataset(1:10, :));


%% =========================================================
% VISUALIZATION
%
% FEATURE DISTRIBUTION
%% =========================================================

figure;

featureNames = { ...

    'Mean Current', ...
    'Std Current', ...
    'Min Current', ...
    'Max Current', ...
    'Current Range', ...
    'Saturation Fraction'};


for f = 1:numFeatures

    subplot(2,3,f);

    boxchart( ...
        dataset.Label, ...
        X(:,f));

    grid on;

    title(featureNames{f});

    ylabel('Feature Value');

end


sgtitle( ...
    'Experiment 13: Feature Distribution by Class');
%% =========================================================
% SAVE DATASET
%% =========================================================

save('jammerDataset.mat', 'dataset');

fprintf('\nDataset saved successfully as jammerDataset.mat\n');