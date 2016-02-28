function []=plotaLDA(Tr,Gr)

[X,Y] = meshgrid(linspace(0,0.00001),linspace(0,0.000001));
 X = X(:); Y = Y(:);
h1 = gscatter(Tr(:,1),Tr(:,2),Gr,'rb','v^',[],'off');
set(h1,'LineWidth',2)
legend('extensao','flexao')
XY=[X Y];
[C,err,P,logp,coeff]=classify(XY,Tr,Gr,'Linear');
hold on;
gscatter(X,Y,C,'rb','.',1,'off');
K = coeff(1,2).const;
L = coeff(1,2).linear;
f = @(x,y) K + [x y]*L ;
h2 = ezplot(f,[0 0.00001 0 0.000001]);
set(h2,'Color','m','LineWidth',2)
axis([0 0.00001 0 0.000001])
xlabel('Musculo extensor')
ylabel('Musculo flexor')
title('{\bf Classificacao do movimento}')

end