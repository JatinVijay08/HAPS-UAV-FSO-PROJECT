function jammerSignal = jammerModel( ...
    jammerPower, ...
    Nbits, ...
    samplesPerBit, ...
    enableJammer)

%% =========================================================
% JAMMER MODEL
%
% Simple Constant Optical Jammer
%
% When enabled:
%
% P_jammer(t) = Pj
%
% When disabled:
%
% P_jammer(t) = 0
%
%% =========================================================


%% =========================================================
% TOTAL NUMBER OF SAMPLES
%% =========================================================

Nsamples = Nbits * samplesPerBit;


%% =========================================================
% JAMMER OFF
%% =========================================================

if ~enableJammer

    jammerSignal = zeros(1, Nsamples);

    return;

end


%% =========================================================
% CONSTANT OPTICAL JAMMER
%% =========================================================

jammerSignal = jammerPower * ones(1, Nsamples);


end