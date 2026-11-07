; Instalador não oficial do GoLiveBypass (https://github.com/bezumiya/GoLiveBypass), GPLv3.
; Compile com:  ISCC.exe /DAppVersion=2.0.16 /DSourceExe=C:\caminho\GoLiveBypass-2.0.16.exe GoLiveBypass-Instalador.iss
; O build.ps1 na raiz do repositório faz tudo (compila o app a partir da tag oficial e chama o ISCC).

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
ptbr.FinishedLabel=Pronto! Na primeira vez:%n%n1. Abra o GoLiveBypass, entre na sua conta Proton e clique em Ativar (o Windows vai pedir administrador para instalar o WireSock, o motor da VPN).%n2. Depois disso é só usar o atalho "Discord com VPN": ele liga a VPN e abre o Discord já por ela.%n%nPara fechar use Sair (botão direito no ícone da bandeja). Não use Desativar, senão o atalho não liga a VPN na próxima vez.

[Tasks]
Name: "startup"; Description: "Iniciar com o Windows (a VPN sobe e o Discord abre já por ela, sem abrir a janela do bypass)"; GroupDescription: "Opções:"; Flags: unchecked
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

[Registry]
; Mesmo valor que o "Iniciar com Windows" do próprio app grava, então o toggle da bandeja reconhece.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#RunValue}"; ValueData: """{app}\{#AppExe}"" --hidden"; Tasks: startup; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#AppExe}"; Description: "Abrir o GoLiveBypass agora para entrar na conta Proton e ativar"; Flags: nowait postinstall skipifsilent

[Code]
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

function InitializeSetup(): Boolean;
begin
  Result := EsperarFechar('continuar a instalação', ExpandConstant('{srcexe}'), WizardSilent());
end;

function InitializeUninstall(): Boolean;
begin
  Result := EsperarFechar('continuar a desinstalação', '', UninstallSilent());
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Data: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    { O app também pode ter gravado o valor pelo próprio toggle "Iniciar com Windows". }
    if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', '{#RunValue}', Data) then
      if Pos(Lowercase(ExpandConstant('{app}')), Lowercase(Data)) > 0 then
        RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', '{#RunValue}');
    { O auto-update do app deixa o exe antigo como .old ao lado. }
    DeleteFile(ExpandConstant('{app}\{#AppExe}.old'));
    RemoveDir(ExpandConstant('{app}'));
  end;
end;
