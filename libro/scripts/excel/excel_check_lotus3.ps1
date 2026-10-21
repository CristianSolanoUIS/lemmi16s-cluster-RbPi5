param($path, $outdir)
# ocultar en la leyenda las series del pre (Excel ignora legendEntry de openpyxl) y ajustar el área de trazado
$hide = @{ "G1_Cluster_vs_baseline" = @(7,8,9,10); "G2_Zamir_vs_baseline" = @(2);
           "G3_Cristian_vs_baseline" = @(2); "G4_Comparacion" = @(4,5,6) }
$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false
try {
  $wb = $xl.Workbooks.Open($path)
  foreach ($n in $hide.Keys) {
    $ch = $wb.Worksheets.Item($n).ChartObjects(1).Chart
    $del = $hide[$n] | Sort-Object -Descending
    if ($ch.Legend.LegendEntries().Count -eq $ch.SeriesCollection().Count) { foreach ($k in $del) { $ch.Legend.LegendEntries($k).Delete() } }
    $W = $ch.ChartArea.Width; $H = $ch.ChartArea.Height
    $ch.Legend.Left = $W - $ch.Legend.Width - 10
    $pa = $ch.PlotArea
    $pa.InsideLeft = 62; $pa.InsideTop = 38
    $pa.InsideWidth = $ch.Legend.Left - 62 - 25
    $pa.InsideHeight = $H - 38 - 58
    $xt = $ch.Axes(1).AxisTitle; $yt = $ch.Axes(2).AxisTitle
    $xt.Top = $pa.InsideTop + $pa.InsideHeight + 24
    $xt.Left = $pa.InsideLeft + ($pa.InsideWidth - $xt.Width) / 2
    $yt.Left = 6
    $yt.Top = $pa.InsideTop + ($pa.InsideHeight - $yt.Height) / 2
  }
  $xl.CalculateFull()
  $nf = 0; $ne = 0
  foreach ($ws in $wb.Worksheets) {
    try { $f = $ws.UsedRange.SpecialCells(-4123); $nf += $f.Count } catch {}
    try { $e = $ws.UsedRange.SpecialCells(-4123, 16); $ne += $e.Count; "ERR " + $ws.Name + " " + $e.Address() } catch {}
  }
  "formulas=$nf errores=$ne"
  $b = $wb.Worksheets.Item("Baselines")
  for ($r=2; $r -le 8; $r++) { "{0} {1} n={2} bl={3:N3}" -f $b.Cells.Item($r,1).Text,$b.Cells.Item($r,2).Text,$b.Cells.Item($r,4).Value2,$b.Cells.Item($r,5).Value2 }
  for ($r=12; $r -le 14; $r++) { "{0} n={1} dur={2} bruta={3:N4} neta={4:N4}" -f $b.Cells.Item($r,1).Text,$b.Cells.Item($r,2).Value2,$b.Cells.Item($r,3).Text,$b.Cells.Item($r,4).Value2,$b.Cells.Item($r,5).Value2 }
  foreach ($n in $hide.Keys) { $null = $wb.Worksheets.Item($n).ChartObjects(1).Chart.Export("$outdir\$n.png") }
  $wb.Worksheets.Item(1).Activate()
  $wb.Save(); $wb.Close($true)
} finally { $xl.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null }
