clc;
clear;
close all;

%% Parameters
Nbits = 20;          % Number of bits being transmitted
Rb = 1e6;            % Bit rate: 1 Mbps (bits per second)
Pt = 1;              % Optical transmit power: 1 W

samplesPerBit = 20;
Fs = Rb * samplesPerBit;

%% Generate random bits
bits = randi([0 1], 1, Nbits); % random bits are generated NBits = 20 in number
%% OOK modulation
ookSymbols = Pt * bits; % 1*power or 0*power

%% Convert symbols into waveform(repetition of bits for imitating the bit duration)
txSignal = repelem(ookSymbols, samplesPerBit);

%% Time axis
t = (0:length(txSignal)-1) / Fs;

%% Plot
figure;
plot(t*1e6, txSignal, 'LineWidth', 1.5);
xlabel('Time (\mus)');
ylabel('Optical Power (W)');
title('HAPS Transmitted OOK Optical Signal');
grid on;
ylim([-0.1 1.1]);