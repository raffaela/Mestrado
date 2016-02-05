function [pd,pt,pb] = det_ini_borda_deriv_subida(y,fs,lM,lvd,fcd,L,Ld,pa)
%pd indices das bordas de inicio, quando braço estiver estabilizado -
%        derivada minima
%pt tempo em que ocorre as bordas
%pb pontos das bordas sem comrreção com derivada
%y sinal de entrada
%fs frequencia de amostragem
%lM limiar de detecção da borda
%lvd limiar da derivada de borda
%fcd frequencia de corte da derivada
%L[inicio fim], numero depontos seguidos a considerar acima do limiar e
%abaixo do limiar
%Ld numero de pontos para pesquisar a deriva pelo inicio da borda
%pa alvos de referencia para os indices encontrados
%autor: Aluizio d'Affonsêca Netto
%Raquel Souza Branco
%Atualizacao: Raffaela Cunha
%data: 01/05/2015


% subida = false;
% p = [];
% for k = 1:(length(y)-L(1)),
%     if subida == false,
%         if ~isempty(find(y(k:(k+(L(1)-1))) < lM)) && isempty(find(y(k:(k+(L(1)-1))) < lM))
%             p = [p,k];
%             subida = true;
%         end
%     end
%     if subida == true,
%         if isempty(find(y(k:(k+(L(2)-1))) > lM))
%             subida = false;
%         end
%     end
% end

%procura pontos de cruzamento do limiar
pb = [];
for k = L(1):(length(y) - L(2)),
    if (length(find(y((k-L(1)+1):k)<lM))==L(1)) && (length(find(y((k+1):(k+L(2)))>=lM))==L(2))
        pb = [pb,k];
    end
end

%corrige posições com derivada
dy = gradient(y,1/fs);
[b,a] = butter(2,fcd*2/fs,'low');
dy = filtfilt(b,a,dy);

%dy = derive_gaus_n(y,60,'um')*fs;

pd=[];
for i = 1:length(pb)
    if pb(i)+Ld<=length(dy)
    for j=pb(i):(pb(i)+Ld)  
       if dy(j-1)>=lvd && dy(j)<lvd
          pd=[pd,j]; 
          break
       end
    end
    end    
end



%corrige indices com alvos 
if nargin == 8,
    
    pc = [];
    %procura indice comums mais próximos dos alvos
    for k = 1:length(pa),
        [mm,pp] = min(abs(pd - pa(k)));
        pc = [pc,pp];
    end
    pd = pd(pc);
    
    pc = [];
    %procura indice comums mais próximos dos alvos
    for k = 1:length(pa),
        [mm,pp] = min(abs(pb - pa(k)));
        pc = [pc,pp];
    end
    pb = pb(pc);
end

pt = (pd-1)/fs; %tempo