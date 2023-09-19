%% NCellID=0 (u=25)
clear;
clc;
%% Generate PSS
% N_rb=6
enb0 = struct();
enb0.NCellID = 0;
enb0.NSubframe = 0;
enb0.NDLRB = 6;
enb0.DuplexMode = 'FDD';
pss0 = ltePSS(enb0);
tx_sig0 = zeros(1,1000);
tx_sig0(501:501+length(pss0)-1) = tx_sig0(501:501+length(pss0)-1)+pss0';

% N_rb=25
enb1 = struct();
enb1.NCellID = 0;
enb1.NSubframe = 0;
enb1.NDLRB = 25;
enb1.DuplexMode = 'FDD';
pss1 = ltePSS(enb1);
tx_sig1 = zeros(1,1000);
tx_sig1(501:501+length(pss1)-1) = tx_sig1(501:501+length(pss1)-1)+pss1';

% N_rb=100
enb2 = struct();
enb2.NCellID = 0;
enb2.NSubframe = 0;
enb2.NDLRB = 100;
enb2.DuplexMode = 'FDD';
pss2 = ltePSS(enb2);
tx_sig2 = zeros(1,1000);
tx_sig2(501:501+length(pss2)-1) = tx_sig2(501:501+length(pss2)-1)+pss2';

%% Add AWGN
NoisePower = 0.05;
% N_rb=6
rx_sig0 = sqrt(NoisePower/2)*(randn(1,1000)+1j*randn(1,1000));
rx_sig0(501:501+length(pss0)-1) = rx_sig0(501:501+length(pss0)-1)+pss0';

% N_rb=25
rx_sig1 = sqrt(NoisePower/2)*(randn(1,1000)+1j*randn(1,1000));
rx_sig1(501:501+length(pss1)-1) = rx_sig1(501:501+length(pss1)-1)+pss1';

% N_rb=100
rx_sig2 = sqrt(NoisePower/2)*(randn(1,1000)+1j*randn(1,1000));
rx_sig2(501:501+length(pss2)-1) = rx_sig2(501:501+length(pss2)-1)+pss2';

%% Cross-Correlation
crx_sig0 = conj(rx_sig0);
crx_sig1 = conj(rx_sig1);
crx_sig2 = conj(rx_sig2);
cc0 = conv(tx_sig0,crx_sig0);
cc1 = conv(tx_sig1,crx_sig1);
cc2 = conv(tx_sig2,crx_sig2);
figure(1);
% N_rb=6
subplot(3,1,1);plot(abs(cc0));
ylabel('Cross correlation');
title('u=25, N_{rb}=6');
% N_rb=25
subplot(3,1,2);plot(abs(cc1));
ylabel('Cross correlation');
title('u=25, N_{rb}=25');
% N_rb=100
subplot(3,1,3);plot(abs(cc2));
ylabel('Cross correlation');
title('u=25, N_{rb}=100');

%% Comparison between tx_sig & rx_sig
% N_rb=6
figure(2);
subplot(3,1,1);plot(abs(tx_sig0));
hold on;
plot(abs(rx_sig0));
title('Comparison between tx\_sig & rx\_sig (u=25, N_{rb}=6)');
% N_rb=25
subplot(3,1,2);plot(abs(tx_sig1));
hold on;
plot(abs(rx_sig1));
title('Comparison between tx\_sig & rx\_sig (u=25, N_{rb}=25)');
% N_rb=100
subplot(3,1,3);plot(abs(tx_sig2));
hold on;
plot(abs(rx_sig2));
title('Comparison between tx\_sig & rx\_sig (u=25, N_{rb}=100)');

%% Information display
for i = 0:2
    switch i
        case 0
            enb = enb0;
        case 1
            enb = enb1;
        otherwise
            enb = enb2;
    end
    disp(strcat('enb',num2str(i),' info'));
    disp(strcat('SamplingRate: ',num2str(lteOFDMInfo(enb).SamplingRate)));
    disp(strcat('Nfft: ',num2str(lteOFDMInfo(enb).Nfft)));
    disp(strcat('CyclicPrefixLengths: ','[',num2str(lteOFDMInfo(enb).CyclicPrefixLengths),']'));
    disp(' ');
end
