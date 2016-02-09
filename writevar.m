function writevar(x,k,filename)
    col = char(64+k);
    N = size(x,1);
    Rg = sprintf([col '2:' col '%i' ],N);
    xlswrite(filename,x,Rg);
end
