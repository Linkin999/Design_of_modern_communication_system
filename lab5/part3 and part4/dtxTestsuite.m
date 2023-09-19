%% 802.11 MAC层协议仿真
clc; clear;

fix(clock)   %-----------------------------------------------------------------------> 显示时钟信息

start=clock;
      dtxPHYLayer
stop=clock;

totaltime=etime(stop,start); %-------------------------------------------------------> 统计消耗的时间
throughput=1/totaltime;
