function st = dtxMACLayerSlot(st,frt)
% dtxMACLayerSlot: Wait DIFS and Random Backoff Time while performing Energy Detection

% st:  State for Designated Transmitter (DTx): 3 Digits, 1st Dig=1 for DTx
%      2nd Digit is 1 for Det Energy, 2 for Transmit DATA, or 3 for Rx ACK
% frt: Flag Retransmit: On ACK timeout, retransmit last 802.11b frame again
% k: Random Backoff Duration Exponent

% trx: Function Handle to transceive() function for this IP Address
% BEB_Choice: Perform Binary Exponential Backoff (BEB) Or Binary Linear Backoff (BLB)?
%             1: BEB; 0: BLB
% cMin: minimum contention window size
% BEB_Slots: Random Back-off Window Size
% vcsFlag: Flag set to indicate whether channel is reserved using RTS/CTS
% vcs_Slots: # Slot-times the channel is reserved using RTS/CTS
% vcsChoice: User picks either DATA/ACK exchanges or RTS/CTS/DATA/ACK exchanges


%DIFS = 2.5 Slots as per the 802.11b standard
DIFS_Slots = 3;  %-------------------------------------------------------------------------------> 设置DIFS时隙

%cmin: minimum contention window size
cMin = 31; %-------------------------------------------------------------------------------------> 设置竞争窗口
    
%Energy Threshold  
energyThreshold = 10;  %-------------------------------------------------------------------------> 设置能量检测门限

% vm:  Verbose Mode
vm  = logical(true(1));  %-----------------------------------------------------------------------> 打开调试信息输出
    
% set flag for virtual carrier sensing  
vcsChoice = logical(false(1));  %----------------------------------------------------------------> 虚拟载波侦听

%Slot-times the channel is reserved using RTS/CTS
vcs_Slots = 3;  %--------------------------------------------------------------------------------> 虚拟载波侦听

%Perform Binary Exponential Backoff (BEB) Or Binary Linear Backoff (BLB)?
BEB_Choice = 1; % 1: BEB; 0: BLB  %--------------------------------------------------------------> 指数退避还是线性退避

% Max Retransmit
numMaxRetransmit = 3;  %-------------------------------------------------------------------------> 设置最大重传次数

% vcsFlag: Flag set to indicate whether channel is reserved using RTS/CTS
vcsFlag = 0;  %----------------------------------------------------------------------------------> 是否为RTS/CTS

k=uint8(2);   %----------------------------------------------------------------------------------> 冲突次数
if (frt == 1) && (vcsFlag == 1)
    k=uint8(min(k+1,numMaxRetransmit));
end

if BEB_Choice == 1  %----------------------------------------------------------------------------> 指数退避
    BEB_Slots = randi((2^(k))-1)*cMin;
else
    BEB_Slots = randi((2*(k))-1)*cMin;
end

if (vcsFlag == 0)  %-----------------------------------------------------------------------------> 不启用RTS/CTS机制
    if(st==uint8(111))
        if(vm), fprintf('Entering DIFS state..\n');end%------------------------------------------> 进入DIFS 状态
            SlotCount=1;
        while SlotCount<DIFS_Slots %-------------------------------------------------------------> 循环检测DIFS_Slots时间
            df=rand(1,25); %--------------------------------------------------------------------->13%的概率信道忙
          if (sum(abs(df).^2)>energyThreshold) %------------------------------------------------->检测到信道忙
              if(vm), fprintf('Energy detected in DIFS state, Backing off!!\n');end
              SlotCount=1; %--------------------------------------------------------------------->开始退避
          end 
            SlotCount=SlotCount+1;
        end
            if(vm),fprintf('... DIFS ends.\n');end
    end
    
    if(vm),fprintf('Entering Random Backoff state..\n');end
    
        SlotCount=1;
    while SlotCount<BEB_Slots
          df=rand(1,25); %----------------------------------------------------->13%的概率信道忙
          if(sum(abs(df).^2)>energyThreshold)%--------------------------------->检测到信道忙
              if(vm),fprintf('Energy detected in Random Backoff state, Backing off!!\n\n');end
              BEB_FreezeSlot=SlotCount;
              SlotCount=1;
              BEB_Slots=BEB_Slots-BEB_FreezeSlot;%----------------------------->下次总退避时间减少
          end
            SlotCount=SlotCount+1;
    end    
    if (vm), fprintf('...Random Backoff ends.\n'); end
else
    %Virtual Carrier Sensing
    SlotCount = 1;
    if (vcsFlag == 1)
        while SlotCount < vcs_Slots         
            SlotCount = SlotCount+1;
        end
        if (vm), fprintf('Defered Medium Access for NAV Duration - Exiting VCS!!\n'); end
    end
end

if (vcsChoice == 1)
    st = uint8(151); % Virtual Carrier Sensing;  %--------------------------------------------> 启用虚拟载波侦听
else
    st=uint8(121); % No Virtual Carrier Sensing; %--------------------------------------------> 不启用虚拟载波侦听
end

end











