function [prec_ext,prec_flex,sens_ext,sens_flex,esp_ext,esp_flex,overall_acc]=assess_results(N,voluntario,tipoclass,cell_acel,cell_cmd_plot)
%métricas de resultados do detector
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
    %% computa posicoes dadas pelo acelerometro.
    pos_mov=cell_acel{1,isinal+2}.mov;
    pos_rel=cell_acel{1,isinal+2}.rel;
    w_mov=floor(pos_mov(:,:)./N);
    w_rel=floor(pos_rel(:,:)./N);
    
   
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
            find_vp=find((cmd_plot(verdade_mov(k,1):verdade_mov(k,2)))==vect_isinal(isinal));
            find_rep=find((cmd_plot(verdade_mov(k,1):verdade_mov(k,2))==0)|(cmd_plot(verdade_mov(k,1):verdade_mov(k,2))==-1));
            if length(find_vp)>=floor((verdade_mov(k,2)-verdade_mov(k,1))/3),%considera-se verdadeiro positivo se mais da metade do trecho for verdadeiro positivo 
                if length(find_rep)>=verdade_mov(k,2)-verdade_mov(k,1)-length(find_vp),
                    num_vp=num_vp+1;
                end
            else num_fn=num_fn+1;
            end
            find_fp_2=find((cmd_plot(verdade_mov(k,1):verdade_mov(k,2)))==setdiff(vect_isinal,vect_isinal(isinal)));
            if length(find_fp_2)>=floor((verdade_mov(k,2)-verdade_mov(k,1))/3),%considera-se verdadeiro positivo se mais da metade do trecho for verdadeiro positivo 
               if length(find_rep)>=verdade_mov(k,2)-verdade_mov(k,1)-length(find_fp_2),
                   num_fp_2=num_fp_2+1;
               else num_vn_2=num_vn_2+1;
               end
            end
    end   
     %% avaliacao dos trechos de repouso
     for l=1:size(verdade_rep,1),
            teste_rep=0;
            find_fp=find((cmd_plot(verdade_rep(l,1):verdade_rep(l,2)))==vect_isinal(isinal));
            if length(find_fp)>=floor((verdade_rep(l,2)-verdade_rep(l,1))/3),%considera-se verdadeiro positivo se mais da metade do trecho for verdadeiro positivo 
                num_fp=num_fp+1;
            else num_vn=num_vn+1;
                 teste_rep=1;
            end
            find_fp_2=find((cmd_plot(verdade_rep(l,1):verdade_rep(l,2)))==setdiff(vect_isinal,vect_isinal(isinal)));
            if length(find_fp_2)>floor((verdade_rep(l,2)-verdade_rep(l,1))/3),%considera-se verdadeiro positivo se mais da metade do trecho for verdadeiro positivo 
               num_fp_2=num_fp_2+1;
            else num_vn_2=num_vn_2+1;   
                 teste_rep=1;
            end
            if teste_rep==1,%se foi verdadeiro negativo para flexao e para extensao, entao sera verdadeiro positivo para repouso.
                 num_vp_rep=num_vp_rep+1;
            end
     end

    num_v_win(isinal)=size(verdade_mov,1);
    num_vp_win(isinal)=num_vp;
    num_fp_win(isinal)=num_fp_win(isinal)+num_fp;
    num_fn_win(isinal)=num_fn;
    num_vn_win(isinal)=num_vn_win(isinal)+num_vn;
    num_vn_win(setdiff(vect_isinal,vect_isinal(isinal)))=num_vn_win(setdiff(vect_isinal,vect_isinal(isinal)))+num_vn_2;
    num_vp_rep_win(isinal)=num_vp_rep;
    num_v_win_rep(isinal)=size(verdade_rep,1);
end

%% cálculo da especificidade e da sensibilidade
prec_ext=num_vp_win(1)/(num_vp_win(1)+num_fp_win(1));
sens_ext=num_vp_win(1)/(num_vp_win(1)+num_fn_win(1));
esp_ext=num_vn_win(1)/(num_vn_win(1)+num_fp_win(1));
prec_flex=num_vp_win(2)/(num_vp_win(2)+num_fp_win(2));
sens_flex=num_vp_win(2)/(num_vp_win(2)+num_fn_win(2));
esp_flex=num_vn_win(2)/(num_vn_win(2)+num_fp_win(2));
total_vp_rep=sum(num_vp_rep_win);
total_v_win_rep=sum(num_v_win_rep);
overall_acc=(num_vp_win(1)+num_vp_win(2)+total_vp_rep)/(num_v_win(1)+num_v_win(2)+total_v_win_rep);

%% salva resultados em arquivo
arq_resultado=strcat(voluntario,'_',tipoclass,'_TFE_resultado_teste.mat');
save(char(arq_resultado),'prec_ext','sens_ext','prec_flex','sens_flex','esp_ext','esp_flex','overall_acc');
%%    
%são calculados a especificidade e precisão para cada padrão(classe).
%Ex: haverá um valor de sensibilidade para a classe flexãO  e um para a
%classe extensão.
%é calculada tambem a overall accuracy que consiste de um únivo valor dado 
%pelo número de janelas corretamente classificadas para todos os padrões 
%dividido pelo número total de janelas testadas.
    