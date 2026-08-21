function [bits, txSignal, t] = generateOOK( ...
    Nbits, Pt, Rb, samplesPerBit)

%% Generate random bits

bits = randi([0 1], 1, Nbits);


%% OOK modulation

ookSymbols = Pt * bits;


%% Convert symbols to waveform

txSignal = repelem( ...
    ookSymbols, ...
    samplesPerBit);


%% Sampling frequency

Fs = Rb * samplesPerBit;


%% Time axis

t = (0:length(txSignal)-1) / Fs;

end