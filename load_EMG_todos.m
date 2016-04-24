clear all
close all
dados=[];
canais_load=[2 3 4 8 6 7];
fs=2000;
N=200;
lcanais=length(canais_load);
ncanais_dados=3;
canal_ac=1+ncanais_dados;
canais=canais_load+ncanais_dados*ones(1,length(canais_load));
carregasinais=['treinamento extensao','treinamento flexao','teste extensao','teste flexao']
cell_sinais=cell(1,4); %sinais necessarios a analise serao reunidos em uma celula.
cell_acel=cell(1,4);
num_mov=[];
<<<<<<< HEAD
voluntarios={'Bruna'};
%
%voluntarios={'Alaise','Anderson','Andrea','Beatriz','Bruna','Bruno','Daniele','Delcy','Fernanda','Filipe','Francisco','Geraldo','Hellen'}
%voluntarios={'Inaiacy','Ivonete','Jessica','Karen','Lorena','Luiza','PRoberto','Rafael','Roberto','Santiago','Thais','Thays','Victor'};
%voluntarios={'Jessica'}
=======
%voluntarios={'Alaise','Anderson','Andrea','Beatriz','Bruna','Bruno','Daniele','Delcy','Fernanda','Filipe','Francisco','Geraldo','Hellen','Inaiacy','Ivonete','Jessica','Karen','Lorena','Luiza','PRoberto','Rafael','Roberto','Santiago','Thais','Thays','Victor'}
%voluntarios={'Inaiacy','Ivonete','Jessica','Karen','Lorena','Luiza','PRoberto','Rafael','Roberto','Santiago','Thais','Thays','Victor'};
voluntarios={'Santiago','Ivonete'}
>>>>>>> parent of 3b7c81e... Inclusão do classificador SVM + alterações necessárias no programa executável
for j=1:length(voluntarios)
    voluntario=char(voluntarios(1,j));
for i=1:4
    if i==1|i==3,
        tarefa='Abertura';
    else tarefa='Fechamento';
    end
    if i==1|i==2,
        sessao='1';
    else sessao='2';
    end
    nomearquivo=strcat(voluntario,'_',tarefa,'_MSD_',sessao,'.mat');
    mensagem=strcat('Abra o arquivo de ',carregasinais(i));
    path='C:\Users\rafaelacunha\Dropbox\processamento_dissertacao\coletas_mat';
    
%     [Arq,PATH]=uigetfile('*.mat',mensagem,'C:\Users\rafaelacunha\Dropbox\processamento_dissertacao\coletas_mat');
%     if Arq==0,
%         sinais = [];      %retorna vazio caso abertura seja cancelada
%         %return;
%         %tratar erro
%     end
%     NomeARQdig=[PATH,Arq];
%     partes_arq=regexp(Arq,'_','split');
%     voluntario=partes_arq(1);
    
    dados_arquivo=load(fullfile(path,nomearquivo));
    
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
   num_mov(i)=length(dados_arquivo.dados.acel.mov);
   cell_acel{1,i}=dados_arquivo.dados.acel;
   
end

if num_mov(3)~= num_mov(4),
    min_mov=min(num_mov(3:4))
    cell_acel{3}.mov=cell_acel{3}.mov(1,1:min_mov);
    cell_acel{3}.rel=cell_acel{3}.rel(1,1:min_mov);
    cell_acel{4}.mov=cell_acel{4}.mov(1,1:min_mov);
    cell_acel{4}.rel=cell_acel{4}.rel(1,1:min_mov);
end
tipos_classes={'TFE','LDA'};
cell_canais_avaliar_duplos={[1 4],[2 5],[3 6]};

%% avaliacao de duplas de canais para TFE e LDA
%set(0,'DefaultFigureVisible','on');

% tipodet='TFE';%TFE ou RMS 
% tipoclass='TFE';
% canal_ext=1;
% canal_flex=2;
% coluna_excel=15;
% canais_avaliar=[1 4];
% [cell_cmd_plot]=mainEMG(canais_avaliar,canal_ext,canal_flex,cell_sinais,cell_acel,voluntario,tipoclass,tipodet);
% [prec_ext,prec_flex,sens_ext,sens_flex,esp_ext,esp_flex,overall_acc]=assess_results(N,voluntario,tipoclass,tipodet,canais_avaliar,coluna_excel,cell_acel,cell_cmd_plot);



tipodet='TFE';%TFE ou RMS 
canal_ext=1;
canal_flex=2;
coluna_excel=2;
for p=1:length(tipos_classes)
    tipoclass=tipos_classes{1,p};
    for q=1:length(cell_canais_avaliar_duplos)
        canais_avaliar=cell_canais_avaliar_duplos{1,q};
         coluna_excel=coluna_excel+1;
        [cell_cmd_plot]=mainEMG(canais_avaliar,canal_ext,canal_flex,cell_sinais,cell_acel,voluntario,tipoclass,tipodet);
        [prec_ext,prec_flex,sens_ext,sens_flex,esp_ext,esp_flex,overall_acc]=assess_results(N,voluntario,tipoclass,tipodet,canais_avaliar,coluna_excel,cell_acel,cell_cmd_plot);
    end
end


%% avaliacao de multiplos canais com LDA
coluna_excel=coluna_excel+1;
canais_avaliar=[1 2 4 5];
canal_ext=1;
canal_flex=3;
tipoclass='LDA';
[cell_cmd_plot]=mainEMG(canais_avaliar,canal_ext,canal_flex,cell_sinais,cell_acel,voluntario,tipoclass,tipodet);
[prec_ext,prec_flex,sens_ext,sens_flex,esp_ext,esp_flex,overall_acc]=assess_results(N,voluntario,tipoclass,tipodet,canais_avaliar,coluna_excel,cell_acel,cell_cmd_plot);

coluna_excel=coluna_excel+1;
canais_avaliar=[1 2 3 4 5 6]
canal_ext=1;
canal_flex=4;
tipoclass='LDA';
[cell_cmd_plot]=mainEMG(canais_avaliar,canal_ext,canal_flex,cell_sinais,cell_acel,voluntario,tipoclass,tipodet);
[prec_ext,prec_flex,sens_ext,sens_flex,esp_ext,esp_flex,overall_acc]=assess_results(N,voluntario,tipoclass,tipodet,canais_avaliar,coluna_excel,cell_acel,cell_cmd_plot);

coluna_excel=coluna_excel+1;
canais_avaliar=[1 2 3 4 5 6]
canal_ext=1;
canal_flex=4;
tipoclass='FDA';
[cell_cmd_plot]=mainEMG(canais_avaliar,canal_ext,canal_flex,cell_sinais,cell_acel,voluntario,tipoclass,tipodet);
[prec_ext,prec_flex,sens_ext,sens_flex,esp_ext,esp_flex,overall_acc]=assess_results(N,voluntario,tipoclass,tipodet,canais_avaliar,coluna_excel,cell_acel,cell_cmd_plot);

end
