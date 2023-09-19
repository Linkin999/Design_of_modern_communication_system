clear;
clc;
NoisePower=1;
wifisignal=wlanHTConfig('ChannelBandwidth','CBW20');
stf=wlanLSTF(wifisignal);
result1=0;
result2=0;
for y = 1:100
s=sqrt(NoisePower/2)*(randn(1,1000)+1j*randn(1,1000));
s(501:660)=s(501:660)+stf.';
rho=zeros(1,800);
for i = 1:length(rho)
    rho(i)=s(i:i+79)*s(i+80:i+159)'/80;
end
[value2,index2]=max(abs(rho));
result1=(index2)/100+result1;
channel=[1 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
r=conv(s,channel);
rsignal=zeros(1,800);
for i = 1:length(rsignal)
    rsignal(i)=r(i:i+79)*r(i+80:i+159)'/80;
end
[value1,index1]=max(abs(rsignal));
result2=(index1)/100+result2;
end
result_multi=result2;
result_single=result1;
figure(1);
plot(abs(rsignal));
title('multipath')

figure(2);
plot(abs(rho));
title('LOS')


grid;
