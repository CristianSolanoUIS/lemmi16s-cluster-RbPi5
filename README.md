# Repositorio Oficial del Clúster ARM64 — Benchmark LEMMI16s (HPC)

> **Proyecto de Grado / Tesis de Ingeniería de Sistemas e Informática**  
> **Universidad Industrial de Santander (UIS)**  
> **Autores:** Cristian Alberto Solano Torres & Zamir Francisco Granados Peñaloza  
> **Fecha:** Septiembre de 2026  
> **Título:** Implementación y evaluación de pipelines bioinformáticos para análisis de amplicones 16S en un clúster de bajo consumo energético basado en Raspberry Pi 5 frente a arquitectura x86_64.

---

## Descripción General

Este repositorio contiene todos los recursos desarrollados para la ejecución, orquestación y medición energética de pipelines metagenómicos de 16S rRNA en un clúster de placas monoplaca (*Single-Board Computers*, SBC) de arquitectura **ARM64 (Raspberry Pi 5)**:

1. **Guías Técnicas y Manuales Operacionales:** Procedimientos detallados de instalación, preparación de bases de datos y ejecución reproducible paso a paso en clúster y en estación x86.
2. **Resultados Cuantitativos Consolidados:** Matrices de tiempo de ejecución, potencia dinámica, consumo energético neto/bruto, métricas verdes (*Reads/Wh*) y validación de fidelidad biológica.
3. **Scripts de Orquestación Slurm Distribuida:** Lanzadores y *workers* adaptados para partición de muestras en 5 nodos de cómputo en paralelo con sincronización automática de telemetría.
4. **Telemetría de Hardware PMIC (1.0 Hz):** Registros CSV oficiales capturados mediante ADC de hardware en los chips Renesas DA9091 bajo el protocolo estandarizado de pre-baseline de 5 minutos (300 s) y estabilización previa de 60 s.
5. **Predicciones Metagenómicas Oficiales (13/13):** Tablas de predicción taxonómica generadas en el clúster en formato LEMMI16s (`.predictions.tsv`) para Kraken 2, LotuS3 y QIIME 2.
6. **Binarios y Herramientas Nativas ARM64:** Compilación de software privativo/C++ para AArch64 (`usearch12`, `LCA`) y recetas Conda exportadas.

---

## Estructura del Repositorio

```text
lemmi16s-cluster-backup/
├── proyecto_Guia/                      # Guías técnicas oficiales de reproducción y operación
│   ├── 01_guia_pipeline_kraken2.md     # Manual completo: Kraken 2 v2.1.3 + Bracken v3.0.1
│   ├── 02_guia_pipeline_lotus3.md      # Manual completo: LotuS3 v3.03 (base UDB pre-indexada)
│   ├── 03_guia_pipeline_qiime2.md      # Manual completo: QIIME 2 Amplicon (clasificador 62k seqs)
│   ├── 04_guia_cluster_slurm_hpc.md    # Arquitectura del clúster, Slurm, NFS, PMIC y red
│   ├── 05_guia_framework_lemmi16s.md   # Portabilidad del framework LEMMI16s a ARM64
│   └── README.md                       # Índice y navegación de guías
├── Resultados/                         # Informes consolidados de métricas y evaluación
│   ├── 01_resultados_eficiencia_energetica.md # Comparativa energética tripartita y Reads/Wh
│   ├── 02_resultados_fidelidad_biologica.md   # Validación biológica (F1, Bray-Curtis, OTUs)
│   └── README.md                       # Índice de resultados experimentales
├── scripts/distribuido/runscripts/     # Orquestación Slurm distribuida multinodo (5 nodos)
│   ├── kraken2/                        # sbatch_multinodo_energy.sh, worker_kraken2_energy.sh, split/merge
│   ├── lotus3/                         # sbatch_multinodo_energy.sh, worker_lotus3_energy.sh, run_all
│   └── qiime2/                         # sbatch_multinodo_energy.sh, worker_qiime2_energy.sh, run_all
├── scripts_cluster_5nodos/             # Scripts auxiliares de particionado y pruebas locales
│   ├── sbatch_5nodos_pipeline.sh       # Lanzador por lotes para 5 nodos
│   ├── split_query_reads_5.py          # Particionador equitativo de FASTQ en 5 fragmentos
│   ├── merge_predictions_5.py          # Reensamblador de predicciones TSV
│   └── run_5chunks_native.sh           # Ejecución nativa secuencial de 5 chunks
├── benchmark/analysis_outputs/         # 13 Predicciones oficiales obtenidas en el clúster
│   ├── kraken2/                        # 5 muestras HOMD_v4_GTDB (c001 a e002)
│   ├── lotus3/                         # 3 muestras HM_Contaminated_Soil (c001, c002, e001)
│   └── qiime2/                         # 5 muestras alfa_v1v2_SILVA (c001 a e002)
├── medicion_energia/                   # Telemetría energética oficial con PMIC (5 min baseline)
│   ├── medir_energia_pmic.py           # Polling de voltaje, corriente y potencia vía PMIC DA9091 (1.0 Hz)
│   ├── reposo_5min/                    # Mediciones de consumo en reposo (stand-by) de los 5 nodos
│   ├── kraken2/                        # Telemetría baseline 5m + corrida activa (5 muestras)
│   ├── lotus3/                         # Telemetría baseline 5m + corrida activa (3 muestras)
│   └── qiime2/                         # Telemetría baseline 5m + corrida activa (5 muestras)
├── mediciones_historicas/              # Registros CSV históricos de fases preliminares
├── logs_slurm/                         # Salidas completas (stdout / stderr) de las corridas Slurm
├── build/                              # Binarios y código fuente adaptado para ARM64
│   ├── LCA/                            # Herramienta Lowest Common Ancestor compilada en AArch64
│   └── usearch12/                      # Binario nativo usearch12 para Linux ARM64
├── local/                              # Bibliotecas de compatibilidad para Squashfuse
├── Pi-Monitor/                         # Servicio web ligero Flask para monitoreo en tiempo real
├── lemmi16s_env_environment.yml        # Entorno Conda para LEMMI16s (Python 3.10, Snakemake)
├── qiime2_arm64_environment.yml        # Entorno Conda para QIIME 2 Amplicon en ARM64
├── Resumenes_MEDICION_Rapl.txt         # Registros de consumo RAPL de la estación x86 (Laptop ASUS TUF)
└── README.md                           # Este documento
```

---

## 1. Especificaciones de Hardware del Clúster ARM64

El clúster fue configurado como un entorno de computación de alto rendimiento (*HPC*) de bajo consumo dedicado:

| Componente | Especificación Técnica | Rol en el Clúster |
| :--- | :--- | :--- |
| **Nodo Maestro** | 1x Raspberry Pi 4 Model B (4 núcleos Cortex-A72 @ 1.8 GHz, 4 GB RAM) | Orquestador Slurm (`slurmctld`), Servidor NFS (`/shared`), pasarela SSH |
| **Nodos de Cómputo** | 5x Raspberry Pi 5 (`rbp5-1` a `rbp5-5`), Broadcom BCM2712 Quad-Core Cortex-A76 @ 2.4 GHz | Nodos de cómputo dedicados (`slurmd`, partición `partition1`) |
| **Núcleos Totales** | 20 núcleos de cómputo dedicados (4 núcleos por SBC) | Cómputo paralelo distribuido |
| **Memoria RAM** | 40 GB RAM agregada (8 GB LPDDR4X-4267 por nodo) | Espacio para asignación de bases de datos y clasificación |
| **Interconexión** | Conmutador Gigabit Ethernet (1000BASE-T, 1 Gbps dúplex) | Red interna de baja latencia |
| **Almacenamiento** | Disco SSD externo NVMe/SATA compartido mediante NFS v4 en `/shared` | Directorio compartido para lecturas, bases de datos y resultados |
| **Telemetría Energética** | Renesas DA9091 PMIC con ADC de 12 canales integrado en placa | Polling a 1.0 Hz con script nativo `medir_energia_pmic.py` |
| **Potencia en Reposo** | ~3.33 W por nodo (~16.65 W en los 5 nodos de cómputo combinados) | Línea base (*stand-by*) para cálculo de energía neta |

---

## 2. Portabilidad Nativa a ARM64 y Entornos Conda

En la infraestructura original de LEMMI16s, la ejecución depende de contenedores Apptainer/Singularity empaquetados para x86_64. En el clúster ARM64, las restricciones de seguridad de Ubuntu 24.04 (bloqueo de *unprivileged user namespaces* en el kernel 6.8+ por AppArmor) y la sobrecarga de emulación QEMU obligaron a adoptar una **estrategia de ejecución nativa**:

1. **Compilación cruzada / nativa:** Compilación de herramientas C++ como `LCA` (Lowest Common Ancestor) y adaptación de `usearch12` para arquitectura AArch64.
2. **Entornos Conda dedicados:**
   ```bash
   # Recrear entorno base LEMMI16s (Snakemake, Python 3.10, biom-format)
   conda env create -f lemmi16s_env_environment.yml

   # Recrear entorno de QIIME 2 Amplicon en ARM64
   conda env create -f qiime2_arm64_environment.yml
   ```
3. **Poda de Memoria en QIIME 2 (Mitigación OOM):** La base SILVA 138 original generaba agotamiento de RAM (>32 GB) en `feature-classifier fit-classifier-naive-bayes`. Se podó a **62,000 secuencias representativas V1–V2** (`referenceClassificator.qza`, 118 MB), permitiendo la clasificación con un consumo contenido de 4.8 GB por muestra.

---

## 3. Resumen de las 13 Predicciones Obtenidas en el Clúster

Todas las predicciones taxonómicas están preservadas en `benchmark/analysis_outputs/` en formato TSV compatible con LEMMI16s:

| Pipeline | Versión de Software | Dataset Evaluado | Muestras Procesadas | Lecturas Totales | Formato Salida | Estado |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Kraken 2 + Bracken** | Kraken 2 v2.1.3 + Bracken v3.0.1 | `HOMD_v4_GTDB` | `c001`, `c002`, `c003`, `e001`, `e002` (5 muestras) | 2,453,431 | `.predictions.tsv` | Completado |
| **LotuS3** | LotuS3 v3.03 (UDB pre-indexada) | `HM_Contaminated_Soil` | `c001`, `c002`, `e001` (3 muestras) | 29,783 | `.predictions.tsv` | Completado |
| **QIIME 2** | QIIME 2 Amplicon ARM64 | `alfa_v1v2_SILVA` | `c001`, `c002`, `c003`, `e001`, `e002` (5 muestras) | 2,690,077 | `.predictions.tsv` | Completado |

---

## 4. Protocolo de Telemetría y Ejecución Distribuida en Slurm

Para garantizar rigor científico y reproducibilidad absoluta, las mediciones energéticas se rigen bajo el **Protocolo Estandarizado de 5 Minutos**:

```
[Inicio Job Slurm] 
       │
       ▼
[Estabilización Térmica: 60 s] (Permite enfriamiento y estabilización de frecuencias del BCM2712)
       │
       ▼
[Pre-Baseline en Reposo: 300 s (5 min)] (Registro continuo a 1.0 Hz del consumo base en idle)
       │
       ▼
[Fase Activa del Pipeline] (Ejecución paralela del pipeline bioinformático con registro PMIC)
       │
       ▼
[Cálculo de Energía Neta]: E_neta = E_activa - (Potencia_baseline_promedio × Tiempo_activo)
```

### Ejecución de Pipelines en el Clúster

Los scripts de orquestación se encuentran en `scripts/distribuido/runscripts/`:

```bash
# 1. Ejecución distribuida de Kraken 2 + Bracken en 5 nodos
sbatch scripts/distribuido/runscripts/kraken2/sbatch_multinodo_energy.sh

# 2. Ejecución distribuida de LotuS3 en 3 nodos
sbatch scripts/distribuido/runscripts/lotus3/sbatch_multinodo_energy.sh

# 3. Ejecución distribuida de QIIME 2 en 5 nodos
sbatch scripts/distribuido/runscripts/qiime2/sbatch_multinodo_energy.sh
```

---

## 5. Resultados Clave: Eficiencia Energética y Fidelidad Biológica

### Rendimiento y Ganancia Verde (Laptop x86 vs. Clúster ARM64)

| Pipeline | Métrica | Laptop ASUS TUF (x86_64, RAPL) | Clúster 5x RPi 5 (ARM64, PMIC) | Impacto / Factor de Ahorro |
| :--- | :--- | :--- | :--- | :--- |
| **Kraken 2** | Tiempo activo (s) | **22.01 s** | 51.04 s | Laptop 2.32x más rápida |
| | Energía activa neta (Wh) | 0.2447 Wh | **0.0642 Wh** | **Clúster 3.81x más eficiente (73.76% ahorro neto)** |
| | Eficiencia (*Reads/Wh*) | 10,026,281 | **38,215,436** | **+281.16% más lecturas por Wh en clúster** |
| **LotuS3** | Tiempo activo (s) | 66.03 s | **32.55 s** | **Clúster 2.03x más rápido** |
| | Energía activa neta (Wh) | 0.3340 Wh | **0.0493 Wh** | **Clúster 6.78x más eficiente (85.24% ahorro neto)** |
| | Eficiencia (*Reads/Wh*) | 89,171 | **604,118** | **+577.48% más lecturas por Wh en clúster** |
| **QIIME 2** | Tiempo activo (s) | 4,323.70 s | **1,678.90 s** | **Clúster 2.58x más rápido** |
| | Energía activa neta (Wh) | 25.100 Wh | **5.492 Wh** | **Clúster 4.57x más eficiente (78.12% ahorro neto)** |
| | Eficiencia (*Reads/Wh*) | 107,174 | **489,817** | **+357.03% más lecturas por Wh en clúster** |

### Fidelidad Biológica (Concordancia 100%)

- **F1-Score y Precisión:** Idénticos entre arquitecturas hasta el cuarto decimal en los tres pipelines.
- **Divergencia L2 y Bray-Curtis:** 0.000000 en Kraken 2 y LotuS3; variaciones despreciables (<0.02%) en QIIME 2 derivadas del algoritmo heurístico de DADA2.
- **Validación `diff -u`:** Concordancia absoluta en perfiles taxonómicos a nivel de género y especie.

---

## 6. Enlaces a Guías y Reportes Completos

- [Índice de Guías Técnicas de Operación](proyecto_Guia/README.md)
  - [Guía 01: Pipeline Kraken 2 + Bracken](proyecto_Guia/01_guia_pipeline_kraken2.md)
  - [Guía 02: Pipeline LotuS3](proyecto_Guia/02_guia_pipeline_lotus3.md)
  - [Guía 03: Pipeline QIIME 2 Amplicon](proyecto_Guia/03_guia_pipeline_qiime2.md)
  - [Guía 04: Clúster Slurm HPC, Red y Telemetría PMIC](proyecto_Guia/04_guia_cluster_slurm_hpc.md)
  - [Guía 05: Portabilidad del Framework LEMMI16s](proyecto_Guia/05_guia_framework_lemmi16s.md)
- [Índice de Resultados Cuantitativos](Resultados/README.md)
  - [Informe 01: Evaluación de Rendimiento y Eficiencia Energética (Reads/Wh)](Resultados/01_resultados_eficiencia_energetica.md)
  - [Informe 02: Evaluación de Fidelidad Biológica y Concordancia Taxonómica](Resultados/02_resultados_fidelidad_biologica.md)
