#!/usr/bin/env bash
# ==============================================================================
# PIPELINE LOTUS3: BENCHMARK Y TELEMETRÍA ENERGÉTICA NATIVA (PC LOCAL x86_64)
# ==============================================================================
# Metodología:
#   - Pipeline de amplicones de alto rendimiento (SDM demux/quality, dereplicación,
#     clustering de OTUs y denoising de ASVs contra base de referencia SILVA).
#   - LotuS3 opera sobre la muestra completa para construir la matriz de abundancia.
#   - Conversión de tabla OTU.biom a formato TSV mediante 'biom convert'.
#   - Estandarización de formato LEMMI con editResult.py.
#   - Telemetría energética de 2 fases (Baseline Pre de 30s y Medición Activa en carga)
#     mediante Intel RAPL sysfs (Package / CPU Cores).
#
# Uso:
#   ./run_lotus3_energy.sh [muestra|all]
#
# Ejemplos:
#   ./run_lotus3_energy.sh c001        # Ejecuta solo muestra c001
#   ./run_lotus3_energy.sh all         # Ejecuta el lote completo (c001, c002, e001)
# ==============================================================================
set -e

SAMPLE_REQ="${1:-all}"

BASE_DIR="/home/cristian-solano/lemmi16s"
PROYECTOS_DIR="/home/cristian-solano/proyectos"
MEDIR_DIR="${BASE_DIR}/medicion_energia"
NATIVAS_DIR="${MEDIR_DIR}/nativas"
OUT_DIR="${BASE_DIR}/benchmark/nativos"
LOGS_DIR="${PROYECTOS_DIR}/logs_nativos"
WORK_DIR="/tmp/run_lotus3_pc_${SAMPLE_REQ}"

LOTUS_BIN="${PROYECTOS_DIR}/lotus3/lotus3"
BIOM_BIN="${PROYECTOS_DIR}/miniconda3/envs/kraken2_env/bin/biom"
DB_DIR="${BASE_DIR}/benchmark/tmp/lotus303_16s_HM_Contaminated/tmp_HM_Contaminated_Soil/database"
INST_DIR="${BASE_DIR}/benchmark/instances/HM_Contaminated_Soil"
INST_NAME="HM_Contaminated_Soil"
EDIT_PY="${BASE_DIR}/resources/candidate_containers/lotus_303_lemmi16s/scripts/editResult.py"
ALL_SAMPLES=("c001" "c002" "e001")

# Verificación de permisos RAPL
if [ ! -r /sys/class/powercap/intel-rapl:0/energy_uj ]; then
    echo "=========================================================================="
    echo "[ERROR] /sys/class/powercap/intel-rapl:0/energy_uj no tiene permisos de lectura."
    echo "Ejecuta en tu terminal:"
    echo "  sudo chmod 444 /sys/class/powercap/intel-rapl:0/energy_uj"
    echo "=========================================================================="
    exit 1
fi

# Verificación de binario LotuS3 y base de datos
if [ ! -x "$LOTUS_BIN" ]; then
    echo "[ERROR] Binario de LotuS3 no encontrado o no ejecutable: $LOTUS_BIN"
    exit 1
fi

if [ ! -f "${DB_DIR}/reference.fasta" ]; then
    echo "[ERROR] Referencia FASTA no encontrada en: ${DB_DIR}/reference.fasta"
    exit 1
fi

mkdir -p "$WORK_DIR" "$NATIVAS_DIR" "$OUT_DIR" "$LOGS_DIR"
rm -rf "$WORK_DIR"/*

if [[ "$SAMPLE_REQ" == "all" ]]; then
    SAMPLES=("${ALL_SAMPLES[@]}")
else
    SAMPLES=("$SAMPLE_REQ")
fi

RUN_TAG="lotus3_Nativo_${SAMPLE_REQ}_$(date +%Y%m%d_%H%M%S)"

echo "=========================================================================="
echo "=== BENCHMARK ENERGÉTICO NATIVO: LotuS3 v3.0.3 (PC LOCAL x86_64) ==="
echo "=========================================================================="
echo "Fecha y hora:        $(date)"
echo "Instancia:           ${INST_NAME}"
echo "Base de datos:       ${DB_DIR}"
echo "Muestras a evaluar:  ${SAMPLES[*]}"
echo "Directorio salida:   ${OUT_DIR}"
echo "Directorio telemet:  ${NATIVAS_DIR}"
echo "=========================================================================="

# --- 1. BASELINE PRE-EJECUCIÓN (30s Idle) ---
echo "[TELEMETRIA] [1/2] Registrando línea base previa (Idle - 30 segundos)..."
cd "$NATIVAS_DIR"
python3 "${MEDIR_DIR}/medir_energia_rapl.py" \
  -e "baseline_pre_lotus3" \
  -i 1.0 \
  -d 30 \
  -o "${NATIVAS_DIR}" > "${LOGS_DIR}/baseline_pre_lotus3.log" 2>&1

echo "[TELEMETRIA] Línea base previa completada. Esperando 3s..."
sleep 3

# --- 2. TELEMETRÍA DURANTE LA EJECUCIÓN ---
echo "[TELEMETRIA] [2/2] Iniciando telemetría activa en segundo plano..."
cd "$NATIVAS_DIR"
python3 "${MEDIR_DIR}/medir_energia_rapl.py" \
  -e "${RUN_TAG}" \
  -i 1.0 \
  -o "${NATIVAS_DIR}" > "${LOGS_DIR}/telemetria_lotus3.log" 2>&1 &
RUN_PID=$!
sleep 1

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
    echo ">>> [LotuS3] Procesando ${INST_NAME}-${s} (${n_reads:,} reads pareadas)..."
    echo "--------------------------------------------------------------------------"

    sample_work="${WORK_DIR}/${s}"
    mkdir -p "${sample_work}/reads"
    cd "$sample_work"

    # Preparar FASTQ y mapa de secuenciación para LotuS3
    cp "$r1" reads/queryReads1.fq
    cp "$r2" reads/queryReads2.fq

    cat <<EOF > reads/miSeqMap.sm.txt
#SampleID	fastqFile	SequencingRun
Sample1	queryReads1.fq,queryReads2.fq	Run1
EOF

    # Ejecución de LotuS3 (4 hilos, sin árbol filogenético ni lulu para coincidir con contenedor LEMMI)
    "$LOTUS_BIN" \
      -derepMin 1:1,1:2,1:3 \
      -i reads/ \
      -m reads/miSeqMap.sm.txt \
      -o reads-output/ \
      -refDB "${DB_DIR}/reference.fasta" \
      -tax4refDB "${DB_DIR}/reference.tsv" \
      -buildPhylo 0 \
      -lulu 0 \
      -t 4

    # Conversión de matriz BIOM a TSV
    "$BIOM_BIN" convert \
      -i reads-output/OTU.biom \
      -o results.txt \
      --to-tsv \
      --header-key taxonomy

    # Estandarización LEMMI
    python3 "$EDIT_PY" results.txt results.tsv summary_tax.tsv

    out_tsv="${OUT_DIR}/lotus3_native.${INST_NAME}-${s}.predictions.tsv"
    cp results.tsv "$out_tsv"

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
echo "=== RESUMEN ENERGÉTICO CONSOLIDADO: LotuS3 v3.0.3 (PC LOCAL x86) ==="
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

pre_file, pre_p = get_powers('*baseline_pre_lotus3*.csv')
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

print(f'Pipeline Evaluado:      LotuS3 (v3.0.3)')
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
echo "[ÉXITO] Pipeline LotuS3 finalizado correctamente."
echo "Predicciones en:       ${OUT_DIR}"
echo "Telemetría RAPL en:    ${NATIVAS_DIR}"
echo "=========================================================================="
