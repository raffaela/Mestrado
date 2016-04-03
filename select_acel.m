 %function [] = seleciona_acel(dados,canal_ac,fs)
clear all
close all
    canal_ac=4;
    fs=2000;
    [dados,nomeArq]=AbreSinalPEB2_msg('Abra o arquivo desejado','C:\Users\rafaelacunha\Dropbox\processamento_dissertacao');
    sinais=dados.ARQdig(4:end,:);
     fs=2000;
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
        sinal_ac=dados.ARQdig(canal_ac,:)*(-1);
        %filtra todos canais dos aceleromeros
        [b,a] = butter(2,5*2/fs,'low');
        sinal_ac = filtfilt(b,a,sinal_ac);
        [b,a] = butter(2,0.005*2/fs,'high');
        sinal_ac = filtfilt(b,a,sinal_ac);
        t=0:1/fs:(size(sinais,2)-1)/fs;
        sinais=[sinal_ac;sinais];
        offsetp = max(max(sinais));
        for k=1:9,
            sinais_corr(:,k) = sinais(k,:)+ (k-1)*offsetp;
        end
        plot(t,sinais_corr');
        title(['offset: ',sprintf('%f',offsetp)]);
        set(gca,'ytick',([1,2,3,4,5,6,7,8,9]-1)*offsetp);
        set(gca,'ytickLabel',{'acel','ch1','ch2','ch3','ch4','ch5','ch6','ch7','ch8'});
    %trigger

    sinal_ref=dados.ARQdig(canal_ac-1,:);
    %sinal_ref=sinal_ref(5001:end);
    %sinal_ac=sinal_ac(5001:end);
    t=0:1/fs:(length(sinal_ac)-1)/fs;
    figure; plot(t,sinal_ref)
       dados.acel=struct;

    [pos_mov]=processa_acel_Raffaela(t,sinal_ac',fs,1);
    % matriz_corr=5000*ones(1,length(XYhist.set1.data(:,2)));
    if isempty(pos_mov)==0,
        dados.acel.mov=floor(((XYhist.set1.data(:,2))')*fs);
        
    end
    clear XYhist;
    [pos_rel]=processa_acel_Raffaela(t,sinal_ac',fs,0);
    %matriz_corr=5000*ones(1,length(XYhist.set1.data(:,2)));
    if isempty(pos_rel)==0,
        dados.acel.rel=floor(((XYhist.set1.data(:,2))')*fs);
    end
    nomeArq_split=strsplit(nomeArq,'.');
    nomeArq=strcat(nomeArq_split(1),'_completo.mat');
    nomeArq_split2=strsplit(char(nomeArq),'\');
    path='C:\Users\rafaelacunha\Dropbox\processamento_dissertacao\coletas_mat'
    nomeArq=fullfile(path,nomeArq_split2(end));
    save(char(nomeArq),'dados');
    

    
    