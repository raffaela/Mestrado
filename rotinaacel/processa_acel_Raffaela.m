function [acel_pi] = processa_acel_Raffaela(t, acel, fs, Acel_fim)

%sinais acelerometro

%Acel_fim 0 -> inicio do movimento, 1 fim do movimento - braço estável


fcortes = 10;  %frequencia de corte superior
fcortei=0.1;
Tacelbase = 1.5;%tempo inicial para calculo da linha de base

%filtra todos canais dos aceleromeros
[b,a] = butter(2,fcortes*2/fs,'low');
acel = filtfilt(b,a,acel);
[b,a] = butter(2,fcortei*2/fs,'high');
acel = filtfilt(b,a,acel);
%sinais do acelerometro para cada braço
acel_d=acel;
% 
% figure
% plot(t,acel_d)
%limpa variável não mais necessária
clear acel
% dados_rep=AbreSinalPEB2();
% acel_rep=dados_rep.ARQdig(ch_acel,1000:end)';

[acel_pid,acel_limiard, lbased,pb] = borda_acel(acel_d, Tacelbase, fs, Acel_fim); %direito


    %remove linhas de base para plotar
    acel_d = acel_d - lbased;

    offset = -1000;  % offset para plotar os gráficos

    fig = figure;  %sinal do acelerometro com trigger
if isempty(acel_pid)==0,
      plot((acel_pid-1)/fs,acel_d(acel_pid),'ko','MarkerFaceColor','g');
   
    crosshair; %retorna os pontos selecionados na variavel XYhist.
    hold on;
    plot(t,acel_d, 'b-');


    hold off
    acel_pi=acel_pid;

    %controle dos pontos excluidos
    PI = zeros(size(acel_pi));

    ax = gca;

    % set(fig,'WindowButtonDownFcn',@ponto_click);

    % set(fig,'CloseRequestFcn',{@fecha_janela});
    % set(fig,'pointer','fullcrosshair');
end
acel_pi=acel_pid;
%funções do callbacks %%%%%%%%%%
%funções para fechar janela
    function fecha_janela(hObject,eventdata)
        uiresume(fig);
        delete(fig);
    end
%clicks sobre o grafico para selecionar pontos
    function ponto_click(hObject,eventdata)
        %procura ponto em x
        px = get(ax,'CurrentPoint');
        px = px(1,1);
        
        [m,idx] = min(abs(t - px));
        [m1,idx1] = min(abs(idx - acel_pi));
        idx = acel_pi(idx1);
        if PI(idx1) == 0, PI(idx1) = 1; ad = 1;
        else PI(idx1) = 0;  ad = 0; end
        
        %         [m2,idx2] = min(abs(idx - acel_pf));
        %         if (m1 <= m2)
        %             idx = acel_pi(idx1);
        %             if PI(idx1) == 0, PI(idx1) = 1; ad = 1;
        %             else PI(idx1) = 0;  ad = 0; end
        %
        %         else
        %             idx = acel_pf(idx2);
        %             if PF(idx2) == 0, PF(idx2) = 1; ad = 1;
        %             else PF(idx2) = 0; ad = 0; end
        %         end 
        
        %mostra pontos adicionados ou retirados
        if ad== 1
          
                line((idx-1)/fs,acel_d(acel_pid(idx1)),'Marker','o','MarkerFaceColor','k');
        else
                line((idx-1)/fs,acel_d(acel_pid(idx1)),'Marker','o','MarkerFaceColor','g');          
        end
    end

%função para reconhecer bordas de subida e descida do sinal
%acel_in: canal do acelerometro para detectar borda
%Tmed: tempo do inicio do sinal para calcular linha de base
    function [pi,limiar,acel_inbase,pb] = borda_acel(acel_in, Tmed, fsample, borda_tipo)
        %linha de base = media do inicio
        acel_inbase = mean(acel_in(1:fix(Tmed*fsample)));
        acel_in= acel_in - acel_inbase;
        
        %limiar para detectar inicio de movimento
        limiar = prctile(acel_in,95)/2;
        
        %         pi = [];
        %         subida = 0;
        %         for k = 2:length(acel_in),
        %             if (acel_in(k - 1) < limiar) && (acel_in(k) >= limiar) && (subida == 0)
        %                 subida = 1;
        %                 pi = [pi,k];
        %             end
        %             if (acel_in(k - 1) > limiar) && (acel_in(k) <= limiar) && (subida == 1)
        %                 subida = 0;
        %             end
        %         end
        if borda_tipo == 1,
            [pi,p0,pb] = det_ini_borda_deriv_subida(acel_in,fs,limiar,0.0012,5,[80 80],1000);
        else
            [pi,p0,pb] = det_ini_borda_deriv_descida(acel_in,fs,limiar,0.0012,5,[80 80],1000);
        end
    end

    function [pao,pbo] = reconhece_idx(ai,bi,w)
        pao = [];
        pbo = [];
        for ka = 1:length(ai),
            for kb = 1: length(bi),
                if (abs(ai(ka) - bi(kb)) <= w),
                    pao = [pao;ka];
                    pbo = [pbo;kb];
                end
            end
        end
    end

%aguarda ferchar figura - resume
uiwait(fig);

%remove pontos ecolhidos
if isempty(acel_pi)==0,
    acel_pi(PI~=0) = [];
end
% acel_piy = [acel_d(:)+lbased,acel_e(:)+lbasee];
% acel_piy = acel_piy(acel_pi,:);

%acel_pf(PF~=0) = [];
end

