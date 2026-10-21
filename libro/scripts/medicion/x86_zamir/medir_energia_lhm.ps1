<#
.SINOPSIS
    Mide consumo energetico del CPU Package (RAPL) via LibreHardwareMonitor
    mientras corre un pipeline (Kraken2, LotuS3, etc.) en WSL2.

.REQUISITOS
    - LibreHardwareMonitor corriendo como Administrador
    - Options > Remote Web Server > Run (puerto por defecto 8085)
    - Verificar antes de usar: http://localhost:8085/data.json en el navegador

.USO
    1. Abre PowerShell como Administrador
    2. cd a la carpeta donde guardaste este script
    3. .\medir_energia_lhm.ps1 -Etiqueta "kraken2_run1"
    4. Cuando el pipeline termine en WSL2, presiona Ctrl+C aqui
    5. Revisa el CSV generado y el resumen impreso en pantalla
#>

param(
    [string]$Etiqueta = "run",
    [string]$Host_LHM = "localhost",
    [int]$Puerto = 8085,
    [double]$IntervaloSegundos = 1.0
)

$ErrorActionPreference = "Stop"
$url = "http://$($Host_LHM):$Puerto/data.json"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = ".\energia_$($Etiqueta)_$timestamp.csv"

# --- Verificar que LibreHardwareMonitor este respondiendo ---
try {
    Invoke-RestMethod -Uri $url -TimeoutSec 5 | Out-Null
} catch {
    Write-Host "ERROR: No se pudo conectar a $url" -ForegroundColor Red
    Write-Host "Verifica que LibreHardwareMonitor este corriendo como Administrador" -ForegroundColor Red
    Write-Host "y que Options > Remote Web Server > Run este activado." -ForegroundColor Red
    exit 1
}

# --- Funcion recursiva para buscar el sensor "CPU Package" en el arbol JSON ---
function Find-PackagePower {
    param($node)

    if ($null -eq $node) { return $null }

    # Nodo hoja con valor tipo "20.5 W"
    if ($node.PSObject.Properties.Name -contains "Value" -and
        $node.Text -match "Package" -and
        $node.Value -match "W") {
        $numStr = ($node.Value -replace "[^\d.,\-]", "") -replace ",", "."
        if ($numStr -ne "") {
            return [double]$numStr
        }
    }

    if ($node.PSObject.Properties.Name -contains "Children") {
        foreach ($child in $node.Children) {
            $result = Find-PackagePower -node $child
            if ($null -ne $result) { return $result }
        }
    }
    return $null
}

Write-Host "=== Medicion de energia iniciada ===" -ForegroundColor Green
Write-Host "Etiqueta: $Etiqueta"
Write-Host "Intervalo: $IntervaloSegundos s"
Write-Host "CSV de salida: $csvPath"
Write-Host "Presiona Ctrl+C para detener cuando el pipeline termine en WSL2."
Write-Host ""

"timestamp,power_w" | Out-File -FilePath $csvPath -Encoding utf8

$energiaWh = 0.0
$muestras = 0
$inicio = Get-Date

try {
    while ($true) {
        $loopStart = Get-Date
        $data = Invoke-RestMethod -Uri $url -TimeoutSec 5
        $watts = Find-PackagePower -node $data

        if ($null -ne $watts) {
            $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            "$now,$watts" | Out-File -FilePath $csvPath -Append -Encoding utf8

            $energiaWh += ($watts * $IntervaloSegundos) / 3600.0
            $muestras++

            Write-Host "`r[$now] Power: $($watts.ToString('F2')) W | Energia acumulada: $($energiaWh.ToString('F4')) Wh | Muestras: $muestras" -NoNewline
        } else {
            Write-Host "`rADVERTENCIA: no se encontro sensor 'Package' en esta muestra" -NoNewline -ForegroundColor Yellow
        }

        $elapsed = (Get-Date) - $loopStart
        $sleep = $IntervaloSegundos - $elapsed.TotalSeconds
        if ($sleep -gt 0) { Start-Sleep -Milliseconds ([int]($sleep * 1000)) }
    }
}
finally {
    $fin = Get-Date
    $duracionSeg = ($fin - $inicio).TotalSeconds
    Write-Host ""
    Write-Host ""
    Write-Host "=== Resumen de medicion ($Etiqueta) ===" -ForegroundColor Green
    Write-Host "Inicio:              $inicio"
    Write-Host "Fin:                 $fin"
    Write-Host "Duracion:            $($duracionSeg.ToString('F1')) s ($(($duracionSeg/60).ToString('F2')) min)"
    Write-Host "Muestras tomadas:    $muestras"
    Write-Host "Energia total:       $($energiaWh.ToString('F4')) Wh"
    Write-Host "Potencia promedio:   $((($energiaWh*3600)/$duracionSeg).ToString('F2')) W"
    Write-Host "CSV guardado en:     $csvPath"
    Write-Host ""
    Write-Host "Recuerda: resta el consumo baseline (standby) medido por separado"
    Write-Host "para obtener la energia neta atribuible al pipeline."
}
