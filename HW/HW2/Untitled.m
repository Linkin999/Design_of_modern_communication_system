clear;
NoisePower = 1;

%generate an L-STF time-domain waveform
cfgHT = wlanHTConfig('ChannelBandwidth', 'CBW20');
STF = wlanLSTF(cfgHT);

%generate noise and add STF to the interval[501£¬660] in noise
s = sqrt(NoisePower/2) * (randn(1,1000) + 1j * randn(1,1000));
s(501:660) = s(501:660) + STF.';

%single channel
channel_single=1;

%multi channel
channel_multi=[1 0 0 0 0.8 0 0 0 0 0.6 0 0 0 0 0.4 0 0 0 0 0.2 0];

%receive signal
rx_single=conv(s, channel_single);
rx_signal = conv(s, channel_multi);



% Define the number of times to average the results
numAverages = 100;

% Initialize a vector to store the results of each iteration1
rho_single_signal=zeros(1, 800);
rho_signal = zeros(1, 800);

% Loop through each iteration and calculate the result
for j = 1:numAverages
    rho_single=zeros(1,800);
    rho = zeros(1, 800);
    for i = 1:length(rho)
        rho_single(i)=rx_single(i:i+79) * rx_single(i+80:i+159)' / 80;
        rho(i) = rx_signal(i:i+79) * rx_signal(i+80:i+159)' / 80;
    end
    rho_single_signal=rho_single_signal+rho_single;
    rho_signal = rho_signal + rho;
end

% Calculate the average of the results
rho_single=rho_single_signal/numAverages;
rho = rho_signal / numAverages;

figure
plot(abs(rho_single));
title('Sun & Zhang: Ac (Single with N)')
grid;
figure
plot(abs(rho_single));
title('Sun & Zhang: Ac (Single with N) ')
xlim([490,520])
grid;
figure
plot(abs(rho));
title('Sun & Zhang: Ac (Multi with N) ')
grid;
figure
plot(abs(rho));
title('Sun & Zhang: Ac (Multi with N) ')
xlim([490,520])
grid;