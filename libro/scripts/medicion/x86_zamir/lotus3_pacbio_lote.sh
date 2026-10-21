#!/usr/bin/env bash
# Corre LotuS3 en modo PacBio para varias muestras, una detras de otra (lo llama run_lotus3_pacbio_x86_lote.ps1).
# Muestras: las que genero Cristian con LEMMI (rama pacbio, MHASS), instancia HM_Contaminated_Soil_PacBio.
# Parametros: iguales al cluster (-derepMin 1:1,1:2,1:3 -p PacBio -s sdm_PacBio_LSSU.txt -buildPhylo 0 -lulu 0 -t 4)
# y la asignacion taxonomica con VSEARCH (-taxAligner vsearch), como en el cluster, donde no existe lambda3 para ARM.
# Entorno: lotus3_pacbio_303 (clon de lotus3_native_303 con los wrappers de Cristian; VSEARCH v2.31.0, igual que el cluster).
# La base de VSEARCH (reference.fasta.vudb, ~3 GB) la construye LotuS3 en la prueba corta de 'preparar', fuera de la medicion.
#
# Uso:
#   bash lotus3_pacbio_lote.sh preparar                              (copia la base y construye el .vudb, sin medir)
#   bash lotus3_pacbio_lote.sh prueba <muestra> <n_lecturas>         (prueba corta, sin medir)
#   bash lotus3_pacbio_lote.sh <fecha> <archivo_marcas> <muestra1> ...  (corrida medida)
set -euo pipefail

source ~/miniconda3/etc/profile.d/conda.sh
conda activate lotus3_pacbio_303

REPO=/home/zamir/proyecto_grado/lemmi16s
INST="$REPO/benchmark/instances/HM_Contaminated_Soil_PacBio"
OUT="$REPO/benchmark/analysis_outputs/lotus3_pacbio"
WORKBASE="$REPO/benchmark/tmp/x86_energybench/lotus3_pacbio"
IDX="$WORKBASE/database_indexada"
SDM="$INST/recursos/sdm_PacBio_LSSU.txt"
EDIT="$INST/scripts/editResult.py"

mkdir -p "$OUT" "$WORKBASE" "$IDX"

correr_muestra() {   # $1 = muestra, $2 = fastq de entrada, $3 = carpeta de trabajo
    local s="$1" fq="$2" work="$3"
    rm -rf "$work"
    mkdir -p "$work/reads"
    cd "$work"
    cp -f "$fq" reads/queryReads.fq
    cp -f "$SDM" reads/sdm_PacBio_LSSU.txt
    printf '#SampleID\tfastqFile\tSequencingRun\nSample1\tqueryReads.fq\tRun1\n' > reads/pacbioMap.sm.txt
    lotus3 -derepMin 1:1,1:2,1:3 -i reads/ -m reads/pacbioMap.sm.txt -o reads-output \
        -refDB "$IDX/reference.fasta" -tax4refDB "$IDX/reference.tsv" \
        -s reads/sdm_PacBio_LSSU.txt -p PacBio -buildPhylo 0 -lulu 0 -t 4 -taxAligner vsearch > "$work.log" 2>&1
    grep -A1 "Assigning taxonomy" "$work.log" | grep -q "using VSEARCH" || { echo "[ERROR] $s no uso VSEARCH, ver $work.log"; exit 1; }
    biom convert -i reads-output/OTU.biom -o results.txt --to-tsv --header-key taxonomy >> "$work.log" 2>&1
    python3 "$EDIT" results.txt results.tsv summary_taxonomy.tsv
}

prueba() {   # $1 = muestra, $2 = numero de lecturas
    local s="$1" n="$2"
    mkdir -p "$WORKBASE/prueba"
    head -n $((n * 4)) "$INST/muestras/HM_Contaminated_Soil-$s/queryReads.fq" > "$WORKBASE/prueba/queryReads_${s}_${n}.fq"
    local ini=$(date +%s)
    correr_muestra "$s" "$WORKBASE/prueba/queryReads_${s}_${n}.fq" "$WORKBASE/prueba/tmp_$s"
    echo "prueba $s con $n lecturas: $(( $(date +%s) - ini )) s ($(grep -A1 'Assigning taxonomy' "$WORKBASE/prueba/tmp_$s.log" | tail -1 | xargs))"
}

if [ "${1:-}" = "preparar" ]; then
    for f in reference.fasta reference.tsv; do
        [ -e "$IDX/$f" ] || cp "$INST/referencia/$f" "$IDX/$f"
    done
    (cd "$INST" && grep -E "referencia/reference\.(fasta|tsv)$" MD5SUMS.txt | sed "s#referencia/#$IDX/#" | md5sum -c -)
    if [ ! -s "$IDX/reference.fasta.vudb" ]; then
        echo "Construyendo la base de VSEARCH con una prueba corta (200 lecturas de c001)..."
        prueba c001 200
        rm -rf "$WORKBASE/prueba"
    fi
    ls -la "$IDX"
    exit 0
fi

if [ "${1:-}" = "prueba" ]; then
    prueba "$2" "$3"
    exit 0
fi

FECHA="$1"; MARCAS="$2"; shift 2
[ -s "$IDX/reference.fasta.vudb" ] || { echo "Falta la base de VSEARCH: corre primero 'lotus3_pacbio_lote.sh preparar'"; exit 1; }

echo "muestra,inicio,fin" > "$MARCAS"
for s in "$@"; do
    WORK="$WORKBASE/tmp_HM_Contaminated_Soil_PacBio-$s"
    ini=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    correr_muestra "$s" "$INST/muestras/HM_Contaminated_Soil-$s/queryReads.fq" "$WORK"
    cp results.tsv "$OUT/lotus3_pacbio_nativo.HM_Contaminated_Soil_PacBio-$s.lote_$FECHA.predictions.tsv"
    fin=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    echo "$s,$ini,$fin" >> "$MARCAS"
    echo "$s listo ($ini -> $fin)"
done
