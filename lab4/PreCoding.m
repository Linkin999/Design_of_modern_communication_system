function [berPreCoding]=PreCoding(M,nBits,nChan,snrVector,Mt,Mr)
    

    berPreCoding=zeros(nChan,length(snrVector));%��ʼ��������
    
    
    U=zeros(Mr,Mt,nBits);%��ʼ��U����
    S=zeros(Mr,Mt,nBits);%��ʼ��S����
    V=zeros(Mr,Mt,nBits);%��ʼ��V����
    prefiltered=zeros(Mt,1,nBits);%��ʼ������ǰ����
    txData=zeros(Mt,1,nBits);%�������ݾ���
    rxData=zeros(Mt,1,nBits);%�������ݾ���
    
    %%2��MIMO precoding
    disp('MIMO precoding');
    for i=1:nChan
        fprintf('channel:%d\n',i);
        %unique MIMO channel for 'Mr' receive and 'Mt' transmit antennas
        H=(randn(Mr,Mt,nBits)+1i*randn(Mr,Mt,nBits))/sqrt(2);
        
        %generate a sequence of random message bits and QAM modulate
        data=randi([0 M-1],Mt,1,nBits);
        dataMod=qammod(data,M);
        
        %precode
        for bit=1:nBits
            %decompose channel matrix H by SVD------����ֵ�ֽ�
            [U(:,:,bit),S(:,:,bit),V(:,:,bit)]=svd(H(:,:,bit));
            %pre-code data for each bit:(x=V*x_hat)-----Ԥ����
            prefiltered(:,:,bit)=V(:,:,bit)*dataMod(:,:,bit);
            %send over the fading channel ---�ŵ��Ϸ���
            txData(:,:,bit)=H(:,:,bit)*prefiltered(:,:,bit);
        end
        
        
        fprintf('SNR:\t');
        for j=1:length(snrVector)
             fprintf('%d\t',j)
             %add white Gaussian noise(x_noisy<--x+noise)
             %for double-sided white noise,(y_hat=U^(H)*y)
             noise=randn(Mr,1,nBits)+1i*randn(Mr,1,nBits)/sqrt(2);
             txNoisy=txData+noise*10^(-snrVector(j)/10/2);
             for bit=1:nBits
                 %post-code data for each bit:remove fading channel components
                 %------>���ݻָ�
                 rxData(:,:,bit)=U(:,:,bit)'*txNoisy(:,:,bit);
             end
             %QAM demodulate and compute bit error rate
             rxData=qamdemod(rxData,M); %---->QAM���
             [~,berPreCoding(i,j)]=biterr(data,rxData);
        end
        fprintf('\n');
        
    end
    
    %%3��take average of all 3 fading channels
    berPreCoding=mean(berPreCoding); %-------->����ƽ��������
    
    
    
end