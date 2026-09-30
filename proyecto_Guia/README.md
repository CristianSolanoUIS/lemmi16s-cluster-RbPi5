# 📚 GUÍAS DE OPERACIÓN, PIPELINES Y REPRODUCIBILIDAD: BENCHMARK LEMMI16s
## 🍓 Clúster Raspberry Pi 5 (ARM64) & 💻 Estación ASUS TUF (x86_64)

> **Proyecto de Grado / Tesis de Ingeniería de Sistemas y Computación**  
> 👥 **Autores:** Cristian Solano & Zamir Peñaloza  
> 📅 **Fecha:** Septiembre de 2026  
> 📁 **Ubicación:** `/home/cristian-solano/Descargas/proyecto_Guia/`

---

## 📌 Estructura y Navegación de las Guías

Este directorio reúne los manuales técnicos, operacionales y de reproducibilidad del benchmark LEMMI16s. La documentación ha sido reestructurada para eliminar redundancias y separar con absoluta claridad la **forma de corrida en PC** frente a la **forma de corrida en el clúster HPC**:

| Guía / Manual | Enfoque Principal | Contenido Destacado |
| :--- | :--- | :--- |
| **[`01_guia_pipeline_kraken2.md`](file:///home/cristian-solano/Descargas/proyecto_Guia/01_guia_pipeline_kraken2.md)** | **Pipeline Kraken 2 + Bracken** | • Fundamento de $k$-meros y re-estimación Bayesiana<br>• **Corrida en PC:** `kraken2_env`, 1 muestra vs 5 chunks, telemetría RAPL<br>• **Corrida en Clúster:** Slurm single vs `sbatch_5nodos_pipeline.sh`<br>• Dataset `HOMD_v4_GTDB-c001` y validación |
| **[`02_guia_pipeline_lotus3.md`](file:///home/cristian-solano/Descargas/proyecto_Guia/02_guia_pipeline_lotus3.md)** | **Pipeline LotuS3** | • Suite Perl + motores C++ (`sdm`, `vsearch`, `minimap2`, `lambda3`, `LCA`)<br>• Parches críticos (`lOTUs.cfg`, `-buildPhylo 0 -lulu 0`, compilación LCA ARM64)<br>• **Corrida en PC:** Generación `miSeqMap.sm.txt`, conversión BIOM<br>• **Corrida en Clúster:** Despacho Slurm tradicional vs 5 nodos |
| **[`03_guia_pipeline_qiime2.md`](file:///home/cristian-solano/Descargas/proyecto_Guia/03_guia_pipeline_qiime2.md)** | **Pipeline QIIME 2** | • Las 5 fases científicas (import $\to$ quality $\to$ Deblur $\to$ Naive Bayes $\to$ collapse)<br>• Parches ARM64 (`sse2neon.h`, `-fsigned-char`, `scikit-learn 0.24.1`)<br>• **Corrida en PC:** Corrida completa 513k lecturas, aceleración 5 chunks (4.17x)<br>• **Corrida en Clúster:** Slurm single vs array de 5 nodos |
| **[`04_guia_cluster_slurm_hpc.md`](file:///home/cristian-solano/Descargas/proyecto_Guia/04_guia_cluster_slurm_hpc.md)** | **Clúster Raspberry Pi 5 & Slurm** | • Topología de hardware (Master `rbpi4-master`, 10x RPi 5, NFS `/shared`)<br>• Despachador universal `run_tool_analysis.sh` (ejecución sin Singularity)<br>• Arquitectura Slurm Job Array 5-chunks (`split`, `array`, `merge`)<br>• Telemetría energética vía PMIC Renesas DA9091 y `pimonitor.service` |
| **[`05_guia_framework_lemmi16s.md`](file:///home/cristian-solano/Descargas/proyecto_Guia/05_guia_framework_lemmi16s.md)** | **Framework LEMMI16s & Evaluación** | • Estructura del repositorio `lemmi16s` y datasets de amplicón<br>• Especificación formal de la tabla unificada `#LEMMI16s`<br>• Orquestación de Snakemake y regla de evaluación `eval.smk`<br>• Fórmulas de F1-Score, Precisión, Recall y Distancia L2 |

---

## 🚀 Resumen Rápido: Comandos de Ejecución por Entorno

| Pipeline | Metodología Principal | Modo PC Local (Intel RAPL) | Modo Clúster Slurm (Telemetría PMIC) |
| :--- | :--- | :--- | :--- |
| **Kraken 2** | $k$-meros exactos + Bracken (-t 10) | `bash ~/lemmi16s/workflow/scripts/nativo/run_kraken2_energy.sh [c001\|all]` | `bash /shared/.../scripts/distribuido/runscripts/kraken2/sbatch_multinodo_energy.sh kraken2 [c001]` |
| **LotuS3** | Clustering OTU + SDM derep | `bash ~/lemmi16s/workflow/scripts/nativo/run_lotus3_energy.sh [c001\|all]` | `bash /shared/.../scripts/distribuido/runscripts/lotus3/sbatch_multinodo_energy.sh [c001 c002 e001]` |
| **QIIME 2** | Deblur denoising + Naive Bayes L7 | `bash ~/lemmi16s/workflow/scripts/nativo/run_qiime2_energy.sh [c001\|all]` | `bash /shared/.../scripts/distribuido/runscripts/qiime2/sbatch_multinodo_energy.sh [c001 c002 c003]` |

---

## 📂 Carpetas del Proyecto y Ubicación de Archivos

```
Descargas/
├── Resultados/                         # EXCLUSIVO: Resultados cuantitativos del proyecto
│   ├── 01_resultados_eficiencia_energetica.md # Potencia, Wh, Reads/Wh, comparativa x86 vs ARM
│   ├── 02_resultados_fidelidad_biologica.md   # Ground Truth, F1-scores, 0 diffs en 13 corridas
│   ├── README.md                              # Resumen ejecutivo de resultados
│   └── *.txt                                  # Reportes crudos de telemetría y benchmark
│
└── proyecto_Guia/                      # EXCLUSIVO: Guías operacionales y reproducibilidad
    ├── 01_guia_pipeline_kraken2.md     # Pipeline Kraken 2 (PC y Clúster)
    ├── 02_guia_pipeline_lotus3.md      # Pipeline LotuS3 (PC y Clúster)
    ├── 03_guia_pipeline_qiime2.md      # Pipeline QIIME 2 (PC y Clúster)
    ├── 04_guia_cluster_slurm_hpc.md    # Clúster RPi 5, Slurm y PMIC
    ├── 05_guia_framework_lemmi16s.md   # Framework LEMMI16s y evaluación
    └── README.md                       # Índice y navegación
```

---

## 👁️ Visualización en Antigravity IDE

> [!TIP]
> Para visualizar las tablas desplegadas, diagramas Mermaid y alertas formateadas con diseño enriquecido:
> * Presiona **`Ctrl + Shift + V`** para vista previa a pantalla completa.
> * Presiona **`Ctrl + K` y luego `V`** para vista previa en panel lateral dividido.
