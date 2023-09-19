function [Long_preamble]=createLTF(L_k)
    N_FFT=64;
    virtual_subcarrier=zeros(1,N_FFT-length(L-k));%[1��11]
    Long_preamble_slot_Frequency=[virtual_subcarrier(1:6),L_k,virtual_subcarrier(7:11)];%[1��64]
    Long_preamble_slot_Time=ifft(ifftshift(Long_preamble_slot_Frequency));%[1��64]
    Long_preamble=[Long_preamble_slot_Time(33:64),Long_preamble_slot_Time,Long_preamble_slot_Time];%[1��160]
    Long_preamble=Long_preamble*10;
end