#!/usr/bin/env bash
# ==============================================================================
# sbatch_multinodo_energy.sh - Kraken 2 + Bracken (Opción A / Muestra por Nodo)
# Asigna 1 muestra biológica completa a cada nodo exclusivo (rbp5-1 a rbp5-5)
# Telemetría PMIC DA9091 continua a 1 Hz (Baseline PRE 30s + Inferencia Activa)
# Cómputo ejecutado con 'nice -n 10' para priorizar muestreo continuo PMIC
# ==============================================================================
set -e

DEFAULT_SAMPLES=("c001" "c002" "c003" "e001" "e002")
if [ $# -gt 0 ]; then
    SAMPLES=("$@")
else
    SAMPLES=("${DEFAULT_SAMPLES[@]}")
fi

BASE_DIR="/shared/users/grupo1/lemmi16s"
INSTANCE="HOMD_v4_GTDB"
MODEL_PATH="${BASE_DIR}/benchmark/tmp/kraken2_16s_HOMD_v4_GTDB/tmp_HOMD_v4_GTDB"
TOOL_NAME="kraken_213_lemmi16s"
ENERGY_SCRIPT="${BASE_DIR}/medicion_energia/medir_energia_pmic.py"
MEDIR_DIR="${BASE_DIR}/medicion_energia/kraken2"
LOGS_DIR="/shared/users/grupo1/logs_slurm"
OUT_DIR="${BASE_DIR}/benchmark/analysis_outputs/kraken2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$MEDIR_DIR" "$LOGS_DIR" "$OUT_DIR"

echo "=========================================================="
echo "=== KRAKEN 2 + BRACKEN MULTINODO (1 muestra por nodo) ==="
echo "=========================================================="

IDLE_NODES=($(sinfo -N -h -p partition1 -t idle -o "%N"))
NUM_IDLE=${#IDLE_NODES[@]}
if [ "$NUM_IDLE" -eq 0 ]; then
    echo "[ERROR] No hay nodos 'idle' en partition1."
    sinfo -p partition1
    exit 1
fi
echo "[NODOS] Idle en partition1: ${IDLE_NODES[*]} ($NUM_IDLE nodos)"
echo "[MUESTRAS] ${SAMPLES[*]} (${#SAMPLES[@]} muestras)"
if [ ${#SAMPLES[@]} -gt "$NUM_IDLE" ]; then
    echo "[AVISO] Hay mas muestras que nodos idle; las sobrantes esperaran turno en la cola."
fi

for SAMPLE in "${SAMPLES[@]}"; do
    QP="${BASE_DIR}/benchmark/instances/${INSTANCE}/${INSTANCE}-${SAMPLE}"
    if [ ! -d "$QP" ]; then
        echo "[ERROR] No existe la muestra: $QP"
        exit 1
    fi
done

WORKER_SCRIPT="${SCRIPT_DIR}/worker_kraken2_energy.sh"
cat << 'WORKER_EOF' > "$WORKER_SCRIPT"
#!/usr/bin/env bash
set -e
NODE=$(hostname)
TMP_DIR="${BASE_DIR}/benchmark/tmp/multinodo_kraken2_${SAMPLE}"
mkdir -p "$TMP_DIR"
rm -rf "${TMP_DIR:?}"/*
cd "$TMP_DIR"

echo "=========================================================="
echo "=== NODO ${NODE} - Kraken 2 muestra completa ${SAMPLE} (job ${SLURM_JOB_ID}) ==="
echo "=========================================================="
echo "Hora inicio: $(date)"

TAG_PRE="baseline_pre_kraken2_${SAMPLE}_node_${NODE}_job${SLURM_JOB_ID}"
TAG_RUN="Kraken2_multinodo_${SAMPLE}_node_${NODE}_job${SLURM_JOB_ID}"

echo "[ESTABILIZACION] [${NODE}] Esperando 60s de reposo antes del baseline..."
sleep 60

echo "[1/2] [${NODE}] Baseline PRE (300s / 5 minutos)..."
sg video -c "python3 \"${ENERGY_SCRIPT}\" -e \"$TAG_PRE\" -i 1.0 -d 300 -o \"${MEDIR_DIR}\""
sleep 3

echo "[2/2] [${NODE}] Telemetria activa en carga..."
sg video -c "python3 \"${ENERGY_SCRIPT}\" -e \"$TAG_RUN\" -i 1.0 -o \"${MEDIR_DIR}\"" \
  > "${LOGS_DIR}/telemetria_kraken2_${SAMPLE}_${SLURM_JOB_ID}.log" 2>&1 &
ENERGY_PID=$!
sleep 2

start_s=$(date +%s)
echo "[PIPELINE] [${NODE}] Ejecutando Kraken2+Bracken sobre ${INSTANCE}-${SAMPLE} completa (4 cores, nice -n 10)..."
export cpus=4
nice -n 10 /shared/users/grupo1/lemmi16s/workflow/scripts/run_tool_analysis.sh "$TOOL_NAME" \
  "${INSTANCE}-${SAMPLE}" "$QUERY_PATH" "$MODEL_PATH" "$OUT_FILE" "none=none"
EXIT_STATUS=$?
end_s=$(date +%s)
dur_s=$((end_s - start_s))

sleep 1
echo "[TELEMETRIA] [${NODE}] Deteniendo telemetria..."
pkill -TERM -f "medir_energia_pmic.py -e ${TAG_RUN}" 2>/dev/null || true
kill -TERM "$ENERGY_PID" 2>/dev/null || true
wait "$ENERGY_PID" 2>/dev/null || true
sleep 1

echo "=== NODO ${NODE} COMPLETO muestra ${SAMPLE} en ${dur_s}s (exit ${EXIT_STATUS}) ==="
WORKER_EOF
chmod +x "$WORKER_SCRIPT"

echo "----------------------------------------------------------"
echo "[LANZANDO] Asignando 1 nodo exclusivo por muestra..."
echo "----------------------------------------------------------"

JOB_IDS=()
for i in "${!SAMPLES[@]}"; do
    SAMPLE="${SAMPLES[$i]}"
    case "$SAMPLE" in
        c001) NODE_ASSIGNED=rbp5-1 ;;
        c002) NODE_ASSIGNED=rbp5-2 ;;
        c003) NODE_ASSIGNED=rbp5-3 ;;
        e001) NODE_ASSIGNED=rbp5-4 ;;
        e002) NODE_ASSIGNED=rbp5-5 ;;
        *) NODE_ASSIGNED="${IDLE_NODES[$i]}" ;;
    esac
    QUERY_PATH="${BASE_DIR}/benchmark/instances/${INSTANCE}/${INSTANCE}-${SAMPLE}"
    OUT_FILE="${OUT_DIR}/kraken2_multinodo.${INSTANCE}-${SAMPLE}.predictions.tsv"
    JID=$(sbatch --parsable \
        --job-name=kraken2_multi --partition=partition1 --account=tg \
        --nodes=1 --cpus-per-task=4 --mem=14G --exclusive --nodelist="$NODE_ASSIGNED" \
        --output="${LOGS_DIR}/kraken2_multi_%j_${SAMPLE}.log" \
        --error="${LOGS_DIR}/kraken2_multi_%j_${SAMPLE}.err" \
        --export=ALL,BASE_DIR="$BASE_DIR",INSTANCE="$INSTANCE",MODEL_PATH="$MODEL_PATH",TOOL_NAME="$TOOL_NAME",ENERGY_SCRIPT="$ENERGY_SCRIPT",MEDIR_DIR="$MEDIR_DIR",LOGS_DIR="$LOGS_DIR",SAMPLE="$SAMPLE",QUERY_PATH="$QUERY_PATH",OUT_FILE="$OUT_FILE" \
        "$WORKER_SCRIPT")
    echo "[+] Muestra ${SAMPLE} -> Job ${JID} asignado a nodo ${NODE_ASSIGNED}"
    JOB_IDS+=("$JID")
done

IDS_CSV=$(IFS=, ; echo "${JOB_IDS[*]}")
SAMPLES_STR="${SAMPLES[*]}"
echo "[+] Esperando finalizacion concurrente de: $IDS_CSV"
while true; do
    REMAINING=$(squeue -h -j "$IDS_CSV" 2>/dev/null | wc -l)
    if [ "$REMAINING" -eq 0 ]; then break; fi
    echo -ne "\r[MONITOR $(date +%T)] Tareas activas: $REMAINING   "
    sleep 3
done
echo -e "\n[+] Todas las muestras de Kraken 2 finalizaron."

echo "=========================================================="
echo "=== RESUMEN POR ARCHIVO DE PREDICCIONES ==="
echo "=========================================================="
for i in "${!SAMPLES[@]}"; do
    SAMPLE="${SAMPLES[$i]}"
    JID="${JOB_IDS[$i]}"
    OUT_FILE="${OUT_DIR}/kraken2_multinodo.${INSTANCE}-${SAMPLE}.predictions.tsv"
    LINES=$(wc -l < "$OUT_FILE" 2>/dev/null || echo 0)
    echo "Muestra ${SAMPLE} (job ${JID}): ${LINES} lineas -> ${OUT_FILE}"
done

echo ""
python3 "${SCRIPT_DIR}/reporte_kraken2_cluster.py" "$IDS_CSV" "$SAMPLES_STR" "$MEDIR_DIR" "$INSTANCE" "$BASE_DIR"
