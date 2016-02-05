function [acel_pi, acel_piy] = processa_acel(t, acel, fs, braco, janela_t, Acel_fim)
%janela_t : janela te mpo para descriminara braços
%sinais acelerometro

%braco = 1;  %1 direito; 2 esquerdo; 3 ambos
%Acel_fim 0 -> inicio do movimento, 1 fim do movimento - braço estável


fcorte = 10;  %frequencia de corte superior
Tacelbase = 10;%tempo inicial para calculo da linha de base

%filtra todos canais dos aceleromeros
[b,a] = butter(2,fcorte*2/fs,'low');
acel = filtfilt(b,a,acel);

%sinais do acelerometro para cada braço
acel_d = acel(:,2);%direito
acel_e = acel(:,5);%esquerdo

%limpa variável não mais necessária
clear acel

[acel_pid,acel_limiard, lbased] = borda_acel(acel_d, Tacelbase, fs, Acel_fim); %direito
[acel_pie,acel_limiare, lbasee] = borda_acel(acel_e, Tacelbase, fs, Acel_fim); %esquerdo

%remove linhas de base para plotar
acel_d = acel_d - lbased;
acel_e = acel_e - lbasee;

Jbraco = fix(janela_t*fs);
if ((braco == 1) || (braco == 2)),
    
    %descarta movimento de ambos os braços
    [idxd,idxe] = reconhece_idx(acel_pid,acel_pie,Jbraco);
    acel_pid(idxd) = [];
    acel_pie(idxe) = [];
    
    if (braco == 1),
        %acel_cn = acel_d;
        acel_pi = acel_pid;
    else
        %acel_cn = acel_e;
        acel_pi = acel_pie;
    end
    
elseif ((braco == 3) || (braco == 4)) %ambos
    %3 referencia ao direito
    %4 referencia ao esquerdo
    
    %aceita apenas ambos movimentos
    [idxd,idxe] = reconhece_idx(acel_pid,acel_pie,Jbraco);
    acel_pid=acel_pid(idxd);
    acel_pie=acel_pie(idxe);
    
    if (braco == 3)  %direito
        %acel_cn = acel_d;
        acel_pi = acel_pid;
    else   % esquerdo
        %acel_cn = acel_e;
        acel_pi = acel_pie;
    end
end

offset = -1000;  % offset para plotar os gráficos

fig = figure;  %sinal do acelerometro com trigger
plot(t,acel_d, 'b-',t, acel_e+offset,'r-');  %braço direito e esquerdo
legend ('direito','esquerdo');
hold on
if (braco == 1)
    plot((acel_pid-1)/fs,acel_d(acel_pid),'ko','MarkerFaceColor','g');
    
elseif(braco == 2)
    plot((acel_pie-1)/fs,acel_e(acel_pie)+offset,'ko','MarkerFaceColor','g');
    
elseif ((braco == 3) || (braco == 4))
    plot((acel_pid-1)/fs,acel_d(acel_pid),'ko','MarkerFaceColor','g');
    plot((acel_pie-1)/fs,acel_e(acel_pie)+offset,'ko','MarkerFaceColor','g');
end

set(gca,'Ytick',[offset,0]);  %muda nomes no eixo Y
set(gca,'ytickLabel',{'esquerdo','direito'});
hold off

%controle dos pontos excluidos
PI = zeros(size(acel_pi));
%PF = zeros(size(acel_pf));

ax = gca;

set(fig,'WindowButtonDownFcn',@ponto_click);

set(fig,'CloseRequestFcn',{@fecha_janela});
set(fig,'pointer','fullcrosshair');

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
            if (braco == 1)
                line((idx-1)/fs,acel_d(acel_pid(idx1)),'Marker','o','MarkerFaceColor','k');
            elseif(braco ==2)
                line((idx-1)/fs,acel_e(acel_pie(idx1))+offset,'Marker','o','MarkerFaceColor','k');
            else
                line((idx-1)/fs,acel_d(acel_pid(idx1)),'Marker','o','MarkerFaceColor','k');
                line((idx-1)/fs,acel_e(acel_pie(idx1))+offset,'Marker','o','MarkerFaceColor','k');
            end
        else
            if (braco == 1)
                line((idx-1)/fs,acel_d(acel_pid(idx1)),'Marker','o','MarkerFaceColor','g');
            elseif(braco == 2)
                line((idx-1)/fs,acel_e(acel_pie(idx1))+offset,'Marker','o','MarkerFaceColor','g');
            else
                line((idx-1)/fs,acel_d(acel_pid(idx1)),'Marker','o','MarkerFaceColor','g');
                line((idx-1)/fs,acel_e(acel_pie(idx1))+offset,'Marker','o','MarkerFaceColor','g');
            end
        end
    end

%função para reconhecer bordas de subida e descida do sinal
%acel_in: canal do acelerometro para detectar borda
%Tmed: tempo do inicio do sinal para calcular linha de base
    function [pi,limiar,acel_inbase] = borda_acel(acel_in, Tmed, fsample, borda_tipo)
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
            [pi] = det_ini_borda_deriv_p2(acel_in,fs,limiar,5,5,[100 100],1800);
        else
            [pi] = det_ini_borda_deriv(acel_in,fs,limiar,5,5,[100 100],1800);
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
acel_pi(PI~=0) = [];
acel_piy = [acel_d(:)+lbased,acel_e(:)+lbasee];
acel_piy = acel_piy(acel_pi,:);

%acel_pf(PF~=0) = [];

end

