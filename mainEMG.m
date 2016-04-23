function [cell_cmd_plot]=mainEMG(canais_avaliar,canal_ext,canal_flex,cell_sinais,cell_acel,voluntario,tipoclass,tipodet)
    %canais_reais:canais que deseja pesquisar
    %canal_ext:canal a ser considerado principal para movimento de extensao
    %canal_flex: canal a ser considerado principal para movimento de flexao
    path_fig='C:\Users\rafaelacunha\Documents\repositorios\figuras_final_10';
    %% inicializa variaveis
    N=200; %numero de amostras(pontos) por trecho.
    M=5; %numero de trechos a serem utilizados para o calculo da TFE.
    fs=2000;  %frequencia de amostragem
    res_esp=fs/N; %resolucao espectral
    frinicial=70/res_esp;%18
    frfinal=110/res_esp;%25
    ndet_min=3; %minimo de janelas seguidas indicando ativacao muscular no musculo agonista para que a classificacao se confirme
    lcanais=length(canais_avaliar);
    lim_det=[];
    %% chama funcao de treinamento
   if tipodet=='TFE',
        [param1,param2]=trainingEMG(fs,canais_avaliar,M,N,frinicial,frfinal,cell_sinais,cell_acel,tipoclass,tipodet,path_fig,voluntario);
   else 
       [param1,param2,lim_det]=trainingEMG(fs,canais_avaliar,M,N,frinicial,frfinal,cell_sinais,cell_acel,tipoclass,tipodet,voluntario);
   end
    %Para TFE: param1=limiar,param2=maior
    %Para LDA: param1=Tr, param2=Gr

    %% inicia classificacao online
    P=M*N*2;

    v_ndet_min=ones(1,ndet_min);
    s_rel=0;
    cell_cmd_plot=cell(1,2);
   
    for isinal=1:2,
        if isinal==1, %determina o canal de teste apenas para ser plotado
           canal_teste=canal_ext;
        else canal_teste=canal_flex;
        end 
        sinais=cell_sinais{isinal+2}(canais_avaliar,:);
        %% inicializa variaveis de classificacao
        cmd_final=[zeros(1,N*(2*M-1))];%amostras iniciais n�o podem ser classificadas, portanto recebem 0.
        cmd_plot=[zeros(1,2*M-1)];%janelas iniciais n�o podem ser classificadas, portanto recebem 0.
        v_det_final=[];
        res_vetor=[];
        %% realiza a classificacao janela a janela (cada uma com N amostras)
        for i=P+1:N:length(sinais),
            [v_det,resultado]=onlineEMG(fs,sinais(:,i-P:i-1),frinicial,frfinal,param1,param2,M,N,tipoclass,tipodet,lim_det);
            v_det_final=[v_det_final v_det];
            cmd=0;
            res=0;
            if size(v_det_final,2)>=8,
               %if ((v_det_final(canal_ext,end-(ndet_min-1):end)==v_ndet_min & comando==1) |(v_det_final(canal_flex,end-(ndet_min-1):end)==v_ndet_min & comando==2)),
                if ((v_det_final(canal_ext,end)==1 & resultado==1) |(v_det_final(canal_flex,end)==1 & resultado==2)),  
                    res=resultado;
                 
                else if (s_rel==1&(v_det_final(canal_ext,end)==-1)|(s_rel==2&(v_det_final(canal_flex,end)==-1))),
                        res=-1;
                     end 
                    %cmd=comando;
                    %else if (cmd_plot(end-1)==1 || cmd_plot(end-1)==2),
%                     else if ((v_det_final(canal_ext,end)==-1)||(v_det_final(canal_flex,end)==-1)),
%                        %cmd=-1; %desativa��o muscular
%                             res=-1;
%                         end
                end
            end
                 
            res_vetor=[res_vetor res];
            if length(res_vetor)>=ndet_min,
%                 if (res_vetor(end-ndet_min+1:end)==(-1*ones(1,ndet_min))),
%                     s_rel=0;
%                 end
                if diff(res_vetor(end-ndet_min+1:end))==zeros(1,ndet_min-1),
                    cmd=res;
                end
                if (cmd==1|cmd==2),
                   s_rel=cmd;
                end
            end
            final=[cmd_final cmd*ones(1,N)];
            cmd_plot=[cmd_plot cmd];
        end

        %% Reune os resultados da analise offline para serem visualizados/analisados
        cell_cmd_plot{1,isinal}=cmd_plot;
        fs=2000;
        vt=0:1/fs:(length(sinais)-1)/fs;
        corr=length(vt)-length(cmd_final);
        cmd_final=[cmd_final 0*ones(1,corr)];
        %% plota os sinais junto com os resultados do detector (verde:extensao,vermelho:flexao,amarelo:relaxamento)
        pos_flex=find(cmd_plot==2)*N-(N-1);
        pos_ext=find(cmd_plot==1)*N-(N-1);
        pos_desativ=find(cmd_plot==-1)*N-(N-1);
        vetor0=zeros(1,length(sinais));
        pos_mov=cell_acel{isinal+2}.mov-2*N; %plota duas janelas antes da janela do acelerometro para seguir o criterio do assessment
        pos_rel=cell_acel{isinal+2}.rel-2*N;
        figura=figure;
        plot(vt,sinais(canal_teste,:),'-b');
        hold on
        plot(pos_flex/fs,vetor0(pos_flex),'ks','MarkerFaceColor','r');
        hold on
        plot(pos_ext/fs,vetor0(pos_ext),'ks','MarkerFaceColor','g');
        hold on
        plot(pos_desativ/fs,vetor0(pos_desativ),'ks','MarkerFaceColor','y');
        hold on
        plot(pos_mov/fs,vetor0(pos_mov),'ko','MarkerFaceColor','m');
        hold on
        plot(pos_rel/fs,vetor0(pos_rel),'ko','MarkerFaceColor','g');
        if isempty(pos_ext)==1,
            legend('Sinal EMG','Flexao','Relaxamento')
        else if isempty(pos_flex)==1,
                legend('Sinal EMG','Extensao','Relaxamento')
            else if isempty(pos_desativ)==1,
                legend('Sinal EMG','Flexao','Extensao')
                else  legend('Sinal EMG','Flexao','Extensao','Relaxamento')
                end
            end
        end
        xlabel('Tempo[s]','FontSize',14)
        ylabel('Amplitude [V]','FontSize',14)
        set(gca,'FontSize',14)
        if isinal==1,
            str_mov='ext'
        else str_mov='flex';
        end
        nome_fig=strcat(voluntario,'_',tipoclass,'_',tipodet,'_',int2str(canais_avaliar),'_',str_mov);
        saveas(figura,char(fullfile(path_fig,nome_fig)),'fig');
        vetor_teste=canal_teste*ones(1,5);
    end
end

