<#
.SINOPSIS
    Variante de medir_energia_lhm.ps1 que en vez de crear un CSV nuevo por
    invocacion, agrega filas (timestamp,muestra,fase,power_w) a UN SOLO CSV
    compartido para todo el benchmark. No modifica medir_energia_lhm.ps1.

.USO
    .\medir_fase.ps1 -CsvPath "C:\medicioenergia\energia_lotus3_x86_TODAS.csv" -Muestra "c001" -Fase "baseline_pre"
#>

param(
    [Parameter(Mandatory=$true)][string]$CsvPath,
    [Parameter(Mandatory=$true)][string]$Muestra,
    [Parameter(Mandatory=$true)][string]$Fase,
    [string]$Host_LHM = "localhost",
    [int]$Puerto = 8085,
    [double]$IntervaloSegundos = 1.0
)

$ErrorActionPreference = "Stop"
$url = "http://$($Host_LHM):$Puerto/data.json"

if (-not (Test-Path $CsvPath)) {
    "timestamp,muestra,fase,power_w" | Out-File -FilePath $CsvPath -Encoding utf8
}

function Find-PackagePower {
    param($node)
    if ($null -eq $node) { return $null }
    if ($node.PSObject.Properties.Name -contains "Value" -and
        $node.Text -match "^CPU Package$" -and
        $node.Value -match "W") {
        $numStr = ($node.Value -replace "[^\d.,\-]", "") -replace ",", "."
        if ($numStr -ne "") { return [double]$numStr }
    }
    if ($node.PSObject.Properties.Name -contains "Children") {
        foreach ($child in $node.Children) {
            $result = Find-PackagePower -node $child
            if ($null -ne $result) { return $result }
        }
    }
    return $null
}

try {
    while ($true) {
        $loopStart = Get-Date
        try {
            $data = Invoke-RestMethod -Uri $url -TimeoutSec 5
            $watts = Find-PackagePower -node $data
            if ($null -ne $watts) {
                $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                "$now,$Muestra,$Fase,$watts" | Out-File -FilePath $CsvPath -Append -Encoding utf8
            }
        } catch { }
        $elapsed = (Get-Date) - $loopStart
        $sleep = $IntervaloSegundos - $elapsed.TotalSeconds
        if ($sleep -gt 0) { Start-Sleep -Milliseconds ([int]($sleep * 1000)) }
    }
} finally { }
