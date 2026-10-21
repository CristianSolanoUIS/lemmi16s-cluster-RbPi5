<#
.SINOPSIS
    HPL (LINPACK) en la laptop de Zamir (WSL2) con el protocolo comun de medicion:
    60 s de estabilizacion sin medir, 5 min de reposo medido (baseline_pre) y HPL medido (fase run).
    Mide con LibreHardwareMonitor usando medir_fase.ps1 (el mismo de siempre).
    HPL: N = 30000, NB = 192, 4 procesos MPI (uno por nucleo fisico), OpenBLAS (ver correr_hpl.sh).

    Salidas en C:\medicioenergia\hpl\:
      - energia_hpl_x86_wsl2_<fecha>.csv   (timestamp, muestra, fase, power_w)
      - hpl_wsl2_<fecha>.txt               salida de HPL (GFLOPS)
      - marcas_hpl_wsl2_<fecha>.csv        inicio y fin de HPL

.USO
    Abrir LibreHardwareMonitor como Administrador (Remote Web Server en el puerto 8085) y luego:
    & "C:\Users\zamir\Downloads\Libro_Proyecto_Grado\scripts\medicion\flops\run_hpl_x86_wsl.ps1"
#>

param(
    [int]$EstabilizacionSegundos = 60,
    [int]$BaselineSegundos = 300,
    [string]$HplWsl = "/home/zamir/hpl"
)

$ErrorActionPreference = "Continue"
$outDir = "C:\medicioenergia\hpl"
New-Item -ItemType Directory -Force $outDir | Out-Null
$medirFase = "C:\medicioenergia\medir_fase.ps1"
$correr = "/mnt/c/Users/zamir/Downloads/Libro_Proyecto_Grado/scripts/medicion/flops/correr_hpl.sh"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = Join-Path $outDir "energia_hpl_x86_wsl2_$timestamp.csv"
Start-Transcript -Path (Join-Path $outDir "_log_hpl_wsl2_$timestamp.txt") | Out-Null

# que la laptop no se suspenda durante la medicion
Add-Type -Namespace Win32 -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
[void][Win32.Power]::SetThreadExecutionState([uint32]2147483651)

function Start-Medicion {
    param([string]$Fase)
    Start-Process -FilePath "powershell.exe" `
        -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$medirFase,"-CsvPath",$csvPath,"-Muestra","hpl","-Fase",$Fase) `
        -WorkingDirectory $outDir -WindowStyle Hidden -PassThru
}

function Stop-Medicion {
    param($proc)
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
}

try { Invoke-RestMethod -Uri "http://localhost:8085/data.json" -TimeoutSec 5 | Out-Null }
catch { Write-Host "LibreHardwareMonitor no responde en el puerto 8085. Abrelo como Administrador y activa Remote Web Server." -ForegroundColor Red; exit 1 }

& wsl.exe -d Ubuntu-22.04 -- test -x "$HplWsl/bin/xhpl"
if ($LASTEXITCODE -ne 0) { Write-Host "Falta HPL en WSL: correr instalar_hpl.sh $HplWsl" -ForegroundColor Red; exit 1 }

Write-Host "=== HPL x86 (WSL2) ===" -ForegroundColor Cyan
Write-Host "[0/2] Estabilizacion ($EstabilizacionSegundos s, sin medir)..." -ForegroundColor Yellow
Start-Sleep -Seconds $EstabilizacionSegundos

Write-Host "[1/2] Reposo previo ($BaselineSegundos s). No toques el equipo..." -ForegroundColor Yellow
$pPre = Start-Medicion -Fase "baseline_pre"
Start-Sleep -Seconds $BaselineSegundos
Stop-Medicion -proc $pPre
Start-Sleep -Seconds 3

Write-Host "[2/2] Corriendo HPL..." -ForegroundColor Yellow
$pRun = Start-Medicion -Fase "run"
Start-Sleep -Seconds 1
& wsl.exe -d Ubuntu-22.04 -- bash $correr $HplWsl "/mnt/c/medicioenergia/hpl" "wsl2_$timestamp"
Start-Sleep -Seconds 2
Stop-Medicion -proc $pRun
[void][Win32.Power]::SetThreadExecutionState([uint32]2147483648)

Write-Host "=== Listo. Energia: $csvPath ===" -ForegroundColor Green
Stop-Transcript | Out-Null
