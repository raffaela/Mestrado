

a = [zeros(1,40), ones(1,20),zeros(1,40)];
a = a + 0.2*randn(size(a));



La = 10;
Ld = 10;
Lm = 0.4;
p = [];
for k = (La):(length(a) - Ld),
    if (length(find(a((k-La+1):k)<Lm))==La) && (length(find(a((k+1):(k+Ld))>=Lm))==Ld)
        p = [p,k];
    end
end

plot(a); shg;
hold on;
plot(p,a(p),'r.');
hold off;


