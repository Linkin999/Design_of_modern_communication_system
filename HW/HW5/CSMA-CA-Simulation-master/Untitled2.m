number = 200; % get number of nodes *
Packet_size = 2000 * 8; % get the packet size in bits % 
T = 1; % get simulation time in s %
Backoff_St = 5; % get the random backoff strategy %

utility=zeros(1,number);

for CW=1:number
    r = (randi([0,CW],N,1)) * 10^-6;
    [M,I] = min(r);
    counter=0;
    for i = 1:N   % check if there are more than one nodes with same minimum counter %
        if (M == r(i))
            counter = counter + 1;
        end
    end
    utility(CW)=counter/number;    
end


