<#
.SINOPSIS
    Reposo largo (5 min por defecto) en la laptop, sin correr ningún pipeline.
    Sirve para validar que el baseline de 30 s (pre) representa bien el reposo.
    Mide igual que el pre de las corridas: medir_fase.ps1 + LibreHardwareMonitor, 1 lectura por segundo.

    Salida: energia_reposo_5min_x86_<fecha>.csv (timestamp, muestra, fase, power_w) en esta carpeta.

.REQUISITOS
    - LibreHardwareMonitor abierto como Administrador, Remote Web Server activo (puerto 8085)
    - Laptop conectada a la corriente, mismas condiciones que en las corridas
    - No tocar el equipo durante la medición

.USO
    & C:\medicioenergia\general\run_reposo_5min.ps1
    & C:\medicioenergia\general\run_reposo_5min.ps1 -Segundos 60
#>

param([int]$Segundos = 300)

$ErrorActionPreference = "Continue"
$scriptDir = $PSScriptRoot
$medirFase = Join-Path (Split-Path $scriptDir -Parent) "medir_fase.ps1"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = Join-Path $scriptDir "energia_reposo_5min_x86_$timestamp.csv"

try { Invoke-RestMethod -Uri "http://localhost:8085/data.json" -TimeoutSec 5 | Out-Null }
catch { Write-Host "LibreHardwareMonitor no responde en el puerto 8085. Abrelo como Administrador y activa Remote Web Server." -ForegroundColor Red; exit 1 }

# que la laptop no se suspenda durante la medición
Add-Type -Namespace Win32 -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
[void][Win32.Power]::SetThreadExecutionState([uint32]2147483651)

Write-Host "=== Reposo de $Segundos s. No toques el equipo... ===" -ForegroundColor Yellow
Write-Host "CSV: $csvPath"
$p = Start-Process -FilePath "powershell.exe" `
    -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$medirFase,"-CsvPath",$csvPath,"-Muestra","reposo","-Fase","reposo_5min") `
    -WorkingDirectory $scriptDir -WindowStyle Hidden -PassThru
Start-Sleep -Seconds $Segundos
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 500
[void][Win32.Power]::SetThreadExecutionState([uint32]2147483648)

$filas = Import-Csv $csvPath
$prom = ($filas | Measure-Object -Property power_w -Average).Average
Write-Host ("=== Listo: {0} lecturas, promedio {1:N3} W ===" -f $filas.Count, $prom) -ForegroundColor Green
