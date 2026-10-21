#!/usr/bin/env bash
# Lanza las 5 muestras PacBio a la vez, una por nodo (mismo reparto fijo que Kraken2).
# Uso: bash lanzar_lotus3_pacbio_5nodos.sh            (corrida medida)
#      bash lanzar_lotus3_pacbio_5nodos.sh --prueba   (solo muestra los comandos)
set -euo pipefail
D=$(cd "$(dirname "$0")" && pwd)
declare -A NODO=( [c001]=rbp5-1 [c002]=rbp5-2 [c003]=rbp5-3 [e001]=rbp5-4 [e002]=rbp5-5 )
for s in c001 c002 c003 e001 e002; do
    cmd=(sbatch --job-name="lotus3_pb_$s" --nodelist="${NODO[$s]}" "$D/sbatch_lotus3_pacbio_multinodo.sh" "$s")
    if [ "${1:-}" = "--prueba" ]; then echo "${cmd[*]}"; else "${cmd[@]}"; fi
done
[ "${1:-}" = "--prueba" ] || squeue -u grupo1
