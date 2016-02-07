clear all
close all
dados=[];
canais_reais=[4 7];
fs=2000;
N=200;
lcanais=length(canais_reais);
ncanais_dados=3;
canal_ac=1+ncanais_dados;
canais=canais_reais+ncanais_dados*ones(1,length(canais_reais));
carregasinais=['treinamento extensao','treinamento flexao','teste extensao','teste flexao']
cell_sinais=cell(1,4); %sinais necessarios a analise serao reunidos em uma celula.
cell_acel=cell(1,4);
for i=1:4
    mensagem=strcat('Abra o arquivo de ',carregasinais(i))
    [Arq,PATH]=uigetfile('*.mat',mensagem);
    if Arq==0,
        sinais = [];      %retorna vazio caso abertura seja cancelada
        %return;
        %tratar erro
    end
    
    NomeARQdig=[PATH,Arq];
    partes_arq=regexp(Arq,'_','split');
    voluntario=partes_arq(1);
    
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
    
   cell_sinais{1,i}=sinais;
   cell_acel{1,i}=dados_arquivo.dados.acel;
   
end

canal_ext=1;
canal_flex=2;
tipoclass='TFE';
tipodet='v1';

[cell_cmd_plot]=mainEMG(canais_reais,canal_ext,canal_flex,cell_sinais,cell_acel,voluntario,tipoclass,tipodet);
[prec_ext,prec_flex,sens_ext,sens_flex,esp_ext,esp_flex,overall_acc]=assess_results(N,voluntario,tipoclass,tipodet,lcanais,cell_acel,cell_cmd_plot);

