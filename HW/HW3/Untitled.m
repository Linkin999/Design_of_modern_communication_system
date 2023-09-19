clear;clc;
cfgHT=wlanHTConfig('ChannelBandwidth','CBW20');
snr = 30; % SNR=30dB  sigpower=0dB

% Tx signals
STF = wlanLSTF(cfgHT);
LTF = wlanLLTF(cfgHT);

% Rx signals (AWGN channel)
x_STF=randn(1000,1)+1i*randn(1000,1);
x_STF(501:660)=x_STF(501:660)+STF;

x_LTF=randn(1000,1)+1i*randn(1000,1);
x_LTF(501:660)=x_LTF(501:660)+LTF;

% Time synchronization (cc)
z_STF=conj(STF(160:-1:1));
cc_STF=conv(x_STF,z_STF);
z_LTF=conj(LTF(160:-1:1));
cc_LTF=conv(x_LTF,z_LTF);

% Time synchronization (ac)
s_STF=sqrt(1/2)*(randn(1,1000)+1i*randn(1,1000));
s_STF(501:660)=s_STF(501:660)+STF';
s_LTF=sqrt(1/2)*(randn(1,1000)+1i*randn(1,1000));
s_LTF(501:660)=s_LTF(501:660)+LTF';


RxAc1=zeros(1,800);
RxAc2=zeros(1,800);
length(RxAc1)
for i=1:length(RxAc1)
    RxAc1(i)=s_STF(i:i+79)*s_STF(i+80:i+159)'/80;
    RxAc2(i)=s_LTF(i:i+79)*s_LTF(i+80:i+159)'/80;
end

figure(1)
subplot(2,1,1);
plot(abs(cc_STF));
xlabel('Time');
ylabel('cross-Correlation of STF');
title('Sun & Zhang: cc of STF');
subplot(2,1,2);
plot(abs(cc_LTF));
xlabel('Time');
ylabel('cross-Correlation of LTF');
title('Sun & Zhang: cc of LTF');

figure(2)
plot(abs(cc_STF));
hold on
plot(abs(cc_LTF));
legend('STF','LTF')
xlabel('Time');
ylabel('cross-Correlation ');
title('Sun & Zhang: cc ');

figure(3)
subplot(2,1,1);
plot(abs(RxAc1));
xlabel('Time');
ylabel('Auto-Correlation of STF');
title('Sun & Zhang: ac of STF');
subplot(2,1,2);
plot(abs(RxAc2));
xlabel('Time');
ylabel('Auto-Correlation of LTF');
title('Sun & Zhang: ac of LTF');

figure(4)
plot(abs(RxAc1));
hold on
plot(abs(RxAc2));
legend('STF','LTF')
xlabel('Time');
ylabel('Auto-Correlation ');
title('Sun & Zhang: AC ');
