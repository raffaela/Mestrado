function [prec_ext,prec_flex,sens_ext,sens_flex,overall_acc]=avalia_resultados(N,voluntario,cell_acel,cell_cmd_plot)
%métricas de resultados do detector
prec_ext=0;
sens_ext=0;
prec_flex=0;
sens_flex=0;
overall_acc=0;

num_vp_prec=zeros(1,2);
num_vp_sens=zeros(1,2);
num_p_win=zeros(1,2);

vect_isinal=[1 2];

for isinal=1:length(vect_isinal),
    
    pos_mov=cell_acel{1,isinal+2}.mov;
    pos_rel=cell_acel{1,isinal+2}.rel;
    w_mov=floor(pos_mov(:,:)./N)+1;
    w_rel=floor(pos_rel(:,:)./N)+1;

    %% valores para o calculo da precisao
    p_1=[];
    cmd_plot=cell_cmd_plot{vect_isinal(isinal)};
        
    p_1 = find(cmd_plot==vect_isinal(isinal))%total de positivos em relação a classe do sinal em questao
    p_2=find(cmd_plot==setdiff(vect_isinal,vect_isinal(isinal)));%total de positivos em relação a outra classe
    v_mov=[];
    verdade_rep=[];
    verdade_mov=[];
    for i=1:length(w_mov)
        trecho_mov=[];
        trecho_rep=[];
        v_mov=[v_mov w_mov(i):w_rel(i)];%cria vetor com posições de cmd_plot onde deve haver movimento
        pos_vet=find(cmd_plot(w_mov(i):w_rel(i))==-1); %verifica se a sequencia "movimento,relaxamento,relaxamento" existe no intervalo entre o mov e o rel do acelerometro
        if (isempty(pos_vet))==0,
            pos_vet= pos_vet+(ones(1,length(pos_vet))*(w_mov(i)-1)); %atualiza as posições relativas (do trecho) para posições absolutas no sinal
            if pos_vet(1)<=w_rel(i)-1,
                trecho_rep=[pos_vet(1)+1:w_rel(i)]; %define como trecho de repouso (verdade) aquele após a presença da sequencia requerida
            end
            if pos_vet(1)>=w_mov(i)+1,
                trecho_mov=w_mov(i):pos_vet(1)-1;  %define como trecho de movimento (verdade) aquele antes da presença da sequencia requerida
            end
        else
            N
            trecho_mov=[w_mov(i):w_rel(i)];
        end
      
        verdade_mov=[verdade_mov trecho_mov];
        verdade_rep=[verdade_rep trecho_rep]; 
    end  
    teste_vp_1=ismember(p_1,verdade_mov);
    num_vp_prec(isinal)=length(find(teste_vp_1)); %calcula o numero de positivos que são verdadeiros para o movimento em questão
    num_p_win(isinal)=length(p_1);
    num_fp_op(isinal)=length(p_2);%calcula o número de falsos positivos para o outro movimento (verdadeiros são sempre falsos no sinal em questão)
 
    %% valores para o calculo da sensibilidade
    vp=find(cmd_plot(verdade_mov)==vect_isinal(isinal));
    num_v_win(isinal)=length(verdade_mov); %número de janelas verdadeiras
    num_vp_sens(isinal)=length(vp);
    v_rel=setdiff(1:length(cmd_plot),v_mov);
    num_vp_repouso(isinal)=length(find(cmd_plot([v_rel verdade_rep])==0));
end
num_p_win(1)=num_p_win(1)+num_fp_op(2);
num_p_win(2)=num_p_win(2)+num_fp_op(1);
total_vp_repouso=sum(num_vp_repouso);
%% cálculo da precisão e da sensibilidade
prec_ext=num_vp_prec(1)/num_p_win(1);
sens_ext=num_vp_sens(1)/num_v_win(1);
prec_flex=num_vp_prec(2)/num_p_win(2);
sens_flex=num_vp_sens(2)/num_v_win(2);
overall_acc=(num_vp_prec(1)+num_vp_prec(2)+total_vp_repouso)/(length(cell_cmd_plot{1})+length(cell_cmd_plot{2}));

%% salva resultados em arquivo
arq_resultado=strcat(voluntario,'_','_TFE_resultado_teste.mat');
save(char(arq_resultado),'prec_ext','sens_ext','prec_flex','sens_flex','overall_acc');
%%    
%são calculados a especificidade e precisão para cada padrão(classe).
%Ex: haverá um valor de sensibilidade para a classe flexãO  e um para a
%classe extensão.
%é calculada tambem a overall accuracy que consiste de um únivo valor dado 
%pelo número de janelas corretamente classificadas para todos os padrões 
%dividido pelo número total de janelas testadas.
    