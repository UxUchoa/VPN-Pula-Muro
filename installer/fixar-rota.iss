{ Incluído pelo GoLiveBypass-Instalador.iss (seção [Code]) e pelo teste de rota. }

{ Fixa a rota que o app mediu na primeira ativação.
  Com protonRoutePreference "auto", todo boot (e todo clique no atalho --hidden) o app mede as rotas
  de novo com uma cópia do proton-confgen chamada golive-speed-probe.exe, numa pasta %TEMP% com nome
  aleatório. O Firewall do Windows guarda a permissão pelo caminho do exe, então pergunta de novo a
  cada boot. Com "manual" e uma rota salva, o boot pula a medição e usa a rota salva
  (optimizeProtonRouteAtStartup); o failover do plano Free continua funcionando, ele não olha essa
  preferência. O app volta para "auto" sozinho se a pessoa otimizar a rota pela janela dele. }
procedure FixarRotaMedida(const Dir: String);
var
  Arq, Chave: String;
  S, Novo: AnsiString;
  P: Integer;
begin
  Arq := Dir + '\settings.json';
  if not LoadStringFromFile(Arq, S) then Exit;
  if (Pos('"protonRoutePreference": "manual"', S) > 0) or (Pos('"protonRoutePreference":"manual"', S) > 0) then
  begin
    Log('Rota Proton já fixa (manual)');
    Exit;
  end;
  if (Pos('"vpnMode": "custom"', S) > 0) or (Pos('"vpnMode":"custom"', S) > 0) then Exit;
  if (Pos('"protonLastServer"', S) = 0) or not FileExists(Dir + '\wireguard.conf') then
  begin
    Log('Nenhuma rota Proton medida ainda; rota não fixada');
    Exit;
  end;

  Chave := '"protonRoutePreference": "auto"';
  P := Pos(Chave, S);
  if P = 0 then
  begin
    Chave := '"protonRoutePreference":"auto"';
    P := Pos(Chave, S);
  end;
  if P > 0 then
    Novo := Copy(S, 1, P - 1) + '"protonRoutePreference": "manual"' + Copy(S, P + Length(Chave), Length(S))
  else
  begin
    { Chave ausente: entra logo depois do "{" que abre o objeto. }
    P := Pos('{', S);
    if (P = 0) or (Pos('"protonRoutePreference"', S) > 0) then Exit;
    Novo := Copy(S, 1, P) + #10 + '  "protonRoutePreference": "manual",' + Copy(S, P + 1, Length(S));
  end;

  FileCopy(Arq, Arq + '.antes-do-instalador', False);
  if SaveStringToFile(Arq, Novo, False) then
    Log('Rota Proton fixada: o boot usa a rota medida na primeira ativação')
  else
  begin
    FileCopy(Arq + '.antes-do-instalador', Arq, False);
    Log('Falha ao gravar settings.json; original restaurado');
  end;
end;
