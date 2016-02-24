function [v_det,comando]= onlineEMG(fs,sinais,frinicial,frfinal,param1,param2,M,N,tipoclass,tipodet,lim_det)
%comando:0=repouso;1=extensao;2=flexao
    lcanais=size(sinais,1);
    fmean=[];
    ax=[];
    Yt_final=[];
    Xt_final=[];

        %% Preparacao para aplicacao do teste F espectral no EMG
       
        tam=length(sinais);
        E=M*2; %numero total de trechos 
        vt=0:1/fs:(length(sinais)-1)/fs;
        s=[];
        Sf=[];
      
            for canal=1:lcanais
                s=reshape(sinais(canal,:),N,E);  %sinal transformado em matriz com cada coluna correspondendo a um trecho e cada linha correspondendo a uma amostra (ponto) do sinal.
                Sf_canal=fft(s);
                Sf=[Sf; Sf_canal];
            end   
         nbins=frfinal-frinicial+1;
        %nbins=(frfinal-frinicial)+1+(frfinal2-frinicial2)+1; %numero de amostras (pontos) de frequencia a serem "unificados" em uma banda.
        % Vetor de frequencias
        TFE=[];
        %% calculo do TFE para cada canal
        Yt_final=[];
        Xt_final=[];
     
         for canal=1:lcanais
            Xt0=sum(abs(Sf(N*(canal-1)+1:N*canal,1:M).^2),2);
            Xt=[];
              Xt=sum(Xt0(frinicial:frfinal));   
              %Xt=sum(Xt0(frinicial:frfinal))+sum(Xt0(frinicial2:frfinal2));
            Yt0=sum(abs(Sf(N*(canal-1)+1:N*canal,M+1:2*M).^2),2);  % numerador da equacao da TFE considerando frequencias individuais
            Yt=[];
              Yt=sum(Yt0(frinicial:frfinal));  
              %Yt=sum(Yt0(frinicial:frfinal))+sum(Yt0(frinicial2:frfinal2));
            Yt_final=[Yt_final;Yt];
            Xt_final=[Xt_final;Xt];

         end
        
        if tipodet=='TFE',
            TFE=Yt_final./Xt_final;
        %end
       
        %Calcula valor critico (de acordo com a distribuicao F teorica)
        gl=2*M*nbins*lcanais/2;
        vcrit_s=finv(0.95,2*M*nbins,gl); % alfa=0.05, graus de liberdade=2*M*nbins e 2*M*nbins
        vcrit_i=finv(0.05,2*M*nbins,gl); % alfa=0.05, graus de liberdade=2*M*nbins e 2*M*nbins  
        % for l=1:E-(2*M)+1,
        
        nivel=0;
        TFEt=[];
        
        Nfloor=floor(N/nbins);
     end 
     for canal=1:lcanais,
         
%          if isempty(limiar_TFE)==0,%utiliza limiar pelo desvio padrao da media dos trechos em repouso(versao 2)
%               if 0<canal<5,
%                 coleta=1;
%               else if 5<canal<9,
%                         coleta=2;
%                   end
%               end
%               vcrit_s=limiar_TFE(coleta,canal),
%          end
        if tipodet=='TFE',
          if TFE(canal)>vcrit_s,
              TFEt(canal)=1;
         else if TFE(canal)<vcrit_i,
               TFEt(canal)=-1;
              else TFEt(canal)=0;
              end
          end  
        end  
          if tipodet=='RMS',
             rms = sqrt(mean(sinais(canal,end-N:end).^2));
             if rms>lim_det(canal),
                  RMSt(canal)=1;
             else if rms<=lim_det(canal),
                   RMSt(canal)=0;
                 end 
             end
          end
     if tipodet=='TFE',
          v_det=TFEt';
     else if tipodet=='RMS',
             v_det=RMSt';
          end
     end
    
     end
     
        

%% determina a razão r_Yt de acordo com o número de canais considerados
canal_ext1=1;
canal_flex1=2;
canal_ext2=3;
canal_flex2=4;
canal_ext3=5;
canal_flex3=6;

r_Yt=[];
if tipoclass=='TFE',
    limiar=param1;
    maior=param2;
    if lcanais==2,
        r_Yt=Yt_final(canal_ext1)./Yt_final(canal_flex1);
    else if lcanais==4,
             r_Yt=(Yt_final(canal_ext1)+Yt_final(canal_ext2))./(Yt_final(canal_flex1)+Yt_final(canal_flex2));
        else if lcanais==6,
                r_Yt=(Yt_final(canal_ext1)+Yt_final(canal_ext2)+Yt_final(canal_ext3))./(Yt_final(canal_flex1)+Yt_final(canal_flex2)+Yt_final(canal_flex3));
             end
        end
    end
    %% determina qual o resultado da detecção final (1:extensao,2:flexao,0:repouso)
    comando=0; 
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
else if tipoclass=='LDA',
        Tr=param1;
        Gr=param2;
        XY=[];
        for canal=1:lcanais
            v_canal=Yt_final(canal);
            XY=[XY v_canal];
        end
        [C,err,P,logp,coeff]=classify(XY,Tr,Gr,'linear');
       
    else if tipoclass=='FDA',
            Tr=param1;
            Gr=param2;
            r_Yt1=Yt_final(canal_ext1)./Yt_final(canal_flex1);
            r_Yt2=Yt_final(canal_ext2)./Yt_final(canal_flex2);
            r_Yt3=Yt_final(canal_ext3)./Yt_final(canal_flex3);
            XY=[];
            XY=[r_Yt1 r_Yt2 r_Yt3];
            [C,err,P,logp,coeff]=classify(XY,Tr,Gr,'linear');
        end
    end
        if tipoclass=='LDA'|tipoclass=='FDA',
            res=C(1);
            if strcmp(res,'extensao'),
                comando=1;  
            else comando=2;
            end
        end
end


