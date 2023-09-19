function [txWaveformHiperLan]=createHiperLanChannel(nonHTcfg,txWaveform,SNR_i)
    [datax,pilotsx] = helperSubcarrierIndices(nonHTcfg, 'Legacy');
    Nst = numel(datax)+numel(pilotsx); % Number of occupied subcarriers
    Nfft = helperFFTLength(nonHTcfg);     % FFT length
    
    SNR = SNR_i-10*log10(Nfft/Nst);
    
    chanMdl='E';
    fs=helperSampleRate(nonHTcfg);
    fd=0;
    channel=stdchan(1/fs,fd,['hiperlan2' chanMdl]);
    
    txWaveformHiperLan=filter(channel,txWaveform);
    txWaveformHiperLan=awgn(txWaveformHiperLan,SNR,'measured');
end