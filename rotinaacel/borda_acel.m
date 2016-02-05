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
            [pi] = det_ini_borda_deriv_p2(acel_in,fsample,limiar,5,5,[100 100],1800);
        else
            [pi] = det_ini_borda_deriv(acel_in,fsample,limiar,5,5,[100 100],1800);
        end
    end