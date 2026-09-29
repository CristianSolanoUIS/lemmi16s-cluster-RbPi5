#!/usr/bin/env bash
# ==============================================================================
# run_all_samples_lotus3.sh
# Lanza el benchmark multinodo completo para LotuS3 sobre las 3 muestras
# (c001, c002, e001) del dataset HM_Contaminated_Soil con telemetria PMIC
# ==============================================================================
set -e

SCRIPT_DIR="/shared/users/grupo1/scripts/distribuido/runscripts/lotus3"
LOGS_DIR="/shared/users/grupo1/logs_slurm"
LOG_FILE="${LOGS_DIR}/run_all_lotus3_multinodo.log"

mkdir -p "$LOGS_DIR"

echo "=== INICIANDO BENCHMARK MULTINODO LOTUS3 (3 MUESTRAS: c001, c002, e001) ===" | tee "$LOG_FILE"
date | tee -a "$LOG_FILE"

bash "${SCRIPT_DIR}/sbatch_multinodo_energy.sh" c001 c002 e001 2>&1 | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "=== BENCHMARK MULTINODO LOTUS3 COMPLETADO CON EXITO ===" | tee -a "$LOG_FILE"
date | tee -a "$LOG_FILE"
