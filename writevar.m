function writevar(x,k,filename,sheet)
    col = char(64+k);
    N = size(x,1)+1;
    Rg = sprintf([col '2:' col '%i' ],N);
    xlswrite(filename,x,char(sheet),Rg);
end
