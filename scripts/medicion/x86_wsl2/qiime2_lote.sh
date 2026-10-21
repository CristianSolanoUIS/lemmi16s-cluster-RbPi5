#!/usr/bin/env bash
# Corre QIIME2 para varias muestras, una detras de otra (lo llama run_qiime2_x86_lote.ps1).
# Mismos pasos y parametros que la corrida de Cristian (q-score 20, Deblur 120 bp,
# Naive Bayes, nivel 7) con 4 hilos. El clasificador ya esta entrenado, no se rehace.
# Uso: bash qiime2_lote.sh <fecha> <archivo_marcas> <muestra1> [muestra2] ...
set -euo pipefail
FECHA="$1"; MARCAS="$2"; shift 2

source ~/miniconda3/bin/activate qiime2-2023.2
export cpus=4

B=/home/zamir/proyecto_grado/lemmi16s
MODEL="$B/benchmark/tmp/qiime2_alfa_v1v2_SILVA/tmp_alfa_v1v2_SILVA"
SCRIPT="$B/resources/candidate_containers/qiime2_20228_lemmi16s/scripts/LEMMI16s_analysis_native.sh"
WORK="$B/benchmark/tmp/x86_energybench/qiime2"
OUT="$B/benchmark/analysis_outputs/qiime2"

mkdir -p "$WORK" "$OUT"
echo "muestra,inicio,fin" > "$MARCAS"
for m in "$@"; do
    sf="alfa_v1v2_SILVA-$m"
    rm -rf "$WORK/tmp_$sf"
    cd "$WORK"
    ini=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    bash "$SCRIPT" "$sf" "$B/benchmark/instances/alfa_v1v2_SILVA/$sf" "$MODEL" \
        "$OUT/qiime2_20228_lemmi16s_nativo.$sf.lote_$FECHA.predictions.tsv" > "$WORK/log_$sf.txt" 2>&1
    fin=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    echo "$m,$ini,$fin" >> "$MARCAS"
    echo "$m listo ($ini -> $fin)"
done
