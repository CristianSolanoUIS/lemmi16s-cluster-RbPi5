#!/usr/bin/env bash
# ==============================================================================
# sbatch_lotus3_pacbio_mononodo.sh
# Experimento Mononodo: LotuS3 PacBio (4 hilos) secuencial en 1 nodo de cómputo
# Procesa las 5 muestras PacBio (c001, c002, c003, e001, e002) una tras otra.
# Medición continua PMIC Renesas DA9091 a 1.0 Hz (Protocolo Unificado Tesis)
# Parámetros: -derepMin 1:1,1:2,1:3 -p PacBio -s sdm_PacBio_LSSU.txt -buildPhylo 0 -lulu 0 -t 4
# Uso: sbatch [--nodelist=rbp5-1] sbatch_lotus3_pacbio_mononodo.sh
# ==============================================================================
#SBATCH --job-name=lotus3_pb_mono
#SBATCH --partition=partition1
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=14G
#SBATCH --account=tg
#SBATCH --output=/shared/users/grupo1/logs_slurm/lotus3_pacbio_mono_%j.log
#SBATCH --error=/shared/users/grupo1/logs_slurm/lotus3_pacbio_mono_%j.err

set -euo pipefail

NODE=$(hostname)
HILOS=4
BASE_DIR="/shared/users/grupo1/lemmi16s"
INST="${BASE_DIR}/benchmark/instances/HM_Contaminated_Soil_PacBio"
IDX="${BASE_DIR}/benchmark/tmp/lotus3_pacbio/database_indexada"
SDM="${INST}/recursos/sdm_PacBio_LSSU.txt"
EDIT="${INST}/scripts/editResult.py"
ENERGY_SCRIPT="${BASE_DIR}/medicion_energia/medir_energia_pmic.py"
MEDIR_DIR="${BASE_DIR}/medicion_energia/lotus3_pacbio/mononodo"
OUT_DIR="${BASE_DIR}/benchmark/analysis_outputs/lotus3_pacbio/mononodo"
LOGS_DIR="/shared/users/grupo1/logs_slurm"

mkdir -p "$MEDIR_DIR/pre" "$OUT_DIR" "$LOGS_DIR"

SAMPLES=("c001" "c002" "c003" "e001" "e002")

echo "=========================================================="
echo "=== LOTUS3 PACBIO MONONODO SECUENCIAL (Job ${SLURM_JOB_ID}) ==="
echo "=========================================================="
echo "Nodo asignado: ${NODE}"
echo "Inicio ejecucion: $(date)"
echo "Muestras a procesar: ${SAMPLES[*]}"
echo "Hilos asignados: ${HILOS}"
echo "=========================================================="

for SAMPLE in "${SAMPLES[@]}"; do
    FQ="${INST}/muestras/HM_Contaminated_Soil-${SAMPLE}/queryReads.fq"
    if [ ! -s "$FQ" ]; then
        echo "[ERROR] No existe la muestra: $FQ"
        exit 1
    fi
done
[ -s "$IDX/reference.fasta.lba.gz" ] || { echo "[ERROR] Falta el indice en $IDX"; exit 1; }

source /shared/software/conda/miniforge3/etc/profile.d/conda.sh
conda activate /shared/users/grupo1/lemmi16s_pacbio_env
export OMP_NUM_THREADS=$HILOS

TAG_PRE="baseline_pre_lotus3_pacbio_mononodo_node_${NODE}_job${SLURM_JOB_ID}"
TAG_RUN="LotuS3_pacbio_mononodo_node_${NODE}_job${SLURM_JOB_ID}"
MARKS_FILE="${MEDIR_DIR}/marcas_tiempo_lotus3_pacbio_mononodo_${SLURM_JOB_ID}.tsv"
ENERGY_PID=""

cleanup() {
    pkill -TERM -f "medir_energia_pmic.py -e ${TAG_RUN}" 2>/dev/null || true
    if [ -n "$ENERGY_PID" ]; then kill -TERM "$ENERGY_PID" 2>/dev/null || true; wait "$ENERGY_PID" 2>/dev/null || true; fi
}
trap cleanup INT TERM EXIT

# 1. 60 s de estabilizacion
echo "[1/4] Estabilizacion 60 s sin medir..."
sleep 60

# 2. 300 s de reposo medido (baseline_pre)
echo "[2/4] Reposo medido 300 s a 1.0 Hz..."
sg video -c "python3 \"${ENERGY_SCRIPT}\" -e \"$TAG_PRE\" -i 1.0 -d 300 -o \"${MEDIR_DIR}/pre\""
sleep 3

# 3. Telemetria activa continua para todo el lote
echo "[3/4] Iniciando telemetria activa continua..."
sg video -c "python3 \"${ENERGY_SCRIPT}\" -e \"$TAG_RUN\" -i 1.0 -o \"${MEDIR_DIR}\"" \
    > "${LOGS_DIR}/telemetria_lotus3_pacbio_mono_${SLURM_JOB_ID}.log" 2>&1 &
ENERGY_PID=$!
sleep 2

echo -e "sample\tnode\tstart_iso\tend_iso\tstart_epoch\tend_epoch\tduration_s\texit_status" > "$MARKS_FILE"

# 4. Procesamiento secuencial
echo "[4/4] Procesando secuencialmente las 5 muestras..."
LOTE_START=$(date +%s)

for idx in "${!SAMPLES[@]}"; do
    SAMPLE="${SAMPLES[$idx]}"
    NUM=$((idx + 1))
    echo "----------------------------------------------------------"
    echo "[MUESTRA $NUM/5] Iniciando ${SAMPLE} a las $(date)..."
    echo "----------------------------------------------------------"

    WORK="${BASE_DIR}/benchmark/tmp/lotus3_pacbio/mononodo_${SAMPLE}"
    rm -rf "$WORK"; mkdir -p "$WORK/reads"; cd "$WORK"
    
    FQ="${INST}/muestras/HM_Contaminated_Soil-${SAMPLE}/queryReads.fq"
    cp -f "$FQ" reads/queryReads.fq
    cp -f "$SDM" reads/sdm_PacBio_LSSU.txt
    printf '#SampleID\tfastqFile\tSequencingRun\nSample1\tqueryReads.fq\tRun1\n' > reads/pacbioMap.sm.txt

    INI_ISO=$(date -Iseconds); INI=$(date +%s)
    set +e
    lotus3 -derepMin 1:1,1:2,1:3 -i reads/ -m reads/pacbioMap.sm.txt -o reads-output \
        -refDB "$IDX/reference.fasta" -tax4refDB "$IDX/reference.tsv" \
        -s reads/sdm_PacBio_LSSU.txt -p PacBio -buildPhylo 0 -lulu 0 -t $HILOS > "$WORK/lotus3.log" 2>&1 \
     && biom convert -i reads-output/OTU.biom -o results.txt --to-tsv --header-key taxonomy >> "$WORK/lotus3.log" 2>&1 \
     && python3 "$EDIT" results.txt results.tsv summary_taxonomy.tsv
    EST=$?
    set -e
    FIN_ISO=$(date -Iseconds); FIN=$(date +%s)
    SAMPLE_DUR=$((FIN - INI))

    echo -e "${SAMPLE}\t${NODE}\t${INI_ISO}\t${FIN_ISO}\t${INI}\t${FIN}\t${SAMPLE_DUR}\t${EST}" >> "$MARKS_FILE"

    if [ "$EST" -ne 0 ]; then
        echo "[ERROR] LotuS3 fallo en ${SAMPLE} (codigo $EST). Ver $WORK/lotus3.log"; tail -30 "$WORK/lotus3.log"; exit $EST
    fi

    OUT_FILE="${OUT_DIR}/lotus3_pacbio_mononodo.HM_Contaminated_Soil_PacBio-${SAMPLE}.job${SLURM_JOB_ID}.predictions.tsv"
    cp results.tsv "$OUT_FILE"
    echo "[MUESTRA $NUM/5 COMPLETA] ${SAMPLE}: exit ${EST} en ${SAMPLE_DUR}s ($(($(wc -l < results.tsv)-2)) taxones)"
done

LOTE_END=$(date +%s)
LOTE_DUR=$((LOTE_END - LOTE_START))

sleep 2
cleanup; trap - INT TERM EXIT

echo "=========================================================="
echo "=== LOTUS3 PACBIO MONONODO FINALIZADO EXITOSAMENTE ==="
echo "Tiempo total de lote: ${LOTE_DUR} s"
echo "Fin ejecucion: $(date)"
echo "=========================================================="
