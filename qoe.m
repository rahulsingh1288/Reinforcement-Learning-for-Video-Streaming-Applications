function [ qoe ] = qoe(  )  %returns combined qoe of all users
alpha = .1;
%alpha = learning rate
N=5 ;% no. of clients
B=50 ; % buffer size
p=2; % no. of power values
% q-values initialization
%% power level = 1 initialization 
Q=2*ones(N,B,p); 
%Q(1,1,1)=-10;Q(1,2,1)=-10;Q(1,3,1)=-10;Q(1,3,1) = 50;Q(1,4,1) =50;Q(1,5,1) = 50;
%%  power level = 2 initialization
%Q(1,3,2) = 100;Q(1,4,2) = 100;Q(1,5,2) = 100;
L = ones(N,1); % instantaneous buffer levels
T = 1000000; %horizon
M = 1;% no. of orthogonal channels 
qoe = 0;% keeps track of net combined qoe of all users till now
index = zeros(N,1);% indices of each clients
V=ones(N,B); % value function
V_delu = V; % stores partial V partial u
A=2*ones(N,B);%stores optimal action
ts = 5; % single packet play duration
P=[0 .7];% success probability for clients under power levels
P=repmat(P,N,1);
Vid_qual = [0 10];% actual quality of video frames
Vid_qual = repmat(Vid_qual,N,1);
ts=5;%playtime of a single pkt
for t=1:T
    alpha = 1/t;
    V;
    A;
    L;
%     if L>2
%         display('yes')
%     end
    alpha =.1;
%    if mod(t,ts)==0
        L= subplus(L-2*ones(N,1))+ones(N,1);
 %   end
    % compute value function for each state
    for client = 1:N
        for level = 1:B
            V(client,level) = max(Q(client,level,:));
             max(Q(client,level,:));
        end
    end
    % compute optimal action for each state
    for client = 1:N
        for level = 1:B
             [~,z] = max(Q(client,level,:));
            A(client,level) = z;
            z;
        end
    end
    % calculate partial V wrt u 
    for client = 1:N
        for level = 1:B
            level_up = min(level + ts,B);
            level_down = subplus(level-2)+1;
            V_delu(client,level) = V(client,level_up)-V(client,level_down);
        end
    end
     index = V_delu(1:numel(L),L);%stores whittle indices    
%    index = V(1:numel(L),L);%stores whittle indices
    [~,index_order] = sort(index,'descend');
    for m=1:M % implement index policy by picking M largest index clients
        client = index_order(m);
        x=L(client);
        del=0; % detects packet delivery 
        ins_cst=0;% declares channel state
        if L(client)==1 % check whether client has ongoing outage
            outage = -1;
        else
            outage =0;
        end
%       enter optimal action based on Q values
        pow_level = A(client,L(client));
        succ_pr = P(client,pow_level);
        %serve the client  
        c_sta = binornd(1,succ_pr);
        if c_sta==1           
            L(client) = min(L(client)+ts,B);%update state of client
            if L(client)-x>0
                del=1;
            else
                del = 0;
            end
        end
        del;
        %instantaneous cost,power,qoe and update total qoe
        ins_cst =  outage+ del*Vid_qual(client,2); 
        qoe = qoe + ins_cst;
        ins_cst;
        %update Q value of client using ins_cst
        Q(client,x,pow_level)...
            =  Q(client,x,pow_level)*(1-alpha)+alpha*(ins_cst+V(client,L(client)));      
    end
end
Q;
qoe = qoe/T
