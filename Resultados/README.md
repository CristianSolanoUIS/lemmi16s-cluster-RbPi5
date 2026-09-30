# 📊 RESULTADOS DEL PROYECTO: BENCHMARK LEMMI16s (METAGENÓMICA 16S)
## ⚡ Evaluación Tripartita: Rendimiento, Eficiencia Energética (Reads/Wh) y Fidelidad Biológica

> **Proyecto de Grado / Tesis de Ingeniería de Sistemas e Informática**  
> 👥 **Autores:** Cristian Alberto Solano Torres & Zamir Francisco Granados Peñaloza  
> 📅 **Fecha:** Septiembre de 2026  
> 📁 **Ubicación:** `/home/cristian-solano/Descargas/Resultados/`

---

## 📌 Índice de Documentos de Resultados Consolidados

Esta carpeta centraliza de forma exclusiva los **resultados cuantitativos oficiales del proyecto**, unificados bajo una metodología comparativa tripartita sin reportes dispersos:

| Documento | Enfoque Principal | Contenido Consolidado |
| :--- | :--- | :--- |
| **[`01_resultados_eficiencia_energetica.md`](01_resultados_eficiencia_energetica.md)** | **Eficiencia Energética y Rendimiento** | • Comparativa tripartita unificada: Laptop Cristian (x86 Nativo) vs. Laptop Zamir (x86 WSL2) vs. Clúster Green HPC (ARM64 RPi 5)<br>• Fórmulas de potencia neta, Wh y Reads/Wh<br>• Telemetría Intel RAPL y PMIC Renesas DA9091 (1.0 Hz)<br>• Mediciones completas en los nodos físicos con fuentes oficiales de 27W<br>• Matrices muestra a muestra para Kraken 2, LotuS3 y QIIME 2 |
| **[`02_resultados_fidelidad_biologica.md`](02_resultados_fidelidad_biologica.md)** | **Fidelidad y Precisión Biológica** | • Validación frente al Ground Truth oficial de LEMMI16s (`queryTaxo.tsv`)<br>• Precisión, Recall y F1-Score reales por rango taxonómico (Familia, Género y Especie)<br>• Validación cruzada diferencial entre las 3 plataformas<br>• Certificación de paridad biológica y reproducibilidad sin pérdida de información |

---

## 🧭 Resumen de los Grandes Hallazgos: Tres Plataformas

| Dimensión Analizada | Laptop Cristian (x86 Nativo) | Laptop Zamir (x86 WSL2) | Clúster Green HPC (RPi 5 ARM64) | Ventaja / Impacto del Clúster ARM64 |
| :--- | :---: | :---: | :---: | :---: |
| **Tiempo Total Lotes (Kraken+LotuS+QIIME)** | 4,411.8 s (73.53 min) | 4,972.0 s (82.87 min) | **1,762.5 s (29.38 min paralelo)** | **2.50x más veloz vs. Nativo / 2.82x vs. WSL2** |
| **Consumo Eléctrico Bruto Total** | 26.03 Wh (93,711 J) | 35.32 Wh (127,159 J) | **8.57 Wh (30,848 J)** | **-67.1% vs. Nativo / -75.7% vs. WSL2** |
| **Consumo Eléctrico Neto de Cómputo** | 12.98 Wh (46,730 J) | 17.36 Wh (62,510 J) | **2.84 Wh (10,214 J)** | **-78.1% vs. Nativo / -83.6% vs. WSL2** |
| **Eficiencia Energética (Reads/Wh)** | 93.5k a 11.24M Rd/Wh | 42.1k a 6.55M Rd/Wh | **324.6k a 12.13M Rd/Wh (Neta: 61.64M)** | **1.08x a 4.07x Bruta / 3.81x a 6.78x Neta vs. Nativo** |
| **Fidelidad Biológica Taxonómica** | *Línea Base Principal* | *Consistente (100% en Fam/Gén LotuS3)* | **Identidad Absoluta (0 diffs en QIIME 2)**| **100.00% Reproducibilidad y Consistencia** |

---

## 👁️ Visualización en Antigravity IDE

> [!TIP]
> Para abrir la vista previa interactiva con tablas formateadas y fórmulas matemáticas:
> * Presiona **`Ctrl + Shift + V`** (pantalla completa) o **`Ctrl + K` y luego `V`** (al lado del código).
