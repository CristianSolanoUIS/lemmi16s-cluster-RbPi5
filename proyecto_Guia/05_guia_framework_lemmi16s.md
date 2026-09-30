# 🧬 GUÍA 5: FRAMEWORK LEMMI16s, DATASETS Y EVALUACIÓN BIOLÓGICA
## 🔬 Metodología de Evaluación Ciega y Reproducible en Metagenómica 16S rRNA

> **Proyecto:** Benchmark LEMMI16s en Arquitecturas Heterogéneas  
> 📄 **Documento:** `05_guia_framework_lemmi16s.md`  
> 📅 **Fecha:** Septiembre 2026  
> 🧬 **Framework:** LEMMI16s (Snakemake + Vue.js)  
> 🎯 **Objetivo:** Evaluación ciega contra Ground Truth y consistencia taxonómica

---

## 1. 🎯 ¿Qué es LEMMI16s?

**LEMMI16s** es un estándar internacional de benchmarking diseñado para someter de forma ciega y estandarizada múltiples clasificadores taxonómicos de 16S rRNA a conjuntos de datos de prueba rigurosos. Permite evaluar:

| Dimensión de Rendimiento | Métrica Matemática | Importancia Científica |
| :--- | :--- | :--- |
| **Sensibilidad y Precisión** | F1-Score, AUPRC | Capacidad de clasificar correctamente desde Dominio hasta Especie |
| **Control de Falsos Positivos** | Tasa FP por rango | Evitar clasificaciones espurias en taxones ausentes |
| **Fidelidad Cuantitativa** | Distancia Euclidiana L2 | Reconstrucción fiel de las abundancias relativas |
| **Eficiencia Computacional** | Tiempo (s), RAM (MB), Reads/Wh | Productividad bioinformática por unidad de energía consumida |

---

## 2. 📂 Datasets Oficiales Evaluados en el Proyecto

El benchmark contiene muestras sintéticas y reales curadas dentro de `benchmark/instances/`:

| Dataset | Región 16S | Base de Datos | Muestra Oficial | Lecturas Pareadas | Entorno Biológico |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **`HOMD_v4_GTDB`** | V4 | GTDB | `HOMD_v4_GTDB-c001` | ~500,000 | Microbioma oral humano |
| **`HM_Contaminated_Soil`** | V4 | SILVA | `HM_Contaminated_Soil-c001` | ~100,000 | Suelo con metales pesados |
| **`alfa_v1v2_SILVA`** | V1-V2 | SILVA | `alfa_v1v2_SILVA-c001` | 513,102 | Comunidad sintética compleja |

Cada carpeta de muestra contiene:
* `queryReads1.fq`: Lecturas directas (*Forward* R1).
* `queryReads2.fq`: Lecturas inversas (*Reverse* R2).
* `queryTaxo.tsv`: La verdad de terreno (*Ground Truth*), que indica los linajes biológicos reales y sus abundancias absolutas exactas.

---

## 3. 📑 El Formato Estándar de Predicción (`#LEMMI16s`)

Para garantizar comparabilidad entre herramientas heterogéneas, cada pipeline convierte sus reportes nativos al formato tabular `#LEMMI16s` mediante el script `editResult.py`:

```tsv
#LEMMI16s
Group_ID	Size	Taxonomy
group_0	499995	d__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Pseudomonadales;f__Pseudomonadaceae;g__Pseudomonas;s__na
group_1	5	d__Bacteria;p__Firmicutes;c__Bacilli;o__Bacillales;f__Bacillaceae;g__Bacillus;s__Bacillus_subtilis
```

### Especificación de Columnas:
1. **`#LEMMI16s`**: Cabecera identificadora obligatoria en la primera línea.
2. **`Group_ID`**: Identificador único del grupo predicho (ej. `group_0`, `OTU_1`, o taxón representativo).
3. **`Size`**: Conteo absoluto de lecturas asignadas a este taxón.
4. **`Taxonomy`**: Linaje taxonómico jerárquico estricto de 7 niveles separados por punto y coma:
   `d__Dominio;p__Filo;c__Clase;o__Orden;f__Familia;g__Género;s__Especie`.

---

## 4. ⚙️ Orquestación del Flujo con Snakemake (`rules/eval.smk`)

La evaluación se orquesta de forma automatizada mediante Snakemake:

```
lemmi16s/
├── workflow/
│   ├── Snakefile                # Orquestador maestro de dependencias
│   └── rules/
│       ├── repository.smk       # Descarga y verificación de bases de datos
│       ├── analysis.smk         # Invocación de scripts de clasificación
│       └── eval.smk             # Comparación matemática contra queryTaxo.tsv
```

### 🔬 Comando Oficial de Evaluación
Para ejecutar la evaluación de una predicción contra el Ground Truth y obtener las métricas oficiales:

```bash
cd /home/cristian-solano/lemmi16s

# Invocación de Snakemake para evaluar las predicciones generadas
python3 -m snakemake \
  --snakefile workflow/Snakefile \
  --configfile config/config.yaml \
  benchmark/final_results/evaluation_summary.tsv \
  -j 4
```

### 📊 Archivos de Métricas Generados
Snakemake produce tablas TSV detalladas por cada rango taxonómico:
* **`benchmark/results/f1.{dataset}.tsv`**: Puntuaciones armónicas F1.
* **`benchmark/results/precision.{dataset}.tsv`**: Exactitud de los taxones reportados.
* **`benchmark/results/recall.{dataset}.tsv`**: Fracción de taxones verdaderos detectados.
* **`benchmark/results/l2.{dataset}.tsv`**: Error cuadrático de abundancias relativas.

> [!NOTE]
> **Reproducibilidad Garantizada:** Como se demostró en las 13 corridas del proyecto, tanto las ejecuciones nativas en PC como en el clúster ARM64 producen exactamente las mismas tablas `#LEMMI16s`, alcanzando idénticas puntuaciones F1-score sin ninguna desviación biológica.
