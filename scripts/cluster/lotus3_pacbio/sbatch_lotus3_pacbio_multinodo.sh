#!/usr/bin/env bash
# ==============================================================================
# sbatch_lotus3_pacbio_multinodo.sh
# LotuS3 PacBio (instancia HM_Contaminated_Soil_PacBio, generada por Cristian) en el cluster:
# UNA muestra por nodo, los 5 nodos a la vez. Lo lanza lanzar_lotus3_pacbio_5nodos.sh.
# Protocolo comun: 60 s sin medir, 300 s de reposo medido (baseline_pre) y la corrida medida (PMIC, 1 Hz).
# Parametros iguales a WSL2: -derepMin 1:1,1:2,1:3 -p PacBio -s sdm_PacBio_LSSU.txt -buildPhylo 0 -lulu 0 -t 4
# Uso: sbatch --nodelist=rbp5-N sbatch_lotus3_pacbio_multinodo.sh <muestra>
# ==============================================================================
#SBATCH --job-name=lotus3_pb
#SBATCH --partition=partition1
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=14G
#SBATCH --account=tg
#SBATCH --output=/shared/users/grupo1/logs_slurm/lotus3_pacbio_%x_%j.log
#SBATCH --error=/shared/users/grupo1/logs_slurm/lotus3_pacbio_%x_%j.err

set -euo pipefail

SAMPLE="$1"
NODE=$(hostname)
HILOS=4
BASE_DIR="/shared/users/grupo1/lemmi16s"
INST="${BASE_DIR}/benchmark/instances/HM_Contaminated_Soil_PacBio"
IDX="${BASE_DIR}/benchmark/tmp/lotus3_pacbio/database_indexada"
SDM="${INST}/recursos/sdm_PacBio_LSSU.txt"
EDIT="${INST}/scripts/editResult.py"
ENERGY_SCRIPT="${BASE_DIR}/medicion_energia/medir_energia_pmic.py"
MEDIR_DIR="${BASE_DIR}/medicion_energia/lotus3_pacbio"
OUT_DIR="${BASE_DIR}/benchmark/analysis_outputs/lotus3_pacbio"
LOGS_DIR="/shared/users/grupo1/logs_slurm"
WORK="${BASE_DIR}/benchmark/tmp/lotus3_pacbio/multinodo_${SAMPLE}"
FQ="${INST}/muestras/HM_Contaminated_Soil-${SAMPLE}/queryReads.fq"

mkdir -p "$MEDIR_DIR/pre" "$OUT_DIR" "$LOGS_DIR"
[ -s "$FQ" ] || { echo "[ERROR] No existe $FQ"; exit 1; }
[ -s "$IDX/reference.fasta.lba.gz" ] || { echo "[ERROR] Falta el indice en $IDX"; exit 1; }

source /shared/software/conda/miniforge3/etc/profile.d/conda.sh
conda activate /shared/users/grupo1/lemmi16s_pacbio_env
export OMP_NUM_THREADS=$HILOS

TAG_PRE="baseline_pre_lotus3_pacbio_${SAMPLE}_node_${NODE}_job${SLURM_JOB_ID}"
TAG_RUN="LotuS3_pacbio_multinodo_${SAMPLE}_node_${NODE}_job${SLURM_JOB_ID}"
MARKS_FILE="${MEDIR_DIR}/marcas_tiempo_lotus3_pacbio_${SAMPLE}_job${SLURM_JOB_ID}.tsv"
ENERGY_PID=""

cleanup() {
    pkill -TERM -f "medir_energia_pmic.py -e ${TAG_RUN}" 2>/dev/null || true
    if [ -n "$ENERGY_PID" ]; then kill -TERM "$ENERGY_PID" 2>/dev/null || true; wait "$ENERGY_PID" 2>/dev/null || true; fi
}
trap cleanup INT TERM EXIT

echo "=== LotuS3 PacBio ${SAMPLE} en ${NODE} (job ${SLURM_JOB_ID}), ${HILOS} hilos, inicio $(date) ==="

echo "[1/4] Estabilizacion 60 s sin medir"
sleep 60

echo "[2/4] Reposo medido 300 s"
sg video -c "python3 \"${ENERGY_SCRIPT}\" -e \"$TAG_PRE\" -i 1.0 -d 300 -o \"${MEDIR_DIR}/pre\""
sleep 3

echo "[3/4] Telemetria de la corrida"
sg video -c "python3 \"${ENERGY_SCRIPT}\" -e \"$TAG_RUN\" -i 1.0 -o \"${MEDIR_DIR}\"" \
    > "${LOGS_DIR}/telemetria_lotus3_pacbio_${SAMPLE}_${SLURM_JOB_ID}.log" 2>&1 &
ENERGY_PID=$!
sleep 2

echo "[4/4] LotuS3"
rm -rf "$WORK"; mkdir -p "$WORK/reads"; cd "$WORK"
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

sleep 2
cleanup; trap - INT TERM EXIT

echo -e "sample\tnode\tstart_iso\tend_iso\tstart_epoch\tend_epoch\tduration_s\texit_status" > "$MARKS_FILE"
echo -e "${SAMPLE}\t${NODE}\t${INI_ISO}\t${FIN_ISO}\t${INI}\t${FIN}\t$((FIN-INI))\t${EST}" >> "$MARKS_FILE"

if [ "$EST" -ne 0 ]; then
    echo "[ERROR] LotuS3 fallo (codigo $EST). Ver $WORK/lotus3.log"; tail -30 "$WORK/lotus3.log"; exit $EST
fi
cp results.tsv "${OUT_DIR}/lotus3_pacbio_multinodo.HM_Contaminated_Soil_PacBio-${SAMPLE}.job${SLURM_JOB_ID}.predictions.tsv"
echo "=== ${SAMPLE} listo en $((FIN-INI)) s, $(($(wc -l < results.tsv)-2)) taxones. Fin $(date) ==="
