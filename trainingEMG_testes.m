function [param1,param2,TFE_final,lim_det]=trainingEMG_testes(fs,canais_avaliar,M,N,frinicial,frfinal,cell_sinais,cell_acel,cell_sinal_ac,tipoclass,tipodet,path_fig,voluntario)

if nargout>3,
    lim_det=[];
end
lcanais=length(canais_avaliar);

msg={'Abra o arquivo correspondente ao movimento de extens�o','Abra o arquivo correspondente ao movimento de flexao','Abra o arquivo correspondente ao repouso'};

mfreq=zeros(2,2);
movimento=struct('pos_mov',{},'pos_rel',{});

%meanfreq=(sum(mfreq)/2);
meanfreq=mean(mfreq);
Gr=[];
Tr=[];

% if tipodet=='v2',
%     limiar_TFE=ones(2,lcanais)*1000; %ser definido um limiar para cada canal para cada coleta.
% else limiar_TFE=[];
% end
% figura=figure;
      
for icoleta=1:2,
     ax=[];
     Yt_final=[];
     
     sinais=cell_sinais{icoleta}(canais_avaliar,:);
    
    %% separacao do trecho em que houve o movinento, atraves do sinal do
      %acelerometro.
     movimento(icoleta).pos_mov=cell_acel{icoleta}.mov;
     movimento(icoleta).pos_rel=cell_acel{icoleta}.rel;
     
     pos_mov=movimento(icoleta).pos_mov;
     pos_rel=movimento(icoleta).pos_rel;
     num_contr=length(pos_mov);
     sinal_acel=cell_sinal_ac{1,icoleta};
     E=floor(length(sinal_acel)/N);
     sinal_acel=sinal_acel(1:N*E);
      vt=0:1/fs:(length(sinal_acel)-1)/fs
 
     for icanal=1:lcanais,
        sinal_filtrado=sinais(icanal,:);
        t=0:1/fs:(length(sinal_filtrado)-1)/fs;
        E=floor(length(sinal_filtrado)/N); %numero total de trechos no sinal inteiro.
        sinal_cut=sinal_filtrado(1:N*E);    
        sinal=reshape(sinal_cut,N,E);  %sinal transformado em matriz com cada coluna correspondendo a um trecho e cada linha correspondendo a uma amostra (ponto) do sinal.
        
       
         Sf=fft(sinal); % Calculo do espectro do sinal para cada trecho (coluna).
       %% calculo do TFE
        nbins=frfinal-frinicial+1;
        TFE=[];
        Yt_f=[];
         for l=2*M:E,
            Xt0=sum(abs(Sf(:,l-2*M+1:l-M).^2),2);
            Xt=[];
            Xt=sum(Xt0(frinicial:frfinal));
            %Xt=sum(Xt0(frinicial:frfinal))+sum(Xt0(frinicial2:frfinal2));
            Yt0=sum(abs(Sf(:,l-M+1:l).^2),2);  % numerador da equacao da TFE considerando frequencias individuais
            Yt=[];
            Yt=sum(Yt0(frinicial:frfinal));
            %Yt=sum(Yt0(frinicial:frfinal))+sum(Yt0(frinicial2:frfinal2));
            TFE(1,l-2*M+1)=Yt./Xt; % cada coluna desta matriz corresponde a TFE calculada para um conjunto de trechos diferentes de y[k].   
            Yt_f(1,l-2*M+1)=Yt;
         end
         
           rep2=zeros(1,2*M); %janelas iniciais nao tem valor do Yt atribuido e portanto recebem 0.
           Yt_final(icanal,:)=[rep2 Yt_f];
           gl=2*M*nbins*lcanais/2;
           %rep=zeros(1,2*M*N-N); %amostras iniciais nao tem valor do TFE atribuido e portanto recebem 0.
           TFE_final=[rep2 TFE];
           t_TFE=0:N/fs:(length(TFE_final)-1)*N/fs
        
        
  
       
           %% Calcula valor critico (de acordo com a distribuicao F teorica)
        if tipodet=='TFE',
            vcrit_s=finv(0.99,2*M*nbins,gl); % alfa=0.05, graus de liberdade=2*M*nbins e 2*M*nbins
            vcrit_i=finv(0.01,2*M*nbins,gl); % alfa=0.05, graus de liberdade=2*M*nbins e 2*M*nbins
            figure
            h1=plot(t_TFE,TFE_final./(max(TFE_final)*100),'-m','LineWidth',2);
            %hold on
            %plot(vt,sinal_acel,'-k');
            
            hold on
            plot(vt,vcrit_s*ones(1,length(vt))./(max(TFE_final)*100),'-k','LineWidth',2);
            hold on
            plot(vt,vcrit_i*ones(1,length(vt))./(max(TFE_final)*100),'-r','LineWidth',2);
            hold on
            h2=plot(vt,sinal_cut,'-c');
            uistack(h1,'top')
            uistack(h2,'bottom')
           legend('Sinal EMG','limiar superior','limiar inferior','\Phi_{y1y2}')
        end
        set(gca,'FontSize',14)
        if tipodet=='RMS',
                rms = sqrt(mean(sinal.^2));
            [n1,xout] = hist(rms(1:floor(pos_mov(1,1)/N)),0:1e-006:(max(rms)));  
            u=3;
            v_lim_det(icoleta,icanal) = xout(find(n1==max(n1))+u);
        end
%         if tipodet=='v2',
%                 for l=0:length(TFE)-1
%                     TFEt(l*N+1:l*N+N)=TFE(l+1);
%                 end
%                 rep=zeros(1,2*M*N-N); %amostras iniciais nao tem valor do TFE atribuido e portanto recebem 100(valor alto para nao influenciar o minimo).
%                 TFEt_final=[rep TFEt];
%                 TFEt_rel=TFEt_final;
%                 for icontr=length(pos_mov):-1:1,
%                     if pos_rel(icontr)+1000<=length(TFEt_final),
%                         TFEt_rel=setdiff(TFEt_rel,TFEt_final(pos_mov(icontr)-2000:pos_rel(icontr)+1000));           
%                     else 
%                         TFEt_rel=setdiff(TFEt_rel,TFEt_final(pos_mov(icontr)-2000:end));           
%                     end
%                 end
%                 limiar_TFE(icoleta,icanal)=mean(TFEt_rel)+2*std(TFEt_rel);
%         end
     end
    
     if tipodet=='RMS',
        lim_det=mean(v_lim_det);
     end
     %faz a estimativa das distribuicoes para o dado movimento de acordo
     %com a razao entre os canais.    
     r_Yt=[];
     if tipoclass=='TFE',
         if lcanais==2,
            r_Yt=Yt_final(1,:)./Yt_final(2,:); %razao entre as energias do musculo extensor e o flexor.
         else if lcanais==4,
            r_Yt=(Yt_final(1,:)+Yt_final(2,:))./(Yt_final(3,:)+Yt_final(4,:));
             else if lcanais==6,
                  r_Yt=(Yt_final(1,:)+Yt_final(2,:)+Yt_final(3,:))./(Yt_final(4,:)+Yt_final(5,:)+Yt_final(6,:));   
                 end
             end
         end
         cores=['-r','-b','-g'];
         vx=[r_Yt(floor(pos_mov(1:num_contr)./N))]; %considera somente 5 pimeiras contracoes
         fmean(icoleta)=median(vx);    
         lambda=fmean*(gl-2)-gl;
         x=0:0.1:12000.01;
         xfdist=fpdf(x,gl,gl)/fmean(icoleta);
         ay(icoleta)=subplot(1,1,1);
%          plot(x*fmean(icoleta),xfdist,cores(icoleta));
%          hold(ay(icoleta),'on')
%          set(gca,'FontSize',14);
     else
         if tipoclass=='LDA',
              Tr_atual=[];
              Gr_atual=[];
               for canal=1:lcanais,
                    Tr_atual(:,canal)= Yt_final(canal,floor(pos_mov(1:num_contr)./N))';
               end
         else
             if tipoclass=='FDA',
                 Tr_atual=[];
                 Gr_atual=[];
                 r_Yt1=[];
                 r_Yt2=[];
                 r_Yt3=[];
                 r_Yt1=Yt_final(1,:)./Yt_final(6,:);
                 r_Yt2=Yt_final(3,:)./Yt_final(5,:);
                 r_Yt3=Yt_final(2,:)./Yt_final(4,:);
                 Tr_atual= [r_Yt1(1,floor(pos_mov(1:num_contr)./N))' r_Yt2(1,floor(pos_mov(1:num_contr)./N))' r_Yt3(1,floor(pos_mov(1:num_contr)./N))'];
             end
         end
     end
     if tipoclass=='LDA'|tipoclass=='FDA',
         Tr=[Tr; Tr_atual];
         if icoleta==1,  
            Gr_atual=repmat({'extensao'},size(Tr_atual,1),1);
         else
            Gr_atual=repmat({'flexao'},size(Tr_atual,1),1);
         end
         Gr=[Gr;Gr_atual];
     end
    
end


%% plota distribuicoes
if tipoclass=='TFE',
%     legend('extensao','flexao')
%     axis([0,500, 0, 1]);
%     xlabel('x','FontSize',14);
%     ylabel('p(x)','FontSize',14);
%     title('Distribuicoes','FontSize',14);
%     set(gca,'FontSize',14);
    nome_fig=strcat(voluntario,'_',tipoclass,'_',tipodet,'_',int2str(canais_avaliar),'_distrib');
%     saveas(figura,char(fullfile(path_fig,nome_fig)),'fig');
%     %% calcula parametros de classificacao (limiar e maior)
     a1=fmean(1);
     a2=fmean(2);
     k=exp((0.5+2/gl)*log(a2/a1));
    lim=(a1*k-a2)/(1-k)
%     hold on
%     plot([lim],xfdist(floor(lim/0.1)),'ks','MarkerFaceColor','g');
%     legend ('Extensao','Flexao','Limiar');  
    if a1>a2,
        maior=1;
    else
        maior=2;

    end
    param1=lim;
    param2=maior;
else if tipoclass=='LDA'|tipoclass=='FDA',
         grupo=size(Gr);
         trein=size(Tr);
         if lcanais==2,
             figura=figure;
             plotaLDA(Tr,Gr);
             nome_fig=strcat(voluntario,'_',tipoclass,'_',tipodet,'_',int2str(canais_avaliar),'_LDAclass');
             saveas(figura,char(fullfile(path_fig,nome_fig)),'fig');
         end
        param1=Tr;
        param2=Gr;
    end
end
 
end
 