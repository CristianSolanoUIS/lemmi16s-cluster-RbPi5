# ⚡ GUÍA 1: PIPELINE KRAKEN 2 + BRACKEN (PC LOCAL Y CLÚSTER HPC)
## 🧬 Clasificación Taxonómica Ultra-Rápida por k-meros y Re-estimación Bayesiana

> **Proyecto:** Benchmark LEMMI16s en Arquitecturas Heterogéneas  
> 📄 **Documento:** `01_guia_pipeline_kraken2.md`  
> 📅 **Fecha:** Septiembre 2026  
> 🔬 **Pipeline:** Kraken 2 (v2.1.3) + Bracken (v3.0.1 alineado)  
> 📊 **Dataset Oficial:** `HOMD_v4_GTDB` (5 muestras: `c001` a `e002`, 2,453,431 lecturas pareadas)

---

## 1. 🎯 Fundamento Teórico y Estructura del Índice

Kraken 2 y Bracken combinan dos técnicas complementarias para clasificar metagenomas 16S a máxima velocidad sin realizar alineamiento de secuencias tradicional:

| Algoritmo / Módulo | Filosofía Computacional | Nivel Taxonómico | Rol en el Flujo |
| :--- | :--- | :--- | :--- |
| **Kraken 2** | Coincidencias exactas de $k$-meros ($k=35$, $l=31$) contra tablas hash compactas | Ancestro Común más Bajo (LCA) | Clasificación ultra-rápida lectura por lectura |
| **Bracken** | Re-estimación Bayesiana de abundancia (*Bayesian Reestimation*) | Género (`-l G`) o Especie (`-l S`) | Redistribución estadística de lecturas intermedias |
| **`editResult.py`** | Estandarización LEMMI16s | Linaje completo (7 niveles) | Conversión a tabla `#LEMMI16s` estándar |

### 🗄️ Archivos Binarios del Índice GTDB (`database/`)
En la carpeta de la base de datos se encuentran los siguientes archivos:
* **`hash.k2d`**: Tabla hash binaria de minimizadores que apunta directamente al taxID de GTDB.
* **`opts.k2d`**: Metadatos binarios con los parámetros del modelo ($k=35$, $l=31$).
* **`taxo.k2d`**: Árbol jerárquico de relaciones de ancestría taxonómica.
* **`seqid2taxid.map`**: Diccionario que relaciona IDs de secuencias con sus taxIDs.
* **`database150mers.kmer_distrib`**: Frecuencias condicionales precalculadas para lecturas de 150 pb en Bracken.

---

## 2. 💻 Forma de Corrida en el PC Local (Laptop ASUS TUF x86_64)

### ⚙️ Entorno y Rutas Locales
* **Entorno Conda:** `/home/cristian-solano/proyectos/miniconda3/envs/kraken2_env`
* **Base de Datos:** `/home/cristian-solano/lemmi16s/benchmark/tmp/kraken2_16s_HOMD_v4_GTDB/tmp_HOMD_v4_GTDB/database`
* **Muestra:** `/home/cristian-solano/lemmi16s/benchmark/instances/HOMD_v4_GTDB/HOMD_v4_GTDB-c001`

---

### 🔹 Opción A: Ejecución Directa de la Muestra Completa (1 Sola Corrida)
Procesa los 500,000 pares de lecturas secuencialmente en la laptop a 4 hilos:

```bash
# 1. Definir rutas y crear carpeta temporal de trabajo
K2_ENV="/home/cristian-solano/proyectos/miniconda3/envs/kraken2_env/bin"
DB_DIR="/home/cristian-solano/lemmi16s/benchmark/tmp/kraken2_16s_HOMD_v4_GTDB/tmp_HOMD_v4_GTDB/database"
SAMPLE_DIR="/home/cristian-solano/lemmi16s/benchmark/instances/HOMD_v4_GTDB/HOMD_v4_GTDB-c001"
WORK_DIR="/tmp/run_kraken2_pc_manual"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# 2. Paso 1: Ejecutar Kraken 2 a 4 hilos
${K2_ENV}/kraken2 \
  --db "$DB_DIR" \
  --threads 4 \
  --paired "$SAMPLE_DIR/queryReads1.fq" "$SAMPLE_DIR/queryReads2.fq" \
  --output query.out \
  --report query.report

# 3. Paso 2: Ejecutar Bracken a nivel de Género (-l G) para lecturas de 150 bp (-r 150)
${K2_ENV}/bracken \
  -d "$DB_DIR" \
  -i query.report \
  -o query.bracken \
  -w query_bracken_genuses.report \
  -l G \
  -r 150

# 4. Paso 3: Estandarizar salida a formato LEMMI16s
python3 /home/cristian-solano/lemmi16s/resources/candidate_containers/kraken_213_lemmi16s/scripts/editResult.py \
  query_bracken_genuses.report results.tsv summary_taxonomy.tsv

# 5. Guardar predicción final
cp results.tsv /home/cristian-solano/lemmi16s/benchmark/analysis_outputs/kraken2_lemmi16s.HOMD_v4_GTDB-c001.predictions.tsv
```

---

### 🔹 Opción B: Ejecución Nativa Paralela en 5 Chunks (`run_5chunks_native.sh`)
Divide automáticamente la muestra en 5 chunks de 100,000 lecturas, los procesa en procesos paralelos y fusiona la predicción:

```bash
/home/cristian-solano/lemmi16s-cluster-backup/scripts_cluster_5nodos/run_5chunks_native.sh kraken2 HOMD_v4_GTDB-c001
```

| Métrica en Laptop | Valor Observado |
| :--- | :--- |
| **Tiempo de Ejecución** | **~2.8 a 3.0 segundos** (muestra completa) |
| **Predicción Generada** | `benchmark/analysis_outputs/kraken2_lemmi16s.HOMD_v4_GTDB-c001.5chunks_merged.tsv` |
| **Concordancia Biológica** | **100.00% Idéntico** al Docker oficial y a la corrida de 1 solo bloque |

---

### 🔹 Medición de Telemetría Energética en PC (Intel RAPL)
Ejecución nativa automatizada mediante el script dedicado en `lemmi16s/workflow/scripts/nativo/run_kraken2_energy.sh`, el cual orquesta el protocolo unificado de telemetría: 60 s de estabilización en frío + 300 s (5 minutos) de reposo previo a 1.0 Hz y registro activo continuo:

```bash
# 1. Permisos RAPL (ejecutar una vez tras reiniciar la laptop si es necesario)
sudo chmod 444 /sys/class/powercap/intel-rapl:0/energy_uj

# 2. Ejecución de 1 muestra (ejemplo: c001)
bash /home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_kraken2_energy.sh c001

# 3. Ejecución del lote completo (c001, c002, c003, e001, e002)
bash /home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_kraken2_energy.sh all
```

---

## 3. 🍓 Forma de Corrida en el Clúster Raspberry Pi 5 (Slurm / ARM64)

### ⚙️ Entorno y Rutas en el Clúster NFS
* **Directorio Base:** `/shared/users/grupo1/`
* **Entorno Conda ARM64:** `/shared/users/grupo1/lemmi16s_env/bin`
* **Despachador Universal:** `/shared/users/grupo1/lemmi16s/workflow/scripts/run_tool_analysis.sh`
* **Base de Datos:** `/shared/users/grupo1/lemmi16s/benchmark/tmp/kraken2_16s_HOMD_v4_GTDB/tmp_HOMD_v4_GTDB/database`
* **Muestra en Clúster:** `/shared/users/grupo1/lemmi16s/benchmark/instances/HOMD_v4_GTDB/HOMD_v4_GTDB-c001`

---

### 🔹 Opción A: Corrida en 1 Solo Nodo (Slurm Tradicional)
Envía la muestra completa a un solo nodo físico (ej. `rbp5-1` a 4 hilos):

```bash
sbatch --partition=partition1 --nodelist=rbp5-1 --job-name=k2_single \
  --wrap="bash /shared/users/grupo1/lemmi16s/workflow/scripts/run_tool_analysis.sh kraken_213_lemmi16s \
  /shared/users/grupo1/lemmi16s/benchmark/tmp/kraken2_16s_HOMD_v4_GTDB/tmp_HOMD_v4_GTDB/database \
  /shared/users/grupo1/lemmi16s/benchmark/instances/HOMD_v4_GTDB/HOMD_v4_GTDB-c001/queryReads1.fq \
  /shared/users/grupo1/lemmi16s/benchmark/instances/HOMD_v4_GTDB/HOMD_v4_GTDB-c001/queryReads2.fq \
  /shared/users/grupo1/lemmi16s/benchmark/analysis_outputs/kraken2_lemmi16s.HOMD_v4_GTDB-c001.predictions.tsv 4"
```

---

### 🔹 Opción B: Corrida Distribuida en los 5 Nodos Físicos (Job Array Slurm)
Aprovecha simultáneamente los 5 nodos físicos de la partición `grupo1` (`rbp5-1` a `rbp5-5`):

```bash
# Lanzamiento del Job Array distribuido
sbatch /shared/users/grupo1/scripts_cluster_5nodos/sbatch_5nodos_pipeline.sh kraken2 HOMD_v4_GTDB-c001
```

#### Fases de la Ejecución Distribuida en Slurm:
1. **Partición Automática:** El nodo maestro ejecuta `split_query_reads_5.py`, segmentando `queryReads1.fq` y `queryReads2.fq` en 5 subdirectorios (`chunk_1` a `chunk_5`) con exactamente 100,000 pares de lecturas cada uno.
2. **Ejecución Paralela:** Slurm asigna mediante el array `#SBATCH --array=1-5` cada chunk a un nodo Raspberry Pi 5 distinto. Cada nodo ejecuta `run_tool_analysis.sh kraken_213_lemmi16s` de manera concurrente.
3. **Fusión Determinista:** Al culminar los 5 nodos, `merge_predictions_5.py` lee los 5 archivos `.predictions.tsv` y consolida los conteos absolutos por taxón.

---

## 4. 🔍 Verificación de Salidas y Validación

El resultado debe contener la cabecera estándar `#LEMMI16s` y los linajes formateados:

```tsv
#LEMMI16s
Group_ID	Size	Taxonomy
group_0	499995	d__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Pseudomonadales;f__Pseudomonadaceae;g__Pseudomonas;s__na
```

Para verificar identidad binaria estricta entre la laptop y el clúster:
```bash
diff -u \
  /home/cristian-solano/lemmi16s/benchmark/analysis_outputs/kraken2_lemmi16s.HOMD_v4_GTDB-c001.predictions.tsv \
  /shared/users/grupo1/lemmi16s/benchmark/analysis_outputs/kraken2_lemmi16s.HOMD_v4_GTDB-c001.predictions.tsv
```
*(Debe retornar 0 diferencias).*

> [!TIP]
> **Eficiencia Máxima:** Kraken 2 es la herramienta más veloz del estudio (menos de 3 segundos en laptop y ~18 segundos en clúster) al operar sobre tablas hash en memoria RAM sin necesidad de alinear bases nitrogenadas una a una.
