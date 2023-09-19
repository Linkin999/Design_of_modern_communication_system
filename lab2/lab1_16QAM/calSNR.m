function [ SNR ] = calSNR( SignalPower,SampleRate,EbNo,BitsPerSymbol )
%UNTITLED2 此处显示有关此函数的摘要
%   此处显示详细说明
BW=SampleRate/(2 * log2(BitsPerSymbol));
EbNo_lin = 10^(EbNo/10);
Es = BitsPerSymbol / 2;
N0 = Es / EbNo_lin / BW;
SNR = 10*log10(SignalPower/N0);
end

