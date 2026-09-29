#!/usr/bin/env bash
set -e
NODE=$(hostname)
TMP_DIR="${BASE_DIR}/benchmark/tmp/multinodo_lotus3_${SAMPLE}"
mkdir -p "$TMP_DIR"
rm -rf "${TMP_DIR:?}"/*
cd "$TMP_DIR"

echo "=========================================================="
echo "=== NODO ${NODE} - LotuS3 muestra completa ${SAMPLE} (job ${SLURM_JOB_ID}) ==="
echo "=========================================================="
echo "Hora inicio: $(date)"

TAG_PRE="baseline_pre_lotus3_${SAMPLE}_node_${NODE}_job${SLURM_JOB_ID}"
TAG_RUN="LotuS3_multinodo_${SAMPLE}_node_${NODE}_job${SLURM_JOB_ID}"

echo "[ESTABILIZACION] [${NODE}] Esperando 60s de reposo antes del baseline..."
sleep 60

echo "[1/2] [${NODE}] Baseline PRE (300s / 5 minutos)..."
python3 "${ENERGY_SCRIPT}" -e "$TAG_PRE" -i 1.0 -d 300 -o "${MEDIR_DIR}"
sleep 3

echo "[2/2] [${NODE}] Telemetria activa..."
python3 "${ENERGY_SCRIPT}" -e "$TAG_RUN" -i 1.0 -o "${MEDIR_DIR}" \
  > "${LOGS_DIR}/telemetria_lotus3_${SAMPLE}_${SLURM_JOB_ID}.log" 2>&1 &
ENERGY_PID=$!
sleep 2

start_s=$(date +%s)
echo "[PIPELINE] [${NODE}] Ejecutando LotuS3 (${TECHNOLOGY}) sobre ${INSTANCE}-${SAMPLE} completa..."
export cpus=2
export OMP_NUM_THREADS=2
/shared/users/grupo1/lemmi16s/workflow/scripts/run_tool_analysis.sh "$TOOL_NAME" \
  "$TECHNOLOGY" "${INSTANCE}-${SAMPLE}" "$QUERY_PATH" "$MODEL_PATH" "$OUT_FILE" "none=none"
EXIT_STATUS=$?
end_s=$(date +%s)
dur_s=$((end_s - start_s))

sleep 2
echo "[TELEMETRIA] [${NODE}] Deteniendo (PID $ENERGY_PID)..."
pkill -TERM -f "medir_energia_pmic.py -e ${TAG_RUN}" 2>/dev/null || true
kill -TERM "$ENERGY_PID" 2>/dev/null || true
wait "$ENERGY_PID" 2>/dev/null || true
sleep 2

echo "=== NODO ${NODE} COMPLETO muestra ${SAMPLE} en ${dur_s}s (exit ${EXIT_STATUS}) ==="
