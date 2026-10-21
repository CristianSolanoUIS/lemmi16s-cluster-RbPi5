# Exporta las gráficas G1-G4 de los 4 Excel de energía como PNG a figuras\ (abre en solo lectura, no guarda nada).
$X = "C:\Users\zamir\Downloads\Libro_Proyecto_Grado\excel graficas"
$F = "C:\Users\zamir\Downloads\Libro_Proyecto_Grado\figuras"
$libros = [ordered]@{ "graficas_kraken2.xlsx" = "kraken2"; "graficas_lotus3.xlsx" = "lotus3";
                      "graficas_qiime2.xlsx" = "qiime2"; "graficas_qiime2_por_minuto.xlsx" = "qiime2_min" }
$hojas = [ordered]@{ "G1_Cluster_vs_baseline" = "cluster"; "G2_Zamir_vs_baseline" = "wsl2";
                     "G3_Cristian_vs_baseline" = "nativo"; "G4_Comparacion" = "normalizada" }
$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false
try {
  foreach ($lb in $libros.Keys) {
    $wb = $xl.Workbooks.Open((Join-Path $X $lb), 0, $true)   # solo lectura
    foreach ($h in $hojas.Keys) {
      $out = Join-Path $F ("fig_{0}_potencia_{1}.png" -f $libros[$lb], $hojas[$h])
      $null = $wb.Worksheets.Item($h).ChartObjects(1).Chart.Export($out)
      $out
    }
    $wb.Close($false)
  }
} finally { $xl.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null }
