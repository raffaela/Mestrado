function [TFEt,comando,r_Yt,Yt_final,Sf]= onlineEMG(sinais,frinicial,frfinal,frinicial2,frfinal2,limiar,maior,M,N)
%comando:0=repouso;1=extensao;2=flexao

fs=2000;  %frequencia de amostragem
fmean=[];
     ax=[];
     Yt_final=[];
     Xt_final=[];

        %Prepara��o para aplica��o do teste F espectral no EMG
       
        tam=length(sinais);
        resf=(fs)/(tam); % resolucao espectral (considerando as bandas de frequencia)
        frsinais=[0:resf:resf*(tam-1)];  %vetor de frequencias de acordo com a resf.
   
       
        E=M*2; %numero total de trechos 
        vt=0:1/fs:(length(sinais)-1)/fs;
        s=[];
        Sf=[];
        for canal=1:2
            s=reshape(sinais(canal,:),N,E);  %sinal transformado em matriz com cada coluna correspondendo a um trecho e cada linha correspondendo a uma amostra (ponto) do sinal.
            Sf_canal=fft(s);
            Sf=[Sf; Sf_canal];
        end   
       
       % Sf=fft(s); % Calculo do espectro do sinal para cada trecho (coluna).

        % RMS de trechos em repouso
        nbins=5; %numero de amostras (pontos) de frequencia a serem "unificados" em uma banda.

        % Vetor de frequencias
        resf=(fs*nbins)/(N); % resolucao espectral (considerando as bandas de frequencia)
        fr=[0:resf:resf*(N/(2*nbins)-1)];  %vetor de frequencias de acordo com a resf.
        TFE=[];
        ifaixa=[];
        %RMS de trechos onde pode ocorrer movimento
        Yt_final=[];
        Xt_final=[];
         for canal=1:2
        %for l=2*M:E,
            Xt0=sum(abs(Sf(N*(canal-1)+1:N*canal,1:M).^2),2);
            Xt=[];
              %Xt=sum(Xt0(frinicial:frfinal));   
              Xt=sum(Xt0(frinicial:frfinal))+sum(Xt0(frinicial2:frfinal2));
            Yt0=sum(abs(Sf(N*(canal-1)+1:N*canal,M+1:2*M).^2),2);  % numerador da equacao da TFE considerando frequencias individuais
            Yt=[];
              %Yt=sum(Yt0(frinicial:frfinal));  
              Yt=sum(Yt0(frinicial:frfinal))+sum(Yt0(frinicial2:frfinal2));
            Yt_final=[Yt_final;Yt];
            Xt_final=[Xt_final;Xt];
%               faixa=[floor(meanfreq(canal)) floor(meanfreq(canal)+20)];
%               ifaixa(canal)= floor((faixa(1)/((fs)/N))/nbins)+1;
        end
  
            TFE=Yt_final./Xt_final;
        %end
        
        %Calcula valor critico (de acordo com a distribuicao F teorica)
        vcrit_s=finv(0.95,2*M*nbins,2*M*nbins); % alfa=0.05, graus de liberdade=2*M*nbins e 2*M*nbins
        vcrit_i=finv(0.05,2*M*nbins,2*M*nbins); % alfa=0.05, graus de liberdade=2*M*nbins e 2*M*nbins
      
        %faixa=[80 179];
        %ifaixa=floor((faixa(1)*N)/(nbins*fs))+1;
       
        % for l=1:E-(2*M)+1,
        nivel=0;
        TFEt=[];
        
        Nfloor=floor(N/nbins);
      
     for canal=1:2,
            %TFE(ifaixa,l)
          if TFE(canal)>vcrit_s,
              TFEt(canal)=1;
         else if TFE(canal)<vcrit_i,
               TFEt(canal)=-1;
              else TFEt(canal)=0;
              end
          end  
        end
TFEt=TFEt';

canal_ext=1;
canal_flex=2;
comando=0; 

r_Yt=Yt_final(canal_ext)./Yt_final(canal_flex);

if TFEt(canal)==1,
    r_Yt
end
    
if maior==1,
    if r_Yt<limiar,
        comando=2;%flexao
    else
        comando=1;%extensao
    end
else 
    if r_Yt>limiar,
        comando=2;
    else
        comando=1;
    end
end



end


