clear all
close all
canais_reais=[2 8];%canais nos quais será baseada a classificação
N=200; %numero de amostras(pontos) por trecho.
M=5; %numero de trechos a serem utilizados para o calculo da TFE.
[frinicial,frfinal,frinicial2,frfinal2,limiar,maior,tipo_coleta,voluntario]=trainingEMG(canais_reais,M,N);
canal_ext=1;
canal_flex=2;
canal_teste=canal_flex;
N=200;
M=5;
P=M*N*2;
ndet_min=5;
v_ndet_min=ones(1,ndet_min);
carrega_sinal;  %carrega o sinal no qual será aplicada a classificação.
% figure;
% plot(sinais(1,:))
% figure
% plot(sinais(2,:))

cmd_final=[zeros(1,N*(2*M-1))];%amostras iniciais não podem ser classificadas, portanto recebem 0.
cmd_plot=[zeros(1,2*M-1)];%janelas iniciais não podem ser classificadas, portanto recebem 0.
TFEt_final=[];
r_Yt_final=[];
Yt_final=[zeros(2,2*M-1)];
ffts=[];

for i=P+1:N:length(sinais),
    [TFEt,comando,r_Yt,Yt,Sf]=onlineEMG(sinais(:,i-P:i-1),frinicial,frfinal,frinicial2,frfinal2,limiar,maior,M,N);
  
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
    r_Yt_final=[r_Yt_final r_Yt];
    Yt_final=[Yt_final Yt];
end
fs=2000;
vt=0:1/fs:(length(sinais)-1)/fs;
corr=length(vt)-length(cmd_final);
cmd_final=[cmd_final 0*ones(1,corr)];
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


%avaliação dos resultados
trecho_mov=floor(pos_mov_teste(:,:)./N);
verdadeiro_positivo=[];
falso_negativo=[];
acertos=[];
erros=[];
falso_positivo=[];
    for i=1:length(trecho_mov)
        verdadeiros=[];         
        verdadeiros= find(cmd_plot(trecho_mov(i)-10:trecho_mov(i)+9));
        verdadeiros= verdadeiros+(ones(1,length(verdadeiros))*(trecho_mov(i)-11));
       relaxamentos=find(cmd_plot(verdadeiros)==-1);
       verdadeiros(relaxamentos)=[];
        teste2=cmd_plot(verdadeiros)
        if length(verdadeiros)>=1,
            verdadeiro_positivo=[verdadeiro_positivo trecho_mov(i)];
            if cmd_plot(verdadeiros(1))==canal_teste,
                acertos=[acertos trecho_mov(i)];
            else erros=[erros trecho_mov(i)];
            end
        else falso_negativo=[falso_negativo trecho_mov(i)];
       end
    end
    pos_det=find(cmd_plot==1|cmd_plot==2);
    for i=1:length(pos_det)
        if isempty(find(verdadeiros==pos_det(i)))~=0,
            falso_positivo=[falso_positivo pos_det(i)];
        end
    end
    total_negativos=length(cmd_plot)-(length(trecho_mov)*20);
    pct_deteccao=100*length(verdadeiro_positivo)/(length(verdadeiro_positivo)+length(falso_negativo))
    sensibilidade=pct_deteccao;
    especificidade=100*(total_negativos-length(falso_positivo))/total_negativos;
    pct_acertos=100*length(acertos)/(length(acertos)+length(erros));
    arq_resultado=strcat(voluntario,'_',tipo_coleta,'_',tipo_coleta_teste,'_TFE_resultado.mat');
    num_testes=length(cmd_plot);
    save(char(arq_resultado),'falso_negativo','verdadeiro_positivo','falso_positivo','acertos','erros','total_negativos', 'pct_acertos','especificidade','sensibilidade');
        
 
