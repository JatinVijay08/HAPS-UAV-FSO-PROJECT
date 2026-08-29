%% =========================================================
% EXPERIMENT 11
%
% FAIR COMPARISON:
% CONSTANT JAMMER vs RANDOM JAMMER
%
% Same Average Jammer Power Budget
%% =========================================================

clear;
clc;
close all;


%% =========================================================
% PATH SETUP
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);


%% =========================================================
% BASELINE MODEL
%% =========================================================

addpath(fullfile( ...
    projectFolder, ...
    'baseline_model'));


%% =========================================================
% MAIN MODELS
%% =========================================================

addpath(fullfile( ...
    projectFolder, ...
    'baseline_model', ...
    'MainModels'));


%% =========================================================
% JAMMER MODELS
%% =========================================================

addpath(fullfile( ...
    projectFolder, ...
    'baseline with jammer'));


%% =========================================================
% EXPERIMENT HEADER
%% =========================================================

fprintf('\n');

fprintf('============================================\n');

fprintf(' EXPERIMENT 11 - FAIR JAMMER COMPARISON\n');

fprintf(' CONSTANT vs RANDOM JAMMER\n');

fprintf(' SAME AVERAGE POWER BUDGET\n');

fprintf('============================================\n\n');

%% =========================================================
% LOAD DEFAULT SYSTEM PARAMETERS
%% =========================================================

params = defaultParameters();


%% =========================================================
% FIX RANDOM SEED
%
% Same legitimate channel realization for comparison
%% =========================================================

params.rngSeed = 1;


%% =========================================================
% ENABLE RECEIVER SATURATION
%
% Required for blinding attack analysis
%% =========================================================

params.enableSaturation = true;


%% =========================================================
% EXPERIMENT PARAMETERS
%% =========================================================

% Random jammer peak power

P_ON = 0.4;      % W


% Average jammer power budgets

PavgSweep = [ ...
    0.00 ...
    0.05 ...
    0.10 ...
    0.15 ...
    0.20 ...
    0.25 ...
    0.30 ...
    0.35 ...
    0.40 ];


numPoints = length(PavgSweep);


%% =========================================================
% PREALLOCATE RESULTS
%% =========================================================

BER_constant = zeros(1, numPoints);

BER_random = zeros(1, numPoints);


errors10_constant = zeros(1, numPoints);

errors01_constant = zeros(1, numPoints);


errors10_random = zeros(1, numPoints);

errors01_random = zeros(1, numPoints);


saturation_constant = zeros(1, numPoints);

saturation_random = zeros(1, numPoints);


actualActivity_random = zeros(1, numPoints);

actualRandomAveragePower = zeros(1, numPoints);
%% =========================================================
% FAIR CONSTANT vs RANDOM JAMMER COMPARISON
%% =========================================================

for k = 1:numPoints


    %% =====================================================
    % CURRENT AVERAGE POWER BUDGET
    %% =====================================================

    Pavg = PavgSweep(k);


    %% =====================================================
    % RANDOM JAMMER ACTIVITY
    %
    % Pavg = P_ON × activityProbability
    %% =====================================================

    activityProbability = Pavg / P_ON;


    %% =====================================================
    % RUN CLEAN BASELINE
    %
    % Same legitimate channel realization
    %% =====================================================

    results = runBaseline(params);


    %% =====================================================
    % CONSTANT JAMMER
    %
    % Constant jammer power = average power budget
    %% =====================================================

    constantJammerSignal = jammerModel( ...
        Pavg, ...
        params.Nbits, ...
        params.samplesPerBit, ...
        true);


    %% =====================================================
    % APPLY CONSTANT ATTACK
    %% =====================================================

    constantAttackedSignal = ...
        results.rxOpticalSignal + ...
        constantJammerSignal;


    %% =====================================================
    % CONSTANT JAMMER RECEIVER
    %
    % Use SAME receiver noise realization
    %% =====================================================

    [detectedBits_constant, ...
        BER_constant(k), ...
        rxCurrent_constant, ...
        rxSamples_constant, ...
        threshold_constant] = receiverModel( ...
        constantAttackedSignal, ...
        results.bits, ...
        params.Pt, ...
        results.H_total, ...
        params.R, ...
        params.samplesPerBit, ...
        results.receiverNoise, ...
        params.enableSaturation);


    %% =====================================================
    % CONSTANT JAMMER ERROR ANALYSIS
    %% =====================================================

    errors10_constant(k) = sum( ...
        (results.bits == 1) & ...
        (detectedBits_constant == 0));

    errors01_constant(k) = sum( ...
        (results.bits == 0) & ...
        (detectedBits_constant == 1));


    %% =====================================================
    % CONSTANT JAMMER SATURATION FRACTION
    %% =====================================================

    I_sat = 0.25;

    saturation_constant(k) = ...
        mean(rxCurrent_constant >= I_sat);


    %% =====================================================
    % RANDOM JAMMER
    %
    % Peak power = P_ON
    %
    % Activity chosen to produce same average power budget
    %% =====================================================

    [randomJammerSignal, jammerBits] = ...
        randomJammerModel( ...
        P_ON, ...
        params.Nbits, ...
        params.samplesPerBit, ...
        true, ...
        activityProbability);


    %% =====================================================
    % ACTUAL RANDOM JAMMER ACTIVITY
    %% =====================================================

    actualActivity_random(k) = mean(jammerBits);

    actualRandomAveragePower(k) = ...
        P_ON * actualActivity_random(k);

    %% =====================================================
    % APPLY RANDOM ATTACK
    %% =====================================================

    randomAttackedSignal = ...
        results.rxOpticalSignal + ...
        randomJammerSignal;


    %% =====================================================
    % RANDOM JAMMER RECEIVER
    %
    % SAME legitimate signal
    % SAME receiver noise
    %% =====================================================

    [detectedBits_random, ...
        BER_random(k), ...
        rxCurrent_random, ...
        rxSamples_random, ...
        threshold_random] = receiverModel( ...
        randomAttackedSignal, ...
        results.bits, ...
        params.Pt, ...
        results.H_total, ...
        params.R, ...
        params.samplesPerBit, ...
        results.receiverNoise, ...
        params.enableSaturation);


    %% =====================================================
    % RANDOM JAMMER ERROR ANALYSIS
    %% =====================================================

    errors10_random(k) = sum( ...
        (results.bits == 1) & ...
        (detectedBits_random == 0));

    errors01_random(k) = sum( ...
        (results.bits == 0) & ...
        (detectedBits_random == 1));


    %% =====================================================
    % RANDOM JAMMER SATURATION FRACTION
    %% =====================================================

    saturation_random(k) = ...
        mean(rxCurrent_random >= I_sat);


    %% =====================================================
    % DISPLAY RESULTS
    %% =====================================================
    fprintf( ...
        '\nPavg Requested = %.2f W\n', ...
        Pavg);


    fprintf( ...
        'Random Activity = %.3f | Actual Pavg = %.4f W\n', ...
        actualActivity_random(k), ...
        actualRandomAveragePower(k));


    fprintf( ...
        'Constant: BER = %.6f | Sat = %.3f\n', ...
        BER_constant(k), ...
        saturation_constant(k));


    fprintf( ...
        'Random:   BER = %.6f | Sat = %.3f\n', ...
        BER_random(k), ...
        saturation_random(k));

end

%% =========================================================
% PLOT 1
% BER COMPARISON
%% =========================================================

figure;

plot(PavgSweep, BER_constant, ...
    '-o', ...
    'LineWidth', 2);

hold on;

plot(PavgSweep, BER_random, ...
    '-s', ...
    'LineWidth', 2);

grid on;

xlabel('Average Jammer Power Budget (W)');

ylabel('Bit Error Rate (BER)');

title('Constant vs Random Jammer: BER Comparison');

legend( ...
    'Constant Jammer', ...
    'Random Jammer', ...
    'Location', 'best');

%% =========================================================
% PLOT 2
% RECEIVER SATURATION COMPARISON
%% =========================================================

figure;

plot(PavgSweep, saturation_constant, ...
    '-o', ...
    'LineWidth', 2);

hold on;

plot(PavgSweep, saturation_random, ...
    '-s', ...
    'LineWidth', 2);

grid on;

xlabel('Average Jammer Power Budget (W)');

ylabel('Saturation Fraction');

title('Constant vs Random Jammer: Receiver Saturation');

legend( ...
    'Constant Jammer', ...
    'Random Jammer', ...
    'Location', 'best');

%% =========================================================
% PLOT 3
% ERROR MECHANISM COMPARISON
%% =========================================================

figure;

plot(PavgSweep, errors10_constant, ...
    '-o', ...
    'LineWidth', 2);

hold on;

plot(PavgSweep, errors01_constant, ...
    '-o', ...
    'LineWidth', 2);

plot(PavgSweep, errors10_random, ...
    '--s', ...
    'LineWidth', 2);

plot(PavgSweep, errors01_random, ...
    '--s', ...
    'LineWidth', 2);

grid on;

xlabel('Average Jammer Power Budget (W)');

ylabel('Number of Errors');

title('Error Mechanisms: Constant vs Random Jamming');

legend( ...
    'Constant: 1→0', ...
    'Constant: 0→1', ...
    'Random: 1→0', ...
    'Random: 0→1', ...
    'Location', 'best');
