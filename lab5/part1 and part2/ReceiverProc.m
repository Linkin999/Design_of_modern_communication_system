function [rxBit,offsetLLTF,pktOffset,packetSeq]=ReceiverProc(MPDU_Param,nonHTcfg,hcd,chanBW,osf,burstCaptures)

% （1）获取PSDU中需要的信息
    indLSTF = wlanFieldIndices(nonHTcfg,'L-STF'); 
    indLLTF = wlanFieldIndices(nonHTcfg,'L-LTF'); 
    indLSIG = wlanFieldIndices(nonHTcfg,'L-SIG');

% （2）下采样接收信号
    fs = helperSampleRate(chanBW);
    rxWaveform = resample(burstCaptures,fs,fs*osf);
    rxWaveformLen = size(rxWaveform,1);
    searchOffset = 0; % Offset from start of the waveform in samples
  
% （3）最小包长度是10个OFDM符号
    lstfLen = double(indLSTF(2)); % Number of samples in L-STF
    minPktLen = lstfLen*5;
    pktInd = 1;
    sr = helperSampleRate(chanBW); % Sampling rate
    offsetLLTF = [];
    packetSeq = [];
    displayFlag = 1; % Flag to display the decoded information

%（4）为MPDU产生FCS
    fcsDet = comm.CRCDetector(MPDU_Param.generatorPolynomial);
    fcsDet.InitialConditions = 1;
    fcsDet.DirectMethod = true;
    fcsDet.FinalXOR = 1;

%（5）计算EVM
    hEVM = comm.EVM('AveragingDimensions',[1 2 3]);
    hEVM.MaximumEVMOutputPort = true;

%（6）接收循环处理
while (searchOffset + minPktLen) <= rxWaveformLen    
    
% 数据包检测 Packet detect
    pktOffset = helperPacketDetect(rxWaveform(1+searchOffset:end,:),chanBW,0.8)-1;
 
% 调整数据包偏移 Adjust packet offset
    pktOffset = searchOffset+pktOffset;
    if isempty(pktOffset) || (pktOffset+indLSIG(2)>rxWaveformLen)
        if pktInd==1
            disp('** No packet detected **');
        end
        break;
    end
 
% 抽取Non-HT域，粗频偏纠正
    nonHT = rxWaveform(pktOffset+(indLSTF(1):indLSIG(2)),:);
    coarseFreqOffset = wlanCoarseCFOEstimate(nonHT,chanBW); 
    nonHT = helperFrequencyOffset(nonHT,fs,-coarseFreqOffset);

% 符号同步 Symbol timing synchronization
    offsetLLTF = helperSymbolTiming(nonHT,chanBW);
    
    if isempty(offsetLLTF)
        searchOffset = pktOffset+lstfLen;
        continue;
    end
    % Adjust packet offset
    pktOffset = pktOffset+offsetLLTF-double(indLLTF(1));

% 定时同步完成
    if (pktOffset<0) || ((pktOffset+minPktLen)>rxWaveformLen) 
        searchOffset = pktOffset+lstfLen; 
        continue; 
    end
    fprintf('\nPacket-%d detected at index %d\n',pktInd,pktOffset+1);
  
    nonHT = rxWaveform(pktOffset+(indLSTF(1):indLSIG(2)),:);
    nonHT = helperFrequencyOffset(nonHT,fs,-coarseFreqOffset);

% 精频偏纠正
    lltf = nonHT(indLLTF(1):indLLTF(2),:);           % Extract L-LTF
    fineFreqOffset = wlanFineCFOEstimate(lltf,chanBW);
    nonHT = helperFrequencyOffset(nonHT,fs,-fineFreqOffset);
    cfoCorrection = coarseFreqOffset+fineFreqOffset; % Total CFO
 
% 利用L-LTF做信道估计
    lltf = nonHT(indLLTF(1):indLLTF(2),:);
    demodLLTF = wlanLLTFDemodulate(lltf,chanBW);
    chanEstLLTF = wlanLLTFChannelEstimate(demodLLTF,chanBW);

% 噪声估计
    noiseVarNonHT = helperNoiseEstimate(demodLLTF);

% 恢复出L-SIG域
    [recLSIGBits,failCheck] = wlanLSIGRecover( ...
           nonHT(indLSIG(1):indLSIG(2),:), ...
           chanEstLLTF, noiseVarNonHT,chanBW);
 
    if failCheck	
        fprintf('  L-SIG check fail \n');
        searchOffset = pktOffset+lstfLen; 
        continue; 
    else
        fprintf('  L-SIG check pass \n');
    end
 
% 恢复数据包参数
    [lsigMCS,lsigLen,rxSamples] = helperInterpretLSIG(recLSIGBits,sr);
 
    if (rxSamples+pktOffset)>length(rxWaveform)
        disp('** Not enough samples to decode packet **');
        break;
    end

% 应用CFO纠正整个数据包
    rxWaveform(pktOffset+(1:rxSamples),:) = helperFrequencyOffset(rxWaveform(pktOffset+(1:rxSamples),:),fs,-cfoCorrection);

% 创建接收Non-HT对象
    rxNonHTcfg = wlanNonHTConfig;
    rxNonHTcfg.MCS = lsigMCS;
    rxNonHTcfg.PSDULength = lsigLen;

% 获取数据域指示
    indNonHTData = wlanFieldIndices(rxNonHTcfg,'NonHT-Data');


% 利用信道估计结果恢复PSDU比特
    [rxPSDU,eqSym] = wlanNonHTDataRecover(rxWaveform(pktOffset+...
           (indNonHTData(1):indNonHTData(2)),:), ...
           chanEstLLTF,noiseVarNonHT,rxNonHTcfg);
 
% 显示当前星座图
    step(hcd,reshape(eqSym,[],1)); % Current constellation 
    release(hcd); % Release previous constellation plot
 
    refSym = helperClosestConstellationPoint(eqSym,rxNonHTcfg);
    [evm.RMS,evm.Peak] = step(hEVM,refSym,eqSym);

% 从MAC头中移除FCS
    [rxBit{pktInd},crcCheck] = step(fcsDet,double(rxPSDU)); 
 
    if ~crcCheck
         disp('  MAC CRC check pass');
    else
         disp('  MAC CRC check fail');
    end
 
% 处理MAC信息
    [mac,packetSeq(pktInd)] = helperNonHTMACHeaderDecode(rxBit{pktInd}); 

% 显示解码结果
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

% 更新搜索序号
    % Update search index
    searchOffset = pktOffset+double(indNonHTData(2));
 
    pktInd = pktInd+1;

% 当重复的包检测到时，结束处理
    if length(unique(packetSeq))<length(packetSeq)
        break
    end  
end
