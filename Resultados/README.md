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
| **[`01_resultados_eficiencia_energetica.md`](01_resultados_eficiencia_energetica.md)** | **Eficiencia Energética y Rendimiento** | • Comparativa tripartita unificada: Laptop Cristian (x86 Nativo) vs. Laptop Zamir (x86 WSL2) vs. Clúster Green HPC (ARM64 RPi 5)<br>• Fórmulas de potencia neta, Wh y Reads/Wh<br>• Telemetría Intel RAPL y PMIC Renesas DA9091 (1.0 Hz)<br>• **Nuevo Benchmark PacBio Full-Length 16S (25.6k lecturas largas)** con ahorro energético de -27.8% vs. x86 Nativo<br>• **Nuevo Benchmark Experimental Mononodo vs. Multinodo**: Demostración empírica de aceleración (Speedup 5.00x en QIIME 2 y 4.36x en PacBio) y ahorro de energía en tareas largas |
| **[`02_resultados_fidelidad_biologica.md`](02_resultados_fidelidad_biologica.md)** | **Fidelidad y Precisión Biológica** | • Validación frente al Ground Truth oficial de LEMMI16s (`queryTaxo.tsv`)<br>• Precisión, Recall y F1-Score reales por rango taxonómico (Familia, Género y Especie)<br>• **Hito de Resolución Biológica PacBio**: Salto cualitativo en LotuS3 desde $F_1 \approx 0.40$ (Illumina corto) hasta **$F_1 = 0.9329$ (Familia) y $F_1 = 0.9003$ (Género)**<br>• **Certificación de Paridad Mononodo vs. Multinodo**: 100.00% de paridad biológica exacta e idéntica predicción taxonómica en todas las muestras |

---

## 🧭 Resumen de los Grandes Hallazgos: Tres Plataformas

| Dimensión Analizada | Laptop Cristian (x86 Nativo) | Laptop Zamir (x86 WSL2) | Clúster Green HPC (RPi 5 ARM64) | Ventaja / Impacto del Clúster ARM64 |
| :--- | :---: | :---: | :---: | :---: |
| **Tiempo Lote Clásico (Kraken+LotuS-Ill+QIIME)** | 4,411.8 s (73.53 min) | 4,972.0 s (82.87 min) | **1,762.5 s (29.38 min paralelo)** | **2.50x más veloz vs. Nativo / 2.82x vs. WSL2** |
| **Consumo Bruto Lote Clásico** | 26.03 Wh (93,711 J) | 35.32 Wh (127,159 J) | **8.57 Wh (30,848 J)** | **-67.1% vs. Nativo / -75.7% vs. WSL2** |
| **Consumo Neto de Cómputo** | 12.98 Wh (46,730 J) | 17.36 Wh (62,510 J) | **2.84 Wh (10,214 J)** | **-78.1% vs. Nativo / -83.6% vs. WSL2** |
| **Eficiencia Energética (Reads/Wh)** | 93.5k a 11.24M Rd/Wh | 42.1k a 6.55M Rd/Wh | **324.6k a 12.13M Rd/Wh (Neta: 61.64M)** | **1.08x a 4.07x Bruta / 3.81x a 6.78x Neta vs. Nativo** |
| **Rendimiento LotuS3 PacBio (16S Largo)** | 1,885.3 s (16.66 Wh) | *[Pendiente WSL2]* | **1,969.7 s (12.03 Wh)** | **-27.8% energía bruta con paridad temporal (1.04x)** |
| **Fidelidad Biológica LotuS3 PacBio** | $F_1 = 0.9219$ (Fam) / $0.8544$ (Gén) | *[Pendiente WSL2]* | **$F_1 = 0.9329$ (Fam) / $0.9003$ (Gén)** | **Salto masivo vs. Illumina ($F_1 \approx 0.40$)** |
| **Paridad Mononodo vs. Multinodo** | — | — | **100.00% Identidad Métrica** | **Speedup 4.36x–5.00x sin distorsión biológica** |

---

## 🔬 Nuevos Benchmarks Especializados Integrados

1. **Benchmark LotuS3 PacBio Full-Length (25,611 lecturas HiFi):**
   * Validación del gen 16S completo (~1,500 pb) en suelos contaminados con metales pesados.
   * El clúster ARM64 entrega la corrida completa en **32.83 min** disipando **12.03 Wh brutos (-27.8% vs. los 16.66 Wh de la laptop Intel Core i5)**.
   * La resolución taxonómica se eleva a **$F_1 = 0.9329$ en Familia y $F_1 = 0.9003$ en Género**.

2. **Benchmark Experimental Mononodo vs. Multinodo (Aceleración y Dinámica de Reposo):**
   * **QIIME 2:** Mononodo 139.92 min vs. Multinodo **27.98 min** (**Speedup lineal de 5.00x** en 5 nodos).
   * **LotuS3 PacBio:** Mononodo 143.04 min vs. Multinodo **32.83 min** (**Speedup de 4.36x**, ahorrando **-15.9% de energía bruta** al eliminar horas de potencia basal inútil).
   * **LotuS3 Illumina:** Mononodo 1.31 min vs. Multinodo **0.54 min** (**Speedup de 2.41x**).
   * **Kraken 2:** Mononodo 1.64 min vs. Multinodo **0.85 min** (**Speedup de 1.93x**).

---

## 👁️ Visualización en Antigravity IDE

> [!TIP]
> Para abrir la vista previa interactiva con tablas formateadas y fórmulas matemáticas:
> * Presiona **`Ctrl + Shift + V`** (pantalla completa) o **`Ctrl + K` y luego `V`** (al lado del código).
