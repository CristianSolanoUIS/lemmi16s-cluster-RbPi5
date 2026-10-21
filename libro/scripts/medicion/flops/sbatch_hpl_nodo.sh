#!/usr/bin/env bash
# ==============================================================================
# sbatch_hpl_nodo.sh
# HPL (LINPACK) en UN nodo Raspberry Pi 5 con el protocolo comun de medicion:
#   60 s sin medir, 300 s de reposo medido (baseline_pre) y HPL medido con el PMIC (1 Hz).
# Tambien guarda vcgencmd get_throttled antes y despues (para descartar baja de frecuencia).
# Lo lanza lanzar_hpl_5nodos.sh, uno por nodo.
# Uso: sbatch --nodelist=rbp5-N sbatch_hpl_nodo.sh
#      (prueba corta sin protocolo: HPL_N=5000 PRUEBA=1 sbatch --export=ALL --nodelist=rbp5-1 sbatch_hpl_nodo.sh)
# ==============================================================================
#SBATCH --job-name=hpl_flops
#SBATCH --partition=partition1
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --mem=14G
#SBATCH --account=tg
#SBATCH --output=/shared/users/grupo1/logs_slurm/hpl_%x_%j.log
#SBATCH --error=/shared/users/grupo1/logs_slurm/hpl_%x_%j.err

set -euo pipefail

NODE=$(hostname)
HPL_DIR="/shared/users/grupo1/hpl"
SCRIPTS="/shared/users/grupo1/lemmi16s/scripts/flops"
ENERGY_SCRIPT="/shared/users/grupo1/lemmi16s/medicion_energia/medir_energia_pmic.py"
MEDIR_DIR="/shared/users/grupo1/lemmi16s/medicion_energia/hpl"
TAG_PRE="baseline_pre_hpl_node_${NODE}_job${SLURM_JOB_ID}"
TAG_RUN="HPL_node_${NODE}_job${SLURM_JOB_ID}"
mkdir -p "$MEDIR_DIR/pre"
[ -x "$HPL_DIR/bin/xhpl" ] || { echo "[ERROR] falta $HPL_DIR/bin/xhpl (correr instalar_hpl.sh)"; exit 1; }

ENERGY_PID=""
cleanup() {
    # el medidor corre dentro de "sg video": se cierra por nombre, porque matar a sg no cierra el python3
    pkill -TERM -f "medir_energia_pmic.py -e ${TAG_RUN}" 2>/dev/null || true
    if [ -n "$ENERGY_PID" ]; then kill -TERM "$ENERGY_PID" 2>/dev/null || true; wait "$ENERGY_PID" 2>/dev/null || true; fi
}
trap cleanup INT TERM EXIT

echo "=== HPL en ${NODE} (job ${SLURM_JOB_ID}), inicio $(date) ==="
if [ "${PRUEBA:-0}" = "1" ]; then   # prueba corta: solo HPL, sin protocolo ni medicion
    bash "$SCRIPTS/correr_hpl.sh" "$HPL_DIR" "/shared/users/grupo1/hpl/prueba" "${NODE}_job${SLURM_JOB_ID}" "${HPL_N:-5000}"
    exit 0
fi
sg video -c "vcgencmd get_throttled; vcgencmd measure_temp; vcgencmd measure_clock arm" > "$MEDIR_DIR/estado_${NODE}_job${SLURM_JOB_ID}_antes.txt" 2>&1 || true

echo "[1/3] Estabilizacion 60 s sin medir"
sleep 60

echo "[2/3] Reposo medido 300 s"
sg video -c "python3 \"${ENERGY_SCRIPT}\" -e \"$TAG_PRE\" -i 1.0 -d 300 -o \"${MEDIR_DIR}/pre\""
sleep 3

echo "[3/3] HPL con telemetria"
sg video -c "python3 \"${ENERGY_SCRIPT}\" -e \"$TAG_RUN\" -i 1.0 -o \"${MEDIR_DIR}\"" \
    > "${MEDIR_DIR}/telemetria_hpl_${NODE}_${SLURM_JOB_ID}.log" 2>&1 &
ENERGY_PID=$!
sleep 2
bash "$SCRIPTS/correr_hpl.sh" "$HPL_DIR" "$MEDIR_DIR" "${NODE}_job${SLURM_JOB_ID}" "${HPL_N:-30000}"
sleep 2
cleanup; trap - INT TERM EXIT

sg video -c "vcgencmd get_throttled; vcgencmd measure_temp; vcgencmd measure_clock arm" > "$MEDIR_DIR/estado_${NODE}_job${SLURM_JOB_ID}_despues.txt" 2>&1 || true
echo "=== ${NODE} listo, fin $(date) ==="
