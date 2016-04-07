function [prec_ext,prec_flex,sens_ext,sens_flex,esp_ext,esp_flex,overall_acc]=assess_results(N,voluntario,tipoclass,tipodet,canais_avaliar,col_excel,cell_acel,cell_cmd_plot)
%m�tricas de resultados do detector
prec_ext=0;
sens_ext=0;
prec_flex=0;
sens_flex=0;
esp_ext=0;
esp_flex=0;
overall_acc=0;
num_vp_win=zeros(1,2);
num_vn_win=zeros(1,2);
num_fp_win=zeros(1,2);
num_fn_win=zeros(1,2);
num_v_win=zeros(1,2);
num_p_win=zeros(1,2);
num_vp_rep_win=0;
vect_isinal=[1 2];
nres_min=3; %numero minimo dedeteccoes para se confirmar um movimento de extens�o ou flex�o
%% analisa primeiramente o sinal de extesao e depois o de flexao
for isinal=1:length(vect_isinal),
    trecho_mov=[];
    trecho_rep=[];
    num_vp=0;
    num_fp=0;
    num_vn=0;
    num_fn=0;
    num_vn_2=0;
    num_fp_2=0;
    num_vp_rep=0;
    num_vn_rel=0;
    %% computa posicoes dadas pelo acelerometro.
    pos_mov=cell_acel{1,isinal+2}.mov;
    pos_rel=cell_acel{1,isinal+2}.rel;
    w_mov=floor(pos_mov(:,:)./N)-1;
    w_rel=floor(pos_rel(:,:)./N)-1;
    
   
    %% pega resultado do detector
    cmd_plot=cell_cmd_plot{vect_isinal(isinal)};
    
    %% registro de trechos verdadeiros para cada classe (movimento - para extensao e flexao/repouso) 
    verdade_mov=[];
    verdade_rep=[1 w_mov(1)];
    for i=1:length(w_mov)      
        pos_mid=floor((w_rel(i)-w_mov(i))/2);
        trecho_mov=[w_mov(i) w_mov(i)+pos_mid-1];
        trecho_rel=[w_mov(i)+pos_mid w_rel(i)-1];
        if i<length(w_mov),
            pos_mid=floor((w_mov(i+1)-w_rel(i))/2);
            trecho_rep=[w_rel(i) w_rel(i)+pos_mid-1;w_rel(i)+pos_mid w_mov(i+1)];
        end
        verdade_mov=[verdade_mov; trecho_mov];
        verdade_rep=[verdade_rep;trecho_rel;trecho_rep]; 
    end
    %% avaliacao dos trechos de movimento
    for k=1:size(verdade_mov,1),
        %% computa verdadeiros positivos e falsos negativos para a classe em quest�o
        if find(cmd_plot(verdade_mov(k,1):verdade_mov(k,2))==vect_isinal(isinal)),
            find_vp=find((cmd_plot(verdade_mov(k,1):verdade_mov(k,2))==vect_isinal(isinal))|(cmd_plot(verdade_mov(k,1):verdade_mov(k,2))==0));
            num_vp=num_vp+length(find_vp)
        else num_fn=num_fn+verdade_mov(k,2)-verdade_mov(k,1)+1;
        end
        %% computa falsos positivos e verdadeiros negativos para outras classes
        find_fp_2=find((cmd_plot(verdade_mov(k,1):verdade_mov(k,2)))==setdiff(vect_isinal,vect_isinal(isinal)));
        num_fp_2=length(find_fp_2); 
        num_vn_2=num_vn_2+verdade_mov(k,2)-verdade_mov(k,1)+1-num_fp_2;
        find_fp_rel=find((cmd_plot(verdade_mov(k,1):verdade_mov(k,2)))==-1);
        num_fp_rel=length(find_fp_rel); 
        num_vn_rel=num_vn_rel+verdade_mov(k,2)-verdade_mov(k,1)+1-num_fp_rel;
    end        
     %% avaliacao dos trechos de repouso
     for l=1:size(verdade_rep,1),
            find_vp_rep=find((cmd_plot(verdade_rep(l,1):verdade_rep(l,2)))==0|(cmd_plot(verdade_rep(l,1):verdade_rep(l,2)))==-1);         
            num_vp_rep=num_vp_rep+length(find_vp_rep);    
            teste_rep=0;
            find_fp=find((cmd_plot(verdade_rep(l,1):verdade_rep(l,2)))==vect_isinal(isinal));
            num_fp=num_fp+length(find_fp);
            num_vn=num_vn+verdade_rep(l,2)-verdade_rep(l,1)+1-num_fp;
            find_fp_2=find((cmd_plot(verdade_rep(l,1):verdade_rep(l,2)))==setdiff(vect_isinal,vect_isinal(isinal)));
            num_fp_2=num_fp_2+length(find_fp_2);
            num_vn_2=num_vn_2+verdade_rep(l,2)-verdade_rep(l,1)+1-num_fp;             
    end
    num_v_win(isinal)=sum(diff(verdade_mov'))+size(verdade_mov,1);
    num_vp_win(isinal)=num_vp;
    num_fp_win(isinal)=num_fp_win(isinal)+num_fp;
    num_fn_win(isinal)=num_fn;
    num_vn_win(isinal)=num_vn_win(isinal)+num_vn;
    num_vn_win(setdiff(vect_isinal,vect_isinal(isinal)))=num_vn_win(setdiff(vect_isinal,vect_isinal(isinal)))+num_vn_2;
    num_vp_rep_win(isinal)=num_vp_rep;
    num_v_win_rep(isinal)=sum(diff(verdade_rep'))+size(verdade_rep,1);
end
num_vp_win
num_fn_win
%% c�lculo da especificidade e da sensibilidade
prec_ext=num_vp_win(1)/(num_vp_win(1)+num_fp_win(1));
sens_ext=num_vp_win(1)/(num_vp_win(1)+num_fn_win(1));
esp_ext=num_vn_win(1)/(num_vn_win(1)+num_fp_win(1));
prec_flex=num_vp_win(2)/(num_vp_win(2)+num_fp_win(2));
sens_flex=num_vp_win(2)/(num_vp_win(2)+num_fn_win(2));
esp_flex=num_vn_win(2)/(num_vn_win(2)+num_fp_win(2));
total_vp_rep=sum(num_vp_rep_win);
total_v_win_rep=sum(num_v_win_rep);
overall_acc=(num_vp_win(1)+num_vp_win(2)+total_vp_rep)/(num_v_win(1)+num_v_win(2)+total_v_win_rep);

%% salva resultados em arquivo .mat e .xlsxl
dir_resultado='C:\Users\rafaelacunha\Dropbox\processamento_dissertacao\resultados';
arq_resultado_mat=strcat(voluntario,'_',tipoclass,'_',tipodet,'_',int2str(canais_avaliar),'_resultado_final_4.mat');
path_resultado_mat=fullfile(dir_resultado,arq_resultado_mat);
% save(char(path_resultado_mat),'prec_ext','sens_ext','prec_flex','sens_flex','esp_ext','esp_flex','overall_acc');
resultados=[sens_ext; sens_flex; esp_ext; esp_flex; prec_ext; prec_flex; overall_acc];
arq_resultado_xlsx='resultado_final_6.xlsx';
sheet=voluntario;
writevar(resultados,col_excel,arq_resultado_xlsx,sheet);
% T = table(prec_ext,sens_ext,prec_flex,sens_flex,esp_ext,esp_flex,overall_acc);
% writetable(T,filename,'Sheet',1,'Range','D1')
%%    
%s�o calculados a especificidade e precis�o para cada padr�o(classe).
%Ex: haver� um valor de sensibilidade para a classe flex�O  e um para a
%classe extens�o.
%� calculada tambem a overall accuracy que consiste de um �nivo valor dado 
%pelo n�mero de janelas corretamente classificadas para todos os padr�es 
%dividido pelo n�mero total de janelas testadas.
    