# Scripts de ejecución y medición

## `cluster/`

Ejecución de los pipelines en el clúster con Slurm, con medición de energía por el PMIC de cada nodo.

- `multinodo/kraken2/`, `multinodo/qiime2/`: una muestra por nodo en los 5 nodos (`sbatch_multinodo_energy.sh` lanza los trabajos y `worker_*_energy.sh` corre en cada nodo).
- `mononodo/`: las 5 muestras en un solo nodo, una tras otra; `calcular_comparacion_mononodo.py` compara con la corrida de 5 nodos.
- `lotus3_pacbio/`: preparación del dataset PacBio en el clúster y corridas de LotuS3 en 5 nodos y en 1 nodo.

## `medicion/`

- `cluster_pmic/medir_energia_pmic.py`: lectura del PMIC de la Raspberry Pi 5 a 1 Hz.
- `x86_nativo/`: corridas en Ubuntu nativo con medición RAPL (`medir_energia_rapl.py`).
- `x86_wsl2/`: corridas en WSL2 con medición RAPL a través de LibreHardwareMonitor, incluido el reposo de 5 min.
- `hpl/`: instalación y ejecución de HPL en cada nodo del clúster (`lanzar_hpl_5nodos.sh`), en x86 nativo y en WSL2.

## `evaluacion/`

Evaluación de las predicciones con LEMMI16s (F1, precisión, recall). Ver su [README](evaluacion/README.md).

Los scripts usan las rutas del clúster (`/shared/users/grupo1/...`) y de cada equipo; hay que ajustarlas para correrlos en otro entorno.
