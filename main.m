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

%% Receiver parameters
R = 0.8;                 % Photodetector responsiveness (A/W)

%% Ideal FSO channel
% rxOpticalSignal = txSignal; % power transmitted is received by detector directly

%% Geometrical Propagation Gain(Beam Intensity Spreading)
L = 10e3;              % HAPS-ground distance (m) 
theta = 1e-3;          % Beam divergence parameter (rad)
w0 = 0.05;             % Initial beam radius (m)

RxDiameter = 0.2;      % Receiver aperture diameter (m)
RxRadius = RxDiameter / 2;

% Beam radius at receiver
wRx = w0 + L * theta;

% Geometrical channel gain
H_geo = (RxRadius / wRx)^2; %(receiver's aperture area/Sender's propagation area)

% Received optical signal
rxOpticalSignal = H_geo * txSignal;

%% Photodetector
rxCurrent = R * rxOpticalSignal; % photodetector converting light to electrical signal

%% Sample once per bit(sample in the middle part and away from edge for better detection)
% 10th bit,30th bit,50th bit for samples
sampleIndices = samplesPerBit/2 : samplesPerBit : length(rxCurrent);

rxSamples = rxCurrent(sampleIndices); % access and put the samples in exSamples

%% New Threshold accounting for Geometrical Gain
threshold = R * Pt * H_geo / 2;  % Decision threshold (A)

%% Decision
detectedBits = rxSamples > threshold; % decision threshold detection of incoming signal/bit

%% BER
numErrors = sum(bits ~= detectedBits); % ~= not equal operator , bit by bit check of both sent and detected bits
BER = numErrors / Nbits; % Bit Error Rate

fprintf('Number of bit errors = %d\n', numErrors);
fprintf('BER = %.4f\n', BER);
% Note: We can observe that even if receiver doesn't receiver much of the
% sent Power of the sender , still there is zero  BER cause the threshold
% is changed and made in accordance with geometrical gain and also the
% channel is too ideal with not attenuation,turbulence,pointing error

%% Observing affect of Increasing HAPS Distance from Receiver and seeing the
% Graphical Nature of Received Power affected due to Geometrical Beam
% Spreading
distances = [1 2 5 10 15 20] * 1e3;

receivedPower = zeros(size(distances));

for k = 1:length(distances)

    L = distances(k);

    wRx = w0 + L * theta;

    H_geo = (RxRadius / wRx)^2;

    receivedPower(k) = Pt * H_geo;

end

figure;
plot(distances/1e3, receivedPower, 'o-', 'LineWidth', 1.5);
xlabel('HAPS-Ground Distance (km)');
ylabel('Received Optical Power (W)');
title('Geometrical Loss: Received Power vs Distance');
grid on;