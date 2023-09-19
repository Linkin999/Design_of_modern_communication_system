function [ SNR ] = calSNR( SignalPower,SampleRate,EbNo,BitsPerSymbol )
%UNTITLED2 �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
BW=SampleRate/(2 * log2(BitsPerSymbol));
EbNo_lin = 10^(EbNo/10);
Es = BitsPerSymbol / 2;
N0 = Es / EbNo_lin / BW;
SNR = 10*log10(SignalPower/N0);
end

