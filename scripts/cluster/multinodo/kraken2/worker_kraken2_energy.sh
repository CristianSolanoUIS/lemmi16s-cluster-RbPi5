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
