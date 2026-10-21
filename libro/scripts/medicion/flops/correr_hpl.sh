#!/usr/bin/env bash
# Corre HPL una vez, con la misma configuracion en todas las plataformas:
#   N = 30000 (unos 7.2 GB de RAM), NB = 192, 4 procesos MPI (uno por nucleo fisico, P x Q = 2 x 2),
#   OpenBLAS con 1 hilo por proceso. Precision doble (FP64), como en el TOP500 / Green500.
# Lo llaman los scripts de medicion (sbatch_hpl_nodo.sh, run_hpl_x86_wsl.ps1, run_hpl_cristian.sh).
#
# Uso:
#   bash correr_hpl.sh <carpeta_hpl> <carpeta_salida> <etiqueta> [N]
# Escribe en <carpeta_salida>:
#   hpl_<etiqueta>.txt      salida completa de HPL (la linea WR... trae el tiempo y los GFLOPS)
#   marcas_hpl_<etiqueta>.csv  inicio y fin de HPL
set -euo pipefail

HPL="${1:?carpeta de HPL}"; OUT="${2:?carpeta de salida}"; TAG="${3:?etiqueta}"; N="${4:-30000}"
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"

for c in "$(dirname "$(dirname "${CONDA_EXE:-/x/bin/conda}")")" /shared/software/conda/miniforge3 \
         ~/miniconda3 ~/miniforge3 ~/anaconda3 /opt/conda; do
    [ -n "$c" ] && [ -f "$c/etc/profile.d/conda.sh" ] && { source "$c/etc/profile.d/conda.sh"; break; }
done
conda activate "$HPL/env"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1

WORK="$(mktemp -d)"; cd "$WORK"
cat > HPL.dat <<EOF
HPLinpack benchmark input file
Proyecto RBPi5 - FLOPs/energia
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N)
$N           Ns
1            # of NBs
192          NBs
0            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
2            Ps
2            Qs
16.0         threshold
1            # of panel fact
2            PFACTs (0=left, 1=Crout, 2=Right)
1            # of recursive stopping criterium
4            NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
1            # of recursive panel fact.
1            RFACTs (0=left, 1=Crout, 2=Right)
1            # of broadcast
1            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1            # of lookahead depth
1            DEPTHs (>=0)
2            SWAP (0=bin-exch,1=long,2=mix)
64           swapping threshold
0            L1 in (0=transposed,1=no-transposed) form
0            U  in (0=transposed,1=no-transposed) form
1            Equilibration (0=no,1=yes)
8            memory alignment in double (> 0)
EOF

echo "muestra,inicio,fin" > "$OUT/marcas_hpl_${TAG}.csv"
ini=$(date '+%Y-%m-%d %H:%M:%S.%3N')
mpirun -np 4 --bind-to core --map-by core "$HPL/bin/xhpl" > "$OUT/hpl_${TAG}.txt" 2>&1
fin=$(date '+%Y-%m-%d %H:%M:%S.%3N')
echo "hpl,$ini,$fin" >> "$OUT/marcas_hpl_${TAG}.csv"
cd /; rm -rf "$WORK"

grep -E "^WR" "$OUT/hpl_${TAG}.txt" | awk '{printf "HPL %s: N=%s  tiempo=%s s  GFLOPS=%s\n", tag, $2, $6, $7}' tag="$TAG"
grep -qE "PASSED" "$OUT/hpl_${TAG}.txt" && echo "Verificacion del resultado: PASSED" || echo "[AVISO] HPL no reporto PASSED"
