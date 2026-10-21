# 📚 GUÍAS DE OPERACIÓN, PIPELINES Y REPRODUCIBILIDAD: BENCHMARK LEMMI16s
## 🍓 Clúster Raspberry Pi 5 (ARM64) & 💻 Estación ASUS TUF (x86_64)

> **Proyecto de Grado / Tesis de Ingeniería de Sistemas y Computación**  
> 👥 **Autores:** Cristian Solano & Zamir Peñaloza  
> 📅 **Fecha:** Septiembre de 2026 (actualizado en octubre con las corridas finales)  

---

## 📌 Estructura y Navegación de las Guías

Este directorio reúne los manuales técnicos, operacionales y de reproducibilidad del benchmark LEMMI16s. La documentación ha sido reestructurada para eliminar redundancias y separar con absoluta claridad la **forma de corrida en PC** frente a la **forma de corrida en el clúster HPC**:

| Guía / Manual | Enfoque Principal | Contenido Destacado |
| :--- | :--- | :--- |
| **[`01_guia_pipeline_kraken2.md`](01_guia_pipeline_kraken2.md)** | **Pipeline Kraken 2 + Bracken** | • Fundamento de $k$-meros y re-estimación Bayesiana<br>• **Corrida en PC:** `kraken2_env`, 1 muestra vs 5 chunks, telemetría RAPL<br>• **Corrida en Clúster:** Slurm single vs `sbatch_5nodos_pipeline.sh`<br>• Dataset `HOMD_v4_GTDB-c001` y validación |
| **[`02_guia_pipeline_lotus3.md`](02_guia_pipeline_lotus3.md)** | **Pipeline LotuS3** | • Suite Perl + motores C++ (`sdm`, `vsearch`, `minimap2`, `lambda3`, `LCA`)<br>• Parches críticos (`lOTUs.cfg`, `-buildPhylo 0 -lulu 0`, compilación LCA ARM64)<br>• **Corrida en PC:** Generación `miSeqMap.sm.txt`, conversión BIOM<br>• **Corrida en Clúster:** Despacho Slurm tradicional vs 5 nodos |
| **[`03_guia_pipeline_qiime2.md`](03_guia_pipeline_qiime2.md)** | **Pipeline QIIME 2** | • Las 5 fases científicas (import $\to$ quality $\to$ Deblur $\to$ Naive Bayes $\to$ collapse)<br>• Parches ARM64 (`sse2neon.h`, `-fsigned-char`, `scikit-learn 0.24.1`)<br>• **Corrida en PC:** Corrida completa 513k lecturas, aceleración 5 chunks (4.17x)<br>• **Corrida en Clúster:** Slurm single vs array de 5 nodos |
| **[`04_guia_cluster_slurm_hpc.md`](04_guia_cluster_slurm_hpc.md)** | **Clúster Raspberry Pi 5 & Slurm** | • Topología de hardware (Master `rbpi4-master`, 10x RPi 5, NFS `/shared`)<br>• Despachador universal `run_tool_analysis.sh` (ejecución sin Singularity)<br>• Arquitectura Slurm Job Array 5-chunks (`split`, `array`, `merge`)<br>• Telemetría energética vía PMIC Renesas DA9091 y `pimonitor.service` |
| **[`05_guia_framework_lemmi16s.md`](05_guia_framework_lemmi16s.md)** | **Framework LEMMI16s & Evaluación** | • Estructura del repositorio `lemmi16s` y datasets de amplicón<br>• Especificación formal de la tabla unificada `#LEMMI16s`<br>• Orquestación de Snakemake y regla de evaluación `eval.smk`<br>• Fórmulas de F1-Score, Precisión, Recall y Distancia L2 |

---

## 🚀 Scripts de las corridas finales

| Pipeline | PC x86 (RAPL) | Clúster, 5 nodos (PMIC) | Clúster, 1 nodo |
| :--- | :--- | :--- | :--- |
| **Kraken 2** | `scripts/medicion/x86_nativo/run_kraken2_energy.sh` · `scripts/medicion/x86_wsl2/run_kraken2_x86_lote.ps1` | `scripts/cluster/multinodo/kraken2/sbatch_multinodo_energy.sh` | `scripts/cluster/mononodo/sbatch_kraken2_mononodo.sh` |
| **LotuS3 (PacBio)** | `scripts/medicion/x86_wsl2/run_lotus3_pacbio_x86_lote.ps1` | `scripts/cluster/lotus3_pacbio/lanzar_lotus3_pacbio_5nodos.sh` | `scripts/cluster/lotus3_pacbio/sbatch_lotus3_pacbio_mononodo.sh` |
| **QIIME 2** | `scripts/medicion/x86_nativo/run_qiime2_energy.sh` · `scripts/medicion/x86_wsl2/run_qiime2_x86_lote.ps1` | `scripts/cluster/multinodo/qiime2/sbatch_multinodo_energy.sh` | `scripts/cluster/mononodo/sbatch_qiime2_mononodo.sh` |

En el clúster cada muestra corre completa en un nodo. Los resultados de estas corridas están en [`resultados/`](../../resultados/README.md).

---

## 📂 Ubicación en el repositorio

Estas guías están en `docs/guias/`. Los resultados, los datos de energía y los scripts están en las carpetas `resultados/`, `datos_energia/` y `scripts/` de la raíz del repositorio (ver el [README principal](../../README.md)).

---

## 👁️ Visualización en Antigravity IDE

> [!TIP]
> Para visualizar las tablas desplegadas, diagramas Mermaid y alertas formateadas con diseño enriquecido:
> * Presiona **`Ctrl + Shift + V`** para vista previa a pantalla completa.
> * Presiona **`Ctrl + K` y luego `V`** para vista previa en panel lateral dividido.
