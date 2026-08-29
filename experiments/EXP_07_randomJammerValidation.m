clc;
clear;
close all;

%% =========================================================
% EXPERIMENT 07
% RANDOM JAMMER VALIDATION
%% =========================================================


%% =========================================================
% ADD REQUIRED PATH
%% =========================================================

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile( ...
    projectRoot, ...
    'baseline with jammer'));


%% =========================================================
% RANDOM SEED
%
% Makes this experiment reproducible
%% =========================================================

rng(42);


%% =========================================================
% PARAMETERS
%% =========================================================

Nbits = 50;

samplesPerBit = 20;

jammerPower = 0.10;

enableJammer = true;

activityProbability = 0.30;


%% =========================================================
% GENERATE RANDOM JAMMER
%% =========================================================

[jammerSignal, jammerBits] = ...
    randomJammerModel( ...
        jammerPower, ...
        Nbits, ...
        samplesPerBit, ...
        enableJammer, ...
        activityProbability);


%% =========================================================
% CALCULATE ACTUAL ACTIVITY
%% =========================================================

actualActivity = mean(jammerBits);


%% =========================================================
% PRINT RESULTS
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 07 - RANDOM JAMMER VALIDATION\n');
fprintf('============================================\n\n');

fprintf('Number of bits = %d\n', Nbits);

fprintf('Jammer power = %.4f W\n', jammerPower);

fprintf('Requested activity probability = %.2f\n', ...
    activityProbability);

fprintf('Actual jammer activity = %.2f\n\n', ...
    actualActivity);


%% =========================================================
% DISPLAY BIT-LEVEL JAMMER STATES
%% =========================================================

disp('Jammer state per bit:');

disp(jammerBits);


%% =========================================================
% FIGURE 1
%
% JAMMER ACTIVITY PER BIT
%% =========================================================

figure;

stairs( ...
    1:Nbits, ...
    jammerBits, ...
    'LineWidth', 2);

ylim([-0.1 1.1]);

xlabel('Bit Index');

ylabel('Jammer State');

title('Random Jammer Activity per Bit');

grid on;


%% =========================================================
% FIGURE 2
%
% FULL JAMMER WAVEFORM
%% =========================================================

figure;

plot(jammerSignal, 'LineWidth', 1.5);

xlabel('Sample Index');

ylabel('Jammer Optical Power (W)');

title('Random Intermittent Jammer Signal');

grid on;