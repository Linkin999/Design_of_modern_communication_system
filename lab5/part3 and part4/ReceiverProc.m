%% ���������ν���ͽ���

function [rxBit,offsetLLTF,pktOffset,packetSeq]=ReceiverProc(MPDU_Param,nonHTcfg,hcd,chanBW,osf,burstCaptures)

% ��1��PPDU�и��������
    indLSTF = wlanFieldIndices(nonHTcfg,'L-STF');     %-------------------------------------> STF����[1 160]
    indLLTF = wlanFieldIndices(nonHTcfg,'L-LTF');     %-------------------------------------> LTF����[161 320]
    indLSIG = wlanFieldIndices(nonHTcfg,'L-SIG');     %-------------------------------------> SIG����[321 400]

% ��2�������������²���
    fs = helperSampleRate(chanBW);
    sr = fs; 
    rxWaveform = resample(burstCaptures,fs,fs*osf);   %-------------------------------------> �����������²���
    rxWaveformLen = size(rxWaveform,1);
    searchOffset = 0;     %-----------------------------------------------------------------> ����������ʼλ������             
  
% ��3����С��������10��OFDM����
    lstfLen = double(indLSTF(2)); %---------------------------------------------------------> STF�ĳ���
    minPktLen = lstfLen*5;   %--------------------------------------------------------------> ��С���ݰ�����
    pktInd = 1;    %------------------------------------------------------------------------> ���ɹ���������
    packetSeq = [];  %----------------------------------------------------------------------> �����
    displayFlag = 1; 

% ��4�����ն�CRCУ��
    fcsDet = comm.CRCDetector(MPDU_Param.generatorPolynomial);   %--------------------------> �뷢��˶�Ӧ
    fcsDet.InitialConditions = 1;
    fcsDet.DirectMethod = true;
    fcsDet.FinalXOR = 1;

%��5������EVM
    hEVM = comm.EVM('AveragingDimensions',[1 2 3]);   %-------------------------------------> ͳ��EVM
    hEVM.MaximumEVMOutputPort = true;

    pktOffsetInx = 1;
%% ��6������ѭ������
while (searchOffset + minPktLen) <= rxWaveformLen    
    
% ���ݰ���� Packet detect    --------------------------------------------------------------> ���ݰ���ʼλ��                   
    pktOffset = helperPacketDetect(rxWaveform(1+searchOffset:end,:),chanBW,0.8)-1;
        
% �������ݰ�ƫ�� Adjust packet offset ------------------------------------------------------> ������ʼλ�� 
    pktOffset = searchOffset + pktOffset;
  
    if pktOffsetInx <=3
       figure(5)  
       subplot(4,1,pktOffsetInx); plot(real(rxWaveform));hold on;plot([0 length(rxWaveform)],[0 0],'r');
       stem(pktOffset,0.4);axis([10000 30000 -0.3 0.5]); xlabel('Time unit'); ylabel('Amplitude');     
       pktOffsetInx = pktOffsetInx + 1;
    end
       
% ���ݰ��������  
    if isempty(pktOffset) || (pktOffset+indLSIG(2)>rxWaveformLen)
        if pktInd==1
            disp('** No packet detected **');
        end
        break;
    end
 
% ��ȡSTF/LTF/SIG����Ƶƫ���� -----------------------------------------------------> STF/LTF/SIG���д�Ƶƫ����
    nonHT = rxWaveform(pktOffset+(indLSTF(1):indLSIG(2)),:);
    coarseFreqOffset = wlanCoarseCFOEstimate(nonHT,chanBW); 
    nonHT = helperFrequencyOffset(nonHT,fs,-coarseFreqOffset);

% LTFͬ�� ------------------------------------------------------------------------> LTF���з���ͬ��
    offsetLLTF = helperSymbolTiming(nonHT,chanBW);
    
    if isempty(offsetLLTF)
        searchOffset = pktOffset+lstfLen;
        continue;
    end
    
    pktOffset = pktOffset+offsetLLTF-double(indLLTF(1));

    if pktOffsetInx == 4
       figure(5)  
       subplot(4,1,pktOffsetInx); plot(real(rxWaveform));hold on;plot([0 length(rxWaveform)],[0 0],'r');
       stem(pktOffset,0.4);axis([10000 30000 -0.3 0.5]);xlabel('Time unit'); ylabel('Amplitude');        
       pktOffsetInx = pktOffsetInx + 1;
    end
    
% �ٴ��ж����ݰ��Ƿ������  -----------------------------------------------------> �ж����ݰ��Ƿ������
    if (pktOffset<0) || ((pktOffset+minPktLen)>rxWaveformLen) 
        searchOffset = pktOffset+lstfLen; 
        continue; 
    end
    
% �ٴγ�ȡSTF/LTF/SIG����Ƶƫ����  
    fprintf('\nPacket-%d detected at index %d\n',pktInd,pktOffset+1);  
    nonHT = rxWaveform(pktOffset+(indLSTF(1):indLSIG(2)),:);
    nonHT = helperFrequencyOffset(nonHT,fs,-coarseFreqOffset);

% ��ȡLTF����Ƶƫ����
    lltf = nonHT(indLLTF(1):indLLTF(2),:);   % -----------------------------------> ��ȡLTF
    fineFreqOffset = wlanFineCFOEstimate(lltf,chanBW);% --------------------------> ��Ƶƫ����
    nonHT = helperFrequencyOffset(nonHT,fs,-fineFreqOffset);% --------------------> ��ƵƫУ��
    cfoCorrection = coarseFreqOffset+fineFreqOffset; % ---------------------------> ��Ƶƫ����У�����ݰ�����
 
% ����L-LTF���ŵ�����
    lltf = nonHT(indLLTF(1):indLLTF(2),:);
    demodLLTF = wlanLLTFDemodulate(lltf,chanBW);
    chanEstLLTF = wlanLLTFChannelEstimate(demodLLTF,chanBW);%---------------------> LTF�����ŵ�����

% ��������
    noiseVarNonHT = helperNoiseEstimate(demodLLTF);%------------------------------> ������������

% �ָ�SIG��
    [recLSIGBits,failCheck] = wlanLSIGRecover( ...  %-----------------------------> �ָ�SIG����
           nonHT(indLSIG(1):indLSIG(2),:), ...
           chanEstLLTF, noiseVarNonHT,chanBW);
 
    if failCheck	%-------------------------------------------------------------> �ָ�SIG����ʧ�ܣ����°����
        fprintf('  L-SIG check fail \n');
        searchOffset = pktOffset+lstfLen; 
        continue; 
    else
        fprintf('  L-SIG check pass \n');
    end
 
% ����SIG�ֶ�
    [lsigMCS,lsigLen,rxSamples] = helperInterpretLSIG(recLSIGBits,sr);%-----------> ����SIG�ֶΣ�����MCS
 
    if (rxSamples+pktOffset)>length(rxWaveform)
        disp('** Not enough samples to decode packet **');
        break;
    end

% ��CFO���������ֶ�ƵƫУ��  %-----------------------------------------------------> �����ֶ�ƵƫУ��
    rxWaveform(pktOffset+(1:rxSamples),:) ...
        = helperFrequencyOffset(rxWaveform(pktOffset+(1:rxSamples),:),fs,-cfoCorrection);

% ����Non-HT����
    rxNonHTcfg = wlanNonHTConfig;
    rxNonHTcfg.MCS = lsigMCS;
    rxNonHTcfg.PSDULength = lsigLen;

% ��ȡNonHT�����ֶ�����
    indNonHTData = wlanFieldIndices(rxNonHTcfg,'NonHT-Data'); %------------------> NonHT�����ֶ�����

% �ָ�PSDU���غ;����ĵ��Ʒ��ţ�ZF��
    [rxPSDU,eqSym] = wlanNonHTDataRecover(rxWaveform(pktOffset+... %-------------> �ָ�PSDU���غ;����ĵ��Ʒ���
           (indNonHTData(1):indNonHTData(2)),:), ...
           chanEstLLTF,noiseVarNonHT,rxNonHTcfg);
 
% ��ʾ��ǰ����ͼ------------------------------------------------------------------> ���Ƶ��Ʒ�������ͼ
    step(hcd,reshape(eqSym,[],1)); 
    release(hcd); 
    refSym = helperClosestConstellationPoint(eqSym,rxNonHTcfg);
    [evm.RMS,evm.Peak] = step(hEVM,refSym,eqSym);    % --------------------------> ����EVM

% �Ƴ�FCS------------------------------------------------------------------------> CRCУ�飬����MSDU����
    [rxBit{pktInd},crcCheck] = step(fcsDet,double(rxPSDU)); 
 
    if ~crcCheck
         disp('  MAC CRC check pass');
    else
         disp('  MAC CRC check fail');
    end
 
% ��ȡ�����---------------------------------------------------------------------> ��MACͷ�ֶ��л�ȡ����ţ������ظ�����
    [mac,packetSeq(pktInd)] = helperNonHTMACHeaderDecode(rxBit{pktInd}); 

% ��ʾ������
    if displayFlag
        fprintf('  Estimated CFO: %5.1f Hz\n\n',cfoCorrection); 
 
        disp('  Decoded L-SIG contents: ');
        fprintf(' MCS: %d\n',lsigMCS);
        fprintf(' Length: %d\n',lsigLen);
        fprintf(' Number of samples in packet: %d\n\n',rxSamples);
 
        fprintf('  EVM:\n');
        fprintf('    EVM peak: %0.3f%%  EVM RMS: %0.3f%%\n\n', ...
        evm.Peak,evm.RMS);
 
        fprintf('  Decoded MAC Sequence Control field contents:\n');
        fprintf('    Sequence number:%d\n',packetSeq(pktInd));
    end

% ���°���������ʼλ�� --------------------------------------------------------> ������һ�����ݰ�����ʼλ��
    searchOffset = pktOffset+double(indNonHTData(2));
    pktInd = pktInd+1;

% ���ظ��İ���⵽ʱ����������
    if length(unique(packetSeq))<length(packetSeq)
        break
    end  
end

packetSeq
