dados=dados_arquivo.dados; 
novo_cursor=[];
for n=length(cursor_info):-1:1
    valor=cursor_info(n).DataIndex;
    novo_cursor=[novo_cursor valor];
end
novo_cursor2=[];
for n=length(cursor_info2):-1:1
    valor=cursor_info2(n).DataIndex;
    novo_cursor2=[novo_cursor2 valor];
end