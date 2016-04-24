clear all
close all
canais_reais=[2 7];%canais nos quais será baseada a classificação
ncanais_dados=3;
canal_ac=1+ncanais_dados;
canais=canais_reais+ncanais_dados*ones(1,length(canais_reais));

fs=2000;  %frequencia de amostragem

   [Arq,PATH]=uigetfile('*.mat','Abra o arquivo desejado para teste','C:\Users\rafaelacunha\Dropbox\processamento_dissertacao');
    if Arq==0,
        sinais = [];      %retorna vazio caso abertura seja cancelada
        %return;
        %tratar erro
    end
   NomeARQdig=[PATH,Arq];
    dados_arquivo=load(NomeARQdig);
    sinais=dados_arquivo.dados.ARQdig(canais,:);
    sinal_ac=dados_arquivo.dados.ARQdig(canal_ac,:);
    

    %filtra todos canais dos aceleromeros
    [b,a] = butter(2,5*2/fs,'low');
    sinal_ac = filtfilt(b,a,sinal_ac);
    [b,a] = butter(2,0.005*2/fs,'high');
    sinal_ac = filtfilt(b,a,sinal_ac);
    
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
     wo = 80*2/(fs);  bw = wo/10;
    [b,a] = iirnotch(wo,bw);
    sinais = filtfilt(b,a,sinais);
    [b,a] = butter(2,20*2/fs,'high');
    sinais = filtfilt(b,a,sinais);
    [b,a] = butter(2,450*2/fs,'low');
    sinais = filtfilt(b,a,sinais);

   sinais=sinais';
   
   sinal_extensor=sinais(2,:);
   
   pos_mov_teste=dados_arquivo.dados.acel.mov; 
   pos_rel_teste=dados_arquivo.dados.acel.rel;
   vt=0:1/fs:(length(sinal_extensor)-1)/fs;
   figure
   plot(sinal_extensor);
   hold on;
   plot(pos_mov_teste,sinal_extensor(pos_mov_teste),'ko','MarkerFaceColor','r');
    hold on;
   plot(pos_rel_teste,sinal_extensor(pos_rel_teste),'ko','MarkerFaceColor','g');
   hold on;
  plot(sinal_ac,'m');

