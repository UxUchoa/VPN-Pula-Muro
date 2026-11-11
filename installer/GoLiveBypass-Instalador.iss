; Instalador não oficial do GoLiveBypass (https://github.com/bezumiya/GoLiveBypass), GPLv3.
; Compile com:  ISCC.exe /DAppVersion=2.0.16 /DSourceExe=C:\caminho\GoLiveBypass-2.0.16.exe GoLiveBypass-Instalador.iss
; O build.ps1 na raiz do repositório faz tudo (compila o app a partir da tag oficial e chama o ISCC).
;
; Fluxo: instala -> abre o GoLiveBypass para o login no Proton -> espera a VPN ser ativada ->
; só então pergunta (modal Sim/Não) se o GoLiveBypass deve iniciar antes do Discord. A resposta marca
; as caixinhas "Iniciar com o Windows" e "Impedir o Discord de abrir sozinho", aplicadas ao avançar.
; Modo silencioso: /VERYSILENT [/INICIAR=1] [/BLOQUEARDISCORD=1]

#ifndef AppVersion
  #error Passe /DAppVersion=x.y.z para o ISCC
#endif
#ifndef SourceExe
  #error Passe /DSourceExe=caminho\GoLiveBypass-x.y.z.exe para o ISCC
#endif
; Revisão do instalador (independente da versão do app). Histórico no README, seção "Versões".
;   r1 = 06/11/2026 publicado no GitHub, inicialização pela chave Run
;   r2 = 08/11/2026 tarefa agendada elevada no lugar da chave Run
;   r3 = 11/11/2026 fixa a rota medida na 1ª ativação (sem prompt do firewall a cada boot)
#ifndef InstallerRev
  #define InstallerRev "3"
#endif
#define FullVersion AppVersion + "-r" + InstallerRev

#define AppName "GoLiveBypass"
#define AppExe "GoLiveBypass.exe"
#define RunValue "GoLiveBypass"
#define TaskName "GoLiveBypass - VPN antes do Discord"
; Espera curta depois do logon para a rede subir antes da VPN.
#define TaskDelay "PT10S"

[Setup]
AppId={{D599304B-B876-4853-AE4F-2127645D818A}
AppName={#AppName}
AppVersion={#FullVersion}
AppVerName={#AppName} {#AppVersion} - instalador r{#InstallerRev} (não oficial)
VersionInfoVersion={#AppVersion}.{#InstallerRev}
VersionInfoProductVersion={#AppVersion}.{#InstallerRev}
VersionInfoProductTextVersion={#FullVersion}
VersionInfoDescription=Instalador não oficial do GoLiveBypass {#FullVersion} (Discord com VPN)
AppPublisher=Comunidade - build não oficial do bezumiya/GoLiveBypass
AppPublisherURL=https://github.com/UxUchoa/GoLiveBypass-Instalador
AppSupportURL=https://github.com/UxUchoa/GoLiveBypass-Instalador/issues
AppUpdatesURL=https://github.com/UxUchoa/GoLiveBypass-Instalador/releases
; Instala só para o usuário atual: sem pedir administrador.
PrivilegesRequired=lowest
DefaultDirName={localappdata}\Programs\{#AppName}
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=no
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName} (Discord com VPN) r{#InstallerRev}
SetupIconFile=icon.ico
InfoBeforeFile=LEIA-ANTES.txt
OutputDir=..\dist
OutputBaseFilename=GoLiveBypass-Instalador-{#FullVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

[Languages]
Name: "ptbr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Messages]
ptbr.FinishedLabel=Pronto!%n%nDaqui em diante use o atalho "Discord com VPN": ele liga a VPN e abre o Discord já por ela.%n%nPara fechar use Sair (botão direito no ícone da bandeja). Não use Desativar, senão o atalho não liga a VPN na próxima vez.%n%nPara ligar ou desligar o início com o Windows depois, rode este instalador de novo. Não use a opção "Iniciar com Windows" da bandeja: o instalador já cuida disso.

[Tasks]
Name: "desktopapp"; Description: "Criar também um atalho do GoLiveBypass (janela de configuração) na área de trabalho"; GroupDescription: "Opções:"; Flags: unchecked

[Files]
Source: "{#SourceExe}"; DestDir: "{app}"; DestName: "{#AppExe}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion

[Icons]
; --hidden: o próprio GoLiveBypass sobe só na bandeja e, se a VPN estava ativa da última vez,
; liga o túnel e só depois reabre o Discord por ele.
Name: "{autodesktop}\Discord com VPN"; Filename: "{app}\{#AppExe}"; Parameters: "--hidden"; WorkingDir: "{app}"; Comment: "Liga a VPN do GoLiveBypass e abre o Discord por ela"
Name: "{autoprograms}\Discord com VPN"; Filename: "{app}\{#AppExe}"; Parameters: "--hidden"; WorkingDir: "{app}"; Comment: "Liga a VPN do GoLiveBypass e abre o Discord por ela"
Name: "{autoprograms}\GoLiveBypass (configurar)"; Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"
Name: "{autodesktop}\GoLiveBypass (configurar)"; Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"; Tasks: desktopapp

[UninstallDelete]
Type: files; Name: "{app}\{#AppExe}.old"

[Registry]
; Para conferir no PC de alguém qual instalador está lá: reg query HKCU\Software\GoLiveBypass-Instalador
Root: HKCU; Subkey: "Software\GoLiveBypass-Instalador"; ValueType: string; ValueName: "Versao"; ValueData: "{#FullVersion}"

[Code]
const
  RunKey = 'Software\Microsoft\Windows\CurrentVersion\Run';
  ApprovedKey = 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run';
  OwnKey = 'Software\GoLiveBypass-Instalador';

var
  PaginaLogin: TWizardPage;
  LblStatus: TNewStaticText;
  ChkIniciar, ChkBloquearDiscord: TNewCheckBox;
  BtnAbrir: TNewButton;
  TimerId: LongWord;
  JaPerguntou: Boolean;

function SetTimer(hWnd, nIDEvent, uElapse, lpTimerFunc: LongWord): LongWord; external 'SetTimer@user32.dll stdcall';
function KillTimer(hWnd, uIDEvent: LongWord): BOOL; external 'KillTimer@user32.dll stdcall';

{ ---------- processo aberto ---------- }

function GoLiveBypassRodando(const Proprio: String): Boolean;
var
  Locator, Service, Procs, Proc: Variant;
  I: Integer;
  Nome, Caminho: String;
begin
  Result := False;
  try
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    Service := Locator.ConnectServer('', 'root\CIMV2', '', '');
    Procs := Service.ExecQuery('SELECT Name, ExecutablePath FROM Win32_Process WHERE Name LIKE ''GoLiveBypass%.exe''');
    for I := 0 to Procs.Count - 1 do
    begin
      Proc := Procs.ItemIndex(I);
      Nome := Proc.Name;
      Nome := Lowercase(Nome);
      if VarIsNull(Proc.ExecutablePath) then Caminho := '' else Caminho := Proc.ExecutablePath;
      { O próprio instalador também se chama GoLiveBypass-...exe: não conta como app aberto. }
      if (Pos('golivebypass-instalador', Nome) = 1) or ((Proprio <> '') and (CompareText(Caminho, Proprio) = 0)) then
        Continue;
      Log('GoLiveBypass em execução: ' + Proc.Name + ' ' + Caminho);
      Result := True;
      Exit;
    end;
  except
    Result := False;
  end;
end;

function EsperarFechar(const Acao, Proprio: String; Silencioso: Boolean): Boolean;
begin
  Result := True;
  while GoLiveBypassRodando(Proprio) do
  begin
    { Em modo silencioso o MsgBox responde sozinho: sem esta saída o laço nunca termina. }
    if Silencioso then
    begin
      Log('GoLiveBypass aberto; abortando em modo silencioso.');
      Result := False;
      Exit;
    end;
    if MsgBox('O GoLiveBypass está aberto.' + #13#10#13#10 +
              'Feche ele pelo ícone da bandeja (botão direito > Sair), espere o Discord voltar ao normal ' +
              'e clique em OK para ' + Acao + '.', mbInformation, MB_OKCANCEL) = IDCANCEL then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

{ ---------- estado do app ---------- }

function VpnJaAtivada(): Boolean;
var
  S: AnsiString;
begin
  { bypassEnabled vira true quando a pessoa entra no Proton e ativa pela primeira vez. }
  Result := False;
  if LoadStringFromFile(ExpandConstant('{localappdata}\GoLiveBypass\settings.json'), S) then
    Result := (Pos('"bypassEnabled": true', S) > 0) or (Pos('"bypassEnabled":true', S) > 0);
end;

#include "fixar-rota.iss"

procedure AbrirApp();
var
  Code: Integer;
begin
  ShellExec('', ExpandConstant('{app}\{#AppExe}'), '', ExpandConstant('{app}'), SW_SHOWNORMAL, ewNoWait, Code);
end;

{ ---------- inicialização ---------- }

{ A inicialização é uma tarefa do Agendador de Tarefas, não a chave Run. Num PC real o Windows
  pulou a entrada Run do GoLiveBypass no boot (sem erro nenhum no log) e ainda abriu o Discord
  com o interruptor dele desligado em StartupApproved. A tarefa de logon não depende dessa lista
  e deixa histórico no Agendador. A versão elevada (CriarTarefaAdmin) vai por schtasks /XML com
  "runas", porque registrar tarefa elevada exige administrador; o "--hidden" fica dentro do XML,
  não na linha de comando (o projeto original já teve um "reg.exe add ... Run ... --hidden"
  barrado pelo Defender, #361). A versão sem administrador usa a API COM do Agendador. }

function UsuarioAtual(): String;
begin
  Result := GetEnv('USERDOMAIN') + '\' + GetEnv('USERNAME');
end;

function CriarTarefaInicio(): Boolean;
var
  Service, Folder, Def, Trigger, Acao: Variant;
begin
  Result := False;
  try
    Service := CreateOleObject('Schedule.Service');
    Service.Connect();
    Folder := Service.GetFolder('\');
    Def := Service.NewTask(0);
    Def.RegistrationInfo.Author := '{#AppName} (instalador)';
    Def.RegistrationInfo.Description := 'Ao entrar no Windows, sobe o GoLiveBypass na bandeja: ele liga a VPN e só depois abre o Discord por ela.';
    Def.Principal.UserId := UsuarioAtual();
    Def.Principal.LogonType := 3;            { TASK_LOGON_INTERACTIVE_TOKEN: roda na sessão da pessoa, sem senha }
    Def.Principal.RunLevel := 0;             { TASK_RUNLEVEL_LUA: sem administrador }
    Def.Settings.Enabled := True;
    Def.Settings.DisallowStartIfOnBatteries := False;
    Def.Settings.StopIfGoingOnBatteries := False;
    Def.Settings.ExecutionTimeLimit := 'PT0S';  { o padrão mataria o app depois de 72 h }
    Def.Settings.MultipleInstances := 2;     { TASK_INSTANCES_IGNORE_NEW }
    Def.Settings.StartWhenAvailable := True;
    Def.Settings.Priority := 4;              { o padrão 7 (abaixo do normal) passaria para o Discord }
    Trigger := Def.Triggers.Create(9);       { TASK_TRIGGER_LOGON }
    Trigger.UserId := UsuarioAtual();
    Trigger.Delay := '{#TaskDelay}';
    Acao := Def.Actions.Create(0);           { TASK_ACTION_EXEC }
    Acao.Path := ExpandConstant('{app}\{#AppExe}');
    Acao.Arguments := '--hidden';
    Acao.WorkingDirectory := ExpandConstant('{app}');
    { 6 = criar ou atualizar. Usuário vazio aqui de propósito: com "DOMINIO\usuario" o registro
      falhou num PC real (domínio com acento, UCHÔA). Vazio + logon interativo registra para quem
      está rodando o instalador, e o UserId do Principal/gatilho acima continua valendo. }
    Folder.RegisterTaskDefinition('{#TaskName}', Def, 6, '', '', 3);
    Result := True;
    Log('Tarefa "{#TaskName}" criada para ' + UsuarioAtual());
  except
    Log('Falha ao criar a tarefa de inicialização: ' + GetExceptionMessage());
  end;
end;

{ Tarefa "com privilégios mais altos": o GoLiveBypass pede administrador (UAC) a cada ativação
  para subir o WireSock, e pula esse pedido quando já roda como administrador. No boot, aberto
  pela tarefa em segundo plano, o pedido fica piscando na barra de tarefas e a ativação desiste
  depois de 2 minutos. Com a tarefa elevada não há pedido nenhum no boot. Efeito colateral
  aceito: o Discord, aberto pelo GoLiveBypass, também roda como administrador.
  Registrar uma tarefa elevada exige administrador: é o único "Sim" pedido na instalação. }

function XmlEsc(const S: String): String;
begin
  Result := S;
  StringChangeEx(Result, '&', '&amp;', True);
  StringChangeEx(Result, '<', '&lt;', True);
  StringChangeEx(Result, '>', '&gt;', True);
end;

function SchtasksElevado(const Params: String): Integer;
var
  Code: Integer;
begin
  if ShellExec('runas', ExpandConstant('{sys}\schtasks.exe'), Params, '', SW_HIDE, ewWaitUntilTerminated, Code) then
    Result := Code
  else
    Result := -1;   { "Não" no UAC (1223) ou falha ao abrir }
  Log('schtasks elevado ' + Params + ' -> ' + IntToStr(Result) + ' (' + IntToStr(Code) + ')');
end;

{ O schtasks recusa XML em UTF-8 ("XML mal construído") e aceita UTF-16, que o Inno não grava
  sozinho: o ADODB.Stream do Windows grava UTF-16 LE com BOM. }
function SalvarUtf16(const Arq, Texto: String): Boolean;
var
  Stream: Variant;
begin
  Result := False;
  try
    Stream := CreateOleObject('ADODB.Stream');
    { Type já nasce 2 (texto); "Type" é palavra reservada no Pascal Script e nem compila. }
    Stream.Charset := 'unicode'; { UTF-16 LE }
    Stream.Open();
    Stream.WriteText(Texto);
    Stream.SaveToFile(Arq, 2);   { sobrescrever }
    Stream.Close();
    Result := True;
  except
    Log('Falha ao gravar ' + Arq + ': ' + GetExceptionMessage());
  end;
end;

function CriarTarefaAdmin(): Boolean;
var
  Xml, Arq: String;
begin
  Result := False;
  Arq := ExpandConstant('{tmp}\golivebypass-tarefa.xml');
  Xml :=
    '<?xml version="1.0" encoding="UTF-16"?>' + #13#10 +
    '<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">' + #13#10 +
    '  <RegistrationInfo>' + #13#10 +
    '    <Author>{#AppName} (instalador)</Author>' + #13#10 +
    '    <Description>Ao entrar no Windows, sobe o GoLiveBypass na bandeja como administrador: ele liga a VPN sem pedir confirmação e só depois abre o Discord por ela.</Description>' + #13#10 +
    '  </RegistrationInfo>' + #13#10 +
    '  <Triggers>' + #13#10 +
    '    <LogonTrigger>' + #13#10 +
    '      <Enabled>true</Enabled>' + #13#10 +
    '      <UserId>' + XmlEsc(UsuarioAtual()) + '</UserId>' + #13#10 +
    '      <Delay>{#TaskDelay}</Delay>' + #13#10 +
    '    </LogonTrigger>' + #13#10 +
    '  </Triggers>' + #13#10 +
    '  <Principals>' + #13#10 +
    '    <Principal id="Author">' + #13#10 +
    '      <UserId>' + XmlEsc(UsuarioAtual()) + '</UserId>' + #13#10 +
    '      <LogonType>InteractiveToken</LogonType>' + #13#10 +
    '      <RunLevel>HighestAvailable</RunLevel>' + #13#10 +
    '    </Principal>' + #13#10 +
    '  </Principals>' + #13#10 +
    '  <Settings>' + #13#10 +
    '    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>' + #13#10 +
    '    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>' + #13#10 +
    '    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>' + #13#10 +
    '    <StartWhenAvailable>true</StartWhenAvailable>' + #13#10 +
    '    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>' + #13#10 +
    '    <Priority>4</Priority>' + #13#10 +
    '    <Enabled>true</Enabled>' + #13#10 +
    '  </Settings>' + #13#10 +
    '  <Actions Context="Author">' + #13#10 +
    '    <Exec>' + #13#10 +
    '      <Command>' + XmlEsc(ExpandConstant('{app}\{#AppExe}')) + '</Command>' + #13#10 +
    '      <Arguments>--hidden</Arguments>' + #13#10 +
    '      <WorkingDirectory>' + XmlEsc(ExpandConstant('{app}')) + '</WorkingDirectory>' + #13#10 +
    '    </Exec>' + #13#10 +
    '  </Actions>' + #13#10 +
    '</Task>';
  if not SalvarUtf16(Arq, Xml) then Exit;
  if SchtasksElevado('/Create /TN "{#TaskName}" /XML "' + Arq + '" /F') = 0 then
  begin
    RegWriteDWordValue(HKCU, OwnKey, 'TarefaAdmin', 1);
    Result := True;
    Log('Tarefa "{#TaskName}" criada como administrador');
  end;
  DeleteFile(Arq);
end;

function TarefaAdminMarcada(): Boolean;
var
  V: Cardinal;
begin
  Result := RegQueryDWordValue(HKCU, OwnKey, 'TarefaAdmin', V) and (V = 1);
end;

procedure ApagarTarefaInicio();
var
  Service: Variant;
begin
  try
    Service := CreateOleObject('Schedule.Service');
    Service.Connect();
    Service.GetFolder('\').DeleteTask('{#TaskName}', 0);
    Log('Tarefa "{#TaskName}" removida');
    RegDeleteValue(HKCU, OwnKey, 'TarefaAdmin');
    Exit;
  except
    { Tarefa inexistente também cai aqui. }
    Log('Tarefa de inicialização não removida sem administrador: ' + GetExceptionMessage());
  end;
  { A tarefa elevada pode exigir administrador para ser apagada. }
  if TarefaAdminMarcada() then
    if SchtasksElevado('/Delete /TN "{#TaskName}" /F') = 0 then
      RegDeleteValue(HKCU, OwnKey, 'TarefaAdmin');
end;

{ Entrada Run do GoLiveBypass (gravada pelo próprio app ou por versões antigas do instalador).
  Com a tarefa ligada, ela só serviria para abrir uma segunda cópia no boot. }
procedure ApagarRunDoApp();
begin
  if RegValueExists(HKCU, RunKey, '{#RunValue}') then
  begin
    RegDeleteValue(HKCU, RunKey, '{#RunValue}');
    Log('Entrada Run do GoLiveBypass removida');
  end;
end;

procedure LigarInicioComWindows();
begin
  if CriarTarefaAdmin() then
  begin
    ApagarRunDoApp();
    Log('Iniciar com o Windows: ligado (como administrador)');
    Exit;
  end;
  if TarefaAdminMarcada() then
  begin
    { Recusou o "Sim" numa reinstalação: a tarefa elevada de antes continua valendo. }
    ApagarRunDoApp();
    Log('Iniciar com o Windows: mantida a tarefa elevada existente');
    Exit;
  end;
  if not WizardSilent() then
    MsgBox('Sem a permissão de administrador, o GoLiveBypass ainda vai iniciar com o Windows, ' +
           'mas a cada boot o Windows vai perguntar se ele pode ligar a VPN: clique em Sim quando aparecer ' +
           '(às vezes o pedido fica piscando na barra de tarefas). Para não precisar disso, rode o instalador ' +
           'de novo e aceite o pedido de administrador.', mbInformation, MB_OK);
  if CriarTarefaInicio() then
    ApagarRunDoApp()
  else
  begin
    { Sem o Agendador (política da empresa, serviço parado), fica o caminho antigo. }
    RegWriteStringValue(HKCU, RunKey, '{#RunValue}', '"' + ExpandConstant('{app}\{#AppExe}') + '" --hidden');
    Log('Iniciar com o Windows: ligado pela chave Run (reserva)');
    Exit;
  end;
  Log('Iniciar com o Windows: ligado');
end;

procedure DesligarInicioComWindows();
var
  Data: String;
begin
  ApagarTarefaInicio();
  if RegQueryStringValue(HKCU, RunKey, '{#RunValue}', Data) then
    if Pos(Lowercase(ExpandConstant('{app}')), Lowercase(Data)) > 0 then
      RegDeleteValue(HKCU, RunKey, '{#RunValue}');
  Log('Iniciar com o Windows: desligado');
end;

procedure BloquearAutostartDiscord();
var
  Atual: AnsiString;
  Data: String;
begin
  { A entrada Run do próprio Discord é apagada (e guardada, para a desinstalação devolver):
    o interruptor de StartupApproved sozinho não segurou o Discord num boot real. }
  if RegQueryStringValue(HKCU, RunKey, 'Discord', Data) then
  begin
    RegWriteStringValue(HKCU, OwnKey, 'DiscordRunOriginal', Data);
    RegDeleteValue(HKCU, RunKey, 'Discord');
    Log('Entrada Run do Discord removida e guardada');
  end;
  { Mantém também o interruptor de Configurações > Aplicativos > Inicialização desligado (03),
    para o caso do Discord regravar a entrada dele. }
  if not (RegQueryBinaryValue(HKCU, ApprovedKey, 'Discord', Atual) and (Length(Atual) > 0) and (Ord(Atual[1]) = 3)) then
  begin
    RegWriteBinaryValue(HKCU, ApprovedKey, 'Discord', #3#0#0#0#0#0#0#0#0#0#0#0);
    RegWriteDWordValue(HKCU, OwnKey, 'DiscordAutostartBloqueado', 1);
  end;
  Log('Autostart do Discord: bloqueado');
end;

{ Devolve só o que o instalador mexeu. }
procedure DevolverAutostartDiscord();
var
  Data: String;
  Marcado: Cardinal;
begin
  if RegQueryStringValue(HKCU, OwnKey, 'DiscordRunOriginal', Data) and (Data <> '') then
  begin
    if not RegValueExists(HKCU, RunKey, 'Discord') then
      RegWriteStringValue(HKCU, RunKey, 'Discord', Data);
    RegDeleteValue(HKCU, OwnKey, 'DiscordRunOriginal');
    Log('Entrada Run do Discord devolvida');
  end;
  if RegQueryDWordValue(HKCU, OwnKey, 'DiscordAutostartBloqueado', Marcado) and (Marcado = 1) then
  begin
    RegWriteBinaryValue(HKCU, ApprovedKey, 'Discord', #2#0#0#0#0#0#0#0#0#0#0#0);
    RegDeleteValue(HKCU, OwnKey, 'DiscordAutostartBloqueado');
    Log('Interruptor de inicialização do Discord religado');
  end;
end;

{ ---------- página "entre no Proton" ---------- }

procedure PararTimer();
begin
  if TimerId <> 0 then
  begin
    KillTimer(0, TimerId);
    TimerId := 0;
  end;
end;

procedure PerguntarIniciarAntes();
begin
  JaPerguntou := True;
  ChkIniciar.Enabled := True;
  ChkBloquearDiscord.Enabled := True;
  { O modal só deixa a escolha óbvia: o resultado vai para as caixinhas, que a pessoa ainda pode mudar. }
  if MsgBox('A VPN está ativa!' + #13#10#13#10 +
            'Gostaria que o GoLiveBypass iniciasse antes do Discord quando o Windows ligar?' + #13#10#13#10 +
            'Se sim: ao ligar o PC, o GoLiveBypass sobe primeiro e liga a VPN, e só depois abre o Discord. ' +
            'Você já entra no Discord com o bypass rodando, pronto para compartilhar a tela. ' +
            '(O Discord deixa de abrir sozinho com o Windows: quem abre ele é o GoLiveBypass.)' + #13#10#13#10 +
            'O Windows vai pedir permissão de administrador uma vez agora: é para o GoLiveBypass ligar a VPN ' +
            'no boot sem perguntar nada. Por isso o Discord aberto por ele também roda como administrador.' + #13#10#13#10 +
            'Se não: o GoLiveBypass não inicia com o Windows. Use o atalho "Discord com VPN" quando quiser.' + #13#10#13#10 +
            'Dá para mudar nas caixinhas desta tela antes de avançar, ou depois rodando o instalador de novo.',
            mbConfirmation, MB_YESNO) = IDYES then
  begin
    ChkIniciar.Checked := True;
    ChkBloquearDiscord.Checked := True;
    LblStatus.Caption := 'VPN ativada! O GoLiveBypass vai iniciar antes do Discord.';
  end
  else
  begin
    ChkIniciar.Checked := False;
    ChkBloquearDiscord.Checked := False;
    LblStatus.Caption := 'VPN ativada! O GoLiveBypass não vai iniciar com o Windows.';
  end;
  LblStatus.Font.Color := clGreen;
  WizardForm.NextButton.Caption := SetupMessage(msgButtonNext);
end;

procedure AtualizarPagina();
begin
  if JaPerguntou then Exit;
  if VpnJaAtivada() then
  begin
    { Para o timer antes do modal: senão ele dispara de novo enquanto a pergunta está aberta. }
    PararTimer();
    PerguntarIniciarAntes();
  end
  else
  begin
    LblStatus.Caption := 'Aguardando você entrar no Proton e clicar em Ativar...';
    LblStatus.Font.Color := clWindowText;
    WizardForm.NextButton.Caption := 'Pular';
  end;
end;

procedure TimerProc(H, Msg, IdEvent, Time: LongWord);
begin
  AtualizarPagina();
end;

procedure BtnAbrirClick(Sender: TObject);
begin
  AbrirApp();
end;

procedure InitializeWizard();
var
  Intro: TNewStaticText;
begin
  PaginaLogin := CreateCustomPage(wpInstalling, 'Entre na sua conta Proton',
    'Falta só um passo para a VPN do Discord funcionar.');

  Intro := TNewStaticText.Create(PaginaLogin);
  Intro.Parent := PaginaLogin.Surface;
  Intro.AutoSize := False;
  Intro.WordWrap := True;
  Intro.Width := PaginaLogin.SurfaceWidth;
  Intro.Height := ScaleY(84);
  Intro.Caption :=
    'O GoLiveBypass abriu. Nele:' + #13#10 +
    '1. Entre com a sua conta Proton (a grátis serve).' + #13#10 +
    '2. Clique em Ativar. Na primeira vez o Windows pede administrador para instalar o WireSock (o motor da VPN).' + #13#10 +
    'Assim que a VPN ligar, o instalador pergunta se o GoLiveBypass deve iniciar antes do Discord.';

  BtnAbrir := TNewButton.Create(PaginaLogin);
  BtnAbrir.Parent := PaginaLogin.Surface;
  BtnAbrir.Top := Intro.Top + Intro.Height + ScaleY(4);
  BtnAbrir.Width := ScaleX(220);
  BtnAbrir.Height := ScaleY(24);
  BtnAbrir.Caption := 'Abrir o GoLiveBypass de novo';
  BtnAbrir.OnClick := @BtnAbrirClick;

  LblStatus := TNewStaticText.Create(PaginaLogin);
  LblStatus.Parent := PaginaLogin.Surface;
  LblStatus.Top := BtnAbrir.Top + BtnAbrir.Height + ScaleY(14);
  LblStatus.Font.Style := [fsBold];

  ChkIniciar := TNewCheckBox.Create(PaginaLogin);
  ChkIniciar.Parent := PaginaLogin.Surface;
  ChkIniciar.Top := LblStatus.Top + ScaleY(26);
  ChkIniciar.Width := PaginaLogin.SurfaceWidth;
  ChkIniciar.Height := ScaleY(20);
  ChkIniciar.Caption := 'Iniciar com o Windows (o GoLiveBypass liga a VPN e depois abre o Discord)';
  ChkIniciar.Enabled := False;

  ChkBloquearDiscord := TNewCheckBox.Create(PaginaLogin);
  ChkBloquearDiscord.Parent := PaginaLogin.Surface;
  ChkBloquearDiscord.Top := ChkIniciar.Top + ScaleY(24);
  ChkBloquearDiscord.Width := PaginaLogin.SurfaceWidth;
  ChkBloquearDiscord.Height := ScaleY(20);
  ChkBloquearDiscord.Caption := 'Impedir o Discord de abrir sozinho com o Windows (ele abre pelo GoLiveBypass)';
  ChkBloquearDiscord.Enabled := False;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = PaginaLogin.ID then
  begin
    if not JaPerguntou then
    begin
      LblStatus.Caption := 'Aguardando você entrar no Proton e clicar em Ativar...';
      WizardForm.NextButton.Caption := 'Pular';
      { O modal sai pelo timer, com a página já desenhada na tela. }
      if TimerId = 0 then
        TimerId := SetTimer(0, 0, 1500, CreateCallback(@TimerProc));
    end;
  end
  else
    PararTimer();
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = PaginaLogin.ID then
  begin
    PararTimer();
    if VpnJaAtivada() then FixarRotaMedida(ExpandConstant('{localappdata}\GoLiveBypass'));
    { As caixinhas valem como estado final: rodar o instalador de novo e desmarcar desliga. }
    if ChkIniciar.Enabled then
      if ChkIniciar.Checked then LigarInicioComWindows() else DesligarInicioComWindows();
    if ChkBloquearDiscord.Enabled then
      if ChkBloquearDiscord.Checked then BloquearAutostartDiscord() else DevolverAutostartDiscord();
  end;
end;

procedure DeinitializeSetup();
begin
  PararTimer();
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if WizardSilent() then
    begin
      if VpnJaAtivada() then FixarRotaMedida(ExpandConstant('{localappdata}\GoLiveBypass'));
      if ExpandConstant('{param:INICIAR|0}') = '1' then LigarInicioComWindows();
      if ExpandConstant('{param:BLOQUEARDISCORD|0}') = '1' then BloquearAutostartDiscord();
    end
    else
      AbrirApp();
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result := EsperarFechar('continuar a instalação', ExpandConstant('{srcexe}'), WizardSilent());
end;

{ ---------- desinstalação ---------- }

function InitializeUninstall(): Boolean;
begin
  Result := EsperarFechar('continuar a desinstalação', '', UninstallSilent());
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    { Tarefa + entrada Run que aponte para esta instalação (o app também pode ter gravado). }
    DesligarInicioComWindows();
    { Devolve o autostart do Discord se fomos nós que bloqueamos. }
    DevolverAutostartDiscord();
    RegDeleteKeyIncludingSubkeys(HKCU, OwnKey);
    RemoveDir(ExpandConstant('{app}'));
  end;
end;
