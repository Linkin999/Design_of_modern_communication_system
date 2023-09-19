function [txWaveform,nonHTcfg,chanBW,overSampleFactor]=createTxWaveform(psduData,numMSDUs,lengthMPDU)
        
    %(1)����WLAN���ݰ�
    nonHTcfg=wlanNonHTConfig; %create packet configuration
    
    %(2)���Ʒ�ʽ��QAM
    nonHTcfg.MCS=6; %Modulation :64QAM Rate:2/3
    
    %(3)����������Ŀ
    nonHTcfg.NumTransmitAntennas=1; %Number of tansmit antenna
    
    %(4)ռ�ô���
    nonHTcfg.ChannelBandwidth='CBW5';
    chanBW=nonHTcfg.ChannelBandwidth;
    
    %(5)����PSDU���ȣ��ֽڣ�
    bitsPerOctet=8;
    nonHTcfg.PSDULength=lengthMPDU/bitsPerOctet; %set the PSDU length
    
    %(6)��ʼ������
    scramblerInitialization=randi([1 127],numMSDUs,1);
    
    %(7)��������NonHT���ݰ�
    txWaveform=wlanWaveformGenerator(psduData,nonHTcfg,...
        'NumPackets',numMSDUs,'IdleTime',80e-6,...
        'ScramblerInitialization',scramblerInitialization);
    
    %Short Trainning Field
%     S_k=sqrt(1/2)*[0,0,1+1j,0,0,0,-1-1j,0,0,0,1+1j,0,0,0,-1-1j,...
%         0,0,0,-1-1j,0,0,0,1+1j,0,0,0,0,0,0,0,-1-1j,...
%         0,0,0,-1-1j,0,0,0,1+1j,0,0,0,1+1j,0,0,0,1+1j,0,0,0,1+1j,0,0];%[1��53]
%     Short_preamble=createSTF(S_k);
%     figure(3)
%     subplot(2,1,1);plot(real(txWaveform(1:length(Short_preamble))));xlabel('n');ylabel('wlanSTF');
%     subplot(2,1,2);plot(real(Short_preamble));xlabel('n');ylabel('S_k');
%     txWaveform(1:length(Short_preamble))=Short_preamble;

    %Long Trainning Field
%     L_k=[1,1,-1,-1,1,1,-1,1,-1,1,1,1,1,1,1,-1,-1,1,1,-1,1,-1,1,1,1,1,0,1,-1,-1,1,...
%         1,-1,1,-1,1,-1,-1,-1,-1,-1,1,1,-1,-1,1,-1,1,-1,1,1,1,1];%[1��53]
%     Long_preamble=createLTF(L_k);
%     figure(4)
%     subplot(2,1,1);
%     plot(real(txWaveform(length(Short_preamble)+1:length(Short_preamble)+length(Long_preamble))));
%     xlabel('n');ylabel('wlanLTF');
%     subplot(2,1,2);plot(real(Long_preamble));xlabel('n');ylabel('L_k');
%     txWaveform(length(Short_preamble)+1:length(Short_preamble)+length(Long_preamble))=Long_preamble;
    
    
    %(8)�ز�������
    fs=helperSampleRate(chanBW);
    overSampleFactor=1.5; %�������������
    txWaveform=resample(txWaveform,fs*overSampleFactor,fs);
    fprintf('\nGenerating WLAN transmit waveform:\n')
    
    %(9)��һ���ź�
    powerScaleFactor=0.8;
    txWaveform=txWaveform.*(1/max(abs(txWaveform))*powerScaleFactor);
    
end