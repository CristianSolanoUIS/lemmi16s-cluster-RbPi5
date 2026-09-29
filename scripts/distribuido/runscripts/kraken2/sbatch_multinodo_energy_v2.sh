#!/usr/bin/env bash
# ==============================================================================
# sbatch_multinodo_energy.sh (Kraken 2 + Bracken)
# Distribuye MUESTRAS COMPLETAS (no reads divididos) entre los nodos idle
# de partition1, una muestra por nodo físico exclusivo, con telemetría PMIC.
#
# METODOLOGÍA UNIFICADA (Idéntica a QIIME 2 y LotuS3):
# - 1 muestra biológica completa por nodo RPi 5
# - 4 cores dedicados por nodo (--cpus-per-task=4, cpus=4)
# - Margen de memoria segura Slurm (--mem=14G)
# - Telemetría de hardware Renesas DA9091 PMIC: 30s PRE + RUN activa + 30s POST
# - Kraken 2 + Bracken corren sobre el 100% de la muestra, eliminando
#   cualquier variación o sesgo bayesiano de particionamiento.
#
# Uso: sbatch_multinodo_energy.sh <muestra1> [muestra2] [muestra3] ...
# Ejemplo: sbatch_multinodo_energy.sh c001 c002 c003 e001 e002
#
# v2 (2026-09-28): igual al original, pero Kraken corre con "nice -n 10" para que el
# medidor PMIC conserve el muestreo a 1 Hz con la CPU al 100 %, y cada muestra va fija
# a su nodo de la corrida original (c001->rbp5-1 ... e002->rbp5-5).
# ==============================================================================
set -e

SAMPLES=("$@")
if [ ${#SAMPLES[@]} -eq 0 ]; then
    echo "Uso: $0 <muestra1> [muestra2] [muestra3] ..."
    echo "Ejemplo: $0 c001 c002 c003 e001 e002"
    exit 1
fi

BASE_DIR="/shared/users/grupo1/lemmi16s"
INSTANCE="HOMD_v4_GTDB"
MODEL_PATH="${BASE_DIR}/benchmark/tmp/kraken2_16s_HOMD_v4_GTDB/tmp_HOMD_v4_GTDB"
TOOL_NAME="kraken_213_lemmi16s"
ENERGY_SCRIPT="${BASE_DIR}/medicion_energia/medir_energia_pmic.py"
MEDIR_DIR="${BASE_DIR}/medicion_energia/kraken2"
LOGS_DIR="/shared/users/grupo1/logs_slurm"
OUT_DIR="${BASE_DIR}/benchmark/analysis_outputs/kraken2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$MEDIR_DIR" "$LOGS_DIR" "$OUT_DIR"

echo "=========================================================="
echo "=== KRAKEN 2 + BRACKEN MULTINODO (1 muestra por nodo) ==="
echo "=========================================================="

IDLE_NODES=($(sinfo -N -h -p partition1 -t idle -o "%N"))
NUM_IDLE=${#IDLE_NODES[@]}
if [ "$NUM_IDLE" -eq 0 ]; then
    echo "[ERROR] No hay nodos 'idle' en partition1."
    sinfo -p partition1
    exit 1
fi
echo "[NODOS] Idle en partition1: ${IDLE_NODES[*]} ($NUM_IDLE nodos)"
echo "[MUESTRAS] ${SAMPLES[*]} (${#SAMPLES[@]} muestras)"
if [ ${#SAMPLES[@]} -gt "$NUM_IDLE" ]; then
    echo "[AVISO] Hay mas muestras que nodos idle; las sobrantes esperaran turno en la cola."
fi

for SAMPLE in "${SAMPLES[@]}"; do
    QP="${BASE_DIR}/benchmark/instances/${INSTANCE}/${INSTANCE}-${SAMPLE}"
    if [ ! -d "$QP" ]; then
        echo "[ERROR] No existe la muestra: $QP"
        exit 1
    fi
done

WORKER_SCRIPT="${SCRIPT_DIR}/worker_kraken2_energy_v2.sh"
cat << 'WORKER_EOF' > "$WORKER_SCRIPT"
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
TAG_POST="baseline_post_kraken2_${SAMPLE}_node_${NODE}_job${SLURM_JOB_ID}"

echo "[1/3] [${NODE}] Baseline PRE (30s)..."
python3 "${ENERGY_SCRIPT}" -e "$TAG_PRE" -i 1.0 -d 30 -o "${MEDIR_DIR}"
sleep 2

echo "[2/3] [${NODE}] Telemetria activa..."
python3 "${ENERGY_SCRIPT}" -e "$TAG_RUN" -i 1.0 -o "${MEDIR_DIR}" \
  > "${LOGS_DIR}/telemetria_kraken2_${SAMPLE}_${SLURM_JOB_ID}.log" 2>&1 &
ENERGY_PID=$!
sleep 2

start_s=$(date +%s)
echo "[PIPELINE] [${NODE}] Ejecutando Kraken2+Bracken sobre ${INSTANCE}-${SAMPLE} completa (4 cores)..."
export cpus=4
nice -n 10 /shared/users/grupo1/lemmi16s/workflow/scripts/run_tool_analysis.sh "$TOOL_NAME" \
  "${INSTANCE}-${SAMPLE}" "$QUERY_PATH" "$MODEL_PATH" "$OUT_FILE" "none=none"
EXIT_STATUS=$?
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
WORKER_EOF
chmod +x "$WORKER_SCRIPT"

echo "----------------------------------------------------------"
echo "[LANZANDO] Asignando 1 nodo exclusivo por muestra..."
echo "----------------------------------------------------------"

JOB_IDS=()
for i in "${!SAMPLES[@]}"; do
    SAMPLE="${SAMPLES[$i]}"
    case "$SAMPLE" in
        c001) NODE_ASSIGNED=rbp5-1 ;; c002) NODE_ASSIGNED=rbp5-2 ;; c003) NODE_ASSIGNED=rbp5-3 ;;
        e001) NODE_ASSIGNED=rbp5-4 ;; e002) NODE_ASSIGNED=rbp5-5 ;;
        *) NODE_ASSIGNED="${IDLE_NODES[$i]}" ;;
    esac
    QUERY_PATH="${BASE_DIR}/benchmark/instances/${INSTANCE}/${INSTANCE}-${SAMPLE}"
    OUT_FILE="${OUT_DIR}/kraken2_multinodo.${INSTANCE}-${SAMPLE}.predictions.tsv"
    JID=$(sbatch --parsable \
        --job-name=kraken2_multi --partition=partition1 --account=tg \
        --nodes=1 --cpus-per-task=4 --mem=14G --exclusive --nodelist="$NODE_ASSIGNED" \
        --output="${LOGS_DIR}/kraken2_multi_%j_${SAMPLE}.log" \
        --error="${LOGS_DIR}/kraken2_multi_%j_${SAMPLE}.err" \
        --export=ALL,BASE_DIR="$BASE_DIR",INSTANCE="$INSTANCE",MODEL_PATH="$MODEL_PATH",TOOL_NAME="$TOOL_NAME",ENERGY_SCRIPT="$ENERGY_SCRIPT",MEDIR_DIR="$MEDIR_DIR",LOGS_DIR="$LOGS_DIR",SAMPLE="$SAMPLE",QUERY_PATH="$QUERY_PATH",OUT_FILE="$OUT_FILE" \
        "$WORKER_SCRIPT")
    echo "[+] Muestra ${SAMPLE} -> Job ${JID} asignado a nodo ${NODE_ASSIGNED}"
    JOB_IDS+=("$JID")
done

IDS_CSV=$(IFS=, ; echo "${JOB_IDS[*]}")
SAMPLES_STR="${SAMPLES[*]}"
echo "[+] Esperando finalizacion concurrente de: $IDS_CSV"
while true; do
    REMAINING=$(squeue -h -j "$IDS_CSV" 2>/dev/null | wc -l)
    if [ "$REMAINING" -eq 0 ]; then break; fi
    echo -ne "\r[MONITOR $(date +%T)] Tareas activas: $REMAINING   "
    sleep 5
done
echo -e "\n[+] Todas las muestras de Kraken 2 finalizaron."

echo "=========================================================="
echo "=== RESUMEN POR ARCHIVO DE PREDICCIONES ==="
echo "=========================================================="
for i in "${!SAMPLES[@]}"; do
    SAMPLE="${SAMPLES[$i]}"
    JID="${JOB_IDS[$i]}"
    OUT_FILE="${OUT_DIR}/kraken2_multinodo.${INSTANCE}-${SAMPLE}.predictions.tsv"
    LINES=$(wc -l < "$OUT_FILE" 2>/dev/null || echo 0)
    echo "Muestra ${SAMPLE} (job ${JID}): ${LINES} lineas -> ${OUT_FILE}"
done

echo "=========================================================="
echo "=== RESUMEN ENERGETICO CONSOLIDADO DEL CLUSTER (KRAKEN 2) ==="
echo "=========================================================="

python3 -c "
import glob, csv, sys
from pathlib import Path

job_ids = '${IDS_CSV}'.split(',')
samples = '${SAMPLES_STR}'.split()
medir_dir = Path('${MEDIR_DIR}')
instance = '${INSTANCE}'
base_dir = Path('${BASE_DIR}')

def read_powers(path):
    powers = []
    if not path or not path.exists():
        return powers
    with open(path) as f:
        r = csv.reader(f)
        next(r, None)
        for row in r:
            if len(row) >= 2:
                try: powers.append(float(row[1]))
                except ValueError: pass
    return powers

print('-' * 85)
print(f'{\"Muestra\":<10} | {\"Job\":<8} | {\"Nodo\":<9} | {\"Pre(W)\":<7} | {\"Post(W)\":<7} | {\"Base(W)\":<7} | {\"Dur(s)\":<6} | {\"Bruta(Wh)\":<9} | {\"Neta(Wh)\":<9}')
print('-' * 85)

tot_gross_wh = 0.0
tot_net_wh = 0.0
durations = []
total_reads_all = 0

for sample, jid in zip(samples, job_ids):
    pre_match = list(medir_dir.glob(f'*baseline_pre*kraken2_{sample}*job{jid}*.csv'))
    run_match = list(medir_dir.glob(f'*Kraken2_multinodo_{sample}*job{jid}*.csv'))
    post_match = list(medir_dir.glob(f'*baseline_post*kraken2_{sample}*job{jid}*.csv'))

    pre_f = pre_match[-1] if pre_match else None
    run_f = run_match[-1] if run_match else None
    post_f = post_match[-1] if post_match else None

    node = 'unknown'
    if run_f:
        parts = run_f.stem.split('_')
        for idx_p, p in enumerate(parts):
            if p == 'node' and idx_p + 1 < len(parts):
                node = parts[idx_p + 1]

    pre_p = read_powers(pre_f)
    run_p = read_powers(run_f)
    post_p = read_powers(post_f)

    avg_pre = sum(pre_p)/len(pre_p) if pre_p else 0.0
    avg_post = sum(post_p)/len(post_p) if post_p else 0.0
    avg_base = (avg_pre + avg_post)/2.0 if (avg_pre and avg_post) else (avg_pre or avg_post)

    dur_s = len(run_p)
    durations.append(dur_s)
    gross_wh = sum(p/3600.0 for p in run_p)
    net_wh = max(0.0, gross_wh - (avg_base * (dur_s / 3600.0)))

    tot_gross_wh += gross_wh
    tot_net_wh += net_wh

    qdir = base_dir / 'benchmark/instances' / instance / f'{instance}-{sample}'
    s_reads = 0
    for fq in [qdir / 'queryReads1.fq', qdir / 'queryReads.fq']:
        if fq.exists():
            with open(fq) as f:
                s_reads = sum(1 for _ in f) // 4
            break
    total_reads_all += s_reads

    print(f'{sample:<10} | {jid:<8} | {node:<9} | {avg_pre:<7.3f} | {avg_post:<7.3f} | {avg_base:<7.3f} | {dur_s:<6} | {gross_wh:<9.4f} | {net_wh:<9.4f}')

rw_gross = (total_reads_all / tot_gross_wh) if tot_gross_wh > 0 else 0
rw_net = (total_reads_all / tot_net_wh) if tot_net_wh > 0 else 0
max_duration_s = max(durations) if durations else 0

print('-' * 85)
print(f'ENERGIA TOTAL BRUTA CLUSTER:   {tot_gross_wh:.4f} Wh ({tot_gross_wh * 3600:.1f} J)')
print(f'ENERGIA TOTAL NETA CLUSTER:    {tot_net_wh:.4f} Wh ({tot_net_wh * 3600:.1f} J)')
print(f'TOTAL LECTURAS PROCESADAS:     {total_reads_all:,}')
print(f'TIEMPO PARALELO (MAX MUESTRA): {max_duration_s} s ({max_duration_s/60:.2f} min)')
print(f'EFICIENCIA BRUTA CLUSTER:      {rw_gross:,.1f} Reads/Wh')
print(f'EFICIENCIA NETA CLUSTER:       {rw_net:,.1f} Reads/Wh')
print('=' * 85)
"
