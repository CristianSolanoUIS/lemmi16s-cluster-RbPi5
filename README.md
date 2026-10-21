# Repositorio Oficial del Clúster ARM64 — Benchmark LEMMI16s (HPC)

> **Proyecto de Grado / Tesis de Ingeniería de Sistemas e Informática**  
> **Universidad Industrial de Santander (UIS)**  
> **Autores:** Cristian Alberto Solano Torres & Zamir Francisco Granados Peñaloza  
> **Fecha:** Septiembre / Octubre de 2026  
> **Título:** Implementación y análisis del desempeño de un pipeline para el estudio de amplicones 16S en un clúster energéticamente eficiente basado en Raspberry Pi 5.

---

## Descripción General

Este repositorio contiene todos los recursos desarrollados para la ejecución, orquestación, medición energética y evaluación biológica de pipelines metagenómicos de 16S rRNA en un clúster de placas monoplaca (*Single-Board Computers*, SBC) de arquitectura **ARM64 (Raspberry Pi 5)**:

1. **Guías Técnicas y Manuales Operacionales:** Procedimientos detallados de instalación, preparación de bases de datos y ejecución reproducible paso a paso en clúster y en estación x86.
2. **Resultados Cuantitativos Consolidados:** Matrices de tiempo de ejecución, potencia dinámica, consumo energético neto/bruto, métricas verdes (*Reads/Wh*) y validación de fidelidad biológica.
3. **Scripts de Orquestación Slurm (Multinodo y Mononodo):** Lanzadores y *workers* adaptados para partición de muestras en 5 nodos de cómputo en paralelo con sincronización automática de telemetría y soporte completo para lecturas largas PacBio.
4. **Suite de Evaluación Biológica LEMMI16s:** Scripts automatizados para ejecutar la regla `eval.smk` de Snakemake y generar métricas oficiales (`f1`, `auprc`, `precision`, `recall`, `l2`).
5. **Telemetría de Hardware PMIC (1.0 Hz):** Registros CSV oficiales capturados mediante ADC de hardware en los chips Renesas DA9091 bajo el protocolo estandarizado de pre-baseline de 5 minutos (300 s) y estabilización previa de 60 s.
6. **Predicciones Metagenómicas Oficiales (30/30):** Tablas de predicción taxonómica generadas en el clúster en formato LEMMI16s (`.predictions.tsv`) para Kraken 2, LotuS3 PacBio y QIIME 2 (5 muestras mononodo y 5 multinodo por pipeline).
7. **Binarios y Herramientas Nativas ARM64:** Compilación de software privativo/C++ para AArch64 (`usearch12`, `LCA`) y recetas Conda exportadas en `environments/`.

---

## Estructura del Repositorio

```text
lemmi16s-cluster-backup/
├── proyecto_Guia/                      # Guías técnicas oficiales de reproducción y operación
│   ├── 01_guia_pipeline_kraken2.md     # Manual completo: Kraken 2 v2.1.3 + Bracken v3.0.1
│   ├── 02_guia_pipeline_lotus3.md      # Manual completo: LotuS3 v3.03 (base UDB pre-indexada y PacBio)
│   ├── 03_guia_pipeline_qiime2.md      # Manual completo: QIIME 2 Amplicon (clasificador 62k seqs)
│   ├── 04_guia_cluster_slurm_hpc.md    # Arquitectura del clúster, Slurm, NFS, PMIC y red
│   ├── 05_guia_framework_lemmi16s.md   # Portabilidad del framework LEMMI16s a ARM64
│   └── README.md                       # Índice y navegación de guías
├── Resultados/                         # Informes consolidados de métricas y evaluación
│   ├── 01_resultados_eficiencia_energetica.md # Comparativa energética tripartita y Reads/Wh
│   ├── 02_resultados_fidelidad_biologica.md   # Validación biológica (F1, Bray-Curtis, OTUs)
│   ├── comparacion_biologica_pc_vs_cluster.txt # Verificación bit por bit PC vs Clúster
│   └── README.md                       # Índice de resultados experimentales
├── scripts/                            # Scripts de ejecución y orquestación
│   ├── distribuido/runscripts/         # Orquestación Slurm distribuida multinodo (5 nodos)
│   ├── mononodo/                       # Scripts de ejecución mononodo en el clúster
│   ├── lotus3_pacbio/                  # Scripts para corridas PacBio (lecturas largas)
│   └── evaluacion/                     # Suite de evaluación biológica LEMMI16s (eval.smk)
│       ├── ejecutar_evaluacion_lemmi.sh # Lanzador de evaluación Snakemake aislado
│       ├── preparar_predicciones_eval.py# Estandarización de nombres para LEMMI
│       ├── generar_metricas_ejecucion.py# Generador de metadatos de tiempo/RAM
│       └── README.md                   # Documentación de la suite de evaluación
├── environments/                       # Especificaciones de entornos Conda para ARM64
│   ├── lemmi16s_env_environment.yml    # Entorno base LEMMI16s (Python 3.10, Snakemake)
│   ├── qiime2_arm64_environment.yml    # Entorno QIIME 2 Amplicon en ARM64
│   └── README.md                       # Guía de recreación de entornos
├── benchmark/                          # Resultados y evaluaciones del benchmark LEMMI16s
│   ├── analysis_outputs/               # 30 Predicciones oficiales (.predictions.tsv y metadatos)
│   ├── final_results/                  # Métricas consolidadas (.f1.tsv, .auprc.tsv, .json)
│   └── evaluations/                    # Tablas de precisión/recall por taxón y muestra
├── taxonomia_detallada/                 # Asignaciones taxonómicas completas por dataset
│   ├── kraken2_HOMD_v4_GTDB/           # Reportes de clasificación y Bracken
│   ├── lotus3_HM_Contaminated_Soil_PacBio/ # Matrices OTU, BIOM y clasificaciones
│   └── qiime2_alfa_v1v2_SILVA/         # Tablas QZA exportadas y taxonomía
├── medicion_energia/                   # Telemetría energética oficial con PMIC (5 min baseline)
│   ├── medir_energia_pmic.py           # Polling de voltaje, corriente y potencia vía PMIC DA9091 (1.0 Hz)
│   ├── reposo_5min/                    # Mediciones de consumo en reposo (stand-by) de los 5 nodos
│   ├── kraken2/                        # Telemetría baseline 5m + corrida activa
│   ├── lotus3_pacbio/                  # Telemetría baseline 5m + corrida activa PacBio
│   ├── qiime2/                         # Telemetría baseline 5m + corrida activa
│   └── Resumenes_MEDICION_Rapl.txt     # Registros de consumo RAPL de la estación x86
├── logs_slurm/                         # Salidas completas (stdout / stderr) de los jobs de Slurm
├── build/                              # Binarios y código fuente adaptado para ARM64
│   ├── LCA/                            # Herramienta Lowest Common Ancestor compilada en AArch64
│   └── usearch12/                      # Binario nativo usearch12 para Linux ARM64
├── libro/                              # Libro aprobado (PDF y LaTeX), datos de energía x86/HPL y scripts de análisis
└── README.md                           # Este documento
```

---

## 1. Especificaciones de Hardware del Clúster ARM64

El clúster fue configurado como un entorno de computación de alto rendimiento (*HPC*) de bajo consumo dedicado:

| Componente | Especificación Técnica | Rol en el Clúster |
| :--- | :--- | :--- |
| **Nodo Maestro** | 1x Raspberry Pi 4 Model B (4 núcleos Cortex-A72 @ 1.8 GHz, 8 GB RAM) | Orquestador Slurm (`slurmctld`), Servidor NFS (`/shared`), pasarela SSH |
| **Nodos de Cómputo** | 5x Raspberry Pi 5 (`rbp5-1` a `rbp5-5`, de los 10 nodos del clúster), Broadcom BCM2712 Quad-Core Cortex-A76 @ 2.4 GHz | Nodos de cómputo dedicados (`slurmd`, partición `partition1`) |
| **Núcleos Totales** | 20 núcleos de cómputo dedicados (4 núcleos por SBC) | Cómputo paralelo distribuido |
| **Memoria RAM** | 80 GB RAM agregada (16 GB LPDDR4X-4267 por nodo) | Espacio para asignación de bases de datos y clasificación |
| **Interconexión** | Conmutador Gigabit Ethernet (1000BASE-T, 1 Gbps dúplex) | Red interna de baja latencia |
| **Almacenamiento** | microSD de 64 GB por nodo (sistema operativo) y directorio compartido mediante NFS v4 en `/shared` | Lecturas, bases de datos y resultados compartidos |
| **Telemetría Energética** | Renesas DA9091 PMIC con ADC de 12 canales integrado en placa | Polling a 1.0 Hz con script nativo `medir_energia_pmic.py` |
| **Potencia en Reposo** | 2.38 W por nodo (11.90 W en los 5 nodos de cómputo combinados) | Línea base (*stand-by*) para cálculo de energía neta |

---

## 2. Portabilidad Nativa a ARM64 y Entornos Conda

En la infraestructura original de LEMMI16s, la ejecución depende de contenedores Apptainer/Singularity empaquetados para x86_64. En el clúster ARM64, las restricciones de seguridad de Ubuntu 24.04 (bloqueo de *unprivileged user namespaces* en el kernel 6.8+ por AppArmor) y la sobrecarga de emulación QEMU obligaron a adoptar una **estrategia de ejecución nativa**:

1. **Compilación cruzada / nativa:** Compilación de herramientas C++ como `LCA` (Lowest Common Ancestor) y adaptación de `usearch12` para arquitectura AArch64.
2. **Entornos Conda dedicados (almacenados en `environments/`):**
   ```bash
   # Recrear entorno base LEMMI16s (Snakemake, Python 3.10, biom-format)
   conda env create -f environments/lemmi16s_env_environment.yml

   # Recrear entorno de QIIME 2 Amplicon en ARM64
   conda env create -f environments/qiime2_arm64_environment.yml
   ```
3. **Poda de Memoria en QIIME 2 (Mitigación OOM):** La base SILVA 138 original generaba agotamiento de RAM (>32 GB) en `feature-classifier fit-classifier-naive-bayes`. Se podó a **62,000 secuencias representativas V1–V2** (`referenceClassificator.qza`, 118 MB), permitiendo la clasificación con un consumo contenido de 4.8 GB por muestra.

---

## 3. Resumen de las 30 Predicciones Obtenidas en el Clúster

Todas las predicciones taxonómicas están preservadas en `benchmark/analysis_outputs/` en formato TSV compatible con LEMMI16s:

| Pipeline | Versión de Software | Dataset Evaluado | Muestras Procesadas | Modalidades | Formato Salida | Estado |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Kraken 2 + Bracken** | Kraken 2 v2.1.3 + Bracken v3.0.1 | `HOMD_v4_GTDB` | `c001` a `e002` (5 muestras) | Mononodo (5) + Multinodo (5) | `.predictions.tsv` | Completado (10) |
| **LotuS3 PacBio** | LotuS3 v3.03 (Long-Read PacBio) | `HM_Contaminated_Soil` | `c001` a `e002` (5 muestras) | Mononodo (5) + Multinodo (5) | `.predictions.tsv` | Completado (10) |
| **QIIME 2** | QIIME 2 Amplicon ARM64 | `alfa_v1v2_SILVA` | `c001` a `e002` (5 muestras) | Mononodo (5) + Multinodo (5) | `.predictions.tsv` | Completado (10) |

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

---

## 5. Resultados Clave: Eficiencia Energética y Fidelidad Biológica

### Rendimiento y eficiencia energética (x86 nativo vs. clúster de 5 nodos)

Valores del libro aprobado (Tabla 3.4). Energía total integrada por la regla del trapecio; energía neta = total − reposo. Lecturas/Wh con energía total.

| Pipeline | Métrica | x86 nativo (i5-10300H, RAPL) | Clúster 5x RPi 5 (PMIC) | Factor |
| :--- | :--- | :--- | :--- | :--- |
| **Kraken 2 + Bracken** | Tiempo | **22.01 s** | 51.04 s | x86 2.32x más rápido (espera por NFS) |
| | Energía neta | 0.1518 Wh | **0.0398 Wh** | **3.81x menos en el clúster** |
| | Lecturas/Wh (total) | 11.2 M | **12.1 M** | 1.08x |
| **LotuS3 (PacBio HiFi)** | Tiempo | 31.65 min | 32.87 min | 0.96x (similar) |
| | Energía neta | 15.65 Wh | **7.33 Wh** | **2.14x menos en el clúster** |
| | Lecturas/Wh (total) | 1,494 | **2,129** | 1.42x |
| **QIIME 2** | Tiempo | 72.06 min | **27.98 min** | **Clúster 2.58x más rápido** |
| | Energía neta | 12.70 Wh | **2.78 Wh** | **4.57x menos en el clúster** |
| | Lecturas/Wh (total) | 105,518 | **324,561** | 3.08x |

El PMIC mide la placa completa y RAPL solo el procesador, por lo que la comparación favorece al x86. Los datos crudos de las tres plataformas, la prueba HPL y los scripts de cálculo están en [`libro/`](libro/README.md).

### Fidelidad Biológica y Concordancia Oficial LEMMI16s

* **QIIME 2 (`alfa_v1v2_SILVA`):** Concordancia **100% idéntica bit-por-bit** entre Clúster (Multi/Mono) y PC.
  * F1 Familia: **0.8286** | F1 Género: **0.7083** | F1 Especie: **0.4500**
* **Kraken 2 (`HOMD_v4_GTDB`):** Concordancia **100% idéntica bit-por-bit** entre Clúster (Multi/Mono) y PC.
  * F1 Familia: **0.5223** | F1 Género: **0.3545** | F1 Especie: **0.0000**
* **LotuS3 PacBio (`HM_Contaminated_Soil`):** Consistencia clúster multi vs mononodo **>99.9%** (Pearson $r \ge 0.9993$).
  * F1 Familia: **0.8667** | F1 Género: **0.8762** (igual en las tres plataformas)

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
  - [Reporte Comparativo PC vs Clúster](Resultados/comparacion_biologica_pc_vs_cluster.txt)
- [Libro aprobado, datos de energía y análisis](libro/README.md)
  - [Libro (PDF)](libro/LibroAmpliconesRBPI5.pdf)
  - [Diapositivas de la sustentación (PDF)](libro/Sustentacion_RBPi5.pdf)
- [Suite de Evaluación Biológica](scripts/evaluacion/README.md)
- [Entornos Conda ARM64](environments/README.md)
