function params = defaultParameters()

%% =========================================================
% DEFAULT HAPS FSO SYSTEM PARAMETERS
%% =========================================================

%% Communication parameters

params.Nbits = 1000;

params.Rb = 1e6;              % Bit rate (bits/s)

params.Pt = 1;                % Transmit optical power (W)


%% Sampling parameters

params.samplesPerBit = 20;


%% Optical parameters

params.lambda = 1550e-9;      % Wavelength (m)

params.theta = 0.01e-3;       % Beam divergence half-angle (rad)


%% Receiver parameters

params.RxDiameter = 0.2;      % Receiver aperture diameter (m)

params.R = 0.8;               % Photodetector responsivity (A/W)


%% HAPS-Ground distance

params.L = 20e3;              % Link distance (m)


%% Atmospheric attenuation

params.alpha = 0.1;           % dB/km


%% Pointing error

params.sigmaPoint = 0.02;     % Pointing displacement std (m)


%% Atmospheric turbulence

params.Cn2 = 1e-16;           % Refractive index structure parameter

%% =========================================================
% RECEIVER PARAMETERS
%% =========================================================

%% Receiver noise

params.sigmaNoise = 0.005;    % Noise standard deviation (A)


params.RxDiameter = 0.2;      % Receiver aperture diameter (m)

params.R = 0.8;               % Photodetector responsivity (A/W)

params.sigmaNoise = 0.005;    % Receiver noise standard deviation (A)

params.enableSaturation = false;


%% Random seed

params.rngSeed = 1;

end