<#
.SINOPSIS
    Corre QIIME2 nativo en WSL2 con el protocolo comun de las 3 plataformas:
    60 s de estabilizacion sin medir, 5 min de reposo medido (baseline_pre) y despues
    las 5 muestras seguidas dentro de UNA sola ventana de medicion (fase run), con 4 hilos.
    Mide con LibreHardwareMonitor (medir_fase.ps1).
    Tarda unos 90 minutos: la laptop debe quedar conectada a la corriente.
    (La version anterior usaba 30 s de pre y sin estabilizacion: -EstabilizacionSegundos 0 -BaselineSegundos 30)

    Salidas (misma carpeta de este script; las corridas viejas van a Viejos\):
      - energia_qiime2_x86_LOTE_<fecha>.csv  (timestamp, muestra, fase, power_w)
      - marcas_qiime2_x86_LOTE_<fecha>.csv   (inicio y fin de cada muestra)
      - _orchestrator_log_qiime2_LOTE_<fecha>.txt
      - predicciones en lemmi16s/benchmark/analysis_outputs/qiime2 (con la fecha)

.USO
    & C:\medicioenergia\qiime2\run_qiime2_x86_lote.ps1
#>

param(
    [string[]]$Muestras = @("c001","c002","c003","e001","e002"),
    [int]$EstabilizacionSegundos = 60,
    [int]$BaselineSegundos = 300
)

$ErrorActionPreference = "Continue"
$scriptDir = $PSScriptRoot
$medirFase = Join-Path (Split-Path $scriptDir -Parent) "medir_fase.ps1"
$outDir = $scriptDir
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = Join-Path $outDir "energia_qiime2_x86_LOTE_$timestamp.csv"
$marcasWin = Join-Path $outDir "marcas_qiime2_x86_LOTE_$timestamp.csv"
$marcasWsl = "/mnt/c/medicioenergia/qiime2/marcas_qiime2_x86_LOTE_$timestamp.csv"
$logPath = Join-Path $outDir "_orchestrator_log_qiime2_LOTE_$timestamp.txt"

function Log { param([string]$t) $l = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $t"; Write-Host $l; $l | Out-File -FilePath $logPath -Append -Encoding utf8 }

# que la laptop no se suspenda durante la medicion
Add-Type -Namespace Win32 -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
[void][Win32.Power]::SetThreadExecutionState([uint32]2147483651)

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

try { Invoke-RestMethod -Uri "http://localhost:8085/data.json" -TimeoutSec 5 | Out-Null }
catch { Write-Host "LibreHardwareMonitor no responde en el puerto 8085. Abrelo como Administrador y activa Remote Web Server." -ForegroundColor Red; exit 1 }

Log "=== QIIME2 x86 (WSL2) en lote: $($Muestras -join ', ') ==="
Log "CSV de energia: $csvPath"

Log "[0/2] Estabilizacion ($EstabilizacionSegundos s, sin medir)..."
Start-Sleep -Seconds $EstabilizacionSegundos

Log "[1/2] Reposo previo ($BaselineSegundos s)..."
$pPre = Start-Medicion -Muestra "lote" -Fase "baseline_pre"
Start-Sleep -Seconds $BaselineSegundos
Stop-Medicion -proc $pPre
Start-Sleep -Seconds 3

Log "[2/2] Corriendo las $($Muestras.Count) muestras seguidas (4 hilos)..."
$pRun = Start-Medicion -Muestra "lote" -Fase "run"
Start-Sleep -Seconds 1

$inicio = Get-Date
$argsWsl = @("-d", "Ubuntu-22.04", "--", "bash", "/mnt/c/medicioenergia/qiime2/qiime2_lote.sh", $timestamp, $marcasWsl) + $Muestras
& wsl.exe @argsWsl 2>&1 | ForEach-Object { Log "$_" }
$exitCode = $LASTEXITCODE
$duracion = ((Get-Date) - $inicio).TotalSeconds

Start-Sleep -Seconds 2
Stop-Medicion -proc $pRun
[void][Win32.Power]::SetThreadExecutionState([uint32]2147483648)

Log "=== Listo: $($duracion.ToString('F1')) s para las $($Muestras.Count) muestras (exit code $exitCode) ==="
