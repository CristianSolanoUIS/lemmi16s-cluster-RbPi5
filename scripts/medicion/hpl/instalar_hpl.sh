#!/usr/bin/env bash
# Instala HPL 2.3 (High Performance LINPACK) sin sudo, con OpenBLAS y Open MPI de conda-forge.
# Sirve igual en ARM64 (Raspberry Pi 5) y en x86 (WSL2 o Linux nativo): misma version de HPL y
# misma biblioteca BLAS en todas las plataformas, para que los GFLOPS sean comparables.
#
# Uso:
#   bash instalar_hpl.sh <carpeta_destino>
# Ejemplos:
#   bash instalar_hpl.sh ~/hpl                       (WSL2 o laptop de Cristian)
#   srun -p partition1 -A tg -w rbp5-1 -N1 --exclusive bash instalar_hpl.sh /shared/users/grupo1/hpl
#     (en el cluster se compila en un nodo Raspberry Pi 5, no en el maestro Pi 4, para que
#      -march=native genere codigo para el Cortex-A76)
# Resultado: <carpeta_destino>/env (entorno conda) y <carpeta_destino>/bin/xhpl
set -euo pipefail

DEST="${1:?Uso: bash instalar_hpl.sh <carpeta_destino>}"
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

for c in "$(dirname "$(dirname "${CONDA_EXE:-/x/bin/conda}")")" /shared/software/conda/miniforge3 \
         ~/miniconda3 ~/miniforge3 ~/anaconda3 /opt/conda; do
    [ -n "$c" ] && [ -f "$c/etc/profile.d/conda.sh" ] && { source "$c/etc/profile.d/conda.sh"; break; }
done
command -v conda >/dev/null || { echo "[ERROR] no se encontro conda"; exit 1; }

echo "=== Arquitectura: $(uname -m) | destino: $DEST ==="
if [ ! -x "$DEST/env/bin/mpicc" ]; then
    conda create -y -q -p "$DEST/env" -c conda-forge openblas openmpi make c-compiler
fi
conda activate "$DEST/env"

cd "$DEST"
if [ ! -d hpl-2.3 ]; then
    curl -fsSL -o hpl-2.3.tar.gz https://www.netlib.org/benchmark/hpl/hpl-2.3.tar.gz
    tar -xzf hpl-2.3.tar.gz
fi
cd hpl-2.3
./configure --prefix="$DEST" CC=mpicc CFLAGS="-O3 -march=native" \
    CPPFLAGS="-I$CONDA_PREFIX/include" \
    LDFLAGS="-L$CONDA_PREFIX/lib -Wl,-rpath,$CONDA_PREFIX/lib" LIBS="-lopenblas" > "$DEST/configure.log" 2>&1
make -j4 > "$DEST/make.log" 2>&1
make install >> "$DEST/make.log" 2>&1

[ -x "$DEST/bin/xhpl" ] || { echo "[ERROR] no se genero xhpl, ver $DEST/make.log"; exit 1; }
echo "=== Listo: $DEST/bin/xhpl ==="
echo "OpenBLAS: $(ls "$CONDA_PREFIX"/lib/libopenblas*.so* | head -1)"
echo "Open MPI: $(mpirun --version | head -1)"
