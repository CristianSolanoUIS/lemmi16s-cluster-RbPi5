#!/usr/bin/env bash
# ==============================================================================
# run_all_samples_qiime2.sh
# Lanza el benchmark multinodo completo para QIIME 2 sobre las 5 muestras
# (c001, c002, c003, e001, e002) del dataset alfa_v1v2_SILVA con telemetria PMIC
# ==============================================================================
set -e

SCRIPT_DIR="/shared/users/grupo1/scripts/distribuido/runscripts/qiime2"
LOGS_DIR="/shared/users/grupo1/logs_slurm"
LOG_FILE="${LOGS_DIR}/run_all_qiime2_multinodo.log"

mkdir -p "$LOGS_DIR"

echo "=== INICIANDO BENCHMARK MULTINODO QIIME2 (5 MUESTRAS: c001, c002, c003, e001, e002) ===" | tee "$LOG_FILE"
date | tee -a "$LOG_FILE"

bash "${SCRIPT_DIR}/sbatch_multinodo_energy.sh" c001 c002 c003 e001 e002 2>&1 | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "=== BENCHMARK MULTINODO QIIME2 COMPLETADO CON EXITO ===" | tee -a "$LOG_FILE"
date | tee -a "$LOG_FILE"
