% teste unitário para o código assess_results.m

N=2;
voluntario='teste_unitario'
tipoclass='TFE',
tipodet='TFE'
canais_avaliar=[1 4];
col_excel=12;
cell_acel=cell(1,4);
cell_acel{1,1}={};
cell_acel{1,2}={};
cell_acel{1,3}.mov=[9 25];  
cell_acel{1,4}.mov=[9 25];
cell_acel{1,3}.rel=[16 32];
cell_acel{1,4}.rel=[16 32];
cell_cmd_plot={[0 0 0 0 1 1 0 0 -1 -1 0 0 1 1 0 0 -1 -1 0 0 ],[0 0 0 0 2 2 0 0 -1 -1 0 0 2 2 0 0 -1 -1 0 0]};
[prec_ext,prec_flex,sens_ext,sens_flex,esp_ext,esp_flex,overall_acc]=assess_results(N,voluntario,tipoclass,tipodet,canais_avaliar,coluna_excel,cell_acel,cell_cmd_plot);
