clear all
close all
dados=AbreSinalPEB2;
sinal=dados.ARQdig(4,:);
fs=2000;
t=0:1/fs:(length(sinal)-1)/fs;
[acel_pi]=processa_acel_Raffaela(t,sinal',fs,0);