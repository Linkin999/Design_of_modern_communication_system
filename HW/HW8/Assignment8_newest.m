%% MIMO Detector for 4×2 STBC
clear;
clc;

%% Initialization
nChan = 1000;
EbNo = -10:2:20; % SNR in dB

%% ZF
for i = 1:nChan
    H = zeros(4,4);
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
        rxData = awgn(txData,EbNo(j));
        x_hat = H\rxData; % H^-1 * rxData
        x_hat = qamdemod(x_hat,4);
        [~,berZeroForcing(i,j)] = biterr(data, x_hat); 
    end
end
berZeroForcing = mean(berZeroForcing);

%% MMSE
for i = 1:nChan
    H = zeros(4,4);
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
        rxData = awgn(txData,EbNo(j));
        Q = (H'*H+eye(4)*10^(-EbNo(j)/10))\H';
        x_hat = Q * rxData;
        x_hat = qamdemod(x_hat,4);
        [~,berMMSE(i,j)] = biterr(data, x_hat);
    end
end
berMMSE = mean(berMMSE);

%% ML
X0 = zeros(4,nChan);
X = X0;
Y = zeros(4,length(EbNo),nChan); % 第一维:4 第二维:SNR 第三维:信道数量
HH = zeros(4,4,nChan);
for i = 1:nChan
    H = zeros(4,4);
    data = randi([0 3],4,1);
    X0(:,i) = data;
    dataMod = qammod(data,4); % QPSK
    while rank(H) < 4
        h = randn(2,4);
        H = [h(1,1),-h(1,2),h(1,3),-h(1,4);
             h(1,1),-h(2,2),h(2,3),-h(2,4);
             h(1,2),h(1,1),h(1,4),h(1,3);
             h(2,2),h(2,1),h(2,4),h(2,3)];
    end
    HH(:,:,i) = H;
	txData = H * dataMod;
    X(:,i) = txData;
	for j = 1:length(EbNo)
        rxData = awgn(txData,EbNo(j));
        Y(:,j,i) = rxData;
    end
end

for i = 1:length(EbNo)
    for j = 1:nChan
        d_min = inf;
        y = Y(:,i,j);
        for k = 1:nChan
            y_hat = X(:,k);
            d = sqrt(sum((abs(y-y_hat)).^2));
            if d < d_min
                x_hat = X0(:,k);
                d_min = d;
            end
        end
        [~,berML(j,i)] = biterr(X0(:,j),x_hat);
    end
end
berML = mean(berML);

%% MIMO BER Curves
figure(1);
semilogy(EbNo, berZeroForcing ,'-v', ...
         EbNo, berMMSE,'-s', ...
         EbNo, berML,'-d','LineWidth',1);
grid on;
axis([EbNo(1)-2 EbNo(end)+2 0 1]);
title(sprintf('%d Tx x %d Rx MIMO: BER Curves by Equalizer', 4, 2));
set(gca,'FontWeight','bold','LineWidth',1);
xlabel('EbNo(dB)');
ylabel('Bit Error Rate (Avg)');
legend('Zero Forcing','MMSE','ML');
snapnow;
