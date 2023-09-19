function [txWaveform,nonHTcfg,chanBW,overSampleFactor] = createTxWaveform(psduData,numMSDUs,lengthMPDU)
nonHTcfg = wlanNonHTConfig;
nonHTcfg.MCS = 6;
nonHTcfg.NumTransmitAntennas = 1;
nonHTcfg.ChannelBandwidth = 'CBW5';
chanBW= nonHTcfg.ChannelBandwidth;

bitsPerOctet = 8;
nonHTcfg.PSDULength = lengthMPDU/bitsPerOctet;
scramblerInitialization = randi([1 127], numMSDUs,1);
txWaveform = wlanWaveformGenerator(psduData, nonHTcfg, ...
    'NumPackets',numMSDUs,'IdleTime',80e-6, ...
    'ScramblerInitialization',scramblerInitialization);

fs = helperSampleRate(chanBW);
overSampleFactor = 1.5;
txWaveform = resample(txWaveform,fs*overSampleFactor,fs);
fprintf('\nGenerating WLAN transmit waveform \n')

powerScaleFactor = 0.8;
txWaveform = txWaveform.*(1/max(abs(txWaveform))*powerScaleFactor);
