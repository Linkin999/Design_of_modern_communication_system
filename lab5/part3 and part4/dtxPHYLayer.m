function dtxPHYLayer()

%Time Out
% to:  Timeout: The #iterations of the main loop to wait before exiting.
to  = uint32(8);  %------------------------------------------------------------------> 超时：Main循环退出前运行的次数

% toa: Timeout ACK: #iterations to wait for an ACK before resending DATA
toa = uint32(4);  %------------------------------------------------------------------> ACK超时：重传数据前等待ACK的次数

vm = logical(true(1));  %------------------------------------------------------------> 显示调试信息

retransmit_counter =0; %-------------------------------------------------------------> 重传计数器

numPackets = 20;  %------------------------------------------------------------------> 数据包发送总数
packet_number =20;  %----------------------------------------------------------------> 数据包序号

% c8f: Count of the Number of 802.11b Packets Sent
c8f = uint8(1);   %------------------------------------------------------------------> 指示当前发送数据包数量

% cai: Count #ACK Iterations: Counts #iter in which DTx is waiting for ACK
cai = uint16(0);  %------------------------------------------------------------------> 指示当前等待ACK次数 

% cni: Count #No-ACK Iterations: Counts #iter in which no ACK Rx'd 
cni = uint16(0);  %------------------------------------------------------------------> 指示当前未收到的ACK次数 

% cti: Count Total #Iterations: Countsc #iterations of main WHILE loop
cti = uint16(0);  %------------------------------------------------------------------> 指示当前While循环执行次数

% fe:  Terminal Flag to Signal End-of-Transmission (EOT) 
fe  = logical(false(1));   %---------------------------------------------------------> 循环结束标志

% fit: Flag Full Image Transmitted; program can exit after last ACK
fit = logical(false(1));   %---------------------------------------------------------> 完整图像传输结束标志

% frt: Flag Retransmit: On ACK timeout, retransmit last 802.11b frame again
frt = logical(false(1));   %---------------------------------------------------------> ACK超时，802.11b重传标志

% st:  State for Designated Transmitter (DTx): 3 Digits, 1st Dig=1 for DTx
%      2nd Digit is 1 for Det Energy, 2 for Transmit DATA, or 3 for Rx ACK
st  = uint8(uint8(111)); %-----------------------------------------------------------> 发射机当前状态：能量检测    

% vcsFlag = logical(false(1));   %---------------------------------------------------> 虚拟载波侦听
% vcs_Slots = 0;  

tic;
while ~fe         %------------------------------------------------------------------> 循环结束标志
    smt = st/uint8(10);         %----------------------------------------------------> 设置发射机起始状态：能量检测状态
    if (smt==uint8(11))   %----------------------------------------------------------> 如果发射机处于能量检测状态
        st = dtxMACLayerSlot(st,frt);    %-------------------------------------------> MAC层检测DIFS时间，下一个状态：发数据
    
        
    elseif (smt==uint8(15)) %DTxStateTransmitRTS  -----------------------------------> 发射机发送RTS
        f8t =  logical(true(1));  %--------------------------------------------------> RTS发送完成
        if (f8t)
            if (vm), fprintf(1,'@%5.2f: 802.11b RTS Packet Transmitted.\n',toc); %---> 输出RTS发送完成消息
            end
            st = uint8(161);   %-----------------------------------------------------> 转移到16状态
        end
    
        
    elseif (smt==uint8(16)) %prm.DTxStateRxCTS --------------------------------------> 发射机接收CTS
        faf = logical(true(1));  %---------------------------------------------------> 成功接收CTS
        if (faf)
            if (vm), fprintf(1,'@%5.2f: 802.11b CTS Packet Received.\n\n',toc); end
            st = uint8(121); %prm.DTxStateTransmitHeader  ---------------------------> 转移到数据发送状态
        else
            if (st~=151)
                % Increment count of #iterations with no CTS  
                cai = (cai+uint16(1)); cni = (cni+uint16(1));
                % If no CTS received within TOA iterations, resend this RTS frame
                if (cni>=toa)    %---------------------------------------------------> 如果长时间未收到CTS，重新发送RTS
                    cni = uint16(0);
                    if (vm)
                    fprintf(1,'@%5.2f: Timeout, No CTS Received in %d iterations, Retransmitting RTS...\n\n',toc,toa); 
                    end
                    retransmit_counter=retransmit_counter+1;
                    st = uint8(111); %prm.DTxStateEnergyDetDIFS
                    % Set flag to retransmit RTS again
                    frt = logical(true);  %-----------------------------------------> 设置重传标志
                end
            end
        end
        
        cti = (cti+uint16(1));  %---------------------------------------------------> 记录循环总次数
        % If no response from DRx received in TO iterations, then exit
        if (cai >= to)   %----------------------------------------------------------> 如果在TO时间内无反应，则退出
            if (vm)
                fprintf(1,'@%5.2f: Timeout, No CTS Received in %d iterations, Continue transmit RTS...\n',toc,to); 
            end
            retransmit_counter=retransmit_counter-1;
            if packet_number == numPackets
                % Change DTx State to Terminal State: no more Tx/Rx performed
                st = uint8(140); %prm.DTxStateEOT
                % Set exit flag
                fe  = logical(true(1));
            else
                %set state
                st  = uint8(111); %prm.DTxStateEnergyDetDIFS
                %set retransmit flag to false
                frt = logical(false(1));
                %resets counters
                cai = uint16(0); cni = uint16(0);
                % Increment count of #802.11B frames
                c8f = c8f + uint8(1);
             end
        end % END IF CTI>TO
    
        
    elseif (smt==uint8(12)) %prm.DTxStateTransmitDATA   %----------------------------------> 发射机发送数据
        
        f8t =  logical(true(1));    %------------------------------------------------------> 发送成功指示
        
        if (f8t)
            if (vm) 
               fprintf(1,'@%5.2f: 802.11b DATA Packet #%d Transmitted.\n',toc,c8f); 
            end
            st = uint8(131); %prm.DTxStateRxACK  %-----------------------------------------> 转移到下一个状态：接收ACK
        end
    
        
    elseif (smt==uint8(13)) %prm.DTxStateRxACK  %------------------------------------------> 发射机接收ACK
        
                faf = (randi(10) > 5);    %------------------------------------------------> 接收成功的概率为90%

        if (faf)    %----------------------------------------------------------------------> 如果接收成功
            % If ACK received, reset count of #iterations with no ACK
            cai = uint16(0); cni = uint16(0);  %-------------------------------------------> 如果接收成功，重置参数
            if (vm)
                fprintf(1,'@%5.2f: 802.11b ACK Packet #%d Received.\n\n',toc,c8f); 
            end
            % Increment count of #802.11b frames sxsfully transceived
            c8f = c8f + uint8(1);     %----------------------------------------------------> 数据包成功传输的次数+1
            if c8f==6                 %----------------------------------------------------> 6次后图像传输完成
               fit=true(1);
            end
            if (fit)
                % If ACK rx'd for last DATA frame & full image was tx'd,
                st = uint8(140); %prm.DTxStateEOT  %--------------------------------------> 图像传输完成后，空闲状态
                % Set exit flag
                fe = logical(true(1));   %------------------------------------------------> 退出While循环
            else
                st = uint8(111);   %------------------------------------------------------> 进入DIFS状态
            end
        else  %---------------------------------------------------------------------------> 如果接收未成功
            % Increment count of #iterations with no ACK
            cai = cai+uint16(1); 
            cni = cni+uint16(1);
            % If no ACK received within TOA iterations, resend this DATA frame
            if (cni >= toa)    %----------------------------------------------------------> ACK未接收超时，状态转移到DIFS
                % Reset no-ACK count
                cni = uint16(0);
                if (vm)
                  fprintf(1,'@%5.2f: Timeout, No ACK Received in %d iterations, Retransmitting DATA #%d...\n\n',toc,toa,c8f); 
                end
                retransmit_counter=retransmit_counter+1;
                st = uint8(111); %prm.DTxStateEnergyDetDIFS
                % Set flag to retransmit DATA
                frt = logical(true(1));   %-----------------------------------------------> 标识重传，该参数影响指数退避时间
            end
        end
    end % END IF DS
 
    cti = cti + uint16(1);         %-----------------------------------------------------> While循环次数+1
    % If no response from DRx received in TO iterations, then exit
    if (cai >= to)    %------------------------------------------------------------------> 请求重传后，仍然超时，退出。
        if (vm)
            fprintf(1,'@%5.2f: Timeout, No ACK Received in %d iterations, Continue transmit next frame...\n',toc,to);
        end
        retransmit_counter=retransmit_counter-1;
        if packet_number == numPackets  %------------------------------------------------> 最后一个数据包，将直接退出循环
            % Change DTx State to Terminal State: no more Tx/Rx performed
            st = uint8(140); %prm.DTxStateEOT
            % Set exit flag
            fe  = logical(true(1));
        else  %-------------------------------------------------------------------------> 否则重新发送
            %set state
            st  = uint8(111); %prm.DTxStateEnergyDetDIFS
            %set retransmit flag to false
            frt = logical(false(1));   %------------------------------------------------> 注意不是重传
            %resets counters
            cai = uint16(0); cni = uint16(0); 
            % Increment count of #802.11B frames
            c8f = c8f + uint8(1); 
        end
    end % END IF CTI>TO
end % END WHILE ~FE
