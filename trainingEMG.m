function [frinicial,frfinal,frinicial2,frfinal2,lim,maior,tipo_coleta,voluntario]=trainingEMG(canais_reais,M,N)

fs=2000;  %frequencia de amostragem
ncanais_dados=3;
canal_ac=1+ncanais_dados;
canais=canais_reais+ncanais_dados*ones(1,length(canais_reais));  

frinicial=7;%18
frfinal=12;%25
frinicial2=18;%7
frfinal2=25;%12
msg={'Abra o arquivo correspondente ao movimento de extens�o','Abra o arquivo correspondente ao movimento de flex�o','Abra o arquivo correspondente ao repouso'};

sinais_ext=[];
sinais_flex=[];
mfreq=zeros(2,2);
movimento=struct('pos_mov',{},'pos_rel',{});
for icoleta=1:2, 
    [Arq,PATH]=uigetfile('*.mat',msg{icoleta});
    if Arq==0,
        sinais = [];      %retorna vazio caso abertura seja cancelada
        %return;
        %tratar erro
    end
    NomeARQdig=[PATH,Arq];
%     partes = regexp(PATH, '/', 'split');
%     voluntario=partes(end-1);
    %voluntario='wilian';
    partes_arq=regexp(Arq,'_','split');
    voluntario=partes_arq(1);
    tipo_coleta=strcat(partes_arq(3),partes_arq(4));
    %tipo_coleta='2';
  
    dados_arquivo=load(NomeARQdig);
    
    sinais=dados_arquivo.dados.ARQdig(canais,:);
    
    sinais=sinais';

    %filtragem
    wo = 60*2/(fs);  bw = wo/10;
    [b,a] = iirnotch(wo,bw);
    sinais = filtfilt(b,a,sinais);
    wo = 180*2/(fs);  bw = wo/10;
    [b,a] = iirnotch(wo,bw);
    sinais = filtfilt(b,a,sinais);
    wo = 300*2/(fs);  bw = wo/10;
    [b,a] = iirnotch(wo,bw);
    sinais = filtfilt(b,a,sinais);
    [b,a] = butter(2,20*2/fs,'high');
    sinais = filtfilt(b,a,sinais);
    sinais=sinais';          

 %sinal de acelerometria
    sinal_ac=dados_arquivo.dados.ARQdig(canal_ac,:);

    %separacao do trecho em que houve o movinento, atraves do sinal do
      %acelerometro.
    
     movimento(icoleta).pos_mov=dados_arquivo.dados.acel.mov;
     movimento(icoleta).pos_rel=dados_arquivo.dados.acel.rel;
     

     ax=[];
     Yt_final=[]; 
  
     if icoleta==1,
        sinais_ext=sinais;
     else if icoleta==2,
             sinais_flex=sinais;
         end
     end
     %inicia processamento para cada canal selecionado.
%     for icanal=1:length(canais),
%     sinal_contr=[];
%     tempo_contr=movimento(icoleta).pos_rel(1)-pos_mov(1);
%     sinal_filtrado=sinais(icanal,:);
%     for icontr=1:length(pos_mov) 
%         if (pos_mov(icontr)+tempo_contr)<=length(sinal_filtrado)
%                 sinal_contr=[sinal_contr sinal_filtrado(pos_mov(icontr):pos_mov(icontr)+tempo_contr)'];
%         end
%     end
        
         %Prepara��o para aplica��o do teste F espectral no EMG
%         s=sinal;
%         tam=length(s);
%         resf=(fs)/(tam); % resolucao espectral (considerando as bandas de frequencia)
%         frsinal=[0:resf:resf*(tam-1)];  %vetor de frequencias de acordo com a resf.
%         ffts=fft(s);
    
%     end
    
end
      

%meanfreq=(sum(mfreq)/2);
meanfreq=mean(mfreq);
for icoleta=1:2,
     if icoleta==1,
       sinais=sinais_ext;
     else if icoleta==2,
            sinais=sinais_flex;
         end
     end
     Yt_final=[];
     for icanal=1:length(canais),
        sinal_filtrado=sinais(icanal,:);
        t=0:1/fs:(length(sinal_filtrado)-1)/fs;
        E=floor(length(sinal_filtrado)/N); %numero total de trechos no sinal inteiro.
        sinal=sinal_filtrado(1:N*E);
        vt=0:1/fs:(length(sinal)-1)/fs;


        sinal=reshape(sinal,N,E);  %sinal transformado em matriz com cada coluna correspondendo a um trecho e cada linha correspondendo a uma amostra (ponto) do sinal.

        Sf=fft(sinal); % Calculo do espectro do sinal para cada trecho (coluna).
       
        % RMS de trechos em repouso
        %nbins=6; %numero de amostras (pontos) de frequencia a serem "unificados" em uma banda.
        nbins=frfinal-frinicial+1;
        %nbins=frfinal-frinicial+1+frinicial2-frfinal2+1;
        % Vetor de frequencias
        resf=(fs*nbins)/(N); % resolucao espectral (considerando as bandas de frequencia)
        fr=[0:resf:resf*(N/(2*nbins)-1)];  %vetor de frequencias de acordo com a resf.
        TFE=[];
        Yt_f=[];
       %calculo do TFE
         for l=2*M:E,
            Xt0=sum(abs(Sf(:,l-2*M+1:l-M).^2),2);
            Xt=[];
           % Xt=sum(Xt0(frinicial:frfinal));
            Xt=sum(Xt0(frinicial:frfinal))+sum(Xt0(frinicial2:frfinal2));
            Yt0=sum(abs(Sf(:,l-M+1:l).^2),2);  % numerador da equacao da TFE considerando frequencias individuais
            Yt=[];
            %Yt=sum(Yt0(frinicial:frfinal))
            Yt=sum(Yt0(frinicial:frfinal))+sum(Yt0(frinicial2:frfinal2));
            TFE(1,l-2*M+1)=Yt./Xt; % cada coluna desta matriz corresponde a TFE calculada para um conjunto de trechos diferentes de y[k].   
            Yt_f(1,l-2*M+1)=Yt;
        end
        %Calcula valor critico (de acordo com a distribuicao F teorica)
        vcrit_s=finv(0.95,2*M*nbins,2*M*nbins); % alfa=0.05, graus de liberdade=2*M*nbins e 2*M*nbins
        vcrit_i=finv(0.05,2*M*nbins,2*M*nbins); % alfa=0.05, graus de liberdade=2*M*nbins e 2*M*nbins
        
        %atribui-se 1 se o valor da TFE> vcritico superior,-1 se TFE<
        %vcritico inferior e 0 se vcrit inf <TFE<vcrit super
%         TFEt=zeros(1,E-2*M+1);
%         for l=1:length(TFE),
%           if TFE(1,l)>vcrit_s,
%               TFEt(l)=1;
%           else if TFE(1,l)<vcrit_i,
%                TFEt(l)=-1;
%                else TFEt(l)=0;    
%               end
%           end
%         end
%         TFEt_tr=TFEt; %TFEt_tr eh parametro de saida
        
        %transforma o vetor do TFE de janelas para amostras (para plotar)
%         TFEt2=[];
%         for l=0:length(TFEt)-1
%             TFEt2(l*N+1:l*N+N)=TFEt(l+1);
%         end
        %Yt_f2=Yt_f(1,:);
      
%         rep=zeros(1,2*M*N-N); %amostras iniciais nao tem valor do TFE atribuido e portanto recebem 0.
%         TFEt_final=[rep TFEt2];
        rep2=zeros(1,2*M-1); %janelas iniciais nao tem valor do Yt atribuido e portanto recebem 0.
        Yt_final(icanal,:)=[rep2 Yt_f];
% 
%         alldatacursors = findall(gcf,'type','hggroup');
%         set(alldatacursors,'FontSize',12);

        %calculando os instantes de tempo de detec��o
%         ldet=2000;
%         dmais=[];
%         dmenos=[];
%         for l=ldet:length(TFEt_final),
%                 fmais=find(TFEt_final(l-ldet+1:l)==1);
%                 fmenos=find(TFEt_final(l-ldet+1:l)==-1);
%         %detec��es de ativa��o muscular 
%                   if isempty(dmais)||length(dmenos)==length(dmais), %uma ativa��o s� ocorre no inicio ou ap�s uma desativa��o.
%                     if length(fmais)==ldet,
%                         dmais=[dmais l];
%                     end
%                  end
%                  if length(dmais)>length(dmenos), %uma desativa��o s� ocorre ap�s uma ativa��o.
%         %detec��es de desativa��o muscular
%                     if length(fmenos)==ldet,
%                         dmenos=[dmenos l];
%                     end
%                 end
%         end
       
        

%         pos_ativ=dmais;
%         pos_desativ=dmenos;
%         t=0:1/fs:(length(sinal_filtrado)-1)/fs;

     end
        pos_mov=movimento(icoleta).pos_mov;
        pos_rel=movimento(icoleta).pos_rel;
        
%            figure
%            plot(t,sinal_filtrado);
%            hold on;
%            plot(pos_mov/fs,sinal_filtrado(pos_mov),'ko','MarkerFaceColor','r');

 r_Yt=[];
 r_Yt=Yt_final(1,:)./Yt_final(2,:);
 cores=['-r','-b','-g'];
 num_contr=length(pos_mov)
 vx=[r_Yt(floor(pos_mov(1:num_contr)./N))]; %considera somente 5 pimeiras contracoes
 gl=2*M*nbins;
 fmean(icoleta)=median(vx);    
 lambda=fmean*(gl-2)-gl;

 x=0.01:0.1:12000.01;
 xfdist=fpdf(x,gl,gl)/fmean(icoleta);
 ay(icoleta)=subplot(1,1,1);
 plot(x*fmean(icoleta),xfdist,cores(icoleta));
 hold(ay(icoleta),'on')
    set(gca,'FontSize',14);
% figure
end
legend('extensao','flexao')

axis([0,500, 0, 1]);
xlabel('x','FontSize',14);
ylabel('p(x)','FontSize',14);
title('Distribui��es','FontSize',14);
set(gca,'FontSize',14);

 a1=fmean(1);
 a2=fmean(2);
 k=exp((0.5+2/gl)*log(a2/a1));
 lim=(a1*k-a2)/(1-k)
hold on
plot([lim],xfdist(floor(lim/0.1)),'ks','MarkerFaceColor','g');
legend ('Extens�o','Flex�o','Limiar');  
if a1>a2,
    maior=1;
else
    maior=2;
 
end
 
end
 