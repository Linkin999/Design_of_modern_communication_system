clear;clc;
%% Initialization
% Preamble1
ue.NULRB = 6; % Number of uplink resource blocks
ue.DuplexMode = 'FDD'; % Duplexing mode
chs1.Format = 0; % Preamble format
preamble1 = ltePRACH(ue,chs1);

% Preamble2
chs2.Format = 1;
preamble2 = ltePRACH(ue,chs2);

% Preamble3
chs3.Format = 2;
preamble3 = ltePRACH(ue,chs3);

figure(1);
subplot(3,1,1);
plot(abs(preamble1));
title('Preamble1');
subplot(3,1,2);
plot(abs(preamble2));
title('Preamble2');
subplot(3,1,3);
plot(abs(preamble3));
title('Preamble3');

%% Transmission
% Tx
tx = [preamble1' preamble2'  preamble3']';
% Rx
rx = awgn(tx,20);

figure(2);
subplot(2,1,1);
plot(abs(tx));
title('Transmitted signal');
subplot(2,1,2);
plot(abs(rx));
title('Received signal');

%% Detection
detect1 = xcorr(rx(1:length(preamble1)),preamble1); % 提取rx中原preamble1对应位置上的信号
detect2 = xcorr(rx(length(preamble1)+1:length(preamble1)+length(preamble2)),preamble2); % 提取rx中原preamble2对应位置上的信号
detect3 = xcorr(rx(length(preamble1)+length(preamble2)+1:length(preamble1)+length(preamble2)+length(preamble3)),preamble3); % 提取rx中原preamble3对应位置上的信号
figure(3);
plot(abs(detect1));
title('Detection of preamble1 in received signal');
figure(4);
plot(abs(detect2));
title('Detection of preamble2 in received signal');
figure(5);
plot(abs(detect3));
title('Detection of preamble3 in received signal');
