#!/usr/bin/env bash
# Junta lo necesario para comparar LotuS3 PacBio (muestra c001) entre dos computadores.
# No corre LotuS3: solo lee la corrida que ya se hizo.
#
# Uso:
#   bash diagnostico_lotus3_pacbio.sh <entorno_conda> <carpeta_trabajo_c001> <carpeta_referencia>
#     entorno_conda          nombre o ruta del entorno conda con el que se corrio LotuS3
#     carpeta_trabajo_c001   carpeta donde quedo reads-output/ de la muestra c001
#     carpeta_referencia     carpeta con reference.fasta, reference.tsv y reference.fasta.vudb usados
# Ejemplo:
#   bash diagnostico_lotus3_pacbio.sh lotus3_env ~/lotus3_work_c001 ~/paquete/referencia
# Resultado: diag_lotus3_<equipo>.tar.gz en la carpeta actual (mandarlo completo).
set -uo pipefail

ENV="$1"; WORK="$2"; REF="$3"
OUT="diag_lotus3_$(hostname)"
rm -rf "$OUT"; mkdir -p "$OUT"
for c in "$(dirname "$(dirname "${CONDA_EXE:-/x/bin/conda}")")" ~/miniconda3 ~/miniforge3 ~/anaconda3 ~/mambaforge /opt/conda; do
    [ -n "$c" ] && [ -f "$c/etc/profile.d/conda.sh" ] && { source "$c/etc/profile.d/conda.sh"; break; }
done
conda activate "$ENV" || { echo "[ERROR] no se pudo activar el entorno $ENV"; exit 1; }
BIN="$(dirname "$(which lotus3)")"

{
  echo "equipo: $(hostname) | $(uname -sm) | $(date -Iseconds)"
  echo "entorno: $CONDA_PREFIX"
  echo "--- versiones"
  vsearch --version 2>&1 | head -1
  lotus3 -v 2>&1 | grep -iE "lotus|version" | head -3
  ls "$CONDA_PREFIX/share" | grep -i lotus
  conda list 2>/dev/null | grep -iE "^(lotus3|vsearch|lambda|minimap2|cd-hit|sdm|rtk|blast) "
  echo "--- binarios que usa LotuS3 (lOTUs.cfg)"
  grep -E "^(vsearch|LCA|lambda3|sdm|cd-hit|minimap2) " "$CONDA_PREFIX"/share/lotus3*/lOTUs.cfg
  echo "--- wrappers"
  ls -la "$BIN"/LCA* "$BIN"/lambda3* 2>&1
  echo "--- md5 de binarios"
  md5sum "$BIN"/vsearch "$BIN"/LCA "$BIN"/LCA.real "$BIN"/sdm 2>/dev/null
  echo "--- md5 de la referencia"
  md5sum "$REF"/reference.fasta "$REF"/reference.tsv 2>/dev/null
  ls -la "$REF"/reference.fasta.vudb 2>&1
  echo "--- md5 de la entrada"
  md5sum "$WORK"/reads/queryReads.fq "$WORK"/reads/sdm_PacBio_LSSU.txt 2>/dev/null
  echo "--- md5 de los intermedios (c001)"
  md5sum "$WORK"/reads-output/OTU.fna "$WORK"/reads-output/hiera_BLAST.txt 2>/dev/null
  echo "tax.0.blast ordenado: $(sort "$WORK"/reads-output/ExtraFiles/tax.0.blast 2>/dev/null | md5sum | cut -c1-32)"
  echo "OTU.fna secuencias: $(grep -c '>' "$WORK"/reads-output/OTU.fna 2>/dev/null)"
} > "$OUT/info.txt" 2>&1

cp "$WORK"/reads-output/LotuSLogS/LotuS_cmds.log "$WORK"/reads-output/LotuSLogS/LotuS_progout.log \
   "$WORK"/reads-output/LotuSLogS/LotuS_run.log "$WORK"/reads-output/LotuSLogS/LCAhits.log \
   "$WORK"/reads-output/OTU.fna "$WORK"/reads-output/hiera_BLAST.txt "$OUT"/ 2>/dev/null
cp "$WORK"/reads-output/ExtraFiles/tax.0.blast "$OUT"/ 2>/dev/null
cp "$WORK"/results.tsv "$OUT"/ 2>/dev/null

tar -czf "$OUT.tar.gz" "$OUT" && rm -rf "$OUT"
echo "Listo: $(pwd)/$OUT.tar.gz"
cat <(tar -xzOf "$OUT.tar.gz" "$OUT/info.txt")
