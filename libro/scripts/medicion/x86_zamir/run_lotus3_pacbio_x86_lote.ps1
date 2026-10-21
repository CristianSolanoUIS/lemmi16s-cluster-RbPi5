<#
.SINOPSIS
    Corre LotuS3 nativo en WSL2 en modo PacBio (5 muestras de Cristian, instancia HM_Contaminated_Soil_PacBio)
    con el protocolo comun de las 3 plataformas:
    60 s de estabilizacion sin medir, 5 min de reposo medido (baseline_pre) y despues
    las 5 muestras seguidas dentro de UNA sola ventana de medicion (fase run).
    Parametros: -derepMin 1:1,1:2,1:3 -p PacBio -s sdm_PacBio_LSSU.txt -buildPhylo 0 -lulu 0 -t 4 -taxAligner vsearch
    (VSEARCH como en el cluster, donde no hay lambda3 para ARM).
    Mide con LibreHardwareMonitor usando medir_fase.ps1 (el mismo de siempre).
    Copia de run_lotus3_x86_lote.ps1 (corrida de 3 muestras); solo cambian las muestras y el script de WSL.

    Salidas (misma carpeta de este script):
      - energia_lotus3_pacbio_x86_LOTE_<fecha>.csv  (timestamp, muestra, fase, power_w)
      - marcas_lotus3_pacbio_x86_LOTE_<fecha>.csv   (inicio y fin de cada muestra)
      - predicciones en lemmi16s/benchmark/analysis_outputs/lotus3_pacbio (con la fecha)

.USO
    & C:\medicioenergia\lotus3\pacbio_5muestras\run_lotus3_pacbio_x86_lote.ps1
#>

param(
    [string[]]$Muestras = @("c001","c002","c003","e001","e002"),
    [int]$EstabilizacionSegundos = 60,
    [int]$BaselineSegundos = 300
)

$ErrorActionPreference = "Continue"
$scriptDir = $PSScriptRoot
$medirFase = "C:\medicioenergia\medir_fase.ps1"
$shWsl = "/mnt/c/medicioenergia/lotus3/pacbio_5muestras/lotus3_pacbio_lote.sh"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = Join-Path $scriptDir "energia_lotus3_pacbio_x86_LOTE_$timestamp.csv"
$marcasWin = Join-Path $scriptDir "marcas_lotus3_pacbio_x86_LOTE_$timestamp.csv"
$marcasWsl = "/mnt/c/medicioenergia/lotus3/pacbio_5muestras/marcas_lotus3_pacbio_x86_LOTE_$timestamp.csv"
Start-Transcript -Path (Join-Path $scriptDir "_log_lotus3_pacbio_x86_LOTE_$timestamp.txt") | Out-Null

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

Write-Host "=== LotuS3 PacBio x86 (WSL2) en lote: $($Muestras -join ', ') ===" -ForegroundColor Cyan
Write-Host "CSV de energia: $csvPath"

# 0. base de referencia y su base de VSEARCH (.vudb): se preparan una sola vez y FUERA de la medicion
Write-Host "[0/2] Revisando la base de referencia y la base de VSEARCH (no se mide)..." -ForegroundColor Yellow
& wsl.exe -d Ubuntu-22.04 -- bash $shWsl preparar | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "No se pudo preparar la base indexada." -ForegroundColor Red; exit 1 }
Write-Host "[0/2] Estabilizacion ($EstabilizacionSegundos s, sin medir)..." -ForegroundColor Yellow
Start-Sleep -Seconds $EstabilizacionSegundos

Write-Host "[1/2] Reposo previo ($BaselineSegundos s). No toques el equipo..." -ForegroundColor Yellow
$pPre = Start-Medicion -Muestra "lote" -Fase "baseline_pre"
Start-Sleep -Seconds $BaselineSegundos
Stop-Medicion -proc $pPre
Start-Sleep -Seconds 3

Write-Host "[2/2] Corriendo las $($Muestras.Count) muestras seguidas..." -ForegroundColor Yellow
$pRun = Start-Medicion -Muestra "lote" -Fase "run"
Start-Sleep -Seconds 1

$inicio = Get-Date
$argsWsl = @("-d", "Ubuntu-22.04", "--", "bash", $shWsl, $timestamp, $marcasWsl) + $Muestras
& wsl.exe @argsWsl
$exitCode = $LASTEXITCODE
$duracion = ((Get-Date) - $inicio).TotalSeconds

Start-Sleep -Seconds 2
Stop-Medicion -proc $pRun
[void][Win32.Power]::SetThreadExecutionState([uint32]2147483648)

Write-Host ""
Write-Host "=== Listo: $($duracion.ToString('F1')) s para las $($Muestras.Count) muestras (exit code $exitCode) ===" -ForegroundColor Green
Write-Host "Energia: $csvPath"
Write-Host "Marcas por muestra: $marcasWin"
Stop-Transcript | Out-Null
