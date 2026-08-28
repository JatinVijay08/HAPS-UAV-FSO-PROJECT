function [H_turb, alphaGG, betaGG, sigmaR2] = ...
    gammaGammaTurbulence(lambda, L, Cn2, N)

%% =========================================================
% Gamma-Gamma Atmospheric Turbulence Model
% ==========================================================

%% Optical wave number

k = 2*pi/lambda;


%% Rytov variance

sigmaR2 = 1.23 * Cn2 * k^(7/6) * L^(11/6);


%% No turbulence condition

if Cn2 == 0

    H_turb = ones(1, N);

    alphaGG = Inf;

    betaGG = Inf;

    return;

end



%% Gamma-Gamma parameters

alphaGG = 1 / ...
    (exp( ...
    (0.49 * sigmaR2) / ...
    (1 + 1.11 * sigmaR2^(6/5))^(7/6) ...
    ) - 1);


betaGG = 1 / ...
    (exp( ...
    (0.51 * sigmaR2) / ...
    (1 + 0.69 * sigmaR2^(6/5))^(5/6) ...
    ) - 1);


%% Generate normalized Gamma variables

X = gamrnd( ...
    alphaGG, ...
    1/alphaGG, ...
    1, N);

Y = gamrnd( ...
    betaGG, ...
    1/betaGG, ...
    1, N);


%% Gamma-Gamma turbulence gain

H_turb = X .* Y;

end