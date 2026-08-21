function [H_geo, wRx, w0, zR] = geometryModel( ...
    lambda, theta, RxDiameter, L)

%% Receiver aperture

RxRadius = RxDiameter / 2;


%% Beam waist from divergence

w0 = lambda / (pi * theta);


%% Rayleigh range

zR = pi * w0^2 / lambda;


%% Beam radius at receiver

wRx = w0 * sqrt( ...
    1 + (L/zR)^2);


%% Gaussian power captured by circular receiver

H_geo = 1 - exp( ...
    -2 * RxRadius^2 / wRx^2);

end