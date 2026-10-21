#!/usr/bin/env bash
# Prepara el cluster para LotuS3 PacBio (5 muestras de Cristian). Se corre UNA vez en el maestro.
#  1. Descomprime el paquete en benchmark/instances/HM_Contaminated_Soil_PacBio y verifica los 21 MD5.
#  2. Clona lemmi16s_env -> lemmi16s_pacbio_env y aplica los wrappers de Cristian SOLO en el clon
#     (lemmi16s_env lo usan Kraken2 y la corrida de 3 muestras del libro: no se toca).
#  3. Crea las carpetas de salida (mismo orden que las otras corridas).
# Uso: bash 02_preparar_pacbio_cluster.sh /ruta/paquete_lotus3_pacbio_5muestras.tar.gz
set -euo pipefail

PAQ="$1"
B=/shared/users/grupo1/lemmi16s
INST=$B/benchmark/instances/HM_Contaminated_Soil_PacBio
ENV_BASE=/shared/users/grupo1/lemmi16s_env
ENV_PB=/shared/users/grupo1/lemmi16s_pacbio_env

echo "== 1. Instancia"
if [ -e "$INST" ]; then
    echo "Ya existe $INST (no se descomprime de nuevo)"
else
    T=$(mktemp -d "$B/benchmark/instances/.tmp_pacbio.XXXX")
    tar -xzf "$PAQ" -C "$T"
    mv "$T/paquete_lotus3_pacbio_5muestras" "$INST"
    rmdir "$T"
fi
(cd "$INST" && md5sum -c MD5SUMS.txt | grep -c ': OK$') | xargs echo "MD5 OK:"
(cd "$INST" && md5sum -c --quiet MD5SUMS.txt) && echo "Todos los MD5 coinciden con los de Cristian"

echo "== 2. Entorno"
source /shared/software/conda/miniforge3/etc/profile.d/conda.sh
if [ -d "$ENV_PB" ]; then
    echo "Ya existe $ENV_PB"
else
    conda create -y -q --clone "$ENV_BASE" -p "$ENV_PB"
fi
bash "$INST/scripts/instalar_wrappers_lotus3.sh" "$ENV_PB"
ls -la "$ENV_PB"/bin/lambda3* "$ENV_PB"/bin/LCA* 2>/dev/null || ls -la "$ENV_PB"/bin/LCA*
echo "-- entorno original (debe seguir siendo binario, sin wrapper):"
file "$ENV_BASE/bin/lambda3" "$ENV_BASE/bin/LCA" 2>/dev/null || file "$ENV_BASE/bin/LCA" | cut -c1-120
conda activate "$ENV_PB"
which lotus3 biom python3

echo "== 3. Carpetas"
mkdir -p $B/benchmark/analysis_outputs/lotus3_pacbio \
         $B/medicion_energia/lotus3_pacbio/pre \
         $B/benchmark/tmp/lotus3_pacbio/database_indexada \
         /shared/users/grupo1/logs_slurm
# Base con su indice lambda (hecho por Cristian en x86; la prueba corta confirma si sirve en ARM)
for f in reference.fasta reference.tsv reference.fasta.lba.gz; do
    [ -e "$B/benchmark/tmp/lotus3_pacbio/database_indexada/$f" ] || cp "$INST/referencia/$f" "$B/benchmark/tmp/lotus3_pacbio/database_indexada/"
done
echo "LISTO"
