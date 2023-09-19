function [txData,psduData,numMSDUs,lengthMPDU] = createPSDU(txImage,MPDU_Param)

msdulength = 4048;
msduBits = msdulength*8;
numMSDUs = ceil(length(txImage)/msduBits);
padZeros = msduBits-mod(length(txImage),msduBits);

txData = [txImage; zeros(padZeros,1)];

generatorPolynomial = MPDU_Param.generatorPolynomial;
fcsGen = comm.CRCGenerator(generatorPolynomial);
fcsGen.InitialConditions = 1;
fcsGen.DirectMethod = true;
fcsGen.FinalXOR = 1;

numFragment = 0;
lengthMACheader = MPDU_Param.lengthMACheader;
lengthFCS = MPDU_Param.lengthFCS;
lengthMPDU = lengthMACheader+msduBits+lengthFCS;

psduData = zeros(lengthMPDU*numMSDUs,1);

for ind=0:numMSDUs-1
    frameBody = txData(ind*msduBits+1:msduBits*(ind+1),:);
    mpduHeader = helperNonHTMACHeader(mod(numFragment,16),mod(ind,4096));
    
    psdu = step(fcsGen,[mpduHeader;frameBody]);
    psduData(lengthMPDU*ind+1:lengthMPDU*(ind+1)) = psdu;
end
end