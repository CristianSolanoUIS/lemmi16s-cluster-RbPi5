# 🍓 GUÍA 4: ARQUITECTURA DEL CLÚSTER RASPBERRY PI 5, SLURM Y TELEMETRÍA
## 🖥️ Computación Científica de Alto Rendimiento en Arquitectura RISC ARM64

> **Proyecto:** Benchmark LEMMI16s en Arquitecturas Heterogéneas  
> 📄 **Documento:** `04_guia_cluster_slurm_hpc.md`  
> 📅 **Fecha:** Septiembre 2026  
> 🍓 **Hardware:** Clúster Green HPC: 1x Nodo Maestro (RPi 4) + 5x Nodos de Cómputo RPi 5 (20 cores, 80 GB RAM)  
> 🐧 **Sistema Operativo:** Ubuntu Server 24.04 LTS (aarch64)

---

## 1. 🌐 Topología Física y de Red del Clúster

El clúster de cómputo de alto rendimiento está compuesto por nodos de placa única (SBC) con arquitectura **ARM64**:

| Componente / Nodo | Hardware / Especificación | Dirección de Red / Rol | Capacidad |
| :--- | :--- | :--- | :---: |
| **Nodo Maestro** (`rbpi4-master`) | Raspberry Pi 4 (8 GB RAM) | IP Tailscale: `100.125.160.56`<br>Controlador Slurm (`slurmctld`), Servidor NFS | Gestión y almacenamiento |
| **Partición 1 (`grupo1`)** | 5x RPi 5 (`rbp5-1` a `rbp5-5`) | BCM2712 Quad Cortex-A76 @ 2.4 GHz, 8 GB RAM | 20 núcleos físicos dedicados |
| **Partición 2 (`grupo2`)** | 5x RPi 5 (`rbp5-6` a `rbp5-10`) | BCM2712 Quad Cortex-A76 @ 2.4 GHz, 8 GB RAM | 20 núcleos físicos asignados |
| **Almacenamiento Compartido** | Montaje NFS en `/shared` | Directorio distribuido montado idéntico en todos los nodos | `/shared/users/grupo1/` |

---

## 2. 📋 Comandos Esenciales de Gestión de Slurm

Para interactuar con la cola de trabajos en el clúster desde el nodo maestro:

| Acción | Comando Slurm | Descripción |
| :--- | :--- | :--- |
| **Ver estado de nodos** | `sinfo -p partition1` | Muestra si los nodos están `idle`, `alloc`, `drain` o `down` |
| **Ver trabajos activos** | `squeue -u grupo1` | Muestra el JobID, estado (`R` corriendo, `PD` pendiente) y nodo |
| **Cancelar un trabajo** | `scancel {JOB_ID}` | Interrumpe y libera los recursos asignados |
| **Cancelar todos mis jobs** | `scancel -u grupo1` | Detiene todas las ejecuciones activas del usuario |
| **Inspeccionar logs** | `cat slurm-{JOB_ID}.out` | Muestra la salida estándar y errores generados |

---

## 3. 🚀 El Despachador Universal Nativo (`run_tool_analysis.sh`)

### ¿Por qué se prescindió de Singularity?
Originalmente LEMMI16s invoca contenedores Singularity (`.sif`). Sin embargo:
1. Las imágenes oficiales en Quay.io fueron compiladas para arquitectura `linux/amd64`, causando error de kernel `Exec format error` en procesadores ARM64.
2. Los nodos del clúster operan con usuarios sin privilegios `root`, impidiendo la creación de espacios de nombres por restricciones de seguridad.

### Código Fuente del Despachador (`/shared/users/grupo1/lemmi16s/workflow/scripts/run_tool_analysis.sh`)
Este script desacopla los contenedores y ejecuta directamente los scripts científicos oficiales sobre los procesadores de los nodos de cómputo inyectando las bibliotecas necesarias:

```bash
#!/bin/bash
set -eo pipefail

toolname=$1; shift
script_dir="/shared/users/grupo1/lemmi16s/resources/candidate_containers/${toolname}/scripts"

# Exportar bibliotecas dinámicas compartidas ARM64
export LD_LIBRARY_PATH="/shared/users/grupo1/qiime2_arm64/lib:/shared/users/grupo1/lemmi16s_env/lib:$LD_LIBRARY_PATH"

if [[ "${toolname}" == *"qiime2"* ]]; then
    # Entorno especializado QIIME 2 (Python 3.8 + scikit-learn 0.24.1)
    export PATH="${script_dir}:/shared/users/grupo1/qiime2_arm64/bin:/shared/users/grupo1/lemmi16s_env/bin:$PATH"
    export PYTHONPATH="/shared/users/grupo1/qiime2_arm64/lib/python3.8/site-packages"
else
    # Entorno general (Kraken 2 y LotuS3)
    export PATH="${script_dir}:/shared/users/grupo1/lemmi16s_env/bin:$PATH"
fi

# Invocar el script de análisis científico oficial de LEMMI
exec bash "${script_dir}/LEMMI16s_analysis.sh" "$@"
```

---

## 4. 🔀 Arquitectura de Scripts: PC Local y Clúster Distribuido

Para optimizar el uso de los 5 nodos físicos de `partition1`, se desarrolló una arquitectura basada en Job Arrays ubicada en el almacenamiento compartido NFS:

```
/shared/users/grupo1/scripts_cluster_5nodos/
├── split_query_reads_5.py       # Segmentador equilibrado de FASTQs
├── merge_predictions_5.py       # Sumador determinista de tablas #LEMMI16s
├── sbatch_5nodos_pipeline.sh    # Script maestro Slurm Job Array (1-5)
└── run_5chunks_native.sh        # Versión homóloga para pruebas locales en PC
```

*(Nota: En la estación de trabajo PC local, los scripts nativos por pipeline con telemetría Intel RAPL se ubican limpiamente dentro de `lemmi16s/workflow/scripts/nativo/`).*

### Flujo de Ejecución del Job Array:
1. **Lanzamiento:** El usuario ejecuta:
   ```bash
   sbatch /shared/users/grupo1/scripts_cluster_5nodos/sbatch_5nodos_pipeline.sh {PIPELINE} {MUESTRA}
   ```
2. **Segmentación:** `split_query_reads_5.py` divide el archivo de lecturas en 5 partes iguales (`chunk_1` a `chunk_5`).
3. **Mapeo Físico:** Con `#SBATCH --array=1-5`, cada tarea se asigna a un nodo físico (`SLURM_ARRAY_TASK_ID=1` corre en `rbp5-1`, `2` en `rbp5-2`, etc.).
4. **Fusión:** Una vez concluidas las 5 tareas, `merge_predictions_5.py` une las tablas sumando las frecuencias de cada taxón sin introducir sesgo biológico.

---

## 5. ⚡ Sistema de Telemetría Energética en el Clúster

### 🍓 El PMIC Renesas DA9091 de la Raspberry Pi 5
Cada Raspberry Pi 5 integra un circuito integrado de gestión de energía (PMIC) **Renesas DA9091**. Este chip mide en tiempo real por bus I2C:
* Tensión (Voltios) y Corriente (Amperios) del núcleo Cortex-A76.
* Rieles de memoria LPDDR5X, GPU VideoCore VII y líneas auxiliares de 3.3V y 5V.

### 🔌 Servicio de Monitoreo (`pimonitor.service`)
En cada nodo de cómputo se ejecuta como servicio de systemd el agente `pimonitor.service` escuchando en el puerto 5000:

```bash
# Consultar métricas de energía de un nodo vía HTTP:
curl -s http://rbp5-1:5000/metrics
```

### 📊 Automatización de Toma de Datos con `medir_energia_rpi5.py`
El script de telemetría sondea periódicamente cada 500 ms los endpoints HTTP de los nodos involucrados durante la ejecución de Slurm:
```bash
python3 /shared/users/grupo1/medicion_energia/medir_energia_rpi5.py \
  --nodes rbp5-1,rbp5-2,rbp5-3,rbp5-4,rbp5-5 \
  --output telemetria_cluster_5nodos.csv
```
El archivo resultante registra potencia instantánea ($W$) y energía acumulada ($Wh$), permitiendo comparar con precisión física la eficiencia frente a Intel RAPL de la laptop.

---

## 6. 🛡️ Protocolo de Estabilidad, Gestión de Memoria y Recuperación de Nodos

Bajo cargas bioinformáticas intensivas en placas Raspberry Pi 5 (16 GB RAM), se implementó un protocolo estricto de contención de hardware y diagnóstico operativo:

### 6.1. Contención de Recursos en Slurm (`--mem=14G` y `--cpus-per-task=2`)
1. **Límite Estricto de Memoria (`--mem=14G`):**
   * Configurado en todos los scripts ejecutores (`sbatch_multinodo_energy.sh`).
   * **Mecanismo:** Si un proceso excede los 14 GB, el subsistema cgroups de Slurm finaliza controladamente el job antes de que el kernel colapse por agotamiento de RAM (*OOM*), preservando ~1.5 GB de margen para el sistema operativo y la conectividad Ethernet.
2. **Límite de Concurrencia de CPU (`--cpus-per-task=2` / `cpus=2`):**
   * Para pipelines mono-muestra CPU-bound (LotuS3/UPARSE y QIIME 2/Deblur), se fijaron 2 núcleos máximos (`export OMP_NUM_THREADS=2`, `OPENBLAS_NUM_THREADS=2`).
   * **Objetivo:** Evita picos de potencia superiores a 6.5 W, reduciendo el riesgo de caídas de voltaje (*brownouts*) en fuentes de alimentación compartidas y manteniendo la temperatura bajo control.

### 6.2. Diagnóstico Rápido ante Caída de un Nodo
Si un nodo deja de responder (`State=down*` o `Not responding` en `sinfo`):
1. **Verificar si actuó el OOM Killer:**
   ```bash
   dmesg -T | grep -i -E "oom|killed process" | tail -20
   ```
   Si se observan registros de procesos eliminados por memoria, se ratifica que el script excedió el límite físico de RAM.
2. **Verificar Conectividad de Red y Puerto Slurmd:**
   Desde el nodo maestro (`rbpi4-master`):
   ```bash
   ping -c 2 192.168.1.10X
   nc -z -v -w 2 192.168.1.10X 6818
   ```

### 6.3. Desbloqueo y Recuperación sin Reinicio Físico
Si un job queda congelado en estado `completing (CG)` pero la placa responde en red, se restablece el nodo ejecutando en el nodo maestro:
```bash
# 1. Cancelar jobs pendientes del usuario
scancel -u grupo1

# 2. Ciclo de drenado y reanudación Slurm (requiere privilegios de administrador / sudo)
sudo scontrol update NodeName=rbp5-X State=DOWN Reason="clearing stuck job"
sudo scontrol update NodeName=rbp5-X State=RESUME
```
Este ciclo purga los descriptores huérfanos en `slurmctld` y reinserta el nodo inmediatamente en estado `IDLE` sin necesidad de reiniciar físicamente la placa.

### 6.4. Organización de Salidas en Subcarpetas
Para garantizar el ordenamiento y evitar colisiones entre pipelines concurrentes, las predicciones taxonómicas oficiales se dirigen a subcarpetas dedicadas:
* `benchmark/analysis_outputs/kraken2/`
* `benchmark/analysis_outputs/lotus3/`
* `benchmark/analysis_outputs/qiime2/`
