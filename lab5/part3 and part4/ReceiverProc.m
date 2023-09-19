%% 复基带波形解调和解码

function [rxBit,offsetLLTF,pktOffset,packetSeq]=ReceiverProc(MPDU_Param,nonHTcfg,hcd,chanBW,osf,burstCaptures)

% （1）PPDU中各域的索引
    indLSTF = wlanFieldIndices(nonHTcfg,'L-STF');     %-------------------------------------> STF索引[1 160]
    indLLTF = wlanFieldIndices(nonHTcfg,'L-LTF');     %-------------------------------------> LTF索引[161 320]
    indLSIG = wlanFieldIndices(nonHTcfg,'L-SIG');     %-------------------------------------> SIG索引[321 400]

% （2）复基带波形下采样
    fs = helperSampleRate(chanBW);
    sr = fs; 
    rxWaveform = resample(burstCaptures,fs,fs*osf);   %-------------------------------------> 复基带波形下采样
    rxWaveformLen = size(rxWaveform,1);
    searchOffset = 0;     %-----------------------------------------------------------------> 波形搜索起始位置索引             
  
% （3）最小包长度是10个OFDM符号
    lstfLen = double(indLSTF(2)); %---------------------------------------------------------> STF的长度
    minPktLen = lstfLen*5;   %--------------------------------------------------------------> 最小数据包长度
    pktInd = 1;    %------------------------------------------------------------------------> 包成功解码索引
    packetSeq = [];  %----------------------------------------------------------------------> 包序号
    displayFlag = 1; 

% （4）接收端CRC校验
    fcsDet = comm.CRCDetector(MPDU_Param.generatorPolynomial);   %--------------------------> 与发射端对应
    fcsDet.InitialConditions = 1;
    fcsDet.DirectMethod = true;
    fcsDet.FinalXOR = 1;

%（5）计算EVM
    hEVM = comm.EVM('AveragingDimensions',[1 2 3]);   %-------------------------------------> 统计EVM
    hEVM.MaximumEVMOutputPort = true;

    pktOffsetInx = 1;
%% （6）接收循环处理
while (searchOffset + minPktLen) <= rxWaveformLen    
    
% 数据包检测 Packet detect    --------------------------------------------------------------> 数据包起始位置                   
    pktOffset = helperPacketDetect(rxWaveform(1+searchOffset:end,:),chanBW,0.8)-1;
        
% 调整数据包偏移 Adjust packet offset ------------------------------------------------------> 更新起始位置 
    pktOffset = searchOffset + pktOffset;
  
    if pktOffsetInx <=3
       figure(5)  
       subplot(4,1,pktOffsetInx); plot(real(rxWaveform));hold on;plot([0 length(rxWaveform)],[0 0],'r');
       stem(pktOffset,0.4);axis([10000 30000 -0.3 0.5]); xlabel('Time unit'); ylabel('Amplitude');     
       pktOffsetInx = pktOffsetInx + 1;
    end
       
% 数据包处理结束  
    if isempty(pktOffset) || (pktOffset+indLSIG(2)>rxWaveformLen)
        if pktInd==1
            disp('** No packet detected **');
        end
        break;
    end
 
% 抽取STF/LTF/SIG，粗频偏纠正 -----------------------------------------------------> STF/LTF/SIG进行粗频偏纠正
    nonHT = rxWaveform(pktOffset+(indLSTF(1):indLSIG(2)),:);
    coarseFreqOffset = wlanCoarseCFOEstimate(nonHT,chanBW); 
    nonHT = helperFrequencyOffset(nonHT,fs,-coarseFreqOffset);

% LTF同步 ------------------------------------------------------------------------> LTF进行符号同步
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
    
% 再次判断数据包是否处理完毕  -----------------------------------------------------> 判断数据包是否处理完毕
    if (pktOffset<0) || ((pktOffset+minPktLen)>rxWaveformLen) 
        searchOffset = pktOffset+lstfLen; 
        continue; 
    end
    
% 再次抽取STF/LTF/SIG，粗频偏纠正  
    fprintf('\nPacket-%d detected at index %d\n',pktInd,pktOffset+1);  
    nonHT = rxWaveform(pktOffset+(indLSTF(1):indLSIG(2)),:);
    nonHT = helperFrequencyOffset(nonHT,fs,-coarseFreqOffset);

% 抽取LTF，精频偏纠正
    lltf = nonHT(indLLTF(1):indLLTF(2),:);   % -----------------------------------> 抽取LTF
    fineFreqOffset = wlanFineCFOEstimate(lltf,chanBW);% --------------------------> 精频偏估计
    nonHT = helperFrequencyOffset(nonHT,fs,-fineFreqOffset);% --------------------> 精频偏校正
    cfoCorrection = coarseFreqOffset+fineFreqOffset; % ---------------------------> 该频偏用于校正数据包数据
 
% 利用L-LTF做信道估计
    lltf = nonHT(indLLTF(1):indLLTF(2),:);
    demodLLTF = wlanLLTFDemodulate(lltf,chanBW);
    chanEstLLTF = wlanLLTFChannelEstimate(demodLLTF,chanBW);%---------------------> LTF进行信道估计

% 噪声估计
    noiseVarNonHT = helperNoiseEstimate(demodLLTF);%------------------------------> 估计噪声功率

% 恢复SIG域
    [recLSIGBits,failCheck] = wlanLSIGRecover( ...  %-----------------------------> 恢复SIG比特
           nonHT(indLSIG(1):indLSIG(2),:), ...
           chanEstLLTF, noiseVarNonHT,chanBW);
 
    if failCheck	%-------------------------------------------------------------> 恢复SIG比特失败，重新包检测
        fprintf('  L-SIG check fail \n');
        searchOffset = pktOffset+lstfLen; 
        continue; 
    else
        fprintf('  L-SIG check pass \n');
    end
 
% 解析SIG字段
    [lsigMCS,lsigLen,rxSamples] = helperInterpretLSIG(recLSIGBits,sr);%-----------> 解析SIG字段，返回MCS
 
    if (rxSamples+pktOffset)>length(rxWaveform)
        disp('** Not enough samples to decode packet **');
        break;
    end

% 用CFO进行数据字段频偏校正  %-----------------------------------------------------> 数据字段频偏校正
    rxWaveform(pktOffset+(1:rxSamples),:) ...
        = helperFrequencyOffset(rxWaveform(pktOffset+(1:rxSamples),:),fs,-cfoCorrection);

% 创建Non-HT对象
    rxNonHTcfg = wlanNonHTConfig;
    rxNonHTcfg.MCS = lsigMCS;
    rxNonHTcfg.PSDULength = lsigLen;

% 获取NonHT数据字段索引
    indNonHTData = wlanFieldIndices(rxNonHTcfg,'NonHT-Data'); %------------------> NonHT数据字段索引

% 恢复PSDU比特和均衡后的调制符号（ZF）
    [rxPSDU,eqSym] = wlanNonHTDataRecover(rxWaveform(pktOffset+... %-------------> 恢复PSDU比特和均衡后的调制符号
           (indNonHTData(1):indNonHTData(2)),:), ...
           chanEstLLTF,noiseVarNonHT,rxNonHTcfg);
 
% 显示当前星座图------------------------------------------------------------------> 绘制调制符号星座图
    step(hcd,reshape(eqSym,[],1)); 
    release(hcd); 
    refSym = helperClosestConstellationPoint(eqSym,rxNonHTcfg);
    [evm.RMS,evm.Peak] = step(hEVM,refSym,eqSym);    % --------------------------> 计算EVM

% 移除FCS------------------------------------------------------------------------> CRC校验，返回MSDU比特
    [rxBit{pktInd},crcCheck] = step(fcsDet,double(rxPSDU)); 
 
    if ~crcCheck
         disp('  MAC CRC check pass');
    else
         disp('  MAC CRC check fail');
    end
 
% 获取包序号---------------------------------------------------------------------> 从MAC头字段中获取包序号，避免重复解码
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

% 更新包搜索的起始位置 --------------------------------------------------------> 设置下一个数据包的起始位置
    searchOffset = pktOffset+double(indNonHTData(2));
    pktInd = pktInd+1;

% 当重复的包检测到时，结束处理
    if length(unique(packetSeq))<length(packetSeq)
        break
    end  
end

packetSeq
