function [sinais,NomeARQdig] = AbreSinalPEB2_msg(mensagem,Caminho)
%Abre_Sinal.m
%Seleciona e salva em disco segmentos de sinal
%

%referencia
%Maur�cio Cagy - mar�o/1998
%�ltima revis�o: 16/05/2006
%Altera��o : Aluizio d'Affons�ca 25/11/2011
%Altera��o : Aluizio d'Affons�ca 06/07/2013
%            Modifi��o para ler arquivos do ADS1299

%Arquiva o caminho (Path) que cont�m os dados
if nargin <= 1
    Dialogo = true;
end

%diretorio padr�o vazio
path_arq = [];

if (nargin == 2)
    [path_arq,arq_name,est_arq] = fileparts(Caminho);
    
    if isempty(arq_name) || isempty(est_arq),
        Dialogo = true;
        if isempty(est_arq) && ~isempty(arq_name),
            path_arq = [path_arq,'\',arq_name];
        end
    else
        Dialogo = false;
        NomeARQdig = Caminho;
    end
end
if (nargin>=1)
    msg=mensagem;
else
    msg='Selecione o arquivo';
end
%abre dialogo para arquivo com diretorio padr�o    
if Dialogo
    [Arq,PATH]=uigetfile('*.peb2',msg,path_arq);
    if Arq==0,
        sinais = [];      %retorna vazio caso abertura seja cancelada
        return;
    end
    NomeARQdig=[PATH,Arq];
end
ARQ=fopen(NomeARQdig,'rb');

if ARQ<0,
    exibe('N�o foi poss�vel abrir este arquivo!','Erro!');
    error('N�o foi poss�vel abrir este arquivo!')
end;


sinais.F_amost_in=[]; % Inicializa a freq. amost. com uma matriz vazia;
% Serve para permitir a inclus�o de um valor "default" no di�logo
% de freq. de amostragem, quando for poss�vel obt�-lo do cabe�alho do arquivo.

%Arquivos formato PEB:
% elseif tipo==4,
Bph=1; %Bytes por elemento do cabe�alho
Bpa=4; %Bytes por amostra
preci='int32';

%L� o cabe�alho:
NChar=fread(ARQ,1,'uint8');
sinais.TipoDeExame=setstr(fread(ARQ,NChar,'uchar')');
sinais.F_amost_in=fread(ARQ,1,'float32');
NChar=fread(ARQ,1,'uint8');
sinais.TimeUnit=setstr(fread(ARQ,NChar,'uchar')');
Ncan_in=fread(ARQ,1,'uint8');
sinais.Ncan_in = Ncan_in; %slava numero de cansi na estrutura
sinais.cAng=fread(ARQ,Ncan_in,'float64');
sinais.cLin=fread(ARQ,Ncan_in,'float64');
for i=1:Ncan_in,
    NChar=fread(ARQ,1,'uint8');
    sinais.ChNames{i}=setstr(fread(ARQ,NChar,'uchar')');
end;
for i=1:Ncan_in,
    NChar=fread(ARQ,1,'uint8');
    sinais.ChUnits{i}=setstr(fread(ARQ,NChar,'uchar')');
end;
TemEstim=fread(ARQ,1,'uint8');
sinais.Ncan_est = TemEstim;   %numero de canais de trigger
Ncan_in=Ncan_in+TemEstim;
sinais.cAng=[sinais.cAng;ones(TemEstim,1)];
sinais.cLin=[sinais.cLin;zeros(TemEstim,1)];
sinais.HighCutOff=fread(ARQ,1,'float32');
sinais.LowCutOff=fread(ARQ,1,'float32');
sinais.AnoExame=fread(ARQ,1,'uint16');
sinais.MesExame=fread(ARQ,1,'uint8');
sinais.DiaExame=fread(ARQ,1,'uint8');
sinais.HoraExame=fread(ARQ,1,'uint8');
sinais.MinExame=fread(ARQ,1,'uint8');
NChar=fread(ARQ,1,'uint8');
sinais.Comments=setstr(fread(ARQ,NChar,'uchar')');
tam_header=ftell(ARQ); %tamanho do cabe�alho

Ncanais=Ncan_in;
fseek(ARQ,0,'eof');    %pula para o final do  arquivo
Tam_arq = (ftell(ARQ)-tam_header)/Bpa;   %tamanho do arquivo que contem as amostras
Numero_amostras=fix(Tam_arq/Ncanais); %Tamanho do sinal em numero de amostras intercaladas
Tam_arq = Numero_amostras*(Ncanais);   % corrige tamanho para corresponder a um numero inteiro de bytes
fseek(ARQ,tam_header,'bof'); %pula o cabe�alho
[ARQdig,sr]=fread(ARQ,Tam_arq,preci);

ARQdig=reshape(ARQdig,Ncanais,Numero_amostras);   %monta matriz com canais nas linhas e amostras nas colunas
for k = 1:Ncanais,
    ARQdig(k,:) = (ARQdig(k,:) + sinais.cLin(k))*sinais.cAng(k);
end
%sinais.ARQdig = (ARQdig +sinais.cLin*ones(1,Numero_amostras)).*(sinais.cAng*ones(1,Numero_amostras));  %escalona os valores
sinais.ARQdig = ARQdig;
sinais.Numero_amostras = Numero_amostras;
sinais.Caminho = NomeARQdig;   %Caminho do arquivo escolhido
fclose(ARQ);