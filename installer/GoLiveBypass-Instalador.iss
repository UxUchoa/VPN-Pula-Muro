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

#define AppName "GoLiveBypass"
#define AppExe "GoLiveBypass.exe"
#define RunValue "GoLiveBypass"

[Setup]
AppId={{D599304B-B876-4853-AE4F-2127645D818A}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion} (instalador não oficial)
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
UninstallDisplayName={#AppName} (Discord com VPN)
SetupIconFile=icon.ico
InfoBeforeFile=LEIA-ANTES.txt
OutputDir=..\dist
OutputBaseFilename=GoLiveBypass-Instalador-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

[Languages]
Name: "ptbr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Messages]
ptbr.FinishedLabel=Pronto!%n%nDaqui em diante use o atalho "Discord com VPN": ele liga a VPN e abre o Discord já por ela.%n%nPara fechar use Sair (botão direito no ícone da bandeja). Não use Desativar, senão o atalho não liga a VPN na próxima vez.%n%nSe pulou a opção de iniciar com o Windows, dá para ligar depois no GoLiveBypass (ícone da bandeja > Iniciar com Windows).

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

procedure AbrirApp();
var
  Code: Integer;
begin
  ShellExec('', ExpandConstant('{app}\{#AppExe}'), '', ExpandConstant('{app}'), SW_SHOWNORMAL, ewNoWait, Code);
end;

{ ---------- inicialização ---------- }

procedure LigarInicioComWindows();
var
  Atual: AnsiString;
begin
  RegWriteStringValue(HKCU, RunKey, '{#RunValue}', '"' + ExpandConstant('{app}\{#AppExe}') + '" --hidden');
  { Se a pessoa tinha desligado o GoLiveBypass em Aplicativos de inicialização, religa. }
  if RegQueryBinaryValue(HKCU, ApprovedKey, '{#RunValue}', Atual) and (Length(Atual) > 0) and (Ord(Atual[1]) <> 2) then
    RegWriteBinaryValue(HKCU, ApprovedKey, '{#RunValue}', #2#0#0#0#0#0#0#0#0#0#0#0);
  Log('Iniciar com o Windows: ligado');
end;

procedure BloquearAutostartDiscord();
var
  Atual: AnsiString;
begin
  { Mesmo interruptor de Configurações > Aplicativos > Inicialização: o Discord pode regravar
    a entrada dele na Run, mas o Windows continua sem abrir. Byte 03 = desativado. }
  if RegQueryBinaryValue(HKCU, ApprovedKey, 'Discord', Atual) and (Length(Atual) > 0) and (Ord(Atual[1]) = 3) then
  begin
    Log('Autostart do Discord já estava desligado');
    Exit;
  end;
  RegWriteBinaryValue(HKCU, ApprovedKey, 'Discord', #3#0#0#0#0#0#0#0#0#0#0#0);
  RegWriteDWordValue(HKCU, OwnKey, 'DiscordAutostartBloqueado', 1);
  Log('Autostart do Discord: bloqueado');
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
            'Se não: nada muda na inicialização. Use o atalho "Discord com VPN" quando quiser.' + #13#10#13#10 +
            'Dá para mudar depois nas caixinhas desta tela ou no GoLiveBypass (ícone da bandeja > Iniciar com Windows).',
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
    LblStatus.Caption := 'VPN ativada! Inicialização do Windows sem mudanças.';
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
    if ChkIniciar.Enabled and ChkIniciar.Checked then LigarInicioComWindows();
    if ChkBloquearDiscord.Enabled and ChkBloquearDiscord.Checked then BloquearAutostartDiscord();
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
var
  Data: String;
  Marcado: Cardinal;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    { Remove a inicialização só se ela aponta para esta instalação (o app também pode ter gravado). }
    if RegQueryStringValue(HKCU, RunKey, '{#RunValue}', Data) then
      if Pos(Lowercase(ExpandConstant('{app}')), Lowercase(Data)) > 0 then
        RegDeleteValue(HKCU, RunKey, '{#RunValue}');
    { Devolve o autostart do Discord se fomos nós que bloqueamos. }
    if RegQueryDWordValue(HKCU, OwnKey, 'DiscordAutostartBloqueado', Marcado) and (Marcado = 1) then
      RegWriteBinaryValue(HKCU, ApprovedKey, 'Discord', #2#0#0#0#0#0#0#0#0#0#0#0);
    RegDeleteKeyIncludingSubkeys(HKCU, OwnKey);
    RemoveDir(ExpandConstant('{app}'));
  end;
end;
