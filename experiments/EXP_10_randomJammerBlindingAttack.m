clc;
clear;
close all;

%% =========================================================
% EXPERIMENT 10
% RANDOM JAMMER BLINDING ATTACK
%% =========================================================

fprintf('\n');
fprintf('============================================\n');
fprintf(' EXPERIMENT 10 - RANDOM JAMMER BLINDING ATTACK\n');
fprintf('============================================\n\n');


%% =========================================================
% PATH SETUP
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);

addpath(fullfile(projectFolder, 'baseline_model'));


%% =========================================================
% BASELINE PARAMETERS
%% =========================================================

params = defaultParameters();

params.Nbits = 10000;


%% =========================================================
% RANDOM JAMMER ATTACK PARAMETERS
%% =========================================================

params.enableJammer = true;

params.jammerPower = 0.4;

activitySweep = 0:0.1:1;


%% =========================================================
% RESULT STORAGE
%% =========================================================

numPoints = length(activitySweep);

BER = zeros(1, numPoints);

errors10 = zeros(1, numPoints);

errors01 = zeros(1, numPoints);

saturationFraction = zeros(1, numPoints);

actualActivity = zeros(1, numPoints);

averageJammerPower = zeros(1, numPoints);