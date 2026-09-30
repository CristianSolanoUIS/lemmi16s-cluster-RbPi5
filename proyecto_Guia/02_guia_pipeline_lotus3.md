# 🌿 GUÍA 2: PIPELINE LotuS3 (PC LOCAL Y CLÚSTER HPC)
## 🧬 Demultiplexación, Control de Calidad SDM, Clustering UPARSE y Clasificación LCA

> **Proyecto:** Benchmark LEMMI16s en Arquitecturas Heterogéneas  
> 📄 **Documento:** `02_guia_pipeline_lotus3.md`  
> 📅 **Fecha:** Septiembre 2026  
> 🔬 **Pipeline:** LotuS3 (v3.0.3)  
> 📊 **Dataset Oficial:** `HM_Contaminated_Soil` (3 muestras: `c001`, `c002`, `e001`, 29,783 lecturas pareadas)

---

## 1. 🎯 Arquitectura Interna de LotuS3 y Parches Críticos

A diferencia de Kraken 2 o QIIME 2, **LotuS3 no es un paquete Conda**. Es una suite científica orquestada en **Perl** que encadena múltiples binarios compilados en C/C++ de alto rendimiento:

| Binario / Motor | Lenguaje | Propósito Bioinformático | Rol en el Flujo |
| :--- | :---: | :--- | :--- |
| **`sdm` (Simple Demultiplexer)** | C++ | Demultiplexación, filtrado PHRED y dereplicación | Control de calidad primario |
| **`usearch12` / `vsearch`** | C++ | Clustering al 97% de identidad | Detección de quimeras y conformación de OTUs |
| **`minimap2`** | C | Mapeo ultra-rápido de lecturas contra semillas OTU | Construcción de matriz de conteos |
| **`lambda3` (Local Aligner)** | C++ | Alineamiento local masivo contra SILVA | Asignación de similitud biológica |
| **`LCA` (Lowest Common Ancestor)**| C++ | Resolución jerárquica de consenso taxonómico | Determinación del linaje taxonómico |

### 🛠️ Parches de Optimización Aplicados
1. **Rutas fijas en `lOTUs.cfg`:** Se reemplazaron las rutas que apuntaban a `/app/LotuS3//bin//` (contenedor Docker) por las rutas nativas locales.
2. **Desactivación de compilación R online:** En `l2phyloseq.R` y `LULU.R` se desactivaron descargas dinámicas de paquetes de Bioconductor, evitando atascos de red y compilación.
3. **Banderas `-buildPhylo 0 -lulu 0`:** LEMMI solo requiere el archivo `OTU.biom`, por lo que suprimir la filogenia reduce el tiempo de ejecución de más de 3 minutos a **24 segundos** en la laptop.
4. **Compilación ARM64 de `LCA`:** En el clúster se compiló nativamente el binario C++ con `g++ -O3 -march=armv8-a` para máxima velocidad sin emulación.

---

## 2. 💻 Forma de Corrida en el PC Local (Laptop ASUS TUF x86_64)

### ⚙️ Entorno y Rutas Locales
* **Suite Nativa:** `/home/cristian-solano/proyectos/lotus3`
* **Base de Datos:** `/home/cristian-solano/lemmi16s/benchmark/tmp/lotus303_16s_HM_Contaminated/tmp_HM_Contaminated_Soil/database`
* **Muestra:** `/home/cristian-solano/lemmi16s/benchmark/instances/HM_Contaminated_Soil/HM_Contaminated_Soil-c001`
* **Binario biom-format:** `/home/cristian-solano/proyectos/miniconda3/envs/kraken2_env/bin/biom`

---

### 🔹 Opción A: Ejecución Directa Tradicional (1 Sola Corrida)
Procesa la muestra completa generando el archivo de mapeo requerido por LotuS3:

```bash
# 1. Definir variables y carpetas
LOTUS_DIR="/home/cristian-solano/proyectos/lotus3"
DB_DIR="/home/cristian-solano/lemmi16s/benchmark/tmp/lotus303_16s_HM_Contaminated/tmp_HM_Contaminated_Soil/database"
SAMPLE_DIR="/home/cristian-solano/lemmi16s/benchmark/instances/HM_Contaminated_Soil/HM_Contaminated_Soil-c001"
WORK_DIR="/tmp/run_lotus3_pc_manual"

mkdir -p "$WORK_DIR/reads"
cd "$WORK_DIR"

# 2. Copiar lecturas pareadas a la subcarpeta reads/
cp "$SAMPLE_DIR/queryReads1.fq" reads/.
cp "$SAMPLE_DIR/queryReads2.fq" reads/.

# 3. Crear el archivo de mapeo obligatorio de LotuS3 (miSeqMap.sm.txt)
cat <<EOF > reads/miSeqMap.sm.txt
#SampleID	fastqFile	SequencingRun
Sample1	queryReads1.fq,queryReads2.fq	Run1
EOF

# 4. Ejecutar LotuS3 a 4 hilos (con flags offline -buildPhylo 0 -lulu 0)
${LOTUS_DIR}/lotus3 \
  -derepMin 1:1,1:2,1:3 \
  -i reads/ \
  -m reads/miSeqMap.sm.txt \
  -o reads-output/ \
  -refDB "${DB_DIR}/reference.fasta" \
  -tax4refDB "${DB_DIR}/reference.tsv" \
  -buildPhylo 0 \
  -lulu 0 \
  -t 4

# 5. Convertir matriz OTU.biom a tabla TSV
/home/cristian-solano/proyectos/miniconda3/envs/kraken2_env/bin/biom convert \
  -i reads-output/OTU.biom \
  -o results.txt \
  --to-tsv \
  --header-key taxonomy

# 6. Estandarizar a formato LEMMI16s
python3 /home/cristian-solano/lemmi16s/resources/candidate_containers/lotus_303_lemmi16s/scripts/editResult.py \
  results.txt results.tsv summary_taxonomy.tsv

# 7. Copiar predicción final
cp results.tsv /home/cristian-solano/lemmi16s/benchmark/analysis_outputs/lotus3_lemmi16s.HM_Contaminated_Soil-c001.predictions.tsv
```

---

### 🔹 Opción B: Ejecución Nativa Paralela en 5 Chunks (`run_5chunks_native.sh`)
Ejecuta los 5 fragmentos en paralelo en la laptop:

```bash
/home/cristian-solano/lemmi16s-cluster-backup/scripts_cluster_5nodos/run_5chunks_native.sh lotus3 HM_Contaminated_Soil-c001
```

| Métrica en Laptop | Valor Observado |
| :--- | :--- |
| **Tiempo de Ejecución** | **~22.6 a 24.0 segundos** |
| **Predicción Generada** | `benchmark/analysis_outputs/lotus3_lemmi16s.HM_Contaminated_Soil-c001.5chunks_merged.tsv` |
| **Concordancia Biológica** | **100.00% Idéntico (0 diffs)** frente a Docker oficial |

---

### 🔹 Medición de Telemetría Energética en PC (Intel RAPL)
Ejecución nativa automatizada mediante el script dedicado en `lemmi16s/workflow/scripts/nativo/run_lotus3_energy.sh`, gestionando dereplicación, clustering OTU, biom convert y protocolo unificado de telemetría (60 s estabilización en frío + 300 s / 5 min de reposo previo a 1.0 Hz y registro activo continuo):

```bash
# 1. Permisos RAPL
sudo chmod 444 /sys/class/powercap/intel-rapl:0/energy_uj

# 2. Ejecución de 1 muestra (ejemplo: c001)
bash /home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_lotus3_energy.sh c001

# 3. Ejecución del lote completo (c001, c002, e001)
bash /home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_lotus3_energy.sh all
```

---

## 3. 🍓 Forma de Corrida en el Clúster Raspberry Pi 5 (Slurm / ARM64)

### ⚙️ Entorno y Rutas en el Clúster NFS
* **Directorio Base:** `/shared/users/grupo1/`
* **Suite y Binarios:** `/shared/users/grupo1/build/LCA` y `/shared/users/grupo1/lotus3`
* **Despachador Universal:** `/shared/users/grupo1/lemmi16s/workflow/scripts/run_tool_analysis.sh`
* **Base de Datos:** `/shared/users/grupo1/lemmi16s/benchmark/tmp/lotus303_16s_HM_Contaminated/tmp_HM_Contaminated_Soil/database`

---

### 🔹 Opción A: Corrida en 1 Solo Nodo (Slurm Tradicional)
```bash
sbatch --partition=partition1 --nodelist=rbp5-2 --job-name=lotus_single \
  --wrap="bash /shared/users/grupo1/lemmi16s/workflow/scripts/run_tool_analysis.sh lotus_303_lemmi16s \
  /shared/users/grupo1/lemmi16s/benchmark/tmp/lotus303_16s_HM_Contaminated/tmp_HM_Contaminated_Soil/database \
  /shared/users/grupo1/lemmi16s/benchmark/instances/HM_Contaminated_Soil/HM_Contaminated_Soil-c001/queryReads1.fq \
  /shared/users/grupo1/lemmi16s/benchmark/instances/HM_Contaminated_Soil/HM_Contaminated_Soil-c001/queryReads2.fq \
  /shared/users/grupo1/lemmi16s/benchmark/analysis_outputs/lotus3_lemmi16s.HM_Contaminated_Soil-c001.predictions.tsv 4"
```

---

### 🔹 Opción B: Corrida Distribuida en los 5 Nodos Físicos (Job Array Slurm)
```bash
# Lanzamiento en los 5 nodos físicos
sbatch /shared/users/grupo1/scripts_cluster_5nodos/sbatch_5nodos_pipeline.sh lotus3 HM_Contaminated_Soil-c001
```

#### Mecanismo Interno:
* `split_query_reads_5.py` divide las lecturas pareadas de la muestra en 5 conjuntos independientes.
* Cada uno de los nodos `rbp5-1` al `rbp5-5` ejecuta de forma aislada `run_tool_analysis.sh lotus_303_lemmi16s`.
* Tras finalizar las 5 tareas, `merge_predictions_5.py` une las matrices sumando las abundancias por taxón y normalizando la salida final.

---

## 4. 🔍 Verificación de Salidas y Validación

El archivo generado contiene las asignaciones taxonómicas de los 49 OTUs reconstruidos:

```tsv
#LEMMI16s
Group_ID	Size	Taxonomy
OTU_1	24812	d__Bacteria;p__Actinobacteriota;c__Actinomycetia;o__Streptomycetales;f__Streptomycetaceae;g__Streptomyces;s__na
```

Para confirmar coincidencia absoluta entre la laptop y el clúster:
```bash
diff -u \
  /home/cristian-solano/lemmi16s/benchmark/analysis_outputs/lotus3_lemmi16s.HM_Contaminated_Soil-c001.predictions.tsv \
  /shared/users/grupo1/lemmi16s/benchmark/analysis_outputs/lotus3_lemmi16s.HM_Contaminated_Soil-c001.predictions.tsv
```
*(Debe retornar 0 diferencias).*

> [!TIP]
> **Eficiencia del Flujo:** El parche que desactiva la construcción del árbol filogenético (`-buildPhylo 0`) y la corrección de errores por LULU (`-lulu 0`) ahorra más del 85% del tiempo sin alterar en absoluto la matriz `OTU.biom` requerida por LEMMI16s.
