%% 802.11 MAC��Э�����
clc; clear;

fix(clock)   %-----------------------------------------------------------------------> ��ʾʱ����Ϣ

start=clock;
      dtxPHYLayer
stop=clock;

totaltime=etime(stop,start); %-------------------------------------------------------> ͳ�����ĵ�ʱ��
throughput=1/totaltime;
