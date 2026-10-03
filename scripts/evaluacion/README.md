# Suite de Evaluación Biológica LEMMI16s (eval.smk)

Este directorio contiene los scripts para la evaluación oficial de las predicciones metagenómicas obtenidas en el clúster ARM64 frente al Ground Truth de LEMMI16s.

---

## 📁 Archivos en este Directorio

* **`ejecutar_evaluacion_lemmi.sh`**: Script orquestador principal. Ejecuta la regla `eval.smk` de Snakemake de manera aislada dentro del repositorio de respaldo, generando las métricas consolidadas en `benchmark/final_results/` y las evaluaciones por rango en `benchmark/evaluations/`.
* **`preparar_predicciones_eval.py`**: Estandariza la nomenclatura de las predicciones del clúster (`multinodo` / `mononodo`) a los nombres de herramienta reconocidos por el benchmark LEMMI (`kraken2_multi_cluster`, `qiime2_multi_cluster`, `lotus3_pacbio_multi_cluster`, etc.).
* **`generar_metricas_ejecucion.py`**: Genera los archivos de metadatos de tiempo y memoria (`.runtime_analysis.txt`, `.memory_analysis.txt`) requeridos formalmente por la regla de evaluación de LEMMI.

---

## 🚀 Uso Rápido

Para ejecutar la evaluación de todas las instancias del clúster:

```bash
cd /home/cristian-solano/lemmi16s-cluster-backup/scripts/evaluacion
./ejecutar_evaluacion_lemmi.sh all
```

O evaluar una instancia específica:

```bash
./ejecutar_evaluacion_lemmi.sh alfa_v1v2_SILVA       # QIIME 2
./ejecutar_evaluacion_lemmi.sh HOMD_v4_GTDB          # Kraken 2
./ejecutar_evaluacion_lemmi.sh HM_Contaminated_Soil   # LotuS3 PacBio
```

Los resultados consolidados se generan en:
* `../../benchmark/final_results/` (`.f1.tsv`, `.precision.tsv`, `.recall.tsv`, `.auprc.tsv`, `.l2.tsv`, `.json`)
* `../../benchmark/evaluations/` (tablas por muestra y nivel taxonómico)
