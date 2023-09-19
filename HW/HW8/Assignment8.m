%% Initialization
clear;
clc;
Mt = 4; % Num of Tx
Mr = 2; % Num of Rx
M = 4; % 调制阶数
k = log2(M); % 单符号比特数
H = zeros(Mr,Mt);
nChan = 1000;
EbNo = -10:2:20; % SNR
snrVector = EbNo + 10*log10(k); % Es/No before adding noise

%initialize
berZeroForcing = zeros(nChan, length(snrVector));%-------->迫零算法
berMMSE = zeros(nChan, length(snrVector));%--------------->MMSE(最小均方)
%berML=zeros(nchan,length(snrVector));%-------------------->ML(最大似然估计)

%% ZF
txData = zeros(Mt, 1);
rxData = zeros(Mr, 1);

disp('MIMO zero forcing');
for i = 1:nChan
    H = (randn(Mr,Mt) + 1j*randn(Mr,Mt))/sqrt(2);
    data = randi([0 M-1],Mt,1); % Generate a sequence of random message bits and QAM modulate
    dataMod = qammod(data,M);
	txData = H*dataMod;
    
    fprintf('SNR:\t');
    for j = 1:length(snrVector)
        fprintf('%d\t',j);
        % add white Gaussian noise
        noise = (randn(Mr,1) + 1j*randn(Mr,1))/sqrt(2);
        txNoise = txData +  noise * 10^(-snrVector(j)/10/2);
        % H*x = y for x, if full rank
        rxData = H\txNoise;
       % QAM demodulate and compute bit error rate
       rxData = qamdemod(rxData,M);
       [~,berZeroForcing(i,j)] = biterr(data, rxData); 
    end
    fprintf('\n');
end
berZeroForcing = mean(berZeroForcing);

%% MMSE
txData = zeros(Mt, 1);
rxData = zeros(Mr, 1);
W = zeros(Mr, Mt);

disp('MIMO MMSE');
for i = 1:nChan
    fprintf('Channel: %d\n',i);
    H = (randn(Mr, Mt) + 1j*randn(Mr, Mt))/sqrt(2);
	data = randi([0 M-1], Mt, 1);
    dataMod = qammod(data, M); 
	txData = H*dataMod;
    
    fprintf('SNR:\t');
	for j = 1:length(snrVector)
        fprintf('%d\t',j);
        noise = (randn(Mr,1) + 1j*randn(Mr,1))/sqrt(2);
        txNoise = txData + noise * 10^(-snrVector(j)/10/2);
        % add noise variations 
        W = (H' * H + eye(Mt) * 10^(-snrVector(j)/10/2))^-1 * H';
        rxData = W * txNoise;
        rxData = qamdemod(rxData,M);
        [~,berMMSE(i,j)] = biterr(data, rxData);
	end
end
berMMSE = mean(berMMSE);

%% ML
txData = zeros(Mt, 1);
rxData = zeros(Mr, 1);
HH=zeros(Mt,Mt,nChan);
data_total=zeros(Mt,length(EbNo),nChan);
txData_total=zeros(Mt,length(EbNo),nChan);
rxData_total=zeros(Mt,length(EbNo),nChan);
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
        data_total(:,j,i) = data;
        txData_total(:,j,i) = txData;
        Noise = randn(4,1);
        rxData = txData + Noise * 10^(-EbNo(j)/10);
        rxData_total(:,j,i) = rxData;
	end
    HH(:,:,i) = H;
end

berML = zeros(nChan,length(EbNo));
for i=1:length(EbNo)
    for j=1:1000
        target=txData_total(:,1,1);
        distance=sum(rxData_total(:,i,j)-HH(:,:,j)*txData_total(:,1,1));
        for m=1:nChan
            distance2=rxData_total(:,i,j)-HH(:,:,j)*txData_total(:,i,m);
        end
    end
end

%% MIMO BER Curves
figure(1);
semilogy(EbNo, berZeroForcing ,'-v', ...
         EbNo, berMMSE,'-s','LineWidth',1);
grid on;
xlim([EbNo(1)-2 EbNo(end)+2]);
title(sprintf('%d Tx x %d Rx MIMO: BER Curves by Equalizer, M = %d QAM', Mt, Mr, M));
set(gca, 'FontWeight','bold','LineWidth',1);
xlabel('Eb/No (dB)');
ylabel('Bit Error Rate (Avg)');
legend('Zero Forcing','MMSE');
snapnow;