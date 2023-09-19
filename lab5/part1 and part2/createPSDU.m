function [txData,psduData,numMSDUs,lengthMPDU]=createPSDU(txImage,MPDU_Param)
    %(1)����NSDU�ֽ���������Ķ���
    msduLength=4048;
    
    %(2)����MSDU������������������
    msduBits=msduLength*8;
    
    %(3)���������MSDU��Ŀ������������
    numMSDUs=ceil(length(txImage)/msduBits);
    
    %(4)��󲻹�һ��MSDU�ı���������0�ճ�һ��MSDU������������
    padZeros=msduBits-mod(length(txImage),msduBits);
    
    %(5)��Ҫ��������
    txData=[txImage;zeros(padZeros,1)];
    
    %(6)����У�����FCS��Frame Check Sequence'֡У�����У�
    generatorPolynomial=MPDU_Param.generatorPolynomial;
    fcsGen=comm.CRCGenerator(generatorPolynomial);%����
    fcsGen.InitialConditions=1;
    fcsGen.DirectMethod=true;
    fcsGen.FinalXOR=1;
    
    %(7)�����ݷֿ�
    numFragment=0;
    
    %(8)MPDUͷ������ı�����
    lengthMACheader=MPDU_Param.lengthMACheader;
    
    %(9)FCS����ı�����
    lengthFCS=MPDU_Param.lengthFCS;%FCS length in bits
    
    %(10)MPDU���ȵ���MAC����+MSDU����+֡У��λ
    lengthMPDU=lengthMACheader+msduBits+lengthFCS;%MPDU length in bits
    
    %(11)���ݳ�ʼ��
    psduData=zeros(lengthMPDU*numMSDUs,1);
    
    %(12)�γ�MSDU���ݰ� 
    for ind=0:numMSDUs-1
        
        %��ȡMSDU���أ�����һ��MPDU֡��������
        frameBody=txData(ind*msduBits+1:msduBits*(ind+1),:);
        
        %����MPDUͷ����WLAN
        mpduHeader=helperNonHTMACHeader(mod(numFragment,16),mod(ind,4096));
        
        %����Я��MACͷ��֡���FCS��MPDU����
        psdu=step(fcsGen,[mpduHeader;frameBody]);
        
        %����PSDU���ݰ�
        psduData(lengthMPDU*ind+1:lengthMPDU*(ind+1))=psdu;
        
        
    end
end