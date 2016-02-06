function [cell_cmd_plot]=mainEMG_todos(canais_reais,canal_ext,canal_flex,cell_sinais,cell_acel,voluntario,tipoclass,tipodet)
    %canais_reais:canais que deseja pesquisar
    %canal_ext:canal a ser considerado principal para movimento de extensao
    %canal_flex: canal a ser considerado principal para movimento de flexao

    %% inicializa variaveis
    N=200; %numero de amostras(pontos) por trecho.
    M=5; %numero de trechos a serem utilizados para o calculo da TFE.
    frinicial=7;%18
    frfinal=12;%25
    frinicial2=18;%7
    frfinal2=25;%12
    fs=2000;  %frequencia de amostragem
    ndet_min=5; %minimo de janelas seguidas indicando ativacao muscular no musculo agonista para que a classificacao se confirme
    lcanais=length(canais_reais);
    %% chama funcao de treinamento
   
    [limiar_TFE,param1,param2]=trainingEMG(fs,canais_reais,M,N,frinicial,frfinal,frinicial2,frfinal2,cell_sinais,cell_acel,tipoclass,tipodet);
    %Para TFE: param1=limiar,param2=maior
    %Para LDA: param1=Tr, param2=Gr

    %% inicia classificacao online
    P=M*N*2;

    v_ndet_min=ones(1,ndet_min);

    cell_cmd_plot=cell(1,2);
   
    for isinal=1:2,
        if isinal==1, %determina o canal de teste apenas para ser plotado
           canal_teste=canal_ext;
        else canal_teste=canal_flex;
        end
        sinais=cell_sinais{1,isinal+2};
        %% inicializa variaveis de classificacao
        cmd_final=[zeros(1,N*(2*M-1))];%amostras iniciais não podem ser classificadas, portanto recebem 0.
        cmd_plot=[zeros(1,2*M-1)];%janelas iniciais não podem ser classificadas, portanto recebem 0.
        TFEt_final=[];
        %r_Yt_final=[];
        Yt_final=[zeros(lcanais,2*M-1)];
        ffts=[];
        %% realiza a classificacao janela a janela (cada uma com N amostras)
        for i=P+1:N:length(sinais),
            [TFEt,comando,Yt,Sf]=onlineEMG(fs,sinais(:,i-P:i-1),frinicial,frfinal,frinicial2,frfinal2,limiar_TFE,param1,param2,M,N,tipoclass);

            TFEt_final=[TFEt_final TFEt];
            cmd=0;
            if size(TFEt_final,2)>=8,
               if ((TFEt_final(canal_ext,end-(ndet_min-1):end)==v_ndet_min & comando==1) |(TFEt_final(canal_flex,end-(ndet_min-1):end)==v_ndet_min & comando==2)),
                   cmd=comando;
                    else if (cmd_plot(end-1)==1 || cmd_plot(end-1)==2),
                       cmd=-1; %desativação muscular
                        end
                end
            end
            cmd_final=[cmd_final cmd*ones(1,N)];
            cmd_plot=[cmd_plot cmd];
            ffts=[ffts Sf];
            %r_Yt_final=[r_Yt_final r_Yt];
            Yt_final=[Yt_final Yt];
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
        figure;
        plot(vt,sinais(canal_teste,:),'-b');
        hold on
        plot(pos_flex/fs,vetor0(pos_flex),'ks','MarkerFaceColor','r');
        hold on
        plot(pos_ext/fs,vetor0(pos_ext),'ks','MarkerFaceColor','g');
        hold on
        plot(pos_desativ/fs,vetor0(pos_desativ),'ks','MarkerFaceColor','y');
        if isempty(pos_ext)==1,
            legend('Sinal EMG','Flexï¿½o','Relaxamento')
        else if isempty(pos_flex)==1,
                legend('Sinal EMG','Extensï¿½o','Relaxamento')
            else if isempty(pos_desativ)==1,
                legend('Sinal EMG','Flexï¿½o','Extensï¿½o')
                else  legend('Sinal EMG','Flexï¿½o','Extensï¿½o','Relaxamento')
                end
            end
        end
        xlabel('Tempo[s]','FontSize',14)
        ylabel('Amplitude [V]','FontSize',14)
        set(gca,'FontSize',14)
        vetor_teste=canal_teste*ones(1,5);
    end
end

