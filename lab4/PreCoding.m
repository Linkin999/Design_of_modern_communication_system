function [berPreCoding]=PreCoding(M,nBits,nChan,snrVector,Mt,Mr)
    

    berPreCoding=zeros(nChan,length(snrVector));%初始化误码率
    
    
    U=zeros(Mr,Mt,nBits);%初始化U矩阵
    S=zeros(Mr,Mt,nBits);%初始化S矩阵
    V=zeros(Mr,Mt,nBits);%初始化V矩阵
    prefiltered=zeros(Mt,1,nBits);%初始化编码前矩阵
    txData=zeros(Mt,1,nBits);%发送数据矩阵
    rxData=zeros(Mt,1,nBits);%接收数据矩阵
    
    %%2：MIMO precoding
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
            %decompose channel matrix H by SVD------奇异值分解
            [U(:,:,bit),S(:,:,bit),V(:,:,bit)]=svd(H(:,:,bit));
            %pre-code data for each bit:(x=V*x_hat)-----预编码
            prefiltered(:,:,bit)=V(:,:,bit)*dataMod(:,:,bit);
            %send over the fading channel ---信道上发送
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
                 %------>数据恢复
                 rxData(:,:,bit)=U(:,:,bit)'*txNoisy(:,:,bit);
             end
             %QAM demodulate and compute bit error rate
             rxData=qamdemod(rxData,M); %---->QAM解调
             [~,berPreCoding(i,j)]=biterr(data,rxData);
        end
        fprintf('\n');
        
    end
    
    %%3：take average of all 3 fading channels
    berPreCoding=mean(berPreCoding); %-------->计算平均误码率
    
    
    
end