#!/usr/bin/env bash
# ==============================================================================
# HPL (LINPACK) en la laptop de Cristian (x86, Ubuntu nativo) con el protocolo comun de medicion:
#   60 s sin medir, 300 s de reposo medido (baseline_pre) y HPL medido con RAPL (1 Hz).
# HPL: N = 30000, NB = 192, 4 procesos MPI (uno por nucleo fisico), OpenBLAS (ver correr_hpl.sh).
#
# Antes (una sola vez):
#   bash instalar_hpl.sh ~/hpl
#   sudo chmod 444 /sys/class/powercap/intel-rapl:0/energy_uj
# Uso:
#   bash run_hpl_cristian.sh [carpeta_hpl] [carpeta_salida]
#   (por defecto ~/hpl y ~/lemmi16s/medicion_energia/hpl)
# Al terminar, mandar a Zamir toda la carpeta de salida:
#   energia_*HPL*.csv, pre/energia_baseline_pre_hpl_*.csv, hpl_nativo_*.txt, marcas_hpl_nativo_*.csv
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HPL_DIR="${1:-$HOME/hpl}"
OUT="${2:-$HOME/lemmi16s/medicion_energia/hpl}"
RAPL_PY="${RAPL_PY:-$HOME/lemmi16s/medicion_energia/medir_energia_rapl.py}"
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "$OUT/pre"

[ -r /sys/class/powercap/intel-rapl:0/energy_uj ] || { echo "[ERROR] sin permiso RAPL: sudo chmod 444 /sys/class/powercap/intel-rapl:0/energy_uj"; exit 1; }
[ -x "$HPL_DIR/bin/xhpl" ] || { echo "[ERROR] falta $HPL_DIR/bin/xhpl (correr instalar_hpl.sh)"; exit 1; }
[ -f "$RAPL_PY" ] || { echo "[ERROR] no se encuentra $RAPL_PY (exportar RAPL_PY=/ruta/medir_energia_rapl.py)"; exit 1; }

RUN_PID=""
cleanup() { if [ -n "$RUN_PID" ]; then kill -TERM "$RUN_PID" 2>/dev/null || true; wait "$RUN_PID" 2>/dev/null || true; fi; }
trap cleanup INT TERM EXIT

echo "=== HPL x86 nativo (Cristian), inicio $(date) ==="
echo "[1/3] Estabilizacion 60 s sin medir"
sleep 60

echo "[2/3] Reposo medido 300 s. No toques el equipo..."
python3 "$RAPL_PY" -e "baseline_pre_hpl_$TS" -i 1.0 -d 300 -o "$OUT/pre"
sleep 3

echo "[3/3] HPL con telemetria"
python3 "$RAPL_PY" -e "HPL_nativo_$TS" -i 1.0 -o "$OUT" > "$OUT/telemetria_hpl_$TS.log" 2>&1 &
RUN_PID=$!
sleep 2
bash "$SCRIPT_DIR/correr_hpl.sh" "$HPL_DIR" "$OUT" "nativo_$TS"
sleep 2
cleanup; trap - INT TERM EXIT
echo "=== Listo, fin $(date). Archivos en $OUT ==="
