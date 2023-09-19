clear;clc;
cfgHT = wlanHTConfig('ChannelBandwidth','CBW20');
snr = 30;  % SNR=30dB  sigpower=0dB

% Tx signals
STF = wlanLSTF(cfgHT);
LTF = wlanLLTF(cfgHT);

% Rx signals (AWGN channel)
y1 = awgn(STF,snr);
y2 = awgn(LTF,snr);

% Time synchronization (Ac)
RxAc1 = xcorr(y1);
RxAc2 = xcorr(y2);

figure(1);
subplot(2,1,1);
plot(abs(RxAc1));
xlabel('Time');
ylabel('Auto-Correlation of STF');
title('Sun & Zhang: Ac of STF');
subplot(2,1,2);
plot(abs(RxAc2));
xlabel('Time');
ylabel('Auto-Correlation of LTF');
title('Sun & Zhang: Ac of LTF');

figure(2);
plot(abs(RxAc1));
hold on;
plot(abs(RxAc2));
legend('STF', 'LTF');
xlabel('Time Lag');
ylabel('Auto-Correlation');
title('Sun & Zhang: Ac');
