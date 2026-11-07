<#
  Gera o instalador do zero, a partir da tag oficial do bezumiya/GoLiveBypass.

  Precisa: Git, Node.js 24+, Go 1.26+ e Inno Setup 6 (ISCC.exe).
  Uso:     powershell -ExecutionPolicy Bypass -File build.ps1 -Version 2.0.16
  Saída:   dist\GoLiveBypass-Instalador-<versão>.exe (+ .sha256)
#>
param(
  [string]$Version = "2.0.16",
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

& $Iscc "/DAppVersion=$Version" "/DSourceExe=$exe" (Join-Path $PSScriptRoot "installer\GoLiveBypass-Instalador.iss")
if ($LASTEXITCODE) { throw "ISCC falhou" }

$out = Join-Path $PSScriptRoot "dist\GoLiveBypass-Instalador-$Version.exe"
$hash = (Get-FileHash $out -Algorithm SHA256).Hash.ToLower()
"$hash  GoLiveBypass-Instalador-$Version.exe" | Out-File -Encoding ascii "$out.sha256"
"Instalador: $out"
"SHA-256:    $hash"
