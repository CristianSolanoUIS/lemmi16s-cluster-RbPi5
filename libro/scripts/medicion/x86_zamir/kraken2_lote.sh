#!/usr/bin/env bash
# Corre Kraken2+Bracken para varias muestras, una detras de otra (lo llama run_kraken2_x86_lote.ps1).
# Uso: bash kraken2_lote.sh <fecha> <archivo_marcas> <muestra1> [muestra2] ...
set -e
FECHA="$1"; MARCAS="$2"; shift 2

source ~/miniconda3/bin/activate kraken2_native

B=/home/zamir/proyecto_grado/lemmi16s
MODEL="$B/benchmark/tmp/kraken2_16s_HOMD_v4_GTDB/tmp_HOMD_v4_GTDB_500k"
SCRIPT="$B/resources/candidate_containers/kraken_213_lemmi16s/scripts/LEMMI16s_analysis_native.sh"
WORK="$B/benchmark/tmp/x86_energybench/kraken2"
OUT="$B/benchmark/analysis_outputs/kraken2"

mkdir -p "$WORK"
echo "muestra,inicio,fin" > "$MARCAS"
for m in "$@"; do
    sf="HOMD_v4_GTDB_500k-$m"
    rm -rf "$WORK/tmp_$sf"
    cd "$WORK"
    ini=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    bash "$SCRIPT" "$sf" "$B/benchmark/instances/HOMD_v4_GTDB_500k/$sf" "$MODEL" \
        "$OUT/kraken_213_lemmi16s_nativo.$sf.lote_$FECHA.predictions.tsv" > "$WORK/log_$sf.txt" 2>&1
    fin=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    echo "$m,$ini,$fin" >> "$MARCAS"
    echo "$m listo ($ini -> $fin)"
done
