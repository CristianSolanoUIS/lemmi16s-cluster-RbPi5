#!/usr/bin/env bash
set -e
NODE=$(hostname)
TMP_DIR="${BASE_DIR}/benchmark/tmp/multinodo_qiime2_${SAMPLE}"
mkdir -p "$TMP_DIR"
rm -rf "${TMP_DIR:?}"/*
cd "$TMP_DIR"

echo "=========================================================="
echo "=== NODO ${NODE} - QIIME2 muestra completa ${SAMPLE} (job ${SLURM_JOB_ID}) ==="
echo "=========================================================="
echo "Hora inicio: $(date)"

TAG_PRE="baseline_pre_qiime2_${SAMPLE}_node_${NODE}_job${SLURM_JOB_ID}"
TAG_RUN="Qiime2_multinodo_${SAMPLE}_node_${NODE}_job${SLURM_JOB_ID}"
TAG_POST="baseline_post_qiime2_${SAMPLE}_node_${NODE}_job${SLURM_JOB_ID}"

trap 'kill -TERM "$ENERGY_PID" 2>/dev/null || true' INT TERM EXIT

echo "[1/3] [${NODE}] Baseline PRE (30s)..."
python3 "${ENERGY_SCRIPT}" -e "$TAG_PRE" -i 1.0 -d 30 -o "${MEDIR_DIR}"
sleep 2

echo "[2/3] [${NODE}] Telemetria activa..."
python3 "${ENERGY_SCRIPT}" -e "$TAG_RUN" -i 1.0 -o "${MEDIR_DIR}" \
  > "${LOGS_DIR}/telemetria_qiime2_${SAMPLE}_${SLURM_JOB_ID}.log" 2>&1 &
ENERGY_PID=$!
sleep 2

start_s=$(date +%s)
echo "[PIPELINE] [${NODE}] Ejecutando QIIME2 sobre ${INSTANCE}-${SAMPLE} completa..."
export cpus=2
export OMP_NUM_THREADS=2
set +e
/shared/users/grupo1/lemmi16s/workflow/scripts/run_tool_analysis.sh "$TOOL_NAME" \
  "${INSTANCE}-${SAMPLE}" "$QUERY_PATH" "$MODEL_PATH" "$OUT_FILE" "none=none"
EXIT_STATUS=$?
set -e
end_s=$(date +%s)
dur_s=$((end_s - start_s))

sleep 2
echo "[TELEMETRIA] [${NODE}] Deteniendo (PID $ENERGY_PID)..."
kill -TERM "$ENERGY_PID" 2>/dev/null || true
wait "$ENERGY_PID" 2>/dev/null || true
sleep 2

echo "[3/3] [${NODE}] Baseline POST (30s)..."
python3 "${ENERGY_SCRIPT}" -e "$TAG_POST" -i 1.0 -d 30 -o "${MEDIR_DIR}"

echo "=== NODO ${NODE} COMPLETO muestra ${SAMPLE} en ${dur_s}s (exit ${EXIT_STATUS}) ==="
