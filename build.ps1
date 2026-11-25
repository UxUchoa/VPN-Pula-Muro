<#
  Gera o instalador do zero: tag oficial do bezumiya/GoLiveBypass + edicao\uxuchoa.patch.

  Precisa: Git, Node.js 24+, Go 1.26+ e Inno Setup 6 (ISCC.exe).
  Uso:     powershell -ExecutionPolicy Bypass -File build.ps1 -Version 2.0.19 -Rev 5
  Saída:   dist\GoLiveBypass-Instalador-<versão>-r<rev>.exe (+ .sha256) e dist\GoLiveBypass-<versão>.exe (portátil, para a release)
#>
param(
  [string]$Version = "2.0.19",
  [string]$Rev = "5",
  [string]$Iscc = "",
  [string]$WorkDir = "$PSScriptRoot\.build"
)
$ErrorActionPreference = "Stop"

function Need($cmd) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "Não achei '$cmd' no PATH." }
}
Need git; Need node; Need npm; Need go

if (-not $Iscc) {
  $candidatos = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
  )
  $Iscc = $candidatos | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $Iscc -or -not (Test-Path $Iscc)) { throw "ISCC.exe do Inno Setup 6 não encontrado. Passe -Iscc <caminho>." }

$src = Join-Path $WorkDir "GoLiveBypass-v$Version"
if (-not (Test-Path $src)) {
  New-Item -ItemType Directory -Force $WorkDir | Out-Null
  git clone --depth 1 --branch "v$Version" https://github.com/bezumiya/GoLiveBypass.git $src
  if ($LASTEXITCODE) { throw "git clone falhou" }
  # Edição UxUchoa: tema azul, sem Discord, issues e atualizações no GitHub do UxUchoa.
  git -C $src apply --whitespace=nowarn (Join-Path $PSScriptRoot "edicao\uxuchoa.patch")
  if ($LASTEXITCODE) { throw "o patch da edição não aplicou na v$Version" }
}

Push-Location (Join-Path $src "golive-gui")
try {
  npm ci --no-audit --no-fund
  if ($LASTEXITCODE) { throw "npm ci falhou" }
  npm run build:win
  if ($LASTEXITCODE) { throw "npm run build:win falhou" }
} finally { Pop-Location }

$exe = Join-Path $src "golive-gui\dist-app\GoLiveBypass-$Version.exe"
if (-not (Test-Path $exe)) { throw "Build não gerou $exe" }

& $Iscc "/DAppVersion=$Version" "/DInstallerRev=$Rev" "/DSourceExe=$exe" (Join-Path $PSScriptRoot "installer\GoLiveBypass-Instalador.iss")
if ($LASTEXITCODE) { throw "ISCC falhou" }

Copy-Item $exe (Join-Path $PSScriptRoot "dist\GoLiveBypass-$Version.exe") -Force
$out = Join-Path $PSScriptRoot "dist\GoLiveBypass-Instalador-$Version-r$Rev.exe"
$hash = (Get-FileHash $out -Algorithm SHA256).Hash.ToLower()
"$hash  GoLiveBypass-Instalador-$Version-r$Rev.exe" | Out-File -Encoding ascii "$out.sha256"
"Instalador: $out"
"SHA-256:    $hash"
