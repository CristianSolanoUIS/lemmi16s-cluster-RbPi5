#!/usr/bin/env bash
# ==============================================================================
# EJECUTOR OFICIAL DE EVALUACIÓN BIOLÓGICA (eval.smk) PARA EL CLÚSTER
# ==============================================================================
# Este script ejecuta la regla Snakemake de evaluación directamente y de manera
# 100% aislada dentro del repositorio de respaldo (lemmi16s-cluster-backup).
# Todos los resultados (.tsv, .json, .f1, .auprc, etc.) quedan generados aquí.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LEMMI_ORIGINAL="/home/cristian-solano/lemmi16s"
SNAKEMAKE_BIN="/home/cristian-solano/proyectos/miniconda3/envs/lemmi16s/bin/snakemake"

TARGET="${1:-all}"

# Asegurar enlaces simbólicos locales de lectura necesarios para la evaluación
mkdir -p "${BACKUP_ROOT}/benchmark"
if [ ! -e "${BACKUP_ROOT}/benchmark/instances" ] && [ -d "${LEMMI_ORIGINAL}/benchmark/instances" ]; then
    ln -sfn "${LEMMI_ORIGINAL}/benchmark/instances" "${BACKUP_ROOT}/benchmark/instances"
fi
if [ ! -e "${BACKUP_ROOT}/benchmark/yaml" ] && [ -d "${LEMMI_ORIGINAL}/benchmark/yaml" ]; then
    ln -sfn "${LEMMI_ORIGINAL}/benchmark/yaml" "${BACKUP_ROOT}/benchmark/yaml"
fi
if [ ! -e "${BACKUP_ROOT}/benchmark/repository" ] && [ -d "${LEMMI_ORIGINAL}/benchmark/repository" ]; then
    ln -sfn "${LEMMI_ORIGINAL}/benchmark/repository" "${BACKUP_ROOT}/benchmark/repository"
fi

ejecutar_instancia() {
    local INSTANCE="$1"
    echo "=========================================================================="
    echo ">>> EVALUANDO INSTANCIA DEL CLÚSTER: ${INSTANCE}"
    echo "=========================================================================="

    export LEMMI16s_ROOT="${BACKUP_ROOT}"
    export PYTHONPATH="${LEMMI_ORIGINAL}/workflow/rules:${PYTHONPATH}"

    cd "${BACKUP_ROOT}"
    local dt=$(date +%s)
    cat "${BACKUP_ROOT}/benchmark/yaml/instances/${INSTANCE}.yaml" "${LEMMI_ORIGINAL}/config/config.yaml" > "${BACKUP_ROOT}/.evaluation.yaml"
    echo "instance_name: ${INSTANCE}" >> "${BACKUP_ROOT}/.evaluation.yaml"

    "$SNAKEMAKE_BIN" \
      --rerun-incomplete \
      --printshellcmds \
      --snakefile "${LEMMI_ORIGINAL}/workflow/rules/eval.smk" \
      --configfile "${BACKUP_ROOT}/.evaluation.yaml" \
      --directory "${BACKUP_ROOT}" \
      --cores 4 \
      --config datetime="$dt"

    rm -f "${BACKUP_ROOT}/.evaluation.yaml"
    rm -rf "${BACKUP_ROOT}/benchmark/tmp/${dt}" 2>/dev/null || true

    echo "[OK] Instancia ${INSTANCE} completada."
}

if [ "$TARGET" = "all" ] || [ "$TARGET" = "todas" ]; then
    echo "Iniciando evaluación completa de todas las instancias del clúster..."
    ejecutar_instancia "alfa_v1v2_SILVA"
    ejecutar_instancia "HOMD_v4_GTDB"
    ejecutar_instancia "HM_Contaminated_Soil"
else
    ejecutar_instancia "$TARGET"
fi

echo "=========================================================================="
echo "🎉 [ÉXITO TOTAL] Todas las evaluaciones quedaron generadas en:"
echo "    ${BACKUP_ROOT}/benchmark/final_results/"
echo "    ${BACKUP_ROOT}/benchmark/evaluations/"
echo "=========================================================================="
