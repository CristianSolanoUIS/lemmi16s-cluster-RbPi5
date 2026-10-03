#!/usr/bin/env bash
# ==============================================================================
# sbatch_lotus3_mononodo.sh
# Experimento Mononodo: LotuS3 (2 hilos) secuencial en rbp5-2
# Procesa las 3 muestras biológicas (c001, c002, e001) una tras otra.
# Medición continua PMIC Renesas DA9091 a 1.0 Hz (Protocolo Unificado Tesis)
# ==============================================================================
#SBATCH --job-name=lotus3_mono
#SBATCH --partition=partition1
#SBATCH --nodelist=rbp5-2
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=14G
#SBATCH --account=tg
#SBATCH --output=/shared/users/grupo1/logs_slurm/lotus3_mono_%j.log
#SBATCH --error=/shared/users/grupo1/logs_slurm/lotus3_mono_%j.err

set -e

NODE=$(hostname)
BASE_DIR="/shared/users/grupo1/lemmi16s"
INSTANCE="HM_Contaminated_Soil"
MODEL_PATH="${BASE_DIR}/benchmark/tmp/lotus303_16s_HM_Contaminated/tmp_HM_Contaminated_Soil"
TOOL_NAME="lotus_303_lemmi16s"
TECHNOLOGY="illumina"
ENERGY_SCRIPT="${BASE_DIR}/medicion_energia/medir_energia_pmic.py"
MEDIR_DIR="${BASE_DIR}/medicion_energia/mononodo/lotus3"
LOGS_DIR="/shared/users/grupo1/logs_slurm"
OUT_DIR="${BASE_DIR}/benchmark/analysis_outputs/lotus3/mononodo"

mkdir -p "$MEDIR_DIR" "$LOGS_DIR" "$OUT_DIR"

SAMPLES=("c001" "c002" "e001")

echo "=========================================================="
echo "=== LOTUS3 MONONODO SECUENCIAL (rbp5-2, Job ${SLURM_JOB_ID}) ==="
echo "=========================================================="
echo "Nodo asignado: ${NODE}"
echo "Inicio ejecucion: $(date)"
echo "Muestras a procesar: ${SAMPLES[*]}"
echo "Hilos asignados: 2"
echo "=========================================================="

# 0. Verificar existencia de las muestras
for SAMPLE in "${SAMPLES[@]}"; do
    QP="${BASE_DIR}/benchmark/instances/${INSTANCE}/${INSTANCE}-${SAMPLE}"
    if [ ! -d "$QP" ]; then
        echo "[ERROR] No existe la muestra: $QP"
        exit 1
    fi
done

TAG_PRE="baseline_pre_lotus3_mononodo_node_${NODE}_job${SLURM_JOB_ID}"
TAG_RUN="LotuS3_mononodo_node_${NODE}_job${SLURM_JOB_ID}"
MARKS_FILE="${MEDIR_DIR}/marcas_tiempo_lotus3_mononodo_${SLURM_JOB_ID}.tsv"

# Manejo de senales para detener telemetria si se cancela el job
cleanup() {
    echo "[TRAP] Deteniendo telemetria activa por cancelacion/salida..."
    pkill -TERM -f "medir_energia_pmic.py -e ${TAG_RUN}" 2>/dev/null || true
    if [ -n "$ENERGY_PID" ]; then
        kill -TERM "$ENERGY_PID" 2>/dev/null || true
        wait "$ENERGY_PID" 2>/dev/null || true
    fi
}
trap cleanup INT TERM EXIT

# 1. 60 segundos de estabilizacion termica sin medir
echo "[1/4] [ESTABILIZACION] Esperando 60s en reposo antes del baseline..."
sleep 60

# 2. 5 minutos de reposo MEDIDO a 1.0 Hz (Baseline PRE)
echo "[2/4] [BASELINE] Midiendo 300s (5 min) de reposo con PMIC a 1.0 Hz..."
sg video -c "python3 \"${ENERGY_SCRIPT}\" -e \"$TAG_PRE\" -i 1.0 -d 300 -o \"${MEDIR_DIR}\""
sleep 3

# 3. Iniciar telemetria activa continua para todo el lote
echo "[3/4] [TELEMETRIA] Iniciando medicion activa continua para las 3 muestras..."
sg video -c "python3 \"${ENERGY_SCRIPT}\" -e \"$TAG_RUN\" -i 1.0 -o \"${MEDIR_DIR}\"" \
  > "${LOGS_DIR}/telemetria_lotus3_mono_${SLURM_JOB_ID}.log" 2>&1 &
ENERGY_PID=$!
sleep 2

# Preparar archivo de marcas de tiempo por muestra
echo -e "sample\tstart_iso\tend_iso\tstart_epoch\tend_epoch\tduration_s\texit_status" > "$MARKS_FILE"

export cpus=2
export OMP_NUM_THREADS=2

# 4. Procesamiento secuencial muestra por muestra
echo "[4/4] [PIPELINE] Procesando secuencialmente las 3 muestras..."
LOTE_START=$(date +%s)

for idx in "${!SAMPLES[@]}"; do
    SAMPLE="${SAMPLES[$idx]}"
    NUM=$((idx + 1))
    echo "----------------------------------------------------------"
    echo "[MUESTRA $NUM/3] Iniciando ${SAMPLE} a las $(date)..."
    echo "----------------------------------------------------------"
    
    TMP_DIR="${BASE_DIR}/benchmark/tmp/mononodo_lotus3_${SAMPLE}"
    mkdir -p "$TMP_DIR"
    rm -rf "${TMP_DIR:?}"/*
    cd "$TMP_DIR"
    
    QUERY_PATH="${BASE_DIR}/benchmark/instances/${INSTANCE}/${INSTANCE}-${SAMPLE}"
    OUT_FILE="${OUT_DIR}/lotus3_mononodo.${INSTANCE}-${SAMPLE}.predictions.tsv"
    
    SAMPLE_START_ISO=$(date -Iseconds)
    SAMPLE_START_EPOCH=$(date +%s)
    
    set +e
    /shared/users/grupo1/lemmi16s/workflow/scripts/run_tool_analysis.sh "$TOOL_NAME" \
      "$TECHNOLOGY" "${INSTANCE}-${SAMPLE}" "$QUERY_PATH" "$MODEL_PATH" "$OUT_FILE" "none=none"
    EXIT_STATUS=$?
    set -e
    
    SAMPLE_END_ISO=$(date -Iseconds)
    SAMPLE_END_EPOCH=$(date +%s)
    SAMPLE_DUR=$((SAMPLE_END_EPOCH - SAMPLE_START_EPOCH))
    
    echo -e "${SAMPLE}\t${SAMPLE_START_ISO}\t${SAMPLE_END_ISO}\t${SAMPLE_START_EPOCH}\t${SAMPLE_END_EPOCH}\t${SAMPLE_DUR}\t${EXIT_STATUS}" >> "$MARKS_FILE"
    
    LINES=$(wc -l < "$OUT_FILE" 2>/dev/null || echo 0)
    echo "[MUESTRA $NUM/3 COMPLETA] ${SAMPLE}: exit ${EXIT_STATUS} en ${SAMPLE_DUR}s (${LINES} predicciones)"
    
    if [ "$EXIT_STATUS" -ne 0 ]; then
        echo "[ERROR] Fallo la muestra ${SAMPLE} con codigo ${EXIT_STATUS}"
        exit $EXIT_STATUS
    fi
done

LOTE_END=$(date +%s)
LOTE_DUR=$((LOTE_END - LOTE_START))

# Detener telemetria activa
echo "----------------------------------------------------------"
echo "[TELEMETRIA] Deteniendo medicion activa (PID $ENERGY_PID)..."
sleep 2
pkill -TERM -f "medir_energia_pmic.py -e ${TAG_RUN}" 2>/dev/null || true
kill -TERM "$ENERGY_PID" 2>/dev/null || true
wait "$ENERGY_PID" 2>/dev/null || true
sleep 2
trap - INT TERM EXIT

echo "=========================================================="
echo "=== LOTUS3 MONONODO FINALIZADO EXITOSAMENTE ==="
echo "Tiempo total de lote: ${LOTE_DUR} s"
echo "Fin ejecucion: $(date)"
echo "=========================================================="
