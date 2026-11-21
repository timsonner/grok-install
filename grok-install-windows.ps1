# Installs or updates Grok Build unified (agent-host) from x.ai as grok.exe. Windows x64, PowerShell 5.1 or newer.
# Usage: & ([scriptblock]::Create((irm <raw url>))) [-Force] [-Help]
param([switch]$Force, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($Help) {
  Write-Host 'Installs or updates Grok Build unified (agent-host) from x.ai as grok.exe.'
  Write-Host 'Usage: grok-install-windows.ps1 [-Force]'
  return
}

try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

if (-not [Environment]::Is64BitOperatingSystem) {
  throw 'this installer is for 64-bit Windows (x64) only'
}

$Base = 'https://x.ai/cli/unified'
$Root = Join-Path $env:LOCALAPPDATA 'grok'
$Dl = Join-Path $Root 'downloads'
$Bin = Join-Path $Root 'bin'
$Exe = Join-Path $Bin 'grok.exe'
$VerFile = Join-Path $Root 'version.txt'
New-Item -ItemType Directory -Force -Path $Dl, $Bin | Out-Null

$V = ((Invoke-WebRequest -UseBasicParsing -Uri "$Base/latest").Content.ToString()).Trim()
if ($V -notmatch '^\d+\.\d+\.\d+$') { throw "bad version from $Base/latest: '$V'" }
$Name = "agent-host-$V-windows-x86_64.exe"
$Target = Join-Path $Dl $Name

$Cur = if (Test-Path $VerFile) { (Get-Content $VerFile -Raw).Trim() } else { '' }
if ($Cur -eq $V -and (Test-Path $Target) -and (Test-Path $Exe) -and -not $Force) {
  Write-Host "already on $V"
} else {
  Write-Host "downloading $V"
  $Sum = ((Invoke-WebRequest -UseBasicParsing -Uri "$Base/$Name.sha256").Content.ToString().Trim() -split '\s+')[0].ToLower()
  $Part = "$Target.part"
  Invoke-WebRequest -UseBasicParsing -Uri "$Base/$Name" -OutFile $Part
  $Got = (Get-FileHash -Algorithm SHA256 -Path $Part).Hash.ToLower()
  if ($Got -ne $Sum) { Remove-Item -Force $Part; throw 'checksum mismatch, nothing changed' }
  Move-Item -Force $Part $Target
  if (Test-Path $Exe) { Move-Item -Force $Exe "$Exe.old" -ErrorAction SilentlyContinue }
  Copy-Item -Force $Target $Exe
  Remove-Item -Force "$Exe.old" -ErrorAction SilentlyContinue
  Set-Content -Path $VerFile -Value $V
  Write-Host "checksum ok, installed $V"
  Get-ChildItem $Dl -Filter 'agent-host-*-windows-x86_64.exe' | Sort-Object LastWriteTime -Descending | Select-Object -Skip 2 | Remove-Item -Force
}

$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($UserPath -split ';') -notcontains $Bin) {
  [Environment]::SetEnvironmentVariable('Path', ($UserPath.TrimEnd(';') + ';' + $Bin).TrimStart(';'), 'User')
  $env:Path += ';' + $Bin
  Write-Host "added $Bin to your user PATH (open a new terminal to use grok)"
}

Write-Host ("now: " + (& $Exe --version 2>&1 | Select-Object -First 1))
