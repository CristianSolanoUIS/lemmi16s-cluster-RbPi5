<#
.SINOPSIS
    Corre Kraken2+Bracken nativo en WSL2 con el protocolo comun de las 3 plataformas:
    60 s de estabilizacion sin medir, 5 min de reposo medido (baseline_pre) y despues
    las 5 muestras seguidas, una detras de otra, dentro de UNA sola ventana de medicion (fase run).
    (La version anterior usaba 30 s de pre y sin estabilizacion: -EstabilizacionSegundos 0 -BaselineSegundos 30)
    Cada muestra sigue llamando a kraken2/bracken por separado (igual que antes).
    Mide con LibreHardwareMonitor usando medir_fase.ps1.

    Salidas:
      - energia_kraken2_x86_LOTE_<fecha>.csv  (timestamp, muestra, fase, power_w)
      - marcas_kraken2_x86_LOTE_<fecha>.csv   (inicio y fin de cada muestra, para
        poder separar el lote por muestra si se necesita)
      - predicciones en lemmi16s/benchmark/analysis_outputs/kraken2 (con la fecha)

.REQUISITOS
    - LibreHardwareMonitor abierto como Administrador, Remote Web Server activo (puerto 8085)
    - Laptop conectada a la corriente y sin otros programas pesados abiertos

.USO
    & C:\medicioenergia\kraken2\run_kraken2_x86_lote.ps1
#>

param(
    [string[]]$Muestras = @("c001","c002","c003","e001","e002"),
    [int]$EstabilizacionSegundos = 60,
    [int]$BaselineSegundos = 300
)

$ErrorActionPreference = "Continue"
$scriptDir = $PSScriptRoot
$medirFase = Join-Path (Split-Path $scriptDir -Parent) "medir_fase.ps1"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = Join-Path $scriptDir "energia_kraken2_x86_LOTE_$timestamp.csv"
$marcasWin = Join-Path $scriptDir "marcas_kraken2_x86_LOTE_$timestamp.csv"
$marcasWsl = "/mnt/c/medicioenergia/kraken2/marcas_kraken2_x86_LOTE_$timestamp.csv"
Start-Transcript -Path (Join-Path $scriptDir "_log_kraken2_x86_LOTE_$timestamp.txt") | Out-Null

# que la laptop no se suspenda durante la medicion
Add-Type -Namespace Win32 -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
[void][Win32.Power]::SetThreadExecutionState([uint32]2147483651)   # ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED

function Start-Medicion {
    param([string]$Muestra, [string]$Fase)
    Start-Process -FilePath "powershell.exe" `
        -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$medirFase,"-CsvPath",$csvPath,"-Muestra",$Muestra,"-Fase",$Fase) `
        -WorkingDirectory $scriptDir -WindowStyle Hidden -PassThru
}

function Stop-Medicion {
    param($proc)
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
}

# comprobar que LibreHardwareMonitor responde antes de empezar
try { Invoke-RestMethod -Uri "http://localhost:8085/data.json" -TimeoutSec 5 | Out-Null }
catch { Write-Host "LibreHardwareMonitor no responde en el puerto 8085. Abrelo como Administrador y activa Remote Web Server." -ForegroundColor Red; exit 1 }

Write-Host "=== Kraken2 x86 (WSL2) en lote: $($Muestras -join ', ') ===" -ForegroundColor Cyan
Write-Host "CSV de energia: $csvPath"

# 0. estabilizacion sin medir
Write-Host "[0/2] Estabilizacion ($EstabilizacionSegundos s, sin medir)..." -ForegroundColor Yellow
Start-Sleep -Seconds $EstabilizacionSegundos

# 1. reposo previo
Write-Host "[1/2] Reposo previo ($BaselineSegundos s). No toques el equipo..." -ForegroundColor Yellow
$pPre = Start-Medicion -Muestra "lote" -Fase "baseline_pre"
Start-Sleep -Seconds $BaselineSegundos
Stop-Medicion -proc $pPre
Start-Sleep -Seconds 3

# 2. las 5 muestras seguidas en una sola ventana de medicion
Write-Host "[2/2] Corriendo las $($Muestras.Count) muestras seguidas..." -ForegroundColor Yellow
$pRun = Start-Medicion -Muestra "lote" -Fase "run"
Start-Sleep -Seconds 1

$inicio = Get-Date
# el ciclo de muestras vive en kraken2_lote.sh (misma carpeta), asi no se arma bash dentro de un texto
$argsWsl = @("-d", "Ubuntu-22.04", "--", "bash", "/mnt/c/medicioenergia/kraken2/kraken2_lote.sh", $timestamp, $marcasWsl) + $Muestras
& wsl.exe @argsWsl
$exitCode = $LASTEXITCODE
$duracion = ((Get-Date) - $inicio).TotalSeconds

Start-Sleep -Seconds 2
Stop-Medicion -proc $pRun
[void][Win32.Power]::SetThreadExecutionState([uint32]2147483648)   # ES_CONTINUOUS: vuelve a lo normal

Write-Host ""
Write-Host "=== Listo: $($duracion.ToString('F1')) s para las $($Muestras.Count) muestras (exit code $exitCode) ===" -ForegroundColor Green
Write-Host "Energia: $csvPath"
Write-Host "Marcas por muestra: $marcasWin"
if (Test-Path $marcasWin) { Import-Csv $marcasWin | Format-Table -AutoSize }
Stop-Transcript | Out-Null
