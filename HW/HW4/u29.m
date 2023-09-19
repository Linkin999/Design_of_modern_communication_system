%% NCellID=0 (u=29)
clear;
clc;
%% Generate PSS
% N_rb=6
enb0 = struct();
enb0.NCellID = 1;
enb0.NSubframe = 0;
enb0.NDLRB = 6;
enb0.DuplexMode = 'FDD';
pss0 = ltePSS(enb0);
tx_sig0 = zeros(1,1000);
tx_sig0(501:501+length(pss0)-1) = tx_sig0(501:501+length(pss0)-1)+pss0';

% N_rb=25
enb1 = struct();
enb1.NCellID = 1;
enb1.NSubframe = 0;
enb1.NDLRB = 25;
enb1.DuplexMode = 'FDD';
pss1 = ltePSS(enb1);
tx_sig1 = zeros(1,1000);
tx_sig1(501:501+length(pss1)-1) = tx_sig1(501:501+length(pss1)-1)+pss1';

% N_rb=100
enb2 = struct();
enb2.NCellID = 1;
enb2.NSubframe = 0;
enb2.NDLRB = 100;
enb2.DuplexMode = 'FDD';
pss2 = ltePSS(enb2);
tx_sig2 = zeros(1,1000);
tx_sig2(501:501+length(pss2)-1) = tx_sig2(501:501+length(pss2)-1)+pss2';

%% Add AWGN
NoisePower = 1;
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
cc0 = xcorr(tx_sig0,rx_sig0);
cc1 = xcorr(tx_sig1,rx_sig1);
cc2 = xcorr(tx_sig2,rx_sig2);
figure(1);
subplot(3,1,1);plot(abs(cc0));
ylabel('Cross correlation');
title('u=25, N_{rb}=6');
subplot(3,1,2);plot(abs(cc1));
ylabel('Cross correlation');
title('u=25, N_{rb}=25');
subplot(3,1,3);plot(abs(cc2));
ylabel('Cross correlation');
title('u=25, N_{rb}=100');

%% Information
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
