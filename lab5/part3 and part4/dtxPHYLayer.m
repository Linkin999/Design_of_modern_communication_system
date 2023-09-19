function dtxPHYLayer()

%Time Out
% to:  Timeout: The #iterations of the main loop to wait before exiting.
to  = uint32(8);  %------------------------------------------------------------------> ��ʱ��Mainѭ���˳�ǰ���еĴ���

% toa: Timeout ACK: #iterations to wait for an ACK before resending DATA
toa = uint32(4);  %------------------------------------------------------------------> ACK��ʱ���ش�����ǰ�ȴ�ACK�Ĵ���

vm = logical(true(1));  %------------------------------------------------------------> ��ʾ������Ϣ

retransmit_counter =0; %-------------------------------------------------------------> �ش�������

numPackets = 20;  %------------------------------------------------------------------> ���ݰ���������
packet_number =20;  %----------------------------------------------------------------> ���ݰ����

% c8f: Count of the Number of 802.11b Packets Sent
c8f = uint8(1);   %------------------------------------------------------------------> ָʾ��ǰ�������ݰ�����

% cai: Count #ACK Iterations: Counts #iter in which DTx is waiting for ACK
cai = uint16(0);  %------------------------------------------------------------------> ָʾ��ǰ�ȴ�ACK���� 

% cni: Count #No-ACK Iterations: Counts #iter in which no ACK Rx'd 
cni = uint16(0);  %------------------------------------------------------------------> ָʾ��ǰδ�յ���ACK���� 

% cti: Count Total #Iterations: Countsc #iterations of main WHILE loop
cti = uint16(0);  %------------------------------------------------------------------> ָʾ��ǰWhileѭ��ִ�д���

% fe:  Terminal Flag to Signal End-of-Transmission (EOT) 
fe  = logical(false(1));   %---------------------------------------------------------> ѭ��������־

% fit: Flag Full Image Transmitted; program can exit after last ACK
fit = logical(false(1));   %---------------------------------------------------------> ����ͼ���������־

% frt: Flag Retransmit: On ACK timeout, retransmit last 802.11b frame again
frt = logical(false(1));   %---------------------------------------------------------> ACK��ʱ��802.11b�ش���־

% st:  State for Designated Transmitter (DTx): 3 Digits, 1st Dig=1 for DTx
%      2nd Digit is 1 for Det Energy, 2 for Transmit DATA, or 3 for Rx ACK
st  = uint8(uint8(111)); %-----------------------------------------------------------> �������ǰ״̬���������    

% vcsFlag = logical(false(1));   %---------------------------------------------------> �����ز�����
% vcs_Slots = 0;  

tic;
while ~fe         %------------------------------------------------------------------> ѭ��������־
    smt = st/uint8(10);         %----------------------------------------------------> ���÷������ʼ״̬���������״̬
    if (smt==uint8(11))   %----------------------------------------------------------> �������������������״̬
        st = dtxMACLayerSlot(st,frt);    %-------------------------------------------> MAC����DIFSʱ�䣬��һ��״̬��������
    
        
    elseif (smt==uint8(15)) %DTxStateTransmitRTS  -----------------------------------> ���������RTS
        f8t =  logical(true(1));  %--------------------------------------------------> RTS�������
        if (f8t)
            if (vm), fprintf(1,'@%5.2f: 802.11b RTS Packet Transmitted.\n',toc); %---> ���RTS���������Ϣ
            end
            st = uint8(161);   %-----------------------------------------------------> ת�Ƶ�16״̬
        end
    
        
    elseif (smt==uint8(16)) %prm.DTxStateRxCTS --------------------------------------> ���������CTS
        faf = logical(true(1));  %---------------------------------------------------> �ɹ�����CTS
        if (faf)
            if (vm), fprintf(1,'@%5.2f: 802.11b CTS Packet Received.\n\n',toc); end
            st = uint8(121); %prm.DTxStateTransmitHeader  ---------------------------> ת�Ƶ����ݷ���״̬
        else
            if (st~=151)
                % Increment count of #iterations with no CTS  
                cai = (cai+uint16(1)); cni = (cni+uint16(1));
                % If no CTS received within TOA iterations, resend this RTS frame
                if (cni>=toa)    %---------------------------------------------------> �����ʱ��δ�յ�CTS�����·���RTS
                    cni = uint16(0);
                    if (vm)
                    fprintf(1,'@%5.2f: Timeout, No CTS Received in %d iterations, Retransmitting RTS...\n\n',toc,toa); 
                    end
                    retransmit_counter=retransmit_counter+1;
                    st = uint8(111); %prm.DTxStateEnergyDetDIFS
                    % Set flag to retransmit RTS again
                    frt = logical(true);  %-----------------------------------------> �����ش���־
                end
            end
        end
        
        cti = (cti+uint16(1));  %---------------------------------------------------> ��¼ѭ���ܴ���
        % If no response from DRx received in TO iterations, then exit
        if (cai >= to)   %----------------------------------------------------------> �����TOʱ�����޷�Ӧ�����˳�
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
    
        
    elseif (smt==uint8(12)) %prm.DTxStateTransmitDATA   %----------------------------------> �������������
        
        f8t =  logical(true(1));    %------------------------------------------------------> ���ͳɹ�ָʾ
        
        if (f8t)
            if (vm) 
               fprintf(1,'@%5.2f: 802.11b DATA Packet #%d Transmitted.\n',toc,c8f); 
            end
            st = uint8(131); %prm.DTxStateRxACK  %-----------------------------------------> ת�Ƶ���һ��״̬������ACK
        end
    
        
    elseif (smt==uint8(13)) %prm.DTxStateRxACK  %------------------------------------------> ���������ACK
        
                faf = (randi(10) > 5);    %------------------------------------------------> ���ճɹ��ĸ���Ϊ90%

        if (faf)    %----------------------------------------------------------------------> ������ճɹ�
            % If ACK received, reset count of #iterations with no ACK
            cai = uint16(0); cni = uint16(0);  %-------------------------------------------> ������ճɹ������ò���
            if (vm)
                fprintf(1,'@%5.2f: 802.11b ACK Packet #%d Received.\n\n',toc,c8f); 
            end
            % Increment count of #802.11b frames sxsfully transceived
            c8f = c8f + uint8(1);     %----------------------------------------------------> ���ݰ��ɹ�����Ĵ���+1
            if c8f==6                 %----------------------------------------------------> 6�κ�ͼ�������
               fit=true(1);
            end
            if (fit)
                % If ACK rx'd for last DATA frame & full image was tx'd,
                st = uint8(140); %prm.DTxStateEOT  %--------------------------------------> ͼ������ɺ󣬿���״̬
                % Set exit flag
                fe = logical(true(1));   %------------------------------------------------> �˳�Whileѭ��
            else
                st = uint8(111);   %------------------------------------------------------> ����DIFS״̬
            end
        else  %---------------------------------------------------------------------------> �������δ�ɹ�
            % Increment count of #iterations with no ACK
            cai = cai+uint16(1); 
            cni = cni+uint16(1);
            % If no ACK received within TOA iterations, resend this DATA frame
            if (cni >= toa)    %----------------------------------------------------------> ACKδ���ճ�ʱ��״̬ת�Ƶ�DIFS
                % Reset no-ACK count
                cni = uint16(0);
                if (vm)
                  fprintf(1,'@%5.2f: Timeout, No ACK Received in %d iterations, Retransmitting DATA #%d...\n\n',toc,toa,c8f); 
                end
                retransmit_counter=retransmit_counter+1;
                st = uint8(111); %prm.DTxStateEnergyDetDIFS
                % Set flag to retransmit DATA
                frt = logical(true(1));   %-----------------------------------------------> ��ʶ�ش����ò���Ӱ��ָ���˱�ʱ��
            end
        end
    end % END IF DS
 
    cti = cti + uint16(1);         %-----------------------------------------------------> Whileѭ������+1
    % If no response from DRx received in TO iterations, then exit
    if (cai >= to)    %------------------------------------------------------------------> �����ش�����Ȼ��ʱ���˳���
        if (vm)
            fprintf(1,'@%5.2f: Timeout, No ACK Received in %d iterations, Continue transmit next frame...\n',toc,to);
        end
        retransmit_counter=retransmit_counter-1;
        if packet_number == numPackets  %------------------------------------------------> ���һ�����ݰ�����ֱ���˳�ѭ��
            % Change DTx State to Terminal State: no more Tx/Rx performed
            st = uint8(140); %prm.DTxStateEOT
            % Set exit flag
            fe  = logical(true(1));
        else  %-------------------------------------------------------------------------> �������·���
            %set state
            st  = uint8(111); %prm.DTxStateEnergyDetDIFS
            %set retransmit flag to false
            frt = logical(false(1));   %------------------------------------------------> ע�ⲻ���ش�
            %resets counters
            cai = uint16(0); cni = uint16(0); 
            % Increment count of #802.11B frames
            c8f = c8f + uint8(1); 
        end
    end % END IF CTI>TO
end % END WHILE ~FE
