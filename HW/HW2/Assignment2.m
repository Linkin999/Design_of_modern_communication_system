clear;
clc;
% Tx: transmitted data
cfgHT=wlanHTConfig('ChannelBandwidth','CBW20');
STF=wlanLSTF(cfgHT);
noisepower=1;
s=sqrt(noisepower/2)*(randn(1,1000)+1j*randn(1,1000));
s(501:660)=s(501:660)+STF.';

% Channel
ts = 1e-6;  % sample time of the input signal
fd = 10;  % maximum Doppler shift
singlechan=rayleighchan(ts,fd);
tau = [0 10e-9 20e-9 30e-9 40e-9 50e-9];  % path delays
pdb = [0 -3 -6 -9 -12 -15];  % average path gains
chan = rayleighchan(ts,fd,tau,pdb);  % create channel object

% Rx: received data
rx_dataofsingle=filter(singlechan,s);
rx_data = filter(chan, s);

% Auto-correlation of the transmitted data and the received data
tx_auto_corr = xcorr(s);
rx_auto_corr_single=xcorr(rx_dataofsingle);
rx_auto_corr = xcorr(rx_data);

rho=zeros(1,800);
for i=1:length(rho)
    rho(i)=s(i:i+79)*s(i+80:i+159)'/80;
end
figure 
plot(abs(rho));

rho2=zeros(1,length(rx_auto_corr_single));
for i=1:length(rho2)
    rho2(i)=rx_auto_corr_single(i:i+79)*rx_auto_corr_single(i+80:i+159)'/80;
end
% Plot the auto-correlation results
figure;
subplot(4,1,1);
plot(abs(STF));
subplot(4,1,2);
plot(abs(rx_dataofsingle))
subplot(4,1,3);
plot(abs(tx_auto_corr));
subplot(4,1,4);
plot(abs(rho2));

figure;
subplot(2,1,1)
plot(abs(tx_auto_corr));
subplot(2,1,2)
plot(abs(rx_auto_corr));
%legend('Transmitted Data', 'Received Data');
xlabel('Time Lag');
ylabel('Auto-Correlation');
title('Sun & Zhang: Ac');
