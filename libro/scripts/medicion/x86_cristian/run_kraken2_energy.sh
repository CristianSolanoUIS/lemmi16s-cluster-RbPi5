#!/usr/bin/env bash
# ==============================================================================
# PIPELINE KRAKEN 2 + BRACKEN: BENCHMARK Y TELEMETRÍA ENERGÉTICA (PC LOCAL x86)
# ==============================================================================
# Metodología:
#   - Clasificación taxonómica directa por coincidencia exacta de k-mers (k=35).
#   - Re-estimación bayesiana de abundancias con Bracken a nivel de Género (-l G -r 150 -t 10).
#   - Base de datos: HOMD_v4_GTDB (125,203 referencias GTDB completas).
#   - Estandarización de formato LEMMI con editResult.py.
#   - Telemetría energética de 2 fases (Baseline Pre de 30s y Medición Activa en carga)
#     mediante Intel RAPL sysfs (Package / CPU Cores).
#
# Uso:
#   ./run_kraken2_energy.sh [muestra|all]
#
# Ejemplos:
#   ./run_kraken2_energy.sh c001       # Ejecuta solo muestra c001
#   ./run_kraken2_energy.sh all        # Ejecuta el lote completo (c001..e002)
# ==============================================================================
set -e

SAMPLE_REQ="${1:-all}"

BASE_DIR="/home/cristian-solano/lemmi16s"
PROYECTOS_DIR="/home/cristian-solano/proyectos"
MEDIR_DIR="${BASE_DIR}/medicion_energia"
NATIVAS_DIR="${MEDIR_DIR}/nativas"
OUT_DIR="${BASE_DIR}/benchmark/nativos"
LOGS_DIR="${PROYECTOS_DIR}/logs_nativos"
WORK_DIR="/tmp/run_kraken2_pc_${SAMPLE_REQ}"

K2_ENV="${PROYECTOS_DIR}/miniconda3/envs/kraken2_env/bin"
DB_DIR="${BASE_DIR}/benchmark/tmp/kraken2_16s_HOMD_v4_GTDB/tmp_HOMD_v4_GTDB/database"
INST_DIR="${BASE_DIR}/benchmark/instances/HOMD_v4_GTDB"
INST_NAME="HOMD_v4_GTDB"
EDIT_PY="${BASE_DIR}/resources/candidate_containers/kraken_213_lemmi16s/scripts/editResult.py"
ALL_SAMPLES=("c001" "c002" "c003" "e001" "e002")

# Verificación de permisos RAPL
if [ ! -r /sys/class/powercap/intel-rapl:0/energy_uj ]; then
    echo "=========================================================================="
    echo "[ERROR] /sys/class/powercap/intel-rapl:0/energy_uj no tiene permisos de lectura."
    echo "Ejecuta en tu terminal:"
    echo "  sudo chmod 444 /sys/class/powercap/intel-rapl:0/energy_uj"
    echo "=========================================================================="
    exit 1
fi

# Verificación de base de datos
if [ ! -f "${DB_DIR}/hash.k2d" ]; then
    echo "[ERROR] Base de datos no encontrada en: ${DB_DIR}"
    exit 1
fi

mkdir -p "$WORK_DIR" "$NATIVAS_DIR" "$OUT_DIR" "$LOGS_DIR"
rm -rf "$WORK_DIR"/*

if [[ "$SAMPLE_REQ" == "all" ]]; then
    SAMPLES=("${ALL_SAMPLES[@]}")
else
    SAMPLES=("$SAMPLE_REQ")
fi

RUN_TAG="kraken2_Nativo_${SAMPLE_REQ}_$(date +%Y%m%d_%H%M%S)"

echo "=========================================================================="
echo "=== BENCHMARK ENERGÉTICO NATIVO: Kraken 2 + Bracken (PC LOCAL x86_64) ==="
echo "=========================================================================="
echo "Fecha y hora:        $(date)"
echo "Instancia:           ${INST_NAME}"
echo "Base de datos:       ${DB_DIR} ($(du -sh "${DB_DIR}" | cut -f1))"
echo "Muestras a evaluar:  ${SAMPLES[*]}"
echo "Directorio salida:   ${OUT_DIR}"
echo "Directorio telemet:  ${NATIVAS_DIR}"
echo "=========================================================================="

# --- 1. BASELINE PRE-EJECUCIÓN (30s Idle) ---
echo "[TELEMETRIA] [1/2] Registrando línea base previa (Idle - 30 segundos)..."
cd "$NATIVAS_DIR"
python3 "${MEDIR_DIR}/medir_energia_rapl.py" \
  -e "baseline_pre_kraken2" \
  -i 1.0 \
  -d 30 \
  -o "${NATIVAS_DIR}" > "${LOGS_DIR}/baseline_pre_kraken2.log" 2>&1

echo "[TELEMETRIA] Línea base previa completada. Esperando 3s..."
sleep 3

# --- 2. TELEMETRÍA DURANTE LA EJECUCIÓN ---
echo "[TELEMETRIA] [2/2] Iniciando telemetría activa en segundo plano..."
cd "$NATIVAS_DIR"
python3 "${MEDIR_DIR}/medir_energia_rapl.py" \
  -e "${RUN_TAG}" \
  -i 1.0 \
  -o "${NATIVAS_DIR}" > "${LOGS_DIR}/telemetria_kraken2.log" 2>&1 &
RUN_PID=$!
sleep 1

# Trampa para asegurar terminación limpia del proceso de telemetría si se interrumpe
trap 'kill -TERM "$RUN_PID" 2>/dev/null || true; exit 1' INT TERM ERR

start_time=$(date +%s)
total_reads=0

# --- 3. PROCESAMIENTO DE MUESTRAS ---
for s in "${SAMPLES[@]}"; do
    s_dir="${INST_DIR}/${INST_NAME}-${s}"
    r1="${s_dir}/queryReads1.fq"
    r2="${s_dir}/queryReads2.fq"

    if [ ! -f "$r1" ]; then
        echo "[ERROR] No se encontró FASTQ: $r1"
        kill -TERM "$RUN_PID" 2>/dev/null || true
        exit 1
    fi

    lines=$(wc -l < "$r1")
    n_reads=$(( lines / 4 ))
    total_reads=$(( total_reads + n_reads ))

    echo "--------------------------------------------------------------------------"
    echo ">>> [Kraken 2] Procesando ${INST_NAME}-${s} (${n_reads:,} reads pareadas)..."
    echo "--------------------------------------------------------------------------"

    cd "$WORK_DIR"

    # Paso 1: Clasificación de k-mers
    "${K2_ENV}/kraken2" \
      --db "$DB_DIR" \
      --threads 4 \
      --paired "$r1" "$r2" \
      --output "${WORK_DIR}/query_${s}.out" \
      --report "${WORK_DIR}/query_${s}.report"

    # Paso 2: Re-estimación de abundancia con Bracken a nivel Género (-t 10 para filtro ruido LEMMI)
    "${K2_ENV}/bracken" \
      -d "$DB_DIR" \
      -i "${WORK_DIR}/query_${s}.report" \
      -o "${WORK_DIR}/query_${s}.bracken" \
      -w "${WORK_DIR}/query_bracken_${s}.report" \
      -l G \
      -r 150 \
      -t 10

    # Paso 3: Conversión al formato estándar de predicciones LEMMI
    python3 "$EDIT_PY" \
      "${WORK_DIR}/query_bracken_${s}.report" \
      "${WORK_DIR}/results_${s}.tsv" \
      "${WORK_DIR}/summary_tax_${s}.tsv"

    out_tsv="${OUT_DIR}/kraken2_native.${INST_NAME}-${s}.predictions.tsv"
    cp "${WORK_DIR}/results_${s}.tsv" "$out_tsv"

    echo "[OK] Predicción guardada: ${out_tsv} ($(wc -l < "$out_tsv") líneas)"
done

end_time=$(date +%s)
duration=$((end_time - start_time))

sleep 2
echo "[TELEMETRIA] Deteniendo telemetría de corrida (PID $RUN_PID)..."
kill -TERM "$RUN_PID" 2>/dev/null || true
wait "$RUN_PID" 2>/dev/null || true
trap - INT TERM ERR
sleep 3

rm -rf "$WORK_DIR"

# --- 4. REPORTE ENERGÉTICO CONSOLIDADO ---
echo "=========================================================================="
echo "=== RESUMEN ENERGÉTICO CONSOLIDADO: Kraken 2 + Bracken (PC LOCAL x86) ==="
echo "=========================================================================="

python3 -c "
import glob, csv, sys
from pathlib import Path

medir_dir = Path('${NATIVAS_DIR}')
run_tag = '${RUN_TAG}'

def get_powers(pattern):
    matches = list(medir_dir.glob(pattern))
    if not matches:
        return None, []
    path = sorted(matches, key=lambda p: p.stat().st_mtime)[-1]
    powers = []
    with open(path) as f:
        r = csv.reader(f)
        next(r, None)
        for row in r:
            if len(row) >= 2:
                try: powers.append(float(row[1]))
                except ValueError: pass
    return path.name, powers

pre_file, pre_p = get_powers('*baseline_pre_kraken2*.csv')
run_file, run_p = get_powers(f'*{run_tag}*.csv')

avg_pre = sum(pre_p)/len(pre_p) if pre_p else 0.0
avg_base = avg_pre

dur_s = len(run_p)
dur_h = dur_s / 3600.0
e_gross = sum(p/3600.0 for p in run_p)
e_base = avg_base * dur_h
e_net = max(0.0, e_gross - e_base)

reads = int('${total_reads}')
rw_gross = (reads / e_gross) if e_gross > 0 else 0
rw_net = (reads / e_net) if e_net > 0 else 0

print(f'Pipeline Evaluado:      Kraken 2 + Bracken (-t 10)')
print(f'Muestras Procesadas:    ${#SAMPLES[@]} (${SAMPLES[*]})')
print(f'Lecturas Totales:       {reads:,}')
print(f'Duración de Corrida:    ${duration} s (${duration}/60:.2f min)')
print(f'Duración Telemetría:    {dur_s} s')
print(f'Potencia Baseline Pre:  {avg_pre:.3f} W ({pre_file})')
print(f'Energía Bruta Consumida:{e_gross:.4f} Wh ({run_file})')
print(f'Energía Neta (Atribuib):{e_net:.4f} Wh')
print(f'Eficiencia Bruta:       {rw_gross:,.1f} Reads/Wh')
print(f'Eficiencia Neta:        {rw_net:,.1f} Reads/Wh')
"

echo "=========================================================================="
echo "[ÉXITO] Pipeline Kraken 2 finalizado correctamente."
echo "Predicciones en:       ${OUT_DIR}"
echo "Telemetría RAPL en:    ${NATIVAS_DIR}"
echo "=========================================================================="
