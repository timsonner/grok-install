# Installs or updates Grok Build unified (agent-host) from x.ai as grok.exe. Windows x64, PowerShell 5.1 or newer.
# Usage: & ([scriptblock]::Create((irm <raw url>))) [-Force] [-KeepV1] [-Revert] [-Help]
param([switch]$Force, [switch]$KeepV1, [switch]$Revert, [switch]$Help)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($Help) {
  Write-Host 'Installs or updates Grok Build unified (agent-host) from x.ai as grok.exe.'
  Write-Host 'Usage: grok-install-windows.ps1 [-Force] [-KeepV1] [-Revert]'
  Write-Host '  -Force   reinstall even if current'
  Write-Host '  -KeepV1  leave an old grok 1.x folder (~\.grok\bin) on your user PATH'
  Write-Host '  -Revert  put the old grok 1.x folder first on your user PATH and rename the unified grok.exe to grok2.exe'
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

if ($Revert) {
  $V1Bin = Join-Path $HOME '.grok\bin'
  $UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  $Rest = @($UserPath -split ';' | Where-Object { $_ -and ($_.TrimEnd('\') -ne $Bin) -and ($_.TrimEnd('\') -ne $V1Bin) })
  $Front = @()
  if (Test-Path $V1Bin) { $Front += $V1Bin } else { Write-Host "no old grok 1.x folder at $V1Bin, nothing to put first" }
  $NewPath = ($Front + @($Bin) + $Rest) -join ';'
  if ($NewPath -ne $UserPath) {
    [Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
    Write-Host "user PATH now has the old grok 1.x folder before $Bin"
  }
  if (Test-Path $Exe) {
    Move-Item -Force $Exe (Join-Path $Bin 'grok2.exe')
    Write-Host 'renamed grok.exe to grok2.exe (the unified build stays installed)'
  }
  Write-Host 'reverted. Open a new terminal, then check: Get-Command grok -All; grok --version'
  return
}
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

$V1Bin = Join-Path $HOME '.grok\bin'
$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$Parts = @($UserPath -split ';' | Where-Object { $_ -and ($_.TrimEnd('\') -ne $Bin) })
$DroppedV1 = $false
if (-not $KeepV1) {
  $Kept = @($Parts | Where-Object { $_.TrimEnd('\') -ne $V1Bin })
  $DroppedV1 = $Kept.Count -ne $Parts.Count
  $Parts = $Kept
}
$NewPath = (@($Bin) + $Parts) -join ';'
if ($NewPath -ne $UserPath) {
  [Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
  Write-Host "put $Bin first on your user PATH (open a new terminal to use grok)"
  if ($DroppedV1) { Write-Host "removed old grok 1.x folder $V1Bin from your user PATH (files left in place, use -KeepV1 to skip)" }
}
$env:Path = (@($Bin) + @($env:Path -split ';' | Where-Object { $_ -and ($_.TrimEnd('\') -ne $Bin) -and ($KeepV1 -or $_.TrimEnd('\') -ne $V1Bin) })) -join ';'

Write-Host ("now: " + (& $Exe --version 2>&1 | Select-Object -First 1))
