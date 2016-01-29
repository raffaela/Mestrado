dados=[];
ncanais_dados=3;
canal_ac=1+ncanais_dados;
canais=canais_reais+ncanais_dados*ones(1,length(canais_reais));
fs=2000;  %frequencia de amostragem

   [Arq,PATH]=uigetfile('*.mat','Abra o arquivo desejado para teste');
    if Arq==0,
        sinais = [];      %retorna vazio caso abertura seja cancelada
        %return;
        %tratar erro
    end
    NomeARQdig=[PATH,Arq];
    partes_arq_teste=regexp(Arq,'_','split');
    tipo_coleta_teste=strcat(partes_arq_teste(2),partes_arq_teste(3),partes_arq_teste(4));
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
    [b,a] = butter(2,450*2/fs,'low');
    sinais = filtfilt(b,a,sinais);

   sinais=sinais';
   sinal_extensor=sinais(1,:);
   sinal_ac=dados_arquivo.dados.ARQdig(4,:);
   


