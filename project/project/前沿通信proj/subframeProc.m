function [rxSymbols,rxEncodedBits,outLen]=subframeProc(enb,sf,rxGrid,frame,LFrame,Lsf,cec,rxSymbols)
    enb.NSubframe = sf;
    rxsf = rxGrid(:,frame*LFrame+sf*Lsf+(1:Lsf),:);
    
    [hestsf,nestsf] = lteDLChannelEstimate(enb,cec,rxsf); % 信道估计
    
    % PCFICH解调
    pcfichIndices = ltePCFICHIndices(enb);
    [pcfichRx,pcfichHest] = lteExtractResources(pcfichIndices,rxsf,hestsf);
    [cfiBits,recsym] = ltePCFICHDecode(enb,pcfichRx,pcfichHest,nestsf);
    
    % CFI解码
    enb.CFI = lteCFIDecode(cfiBits);
                    
    % 获得PDSCH索引
    [pdschIndices,pdschIndicesInfo] = ltePDSCHIndices(enb, enb.PDSCH, enb.PDSCH.PRBSet);
    [pdschRx, pdschHest] = lteExtractResources(pdschIndices, rxsf, hestsf);
    
    % PDSCH解码
    [rxEncodedBits, rxEncodedSymb] = ltePDSCHDecode(enb,enb.PDSCH,pdschRx,pdschHest,nestsf);
    % 重构符号流
    rxSymbols = [rxSymbols; rxEncodedSymb{:}];
                    
    % DL-SCH解码
    outLen = enb.PDSCH.TrBlkSizes(enb.NSubframe+1);
end
