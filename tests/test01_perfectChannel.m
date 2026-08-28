clc;
clear;
close all;

%% =========================================================
% TEST 01 - PERFECT / IDEAL CHANNEL
%
% Purpose:
% Verify that the FSO simulation produces BER ≈ 0
% when channel impairments and receiver noise are removed.
%% =========================================================


%% =========================================================
% ADD PROJECT PATHS
%% =========================================================

currentFolder = fileparts(mfilename('fullpath'));

projectFolder = fileparts(currentFolder);

baselineFolder = fullfile(projectFolder, 'baseline_model');

mainModelsFolder = fullfile(baselineFolder, 'MainModels');

addpath(baselineFolder);

addpath(mainModelsFolder);

%% =========================================================
% LOAD DEFAULT PARAMETERS
%% =========================================================

params = defaultParameters();


%% =========================================================
% IDEALIZE THE CHANNEL
%% =========================================================

% Remove pointing error

params.sigmaPoint = 0;


% Remove atmospheric turbulence

params.Cn2 = 0;


% Remove receiver noise

params.sigmaNoise = 0;


% Disable saturation

params.enableSaturation = false;


%% =========================================================
% RUN SIMULATION
%% =========================================================

results = runBaseline(params);


%% =========================================================
% DISPLAY RESULTS
%% =========================================================

fprintf('\n');

fprintf('============================================\n');

fprintf('       TEST 01 - PERFECT CHANNEL\n');

fprintf('============================================\n');

fprintf('\n');

fprintf('Pointing sigma = %.6f m\n', ...
    params.sigmaPoint);

fprintf('Cn^2           = %.2e\n', ...
    params.Cn2);

fprintf('Noise sigma    = %.6f A\n', ...
    params.sigmaNoise);

fprintf('\n');

fprintf('Bit errors     = %d\n', ...
    results.bitErrors);

fprintf('BER            = %.10f\n', ...
    results.BER);