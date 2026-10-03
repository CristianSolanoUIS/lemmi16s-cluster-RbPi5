#!/usr/bin/env bash
set -e
B=/shared/users/grupo1/lemmi16s
INST=$B/benchmark/instances/HM_Contaminated_Soil_PacBio
IDX=$B/benchmark/tmp/lotus3_pacbio/database_indexada
WORK=$B/benchmark/tmp/lotus3_pacbio/prueba_corta
SDM=$INST/recursos/sdm_PacBio_LSSU.txt
EDIT=$INST/scripts/editResult.py

echo "=== Iniciando prueba corta (200 lecturas c001 en $(hostname)) ==="
rm -rf "$WORK"
mkdir -p "$WORK/reads"
cd "$WORK"

head -n 800 "$INST/muestras/HM_Contaminated_Soil-c001/queryReads.fq" > reads/queryReads.fq
cp -f "$SDM" reads/sdm_PacBio_LSSU.txt
printf '#SampleID\tfastqFile\tSequencingRun\nSample1\tqueryReads.fq\tRun1\n' > reads/pacbioMap.sm.txt

source /shared/software/conda/miniforge3/etc/profile.d/conda.sh
conda activate /shared/users/grupo1/lemmi16s_pacbio_env

echo "=== Corriendo LotuS3 en prueba corta ==="
lotus3 -derepMin 1:1,1:2,1:3 -i reads/ -m reads/pacbioMap.sm.txt -o reads-output     -refDB "$IDX/reference.fasta" -tax4refDB "$IDX/reference.tsv"     -s reads/sdm_PacBio_LSSU.txt -p PacBio -buildPhylo 0 -lulu 0 -t 4

echo "=== Convirtiendo biom ==="
biom convert -i reads-output/OTU.biom -o results.txt --to-tsv --header-key taxonomy

echo "=== Formateando tabla con editResult.py ==="
python3 "$EDIT" results.txt results.tsv summary_taxonomy.tsv

echo "=== Verificando resultados ==="
ls -lh results.tsv
wc -l results.tsv
head -n 10 results.tsv
echo "=== PRUEBA CORTA EXITOSA ==="
