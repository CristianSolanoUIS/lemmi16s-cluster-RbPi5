#!/usr/bin/env bash
# Lanza HPL en los 5 nodos de computo (rbp5-1 a rbp5-5), un trabajo por nodo, todos a la vez.
# HPL no lee datos del almacenamiento compartido, asi que correr los 5 juntos no afecta el resultado
# de cada nodo y ahorra tiempo (unos 17 min en total con el protocolo).
# Uso (en el nodo maestro):  bash lanzar_hpl_5nodos.sh
set -euo pipefail
SCRIPTS="/shared/users/grupo1/lemmi16s/scripts/flops"
for n in 1 2 3 4 5; do
    sbatch --nodelist="rbp5-$n" "$SCRIPTS/sbatch_hpl_nodo.sh"
done
squeue -u "$USER"
