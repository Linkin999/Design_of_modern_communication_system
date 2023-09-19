%% MIMO Detector for 4×2 STBC
clear;
clc;

%% Initialization
nChan = 1000;
EbNo = -10:2:20; % SNR in dB
H = zeros(4,4);
X = zeros(4,length(nChan));
Y = X;

%% ZF
for i = 1:nChan
	data = randi([0 2],4,1);
    dataMod = qammod(data,4); % QPSK
    while rank(H) < 4
        h = randn(2,4);
        H = [h(1,1),-h(1,2),h(1,3),-h(1,4);
             h(1,1),-h(2,2),h(2,3),-h(2,4);
             h(1,2),h(1,1),h(1,4),h(1,3);
             h(2,2),h(2,1),h(2,4),h(2,3)];
    end
	txData = H * dataMod;
    for j = 1:length(EbNo)
        Noise = randn(4,1);
        rxData = awgn(txData,EbNo(j));
        recData = H\rxData; % H^-1 * rxData
        recData = qamdemod(recData,4);
        [~,berZeroForcing(i,j)] = biterr(data, recData); 
    end
end
berZeroForcing = mean(berZeroForcing);

%% MMSE
for i = 1:nChan
    data = randi([0 3],4,1);
    dataMod = qammod(data,4); % QPSK
    while rank(H) < 4
        h = randn(2,4);
        H = [h(1,1),-h(1,2),h(1,3),-h(1,4);
             h(1,1),-h(2,2),h(2,3),-h(2,4);
             h(1,2),h(1,1),h(1,4),h(1,3);
             h(2,2),h(2,1),h(2,4),h(2,3)];
    end
	txData = H * dataMod;
	for j = 1:length(EbNo)
        Noise = randn(4,1);
        rxData = awgn(txData,EbNo(j));
        Q = (H'*H+eye(4)*10^(-EbNo(j)/10))\H';
        recData = Q * rxData;
        recData = qamdemod(recData,4);
        [~,berMMSE(i,j)] = biterr(data, recData);
	end
end
berMMSE = mean(berMMSE);

%% ML
for i = 1:nChan
    data = randi([0 3],4,1);
    dataMod = qammod(data,4); % QPSK
    while rank(H) < 4
        h = randn(2,4);
        H = [h(1,1),-h(1,2),h(1,3),-h(1,4);
             h(1,1),-h(2,2),h(2,3),-h(2,4);
             h(1,2),h(1,1),h(1,4),h(1,3);
             h(2,2),h(2,1),h(2,4),h(2,3)];
    end
	txData = H*dataMod;
	for j = 1:length(EbNo)
        Noise = randn(4,1);
        rxData = txData + Noise * 10^(-EbNo(j)/10);
    end
    X(:,i) = txData;
	Y(:,i) = rxData;
end
berML = mean(berML);

%% MIMO BER Curves
figure(1);
semilogy(EbNo, berZeroForcing ,'-v', ...
         EbNo, berMMSE,'-s','LineWidth',1);
grid on;
xlim([EbNo(1)-2 EbNo(end)+2]);
title(sprintf('%d Tx x %d Rx MIMO: BER Curves by Equalizer', 4, 2));
set(gca,'FontWeight','bold','LineWidth',1);
xlabel('EbNo(dB)');
ylabel('Bit Error Rate (Avg)');
legend('Zero Forcing','MMSE');
snapnow;
