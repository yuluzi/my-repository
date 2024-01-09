function [ThreeSystemBERNum , ThreeSystemFERNum ,FourSystemBERNum , FourSystemFERNum,FiveSystemBERNum , FiveSystemFERNum, ...
    ThreeSystemBER ,ThreeSystemFER, FourSystemBER ,FourSystemFER, FiveSystemBER,FiveSystemFER, TotalExecutorsBERNum , TotalExecutorsFERNum ,...
    TotalExecutorsBER , TotalExecutorsFER ,  EachFrameExecutorsBERs] =  ...
    SingleSNRSimulationAttack2(N,K,ebn0,total_frame_num,max_frame_num,construction_method,   ...
    bp_iter_num,scan_iter_num,scl_list_size,crc_size,decoder_tree_initial, G_set, B_set)
%     SC_decoder_conditions , BP_decoder_conditions , SCAN_decoder_conditions ,SCL_decoder_conditions , SSC_decoder_conditions

%SingleSNRSimulationDHR 此处显示有关此函数的摘要
%   执行体按照执行最大帧数出错概率为error_factor发生随随机故障


% r = a + (b-a)*rand(m,n) = 0.3 + （1 - 0.3）* rand(1)
    ThreeSystemBERNum = 0;
    ThreeSystemFERNum = 0;

    FourSystemBERNum = 0;
    FourSystemFERNum = 0;

    FiveSystemBERNum = 0;
    FiveSystemFERNum = 0;
    
%     SystemBERNum = 0;
%     SystemFERNum = 0;
    design_snr_dB = 0;%使用BA构造方法构造极坐标代码的参数
    sigma = 0.9;%使用GA构造方法构造极坐标代码的参数



    
    IsContinue = true;
    current_total_frame_num = 0;
    
    ExecutorConditions = zeros(5,2);%用于存储各个执行体当前运行状态 -1/0/1  -1：故障   0：不在运行   1：在运行
    %第一列当前运行状态  其余列暂未用上
%     SC_decoder_conditions = zeros(1,total_frame_num);
%     BP_decoder_conditions = zeros(1,total_frame_num);
%     SCAN_decoder_conditions = zeros(1,total_frame_num);
%     SCL_decoder_conditions = zeros(1,total_frame_num);
%     SSC_decoder_conditions = zeros(1,total_frame_num);

    %选择一个被攻击执行体
    rand_executor = randperm(5,1);
    
    ExecutorNames = ["1.SC decoder","2.BP decoder","3.SCAN decoder","4.SCL decoder","5.SSC decoder"];%存取每个执行体名称
    
    TotalExecutorsBERNum = zeros(5,length(ebn0));%存取各个执行体在不同的信噪比条件下执行完所有帧后的的误码数
    % 例如：TotalExecutorsBERNum(executors(1),ebn0(1)) 代表第一个执行体在第一个信噪比条件下执行后得到的误码数
    
    TotalExecutorsFERNum = zeros(5,length(ebn0));%存取各个执行体在不同的信噪比条件下执行完所有帧后的的误帧数
    % 例如：TotalExecutorsFERNum(executors(1),ebn0(1)) 代表第一个执行体在第一个信噪比条件下执行后得到的误帧数
    
    TotalExecutorsBER = zeros(5,length(ebn0));%存取各个执行体在不同的信噪比条件下执行完所有帧后的的误码率
    % 例如：TotalExecutorsBER(executors(1),ebn0(1)) 代表第一个执行体在第一个信噪比条件下执行后得到的误码率
    
    TotalExecutorsFER = zeros(5,length(ebn0));%存取各个执行体在不同的信噪比条件下执行完所有帧后的的误帧率
    % 例如：TotalExecutorsFER(executors(1),ebn0(1)) 代表第一个执行体在第一个信噪比条件下执行后得到的误帧率
    
    EachFrameExecutorsBERs = zeros(6,K); %存取每个执行体在各个帧下的误码率 最后一个是dhr


    while IsContinue
        if current_total_frame_num>=total_frame_num
            break;
        else
%             ExecutorsBERNum = zeros(5,length(ebn0));%存取各个执行体在不同的信噪比条件下执行的误码数
%             % 例如：ExecutorsBER(executors(1),ebn0(1)) 代表第一个执行体在第一个信噪比条件下执行后得到的误码数
%             
%             ExecutorsFERNum = zeros(5,length(ebn0));%存取各个执行体在不同的信噪比条件下执行的误帧数
%             % 例如：ExecutorsBER(executors(1),ebn0(1)) 代表第一个执行体在第一个信噪比条件下执行后得到的误帧数
%             
%             ExecutorsBER = zeros(5,length(ebn0));%存取各个执行体在不同的信噪比条件下执行的误码率
%             % 例如：ExecutorsBER(executors(1),ebn0(1)) 代表第一个执行体在第一个信噪比条件下执行后得到的误码率
%             
%             ExecutorsFER = zeros(5,length(ebn0));%存取各个执行体在不同的信噪比条件下执行的误帧率
%             % 例如：ExecutorsBER(executors(1),ebn0(1)) 代表第一个执行体在第一个信噪比条件下执行后得到的误帧率

            executors = [1,2,3,4,5];%对比试验执行体集

            % 选取3个执行体构成执行体集合
            executornum = 3; %input('请输入需要选取的执行体数量（请请输入最小为1，最大为5的正整数）：');
            [DHRExecutors,ExecutorConditions] = SwichExecutor(ExecutorConditions,executornum);   
            
            

            for l = current_total_frame_num + 1 : current_total_frame_num + max_frame_num
                
%                 fprintf('\n Now running:%f  [%d of %d] \n\t Iteration-Counter: %53d',ebn0(j),j,length(ebn0),0);
%                 tt=tic();%用于启动一个计时器以测量代码的执行时间。返回值tt是一个计时器对象，用于停止计时器并计算经过的时间 

                %每次先生成信息序列，然后执行，使每个执行体执行相同的信息序列
                u = randi(2,1,K)-1; %Bernoulli(0.5);  伯努利分布 生成一个长度为K的随机二进制序列（0或1），每个元素的取值都是等概率的
                u_executors = zeros(5,K);

                %每个帧/块需要每个执行体都执行一次
                for ii = 1:length(executors)
                    
                    switch executors(ii)
                        case 1

                            crc_size = 0;
                            initPC(N,K,construction_method,design_snr_dB,sigma,crc_size);
                        case 2

                            crc_size = 0;
                            initPC(N,K,construction_method,design_snr_dB,sigma,crc_size);
                        case 3

                            crc_size = 0;
                            initPC(N,K,construction_method,design_snr_dB,sigma,crc_size);
                        case 4

                            initPC(N,K,construction_method,design_snr_dB,sigma,crc_size);
                        case 5

                            crc_size = 0;
                            initPC(N,K,construction_method,design_snr_dB,sigma,crc_size);
                        otherwise

                            bp_iter_num = 60;
                            scan_iter_num = 8;
                            scl_list_size = 4;
                            crc_size = 0;
                    end
                    
                    %生成随机攻击时间数组
                    attack_frame = round(total_frame_num * rand(1));


                    [TotalExecutorsBERNum(executors(ii),1),TotalExecutorsFERNum(executors(ii),1),u_executors(ii,:)] = ...
                            RunABlock2(N,K,u,executors(ii),ebn0,TotalExecutorsBERNum(executors(ii),1),TotalExecutorsFERNum(executors(ii),1),...
                        bp_iter_num,scan_iter_num,scl_list_size,decoder_tree_initial, G_set, B_set, attack_frame, l, rand_executor);

                    %计算误码数和误帧数
                    if l == current_total_frame_num + max_frame_num
                        fprintf(' \n异构执行体：%7s   在码率为：%7d ，信噪比为：%7d  的环境下从第%7d 个块执行到第%7d 个块的总误码数为：%7d ',ExecutorNames(executors(ii)),K/N,ebn0,l-max_frame_num+1,l,TotalExecutorsBERNum(executors(ii),1));
                        fprintf(' \n异构执行体：%7s   在码率为：%7d ，信噪比为：%7d  的环境下从第%7d 个块执行到第%7d 个块的总误帧数为：%7d ',ExecutorNames(executors(ii)),K/N,ebn0,l-max_frame_num+1,l,TotalExecutorsFERNum(executors(ii),1));
%                             fprintf('\n\t Total time taken: %.2f sec (%d samples)',toc(tt),l);
                        fprintf('\n');
                    end


                    
                    %每次执行一个帧，计算每个执行体在不同信噪比下的BER、FER
%                     if l == current_total_frame_num + max_frame_num
                        %求出每个执行体执行所有帧后的总BERNum、FERNum
%                         TotalExecutorsBERNum(executors(ii),1) = TotalExecutorsBERNum(executors(ii),1);
%                         TotalExecutorsFERNum(executors(ii),1) = TotalExecutorsFERNum(executors(ii),1);
%                         ExecutorsBER(executors(ii),1) = TotalExecutorsBERNum(executors(ii),1)/(K*l);
%                         ExecutorsFER(executors(ii),1) = TotalExecutorsFERNum(executors(ii),1)/l;
                        %得到每个执行体执行所有帧后的总BER、FER
                        TotalExecutorsBER(executors(ii),1) = TotalExecutorsBERNum(executors(ii),1)/(K*l);
                        TotalExecutorsFER(executors(ii),1) = TotalExecutorsFERNum(executors(ii),1)/l;
%                     end

                    EachFrameExecutorsBERs(executors(ii),l) = TotalExecutorsBER(executors(ii),1);
                    
                end
                
                

                %裁决 对比 u_executors和u
                %3余度dhr
                Three_u_executors = u_executors(DHRExecutors,:);
                u_System = mode(Three_u_executors,1);
                %计算每一帧系统误码数
                nfails = sum(u_System ~= u);
                ThreeSystemBERNum = ThreeSystemBERNum + nfails;
                ThreeSystemFERNum = ThreeSystemFERNum + (nfails>0);
                ThreeSystemBER = ThreeSystemBERNum/(l*K);
                ThreeSystemFER = ThreeSystemFERNum/l;
                EachFrameExecutorsBERs(6,l) = ThreeSystemBER;

                %4余度dhr
                %找到剩余执行体
                temp_executors = executors( ~ismember(executors,DHRExecutors) );
                temp_executors = temp_executors(2);
                temp_executors = [DHRExecutors,temp_executors];
                Four_u_executors = u_executors(temp_executors,:);
                u_System = mode(Four_u_executors,1);
                %计算每一帧系统误码数
                nfails = sum(u_System ~= u);
                FourSystemBERNum = FourSystemBERNum + nfails;
                FourSystemFERNum = FourSystemFERNum + (nfails>0);
                FourSystemBER = FourSystemBERNum/(l*K);
                FourSystemFER = FourSystemFERNum/l;
                EachFrameExecutorsBERs(7,l) = FourSystemBER;

                %5余度dhr
                u_System = mode(u_executors,1);
                %计算每一帧系统误码数
                nfails = sum(u_System ~= u);
                FiveSystemBERNum = FiveSystemBERNum + nfails;
                FiveSystemFERNum = FiveSystemFERNum + (nfails>0);
                FiveSystemBER = FiveSystemBERNum/(l*K);
                FiveSystemFER = FiveSystemFERNum/l;
                EachFrameExecutorsBERs(8,l) = FiveSystemBER;

                
%                 % 画图
%                 semilogy(l,SystemBER,'m-s','LineWidth',1.5,'MarkerSize',6)
%                 hold on;
%                 semilogy(l,TotalExecutorsBER(1,1),'b-*','LineWidth',1.5,'MarkerSize',6)
%                 hold on;
%                 semilogy(l,TotalExecutorsBER(2,1),'g-d','LineWidth',1.5,'MarkerSize',6)
%                 hold on;
%                 semilogy(l,TotalExecutorsBER(3,1),'c-s','LineWidth',1.5,'MarkerSize',6)
%                 hold on;
%                 semilogy(l,TotalExecutorsBER(4,1),'r-.','LineWidth',1.5,'MarkerSize',6)
%                 hold on;
%                 semilogy(l,TotalExecutorsBER(5,1),'k-p','LineWidth',1.5,'MarkerSize',6)
%                 hold on;
                
            
            end

%             title('码率：',K/N);
%             xlabel('已执行帧数')
%             ylabel('误码率(BER)')
%             legend('FER of DHR polar decoder','FER of SC polar decoder','FER of BP polar decoder' ,...
%             'FER of SCAN polar decoder','FER of SCL polar decoder','FER of SSC polar decoder')
%             hold on;
            
            %所有执行体执行完一轮（max_frame_num）后，比较被选出的执行体的BER和FER，并选最好的作为系统的结果,最差的下次不被选用
            [MINBERs,MINBERExecutors] = GetMinBER(length(DHRExecutors),TotalExecutorsBERNum,ebn0,DHRExecutors,ExecutorNames);
            [MINFERs,MINFERExecutors] = GetMinFER(length(DHRExecutors),TotalExecutorsFERNum,ebn0,DHRExecutors,ExecutorNames);
            [MAXBERs,MAXBERExecutors] = GetMaxBER(length(DHRExecutors),TotalExecutorsBERNum,ebn0,DHRExecutors,ExecutorNames);
            [MAXFERs,MAXFERExecutors] = GetMaxFER(length(DHRExecutors),TotalExecutorsFERNum,ebn0,DHRExecutors,ExecutorNames);
            fprintf(' \n异构执行体：%7s   不会在下一轮执行体选取中被选中 ',ExecutorNames(MAXBERExecutors));
            
            %ExecutorConditions全部清零，以便下次选取
            for i = 1:5
                ExecutorConditions(i,1) = 0;
            end

            if MINBERExecutors ~= MAXBERExecutors %排除误码数为0时剔除一个异构体
                ExecutorConditions(MAXBERExecutors,1) = 1;
            end

            %计算系统的误码总数和误帧总数
%             SystemBERNum = SystemBERNum + MINBERs;
%             SystemFERNum = SystemFERNum + MINFERs;
%             SystemBER = SystemBERNum/((current_total_frame_num+max_frame_num)*K);
%             SystemFER = SystemFERNum/(current_total_frame_num+max_frame_num);
    
    
            current_total_frame_num = current_total_frame_num + max_frame_num;
    
        end
       
    end





end

