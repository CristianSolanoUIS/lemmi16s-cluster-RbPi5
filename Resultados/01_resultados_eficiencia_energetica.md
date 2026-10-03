# ⚡ INFORME DE RESULTADOS DE EFICIENCIA ENERGÉTICA Y RENDIMIENTO COMPUTACIONAL
## 🔋 Evaluación Comparativa Tripartita: x86_64 Ubuntu Nativo (Laptop Cristian) vs. x86_64 WSL2 (Laptop Zamir) vs. ARM64 Green HPC (Clúster Raspberry Pi 5)

> **Proyecto de Grado / Tesis de Ingeniería de Sistemas e Informática**  
> 👥 **Autores:** Cristian Alberto Solano Torres & Zamir Francisco Granados Peñaloza  
> 📅 **Fecha:** Septiembre / Octubre de 2026  
> 📁 **Archivo:** `/home/cristian-solano/Descargas/Resultados/01_resultados_eficiencia_energetica.md`  
> 📖 **Referencia Metodológica:** Protocolo Unificado de Telemetría (Estabilización 60 s + Línea Base Previa 5 min + In-Run a 1.0 Hz) homologado con el Libro de Tesis (`lemmi16s/Libro_Proyecto_Grado/main.tex`).

---

## 1. 🎯 Resumen Ejecutivo

Este informe consolida las mediciones experimentales de desempeño computacional, consumo de potencia eléctrica y eficiencia energética en lecturas biológicas por vatio-hora (**Reads/Wh**) para el análisis metagenómico del gen 16S rRNA bajo el benchmark internacional **LEMMI16s**.

La evaluación compara de manera exhaustiva y reproducible tres entornos de cómputo representativos:
1. **x86_64 Ubuntu Nativo (Laptop Cristian):** Estación de control de referencia principal (Intel Core i5-10300H).
2. **x86_64 WSL2 (Laptop Zamir):** Estación de referencia complementaria con idéntico procesador base bajo Windows 11 y subsistema WSL2 para cuantificar el costo de la virtualización ligera.
3. **ARM64 Green HPC (Clúster Raspberry Pi 5):** Plataforma distribuida de bajo consumo compuesta por 5 nodos de cómputo dedicados (20 núcleos ARM Cortex-A76 @ 2.4 GHz) interconectados por red Gigabit bajo Slurm.

> [!IMPORTANT]
> **Veredictos Clave de Eficiencia y Rendimiento (Lotes Completos):**
> 1. **Reducción de Tiempo en Cómputo Distribuido:** En el procesamiento de lotes pesados (QIIME 2 y LotuS3), el paralelismo multinodo del clúster físico superó holgadamente la ejecución secuencial mononodo de las laptops, reduciendo el tiempo de QIIME 2 de **72.06 min (Nativo)** y **79.99 min (WSL2)** a solo **27.98 min** en el clúster (**2.58x más rápido que Nativo y 2.86x que WSL2**). El tiempo acumulado de todos los lotes fue de **29.38 min en el clúster frente a 73.53 min en Nativo (2.50x)** y **82.87 min en WSL2 (2.82x)**.
> 2. **Ahorro Eléctrico Masivo:** El clúster consumió en total **8.57 Wh (30,848 J)** frente a **26.03 Wh (93,711 J)** de la estación nativa (**-67.1% de ahorro bruto**) y **35.32 Wh (127,159 J)** de WSL2 (**-75.7% de ahorro bruto**). En términos de energía neta algorítmica, el clúster disipó únicamente **2.84 Wh frente a 12.98 Wh nativo (-78.1%)** y **17.36 Wh WSL2 (-83.6%)**.
> 3. **Productividad Energética Superior (Reads/Wh):** La ganancia en productividad biológica bruta ($\eta_{\text{bruta}}$) del clúster ARM64 osciló entre **1.08x y 4.07x frente a Linux Nativo** (y hasta **9.04x frente a WSL2**). En productividad neta ($\eta_{\text{neta}}$), la ganancia alcanzó de **3.81x a 6.78x frente a Nativo** (y hasta **10.75x frente a WSL2**), consolidando la microarquitectura ARM64 como una alternativa sostenible de computación verde (*Green HPC*) para bioinformática.

---

### Tabla Resumen Comparativa Global (Lotes Completos)
*Datos correspondientes a las Tablas 3.5, 3.6, 3.7 y 3.8 del libro de grado oficial.*

| Pipeline Evaluado | Lecturas Totales | Métrica Clave | Laptop Cristian (x86 Nativo) | Laptop Zamir (x86 WSL2) | Clúster RPi 5 (ARM64) | Impacto / Factor de Ganancia (Clúster vs. x86) |
| :--- | :---: | :--- | :---: | :---: | :---: | :--- |
| **Kraken 2 + Bracken** | 2,453,431 | **Tiempo de Ejecución** | **22.01 s** | 51.41 s | 51.04 s (paralelo 5 nodos) | Cómputo distribuido simultáneo (1 muestra/nodo) |
| *(Dataset: HOMD_v4_GTDB)* | *(5 muestras)* | **Energía Bruta (Wh)** | 0.2183 Wh (785.9 J) | 0.3744 Wh (1,347.8 J) | **0.2023 Wh (728.3 J)** | **-7.3% vs. Nativo / -46.0% vs. WSL2** |
| | | **Energía Neta (Wh)** | 0.1518 Wh (546.5 J) | 0.1775 Wh (639.0 J) | **0.0398 Wh (143.3 J)** | **-73.8% vs. Nativo / -77.6% vs. WSL2** |
| | | **Eficiencia Bruta** | 11,237,105 Rd/Wh | 6,553,358 Rd/Wh | **12,125,061 Rd/Wh** | **1.08x Bruta vs. Nativo (1.85x vs. WSL2)** |
| | | **Eficiencia Neta** | 16,162,260 Rd/Wh | 13,822,146 Rd/Wh | **61,641,734 Rd/Wh** | **3.81x Neta vs. Nativo (4.46x vs. WSL2)** |
| **LotuS3 Suite (Illumina)** | 29,783 | **Tiempo de Ejecución** | 66.03 s (1.10 min) | 121.19 s (2.02 min) | **32.55 s (0.54 min paral.)** | **2.03x más veloz vs. Nativo / 3.72x vs. WSL2** |
| *(Dataset: HM_Contaminated_Soil)*| *(3 muestras)* | **Energía Bruta (Wh)** | 0.3187 Wh (1,147.3 J) | 0.7067 Wh (2,544.1 J) | **0.0782 Wh (281.5 J)** | **-75.5% vs. Nativo / -88.9% vs. WSL2** |
| *(Línea Base Histórica)* | | **Energía Neta (Wh)** | 0.1322 Wh (475.9 J) | 0.2097 Wh (754.9 J) | **0.0195 Wh (70.2 J)** | **-85.2% vs. Nativo / -90.7% vs. WSL2** |
| | | **Eficiencia Bruta** | 93,462 Rd/Wh | 42,141 Rd/Wh | **380,844 Rd/Wh** | **4.07x Bruta vs. Nativo (9.04x vs. WSL2)** |
| | | **Eficiencia Neta** | 225,287 Rd/Wh | 142,027 Rd/Wh | **1,527,333 Rd/Wh** | **6.78x Neta vs. Nativo (10.75x vs. WSL2)** |
| **LotuS3 Suite (PacBio)** | 25,611 | **Tiempo de Ejecución** | **1,896.00 s (31.60 min)** | *[Pendiente WSL2]* | 1,969.71 s (32.83 min paral.) | **Speedup 4.36x multinodo vs. mononodo** |
| *(Dataset: HM_Contaminated_Soil)*| *(5 muestras)* | **Energía Bruta (Wh)** | 17.1326 Wh (61,677 J) | *[Pendiente WSL2]* | **12.0311 Wh (43,312 J)** | **-29.8% vs. Nativo / -15.9% vs. Mononodo** |
| *(Amplicón Full-Length 16S)* | *(25.6k reads)*| **Energía Neta (Wh)** | 15.6405 Wh (56,306 J) | *[Pendiente WSL2]* | **7.3270 Wh (26,377 J)** | **-53.2% vs. Nativo / -15.3% vs. Mononodo** |
| | | **Eficiencia Bruta** | 1,494.9 Rd/Wh | *[Pendiente WSL2]* | **2,128.7 Rd/Wh** | **1.42x Bruta vs. Nativo (1.19x vs. Mononodo)** |
| | | **Eficiencia Neta** | 1,637.5 Rd/Wh | *[Pendiente WSL2]* | **3,495.4 Rd/Wh** | **2.13x Neta vs. Nativo (1.18x vs. Mononodo)** |
| **QIIME 2 (Deblur + NB)** | 2,690,077 | **Tiempo de Ejecución** | 4,323.72 s (72.06 min) | 4,799.44 s (79.99 min) | **1,678.94 s (27.98 min paral.)**| **2.58x más veloz vs. Nativo / 2.86x vs. WSL2** |
| *(Dataset: alfa_v1v2_SILVA)* | *(5 muestras)* | **Energía Bruta (Wh)** | 25.4939 Wh (91,778 J) | 34.2407 Wh (123,267 J) | **8.2884 Wh (29,838 J)** | **-67.5% vs. Nativo / -75.8% vs. WSL2** |
| | | **Energía Neta (Wh)** | 12.6965 Wh (45,707 J) | 16.9772 Wh (61,118 J) | **2.7779 Wh (10,000 J)** | **-78.1% vs. Nativo / -83.6% vs. WSL2** |
| | | **Eficiencia Bruta** | 105,518 Rd/Wh | 78,564 Rd/Wh | **324,561 Rd/Wh** | **3.08x Bruta vs. Nativo (4.13x vs. WSL2)** |
| | | **Eficiencia Neta** | 211,875 Rd/Wh | 158,452 Rd/Wh | **968,385 Rd/Wh** | **4.57x Neta vs. Nativo (6.11x vs. WSL2)** |
| **TOTALES LOTE CLÁSICO** | **5,173,291** | **Tiempo Acumulado** | 4,411.8 s (73.53 min) | 4,972.04 s (82.87 min) | **1,762.53 s (29.38 min paral.)**| **2.50x más veloz vs. Nativo / 2.82x vs. WSL2** |
| *(Kraken2 + LotuS3-Ill + QIIME2)*| *(13 ejecuciones)*| **Energía Bruta Total** | 26.0309 Wh (93,711 J) | 35.3218 Wh (127,159 J) | **8.5689 Wh (30,848 J)** | **-67.1% vs. Nativo / -75.7% vs. WSL2** |
| | | **Energía Neta Total** | 12.9805 Wh (46,730 J) | 17.3644 Wh (62,510 J) | **2.8372 Wh (10,214 J)** | **-78.1% vs. Nativo / -83.6% vs. WSL2** |

---

## 2. 🖥️ Plataformas de Hardware Evaluadas

*Datos sincronizados con la Tabla 3.1 del libro de grado (`tab:entornos`).*

| Parámetro / Componente | Estación Local de Control (x86_64 Nativo) — Laptop Cristian | Plataforma Virtualizada (x86_64 WSL2) — Laptop Zamir | Clúster de Cómputo Green HPC (ARM64) |
| :--- | :--- | :--- | :--- |
| **Rol en el Estudio** | Referencia x86 principal | Referencia complementaria (evaluación de virtualización) | Plataforma evaluada (Green HPC) |
| **Procesador (CPU)** | Intel Core i5-10300H (4 núcleos físicos / 8 hilos lógicos) | Intel Core i5-10300H (4 núcleos físicos / 8 hilos lógicos) | Broadcom BCM2712 Quad-Core Cortex-A76 (4 núcleos por nodo, 20 núcleos total de cómputo) |
| **Arquitectura de Instrucciones** | CISC (x86_64) | CISC (x86_64) | RISC (ARMv8.2-A, 64-bit) |
| **Frecuencia de Reloj** | 2.50 GHz base / hasta 4.50 GHz Turbo Boost | 2.50 GHz base / hasta 4.50 GHz Turbo Boost | 2.40 GHz sostenido con disipación activa oficial |
| **Memoria RAM** | 16 GB DDR4 @ 2933 MHz | 32 GB DDR4 (28 GB asignados a WSL2) | 16 GB LPDDR4X-4267 por nodo (80 GB agregados en cómputo) + 8 GB en nodo máster |
| **Almacenamiento** | SSD NVMe M.2 512 GB local | SSD NVMe M.2 500 GB local | MicroSD local 64 GB A2 (arranque) + NFS compartido Gigabit |
| **Sistema Operativo** | Linux Ubuntu 24.04 LTS (Kernel nativo 6.8) | Windows 11 + Ubuntu 22.04 LTS sobre WSL2 (Kernel 5.15) | Ubuntu Server 24.04 LTS (Kernel 6.8 aarch64) |
| **Gestor de Cargas** | Ejecución mononodo secuencial (Bash / Conda) | Ejecución mononodo secuencial en WSL2 (Bash / Conda) | Slurm Workload Manager 23.11 (`partition1`, cuenta `tg`) |
| **Sensor de Telemetría** | Intel RAPL directo vía MSR/powercap (`sysfs`, 1.0 Hz) | Intel RAPL vía LibreHardwareMonitor (1.0 Hz) | PMIC Renesas DA9091 (ADC hardware interno, 1.0 Hz) |
| **Dominio de Medición** | `package-0` (CPU Package completo) | CPU Package | Nivel de placa / rieles principales del SoC |

> [!NOTE]
> **Homogeneidad de Procesador en x86:** Ambas estaciones x86_64 cuentan con el mismo procesador base (Intel Core i5-10300H). Esto aísla de forma rigurosa la variable de arquitectura y permite atribuir con certeza matemática las diferencias entre Nativo y WSL2 a la capa de virtualización y al consumo basal del sistema operativo anfitrión (Windows 11).

---

## 3. 📐 Metodología de Medición, Modelo Físico y Protocolo de Reposo

### 3.1. Protocolo Estandarizado de Medición (Tres Fases Continuas)
Para garantizar que cada corrida experimental comenzara con el equipo sin carga residual y térmicamente estabilizado, se estructuró un protocolo de tres fases obligatorias:
1. **Estabilización Térmica Previa (60 segundos, sin medición):** Tras invocar el entorno, el sistema permanece en reposo total sin procesos en ejecución para asentar la CPU y finalizar procesos residuales.
2. **Línea Base Previa en Reposo (*Pre-run idle*, 5 minutos = 300 segundos a 1.0 Hz):** Registro continuo del consumo basal en reposo operativo sin carga de cómputo. Su promedio define la potencia basal $\bar{P}_{\text{idle}}$ oficial de esa sesión.
3. **Fase de Cómputo Activo (*Active computation*, 1.0 Hz continuo):** Ejecución del pipeline bioinformático completo bajo Slurm en el clúster o mediante ejecución nativa en x86, registrando concurrentemente la potencia instantánea $P(\tau)$.

### 3.2. Modelo Matemático de Telemetría Eléctrica

1. **Potencia Neta de Cómputo ($P_{\text{neta}}$):**
   $$P_{\text{neta}}(\tau) = P_{\text{activa}}(\tau) - \bar{P}_{\text{idle}}$$

2. **Energía Total Bruta ($E_{\text{total}}$ en Wh):**
   $$E_{\text{total}} = \int_{0}^{t} P_{\text{activa}}(\tau)\, d\tau \approx \frac{1}{3600} \sum_{k=1}^{t} P_{\text{activa}}(k)$$

3. **Energía Neta de Cómputo ($E_{\text{neta}}$ en Wh):**
   $$E_{\text{neta}} = \int_{0}^{t} P_{\text{neta}}(\tau)\, d\tau = E_{\text{total}} - \left( \bar{P}_{\text{idle}} \times \frac{t}{3600} \right)$$

4. **Productividad Energética Bruta y Neta (Reads/Wh):**
   $$\eta_{\text{bruta}} = \frac{N_{\text{reads}}}{E_{\text{total}}}, \qquad \eta_{\text{neta}} = \frac{N_{\text{reads}}}{E_{\text{neta}}}$$

5. **Factores de Ganancia frente a x86 Nativo:**
   $$G_{\text{bruta}} = \frac{\eta_{\text{bruta, clúster}}}{\eta_{\text{bruta, x86}}}, \qquad G_{\text{neta}} = \frac{E_{\text{neta, x86}}}{E_{\text{neta, clúster}}}$$

### 3.3. Comportamiento de la Potencia Basal en Reposo ($P_{\text{idle}}$)
* **Clúster RPi 5 (5 nodos de cómputo):** Potencia individual por nodo entre **$2.341\text{ W}$ y $2.429\text{ W}$** (media global de **$2.39\text{ W}$** por nodo, total de **$11.964\text{ W}$** sumando los 5 nodos físicos con Ubuntu Server activo).
* **Laptop Cristian (Ubuntu Nativo):** Potencia en reposo entre **$10.17\text{ W}$ y $10.88\text{ W}$** (media de **$10.57\text{ W}$**).
* **Laptop Zamir (WSL2):** Potencia en reposo entre **$12.95\text{ W}$ y $14.76\text{ W}$** (media de **$13.83\text{ W}$** debido al fondo activo de Windows 11).

---

## 4. 📊 Gran Matriz Comparativa Tripartita de Resultados

### 4.1. Resumen Consolidado Tripartito por Pipeline (Protocolo Oficial de 5 min Pre)
*Valores tomados directamente de las Tablas 3.5, 3.6, 3.7 y 3.8 del libro de grado.*

| Parámetro / Métrica | Kraken 2: Laptop Cristian (Nativo) | Kraken 2: Laptop Zamir (WSL2) | Kraken 2: Clúster RPi 5 (ARM64) | LotuS3: Laptop Cristian (Nativo) | LotuS3: Laptop Zamir (WSL2) | LotuS3: Clúster RPi 5 (ARM64) | QIIME 2: Laptop Cristian (Nativo) | QIIME 2: Laptop Zamir (WSL2) | QIIME 2: Clúster RPi 5 (ARM64) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Topología de Cómputo** | Mononodo (4 cores) | Mononodo (4 cores) | **5 Nodos Concurrentes** | Mononodo (4 cores) | Mononodo (4 cores) | **3 Nodos Concurrentes** | Mononodo (4 cores) | Mononodo (4 cores) | **5 Nodos Concurrentes** |
| **Lecturas Evaluadas** | 2,453,431 (5 m.) | 2,453,431 (5 m.) | **2,453,431 (5 m.)** | 29,783 (3 m.) | 29,783 (3 m.) | **29,783 (3 m.)** | 2,690,077 (5 m.) | 2,690,077 (5 m.) | **2,690,077 (5 m.)** |
| **Tiempo de Inferencia ($t$, s)**| **22.01 s** | 51.41 s | 51.04 s (paralelo) | 66.03 s (1.10 min) | 121.19 s (2.02 min) | **32.55 s (0.54 min paral.)** | 4,323.72 s (72.06 min) | 4,799.44 s (79.99 min) | **1,678.94 s (27.98 min paral.)** |
| **Uso Medio de CPU (%)** | 94.20% | 88.50% | 91.50% (por nodo) | 88.00% | 85.00% | 85.00% (por nodo) | 96.50% | 92.00% | 94.00% (por nodo) |
| **RAM Máxima por Proceso** | 1.80 GB | 1.80 GB | 1.60 GB (por nodo) | 1.20 GB | 1.40 GB | 1.10 GB (por nodo) | 2.40 GB | 3.20 GB | 2.10 GB (por nodo) |
| **Potencia Reposo ($P_{\text{idle}}$, W)**| 10.88 W | 13.78 W | 2.35 W/nodo (11.75 W tot)| 10.17 W | 14.76 W | 2.41 W/nodo (7.23 W tot) | 10.66 W | 12.95 W | 2.42 W/nodo (12.10 W tot) |
| **Potencia Media en Carga (W)** | 35.70 W | 26.22 W | 2.93 W/nodo (14.65 W tot)| 17.37 W | 20.99 W | 3.22 W/nodo (9.66 W tot) | 21.23 W | 25.68 W | 3.64 W/nodo (18.20 W tot) |
| **Potencia Neta Cómputo (W)** | 24.83 W | 12.43 W | 0.58 W/nodo (2.90 W tot) | 7.21 W | 6.23 W | 0.80 W/nodo (2.40 W tot) | 10.57 W | 12.73 W | 1.22 W/nodo (6.10 W tot) |
| **Energía Total Bruta (Wh)** | 0.2183 Wh (786 J) | 0.3744 Wh (1,348 J)| **0.2023 Wh (728 J)** | 0.3187 Wh (1,147 J)| 0.7067 Wh (2,544 J) | **0.0782 Wh (282 J)** | 25.4939 Wh (91,778 J)| 34.2407 Wh (123,267 J)| **8.2884 Wh (29,838 J)** |
| **Energía Neta Cómputo (Wh)** | 0.1518 Wh (547 J) | 0.1775 Wh (639 J) | **0.0398 Wh (143 J)** | 0.1322 Wh (476 J) | 0.2097 Wh (755 J) | **0.0195 Wh (70 J)** | 12.6965 Wh (45,707 J)| 16.9772 Wh (61,118 J)| **2.7779 Wh (10,000 J)** |
| **Eficiencia Bruta (Rd/Wh)** | 11,237,105 Rd/Wh | 6,553,358 Rd/Wh | **12,125,061 Rd/Wh** | 93,462 Rd/Wh | 42,141 Rd/Wh | **380,844 Rd/Wh** | 105,518 Rd/Wh | 78,564 Rd/Wh | **324,561 Rd/Wh** |
| **Eficiencia Neta (Rd/Wh)** | 16,162,260 Rd/Wh | 13,822,146 Rd/Wh | **61,641,734 Rd/Wh** | 225,287 Rd/Wh | 142,027 Rd/Wh | **1,527,333 Rd/Wh** | 211,875 Rd/Wh | 158,452 Rd/Wh | **968,385 Rd/Wh** |
| **Ganancia Bruta (RPi5 vs Nat)**| *1.00x (Ref)* | 0.58x | **1.08x (1.85x vs WSL2)**| *1.00x (Ref)* | 0.45x | **4.07x (9.04x vs WSL2)**| *1.00x (Ref)* | 0.74x | **3.08x (4.13x vs WSL2)** |
| **Ganancia Neta (RPi5 vs Nat)** | *1.00x (Ref)* | 0.86x | **3.81x (4.46x vs WSL2)**| *1.00x (Ref)* | 0.63x | **6.78x (10.75x vs WSL2)**| *1.00x (Ref)* | 0.75x | **4.57x (6.11x vs WSL2)** |

---

### 4.2. Análisis Detallado por Pipeline Bioinformático

#### ⚡ Kraken 2 + Bracken (Clasificación Basada en k-meros sobre GTDB)
* **Perfil de Carga:** Fase breve dominada por operaciones de lectura en memoria I/O y recorrido intensivo de árboles taxonómicos sobre los 142 MB de la base GTDB.
* **Comportamiento Temporal:** La estación x86 nativa obtuvo un tiempo menor (**22.01 s**) debido a la mayor velocidad de transferencia del disco SSD NVMe M.2 local frente a la lectura en red NFS del clúster (**51.04 s** distribuidos en 5 nodos).
* **Eficiencia:** A pesar del tiempo de acceso a red, la bajísima potencia disipada por nodo en ARM64 (2.93 W en carga vs. 35.70 W en x86) permitió al clúster alcanzar **12,125,061 Rd/Wh brutos (1.08x)** y **61,641,734 Rd/Wh netos (3.81x de ventaja frente a Nativo)**.

#### 🌿 LotuS3 Suite (Construcción de OTUs sobre SILVA)
* **Perfil de Carga:** Flujo intermedio que combina control de calidad demultiplexado (`sdm`), desreplicación y agrupamiento *de novo* UPARSE (`usearch`) con indexación rápida.
* **Comportamiento Temporal:** El clúster aceleró el procesamiento paralelo a **32.55 s (2.03x más rápido que Nativo y 3.72x que WSL2)**.
* **Eficiencia:** El clúster consumió apenas **0.0782 Wh brutos** frente a **0.3187 Wh nativo (-75.5%)** y **0.7067 Wh en WSL2 (-88.9%)**, registrando una eficiencia de **380,844 Rd/Wh brutos (4.07x)** y **1,527,333 Rd/Wh netos (6.78x vs. Nativo)**.

#### 🧬 QIIME 2 (Denoising con Deblur + Clasificación Bayesiana Naive Bayes SILVA 138)
* **Perfil de Carga:** El pipeline más intensivo del benchmark, con un alto costo de cómputo algorítmico continuo de entre 28 y 80 minutos por lote completo.
* **Comportamiento Temporal:** La distribución simultánea en los 5 nodos físicos del clúster completó el procesamiento en **27.98 min (1,678.94 s)**, superando radicalmente la ejecución secuencial de **72.06 min en Nativo (2.58x)** y **79.99 min en WSL2 (2.86x)**.
* **Eficiencia:** El clúster redujo la energía total consumida de **25.49 Wh (Nativo)** y **34.24 Wh (WSL2)** a **8.29 Wh (-67.5% y -75.8% de ahorro eléctrico)**. En energía neta algorítmica, el consumo cayó de **12.70 Wh nativo a solo 2.78 Wh (-78.1%)**, logrando una eficiencia de **324,561 Rd/Wh brutos (3.08x)** y **968,385 Rd/Wh netos (4.57x)**.

---

### 4.3. Desglose Muestra a Muestra Complementario (Registros Granulares de Inferencia)
Para fines de reproducibilidad y trazabilidad por muestra individual (`c001` a `e002`), se dispone de los registros temporales y energéticos por corrida individual:

* **Muestra de Control `e001` (Referencia Común en las 3 Plataformas):**
  * *Kraken 2:* Nativo: 4.0 s, 37.25 W, 0.0414 Wh (12.44M Rd/Wh) | WSL2: 4.4 s, 28.89 W, 0.0642 Wh (8.02M Rd/Wh) | Clúster (1 nodo): 14.0 s, 3.85 W, 0.0150 Wh (34.33M Rd/Wh).
  * *LotuS3 (Illumina):* Nativo: 22.0 s, 17.52 W, 0.1071 Wh (97,255 Rd/Wh) | WSL2: 174.2 s, 24.36 W, 1.1792 Wh (8,833 Rd/Wh) | Clúster (1 nodo): 28.0 s, 3.26 W, 0.0254 Wh (410,079 Rd/Wh).
  * *LotuS3 (PacBio):* Nativo: 350.2 s (5.8 min), 31.85 W, 3.098 Wh (1,657 Rd/Wh) | Clúster (1 nodo): 1,386.2 s (23.1 min), 6.22 W, 2.3522 Wh (2,182 Rd/Wh).
  * *QIIME 2:* Nativo: 865.0 s (14.4 min), 20.65 W, 4.9629 Wh (111,885 Rd/Wh) | WSL2: 936.7 s (15.6 min), 24.67 W, 6.4178 Wh (88,174 Rd/Wh) | Clúster (1 nodo): 1,584.0 s (26.4 min), 3.67 W, 1.6155 Wh (343,716 Rd/Wh).

---

### 4.4. 🧬 Benchmark Especializado: LotuS3 Suite sobre Lecturas Largas PacBio (Gen 16S Full-Length)

Para atender las observaciones de la dirección de tesis respecto a la representatividad biológica de LotuS3 en comunidades de alta complejidad (suelos contaminados con metales pesados, `HM_Contaminated_Soil`), se implementó la evaluación oficial con tecnología de **lecturas largas PacBio HiFi (~1,500 pb)** abarcando las 5 muestras completas (`c001` a `e002`, con un total de **25,611 lecturas**).

Este flujo aprovecha la demultiplexación y control de calidad especializado para secuencias largas mediante el perfil de configuración `sdm_PacBio_LSSU.txt`, agrupamiento OTU de alta resolución contra SILVA y asignación taxonómica rigurosa.

#### Desglose Experimental Multinodo en el Clúster ARM64 (5 Nodos Concurrentes, Slurm Jobs 1792 a 1796)

| Muestra Biológica | Nodo Físico Asignado | Potencia Reposo ($P_{\text{idle}}$, W) | Potencia en Carga ($P_{\text{carga}}$, W) | Duración ($t$, s) | Energía Bruta ($E_{\text{tot}}$, Wh) | Energía Neta ($E_{\text{net}}$, Wh) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `c001` (5,179 reads) | `rbp5-1` | 2.379 W | 5.996 W | 1,775.9 s (29.60 min) | 2.9471 Wh (10,610 J) | 1.7737 Wh (6,385 J) |
| `c002` (5,045 reads) | `rbp5-2` | 2.347 W | 6.838 W | 867.1 s (14.45 min) | 1.5955 Wh (5,744 J) | 1.0301 Wh (3,708 J) |
| `c003` (5,194 reads) | `rbp5-3` | 2.401 W | 6.273 W | 1,181.7 s (19.70 min) | 2.0143 Wh (7,251 J) | 1.2262 Wh (4,414 J) |
| `e001` (5,133 reads) | `rbp5-4` | 2.365 W | 6.219 W | 1,386.2 s (23.10 min) | 2.3522 Wh (8,468 J) | 1.4415 Wh (5,189 J) |
| `e002` (5,060 reads) | `rbp5-5` | 2.315 W | 5.751 W | 1,969.7 s (32.83 min) | 3.1219 Wh (11,239 J) | 1.8555 Wh (6,680 J) |
| **CONSOLIDADO MULTINODO** | **5 Nodos Clúster** | **2.361 W (media)** | **6.118 W (media)** | **1,969.71 s (32.83 min)** | **12.0311 Wh (43,312 J)** | **7.3270 Wh (26,377 J)** |

#### Comparativa de Plataformas en LotuS3 PacBio (25,611 Lecturas Largas)

| Métrica / Dimensión | Laptop Cristian (x86_64 Nativo) | Laptop Zamir (x86_64 WSL2) | Clúster RPi 5 (ARM64 Mononodo) | Clúster RPi 5 (ARM64 Multinodo) | Impacto Clúster Multinodo vs. x86 Nativo |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Topología y Cores** | 1 Estación (4 cores / 8 hilos) | *[Pendiente]* | 1 Nodo RPi 5 (4 cores) | **5 Nodos RPi 5 (4 cores/nodo, 20 cores)** | Paralelismo masivo distribuido |
| **Tiempo de Inferencia** | **1,896.00 s (31.60 min)** | *[Pendiente]* | 8,582.68 s (143.04 min, 2.38 h) | 1,969.71 s (32.83 min paralelo) | **1.04x (Paridad temporal con x86)** |
| **Speedup vs. Mononodo** | — | — | 1.00x (Referencia secuencial) | **4.36x más veloz** | Eficiencia paralela del 87.2% |
| **Potencia Reposo ($P_{\text{idle}}$)**| 2.829 W | *[Pendiente]* | 2.369 W | 2.361 W por nodo | Línea base homogénea en ARM64 |
| **Potencia Media en Carga** | 32.478 W | *[Pendiente]* | 6.007 W | 6.118 W por nodo | Disipación 5.3x menor por nodo |
| **Energía Total Bruta ($E_{\text{tot}}$)**| 17.1326 Wh (61,677 J) | *[Pendiente]* | 14.2991 Wh (51,477 J) | **12.0311 Wh (43,312 J)** | **-29.8% de ahorro energético bruto** |
| **Energía Neta ($E_{\text{net}}$)**| 15.6405 Wh (56,306 J) | *[Pendiente]* | 8.6506 Wh (31,142 J) | **7.3270 Wh (26,377 J)** | **-53.2% de ahorro energético neto** |
| **Eficiencia Bruta ($\eta_{\text{bruta}}$)**| 1,494.9 Reads/Wh | *[Pendiente]* | 1,791.1 Reads/Wh | **2,128.7 Reads/Wh** | **1.42x mayor productividad biológica** |
| **Eficiencia Neta ($\eta_{\text{neta}}$)**| 1,637.5 Reads/Wh | *[Pendiente]* | 2,960.6 Reads/Wh | **3,495.4 Reads/Wh** | **2.13x mayor productividad neta** |

> [!TIP]
> **Conclusión Energética del Experimento PacBio:**
> Al procesar amplicones de gen completo 16S, el clúster ARM64 entrega la corrida completa en un tiempo prácticamente equivalente al procesador Intel Core i5 de alta gama (**32.83 min vs. 31.60 min**), pero disipando **-29.8% menos energía bruta total (12.03 Wh frente a 17.13 Wh)** y **-53.2% menos energía neta de cálculo**. La productividad energética del clúster se eleva a **2,128.7 Reads/Wh (1.42x bruta y 2.13x neta)**.

---

## 5. 🔀 Benchmark Experimental Mononodo vs. Multinodo en el Clúster ARM64 (Validación de Escalabilidad y Demostración Green HPC)

Por requerimiento expreso de la dirección de tesis, se ejecutó una campaña experimental dedicada para contrastar la **ejecución mononodo secuencial (1 único nodo procesando todo el lote)** frente a la **ejecución multinodo concurrente (N nodos procesando en paralelo 1 muestra por nodo bajo Slurm)** sobre el mismo clúster físico Raspberry Pi 5.

Este experimento demuestra de manera empírica:
1. La aceleración real (*Speedup*) alcanzada por el gestor Slurm en hardware ARM64.
2. La relación entre la duración de la tarea computacional y la dinámica de acumulación de la potencia basal de reposo.

### 5.1. Gran Tabla Comparativa Mononodo vs. Multinodo (Todos los Pipelines)

| Pipeline Bioinformático | Dataset y Muestras | Configuración | Tiempo ($t$, s) | Speedup Real | $P_{\text{idle}}$ (W) | $P_{\text{carga}}$ (W) | Energía Bruta (Wh) | Energía Neta (Wh) | Eficiencia Bruta (Rd/Wh) | Eficiencia Neta (Rd/Wh) |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **QIIME 2** | `alfa_v1v2_SILVA` | **Mononodo (1 nodo)** | 8,394.91 s (139.92 min, 2.33 h) | 1.00x | 2.363 W | 3.615 W | 8.4246 Wh (30,329 J) | 2.9144 Wh (10,492 J) | 319,312 Rd/Wh | 923,016 Rd/Wh |
| *(Deblur + Naive Bayes)* | *(5 muestras, 2.69M reads)*| **Multinodo (5 nodos)** | **1,678.94 s (27.98 min)** | **5.00x** | 2.420 W | 3.640 W | **8.2884 Wh (29,838 J)** | **2.7779 Wh (10,000 J)** | **324,559 Rd/Wh** | **968,385 Rd/Wh** |
| **LotuS3 PacBio** | `HM_Contaminated_Soil` | **Mononodo (1 nodo)** | 8,582.68 s (143.04 min, 2.38 h) | 1.00x | 2.369 W | 6.007 W | 14.2991 Wh (51,477 J) | 8.6506 Wh (31,142 J) | 1,791.1 Rd/Wh | 2,960.6 Rd/Wh |
| *(Amplicón Full-Length 16S)*| *(5 muestras, 25.6k reads)*| **Multinodo (5 nodos)** | **1,969.71 s (32.83 min)** | **4.36x** | 2.361 W | 6.118 W | **12.0311 Wh (43,312 J)** | **7.3270 Wh (26,377 J)** | **2,128.7 Rd/Wh** | **3,495.4 Rd/Wh** |
| **LotuS3 Illumina** | `HM_Contaminated_Soil` | **Mononodo (1 nodo)** | 78.50 s (1.31 min) | 1.00x | 2.374 W | 3.196 W | **0.0697 Wh (251 J)** | **0.0179 Wh (64 J)** | **427,292 Rd/Wh** | **1,660,482 Rd/Wh** |
| *(Línea Base Histórica)* | *(3 muestras, 29.8k reads)*| **Multinodo (3 nodos)** | **32.55 s (0.54 min)** | **2.41x** | 2.410 W | 3.220 W | 0.0782 Wh (282 J) | 0.0195 Wh (70 J) | 380,857 Rd/Wh | 1,527,333 Rd/Wh |
| **Kraken 2 + Bracken** | `HOMD_v4_GTDB` | **Mononodo (1 nodo)** | 98.35 s (1.64 min) | 1.00x | 2.398 W | 4.015 W | **0.0976 Wh (351 J)** | **0.0321 Wh (116 J)** | **25,134,137 Rd/Wh** | **76,452,382 Rd/Wh** |
| *(Clasificación k-meros)* | *(5 muestras, 2.45M reads)*| **Multinodo (5 nodos)** | **51.04 s (0.85 min)** | **1.93x** | 2.350 W | 2.930 W | 0.2023 Wh (728 J) | 0.0398 Wh (143 J) | 12,127,687 Rd/Wh | 61,643,995 Rd/Wh |

> [!NOTE]
> *Nota Metodológica:*
> * En **Multinodo**, la energía representa la sumatoria total del consumo de todos los nodos físicos concurrentes durante la ventana de ejecución paralela.
> * En **Mononodo**, la energía representa el consumo total de un único nodo procesando secuencialmente una muestra tras otra.

### 5.2. Análisis de Rendimiento y Dinámica Energética (Amdahl y Costo Basal)

1. **Aceleración Lineal Perfecta en Cargas Intensivas (QIIME 2):**
   * En QIIME 2, la ejecución multinodo en 5 nodos redujo el tiempo de **139.92 minutos a 27.98 minutos**, obteniendo un factor de aceleración exacto de **$S = 5.00\text{x}$** ($100.0\%$ de eficiencia de paralelización teórica). Al ser cada muestra totalmente independiente, no existe sobrecarga de comunicación inter-nodo durante el procesamiento algorítmico de Deblur y Naive Bayes.
   * En LotuS3 PacBio, el speedup alcanzó **$4.36\text{x}$** ($87.2\%$ de eficiencia en 5 nodos), recortando la espera de **2.38 horas (143 min) a solo 32.83 minutos**.

2. **La Paradoja de la Potencia Basal: ¿Por qué Multinodo Ahorra Energía en Tareas Largas?**
   * Un hallazgo fundamental para la tesis radica en el consumo eléctrico bruto: en cargas computacionalmente pesadas (> 30 minutos), **la ejecución multinodo consume MENOS energía bruta que la mononodo** (QIIME 2: $8.29\text{ Wh}$ vs. $8.42\text{ Wh}$; LotuS3 PacBio: **$12.03\text{ Wh}$ vs. $14.30\text{ Wh}$, ahorro del $-15.9\%$**).
   * **Explicación Física:** En ejecución mononodo secuencial, el sistema debe permanecer encendido durante más de dos horas disipando continuamente su potencia basal de reposo ($\sim 2.37\text{ W} \times 2.38\text{ h} \approx 5.64\text{ Wh}$ de pura energía basal pasiva). Al paralelizar en 5 nodos, el trabajo se completa en 32 minutos, minimizando el tiempo total de disipación residual activa.

3. **Cargas Ultracortas y Costo de Activación Paralela:**
   * En flujos muy breves (< 2 minutos como Kraken 2 e Illumina), el speedup es menor ($1.93\text{x}$ a $2.41\text{x}$) debido a la latencia fija del sistema de archivos en red NFS y el arranque de contenedores Slurm.
   * En estos casos, encender 5 nodos a la vez acumula la potencia base de 5 placas simultáneamente durante 50 segundos ($5 \times 2.35\text{ W} \approx 11.75\text{ W}$), resultando en un consumo bruto ligeramente mayor en multinodo ($0.2023\text{ Wh}$ vs. $0.0976\text{ Wh}$), aunque reduciendo el tiempo a la mitad.

---

## 6. 🔬 Fichas Técnicas de Telemetría y Trazabilidad de Archivos

### 6.1. Kraken 2 + Bracken
* **Laptop Cristian (x86 Nativo):**
  * Script Fuente: [`workflow/scripts/nativo/run_kraken2_energy.sh`](file:///home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_kraken2_energy.sh)
  * Telemetría RAPL: `medicion_energia/nativas/energia_Kraken2_Nativo_Batch5_GTDB_*.csv`
  * Predicciones: `benchmark/nativos/kraken2_native.HOMD_v4_GTDB-*.predictions.tsv`
* **Laptop Zamir (x86 WSL2):**
  * Script Telemetría: PowerShell `medir_fase.ps1` con LibreHardwareMonitor.
  * Archivo Fuente: `C:\medicioenergia\kraken2\energia_kraken2_x86_TODAS_20260925_110858.csv`
  * Predicciones: `benchmark/analysis_outputs/kraken2/kraken2_213_lemmi16s_nativo.HOMD_v4_GTDB-*.predictions.tsv`
* **Clúster Green HPC (5 Nodos ARM64 Multinodo):**
  * Despacho: Jobs Slurm 1483 a 1487 (`rbp5-1` a `rbp5-5`), 4 cores por nodo (`--exclusive`).
  * Telemetría PMIC DA9091: `medicion_energia/kraken2/` (15 archivos CSV: pre, in-run y post).
* **Clúster Green HPC (Mononodo Secuencial):**
  * Despacho: Job Slurm 1750 (`rbp5-3`, 4 cores).
  * Telemetría PMIC DA9091: `medicion_energia/mononodo/energia_Kraken2_mononodo_node_rbp5-3_job1750_*.csv`.

### 6.2. LotuS3 Suite (PacBio Full-Length 16S y Línea Base Illumina)
* **Laptop Cristian (x86 Nativo - PacBio 5 Muestras):**
  * Script Fuente: [`workflow/scripts/nativo/run_lotus3_pacbio_energy.sh`](file:///home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_lotus3_pacbio_energy.sh)
  * Telemetría RAPL: `medicion_energia/nativas/energia_lotus3_pacbio_Nativo_all_20261003_123350_20261003_123953.csv`
  * Baseline Pre: `medicion_energia/nativas/energia_baseline_pre_lotus3_pacbio_20261003_123450.csv` ($P_{\text{idle}} = 2.829\text{ W}$)
  * Predicciones: `benchmark/nativos/lotus3_native.HM_Contaminated_Soil-*.predictions.tsv` (25,611 reads).
* **Laptop Cristian (x86 Nativo - Línea Base Illumina 3 Muestras):**
  * Script Fuente: [`workflow/scripts/nativo/run_lotus3_energy.sh`](file:///home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_lotus3_energy.sh)
  * Telemetría RAPL: `medicion_energia/nativas/energia_LotuS3_Nativo_Batch3_SILVA_20260927_135552.csv`
  * Respaldo Aislado: `benchmark/evaluations/corrida_Lotus3_3Muestras_evaluations/`
* **Laptop Zamir (x86 WSL2):**
  * Archivo Fuente (Illumina): `C:\medicioenergia\lotus3\energia_lotus3_x86_TODAS_20260925_111712.csv`
  * Predicciones: `benchmark/analysis_outputs/lotus3/lotus_303_lemmi16s_nativo.HM_Contaminated_Soil-*.predictions.tsv`
  * *Estado PacBio:* Pendiente de integración.
* **Clúster Green HPC (5 Nodos ARM64 Multinodo - PacBio):**
  * Despacho: Jobs Slurm 1792 a 1796 (`rbp5-1` a `rbp5-5`), 4 cores por nodo (`--exclusive`).
  * Telemetría PMIC DA9091: `medicion_energia/lotus3_pacbio/` (10 archivos CSV: pre y active run).
  * Predicciones: `benchmark/analysis_outputs/lotus3_pacbio/lotus3_pacbio_multinodo.HM_Contaminated_Soil_PacBio-*.predictions.tsv`.
* **Clúster Green HPC (Mononodo Secuencial - PacBio):**
  * Despacho: Job Slurm 1797 (`rbp5-1`, 4 cores).
  * Telemetría PMIC DA9091: `medicion_energia/lotus3_pacbio/mononodo/energia_LotuS3_pacbio_mononodo_node_rbp5-1_job1797_*.csv`.
* **Clúster Green HPC (Mononodo Secuencial - Illumina):**
  * Despacho: Job Slurm 1749 (`rbp5-2`, 4 cores).
  * Telemetría PMIC DA9091: `medicion_energia/mononodo/energia_LotuS3_mononodo_node_rbp5-2_job1749_*.csv`.

### 6.3. QIIME 2 (Deblur + Naive Bayes SILVA 138)
* **Laptop Cristian (x86 Nativo):**
  * Script Fuente: [`workflow/scripts/nativo/run_qiime2_energy.sh`](file:///home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_qiime2_energy.sh)
  * Telemetría RAPL: `medicion_energia/nativas/energia_Qiime2_Nativo_Batch5_SILVA_20260918_125756.csv`
  * Predicciones: `benchmark/nativos/qiime2_native.alfa_v1v2_SILVA-*.predictions.tsv`
* **Laptop Zamir (x86 WSL2):**
  * Entorno: `qiime2-2023.2` (q2cli 2022.8.0 y Deblur 1.1.0).
  * Archivos Fuente: `energia_qiime2_x86_TODAS_20260926_122756.csv` y `..._143927.csv`.
  * Predicciones: `benchmark/analysis_outputs/qiime2/qiime2_20228_lemmi16s_nativo.alfa_v1v2_SILVA-*.predictions.tsv`
* **Clúster Green HPC (5 Nodos ARM64 Multinodo):**
  * Despacho: Jobs Slurm 1491 a 1495 (`rbp5-1` a `rbp5-5`), 2 cores por nodo (`--exclusive`).
  * Telemetría PMIC DA9091: `medicion_energia/qiime2/` (15 archivos CSV: pre, in-run y post).
* **Clúster Green HPC (Mononodo Secuencial):**
  * Despacho: Job Slurm 1748 (`rbp5-1`, 4 cores).
  * Telemetría PMIC DA9091: `medicion_energia/mononodo/energia_Qiime2_mononodo_node_rbp5-1_job1748_*.csv`.

---

## 7. 🎓 Conclusiones de Rendimiento y Eficiencia Energética para la Tesis

1. **Aceleración Distribuida en Cargas Intensivas:**
   * En pipelines con etapas de cómputo algorítmico intensivo (Deblur, UPARSE y Naive Bayes), la topología distribuida del clúster físico superó el procesamiento secuencial mononodo de las laptops, reduciendo el tiempo de QIIME 2 de **72.06 min (Nativo)** y **79.99 min (WSL2)** a **27.98 min** en el clúster (**2.58x y 2.86x más rápido**), y el lote total acumulado a **29.38 min frente a 73.53 min (2.50x) y 82.87 min (2.82x)**.
2. **Supremacía en Eficiencia Energética (Green HPC):**
   * El clúster Raspberry Pi 5 redujo drásticamente el consumo eléctrico en los tres flujos evaluados: **8.57 Wh totales frente a 26.03 Wh en Linux Nativo (-67.1%)** y **35.32 Wh en WSL2 (-75.7%)**.
   * En términos netos de cálculo computacional, el gasto cayó de **12.98 Wh nativo y 17.36 Wh WSL2 a tan solo 2.84 Wh en el clúster (-78.1% y -83.6% de ahorro neto)**.
   * La métrica de productividad ($\text{Reads/Wh}$) ratificó una ventaja del clúster de **1.08x a 4.07x en productividad bruta** y de **3.81x a 6.78x en productividad neta frente a x86 nativo** (y de hasta **9.04x bruta y 10.75x neta frente a WSL2**).
3. **Validación Experimental de Amplicón Largo (PacBio Full-Length):**
   * En el procesamiento de secuencias largas de gen completo 16S con LotuS3, el clúster multinodo igualó el tiempo de ejecución de una estación Intel Core i5 nativa (**32.83 min vs. 31.60 min**), logrando un **ahorro energético del -29.8% bruto (12.03 Wh vs. 17.13 Wh) y del -53.2% neto (7.33 Wh vs. 15.64 Wh)**, con una productividad bruta superior de **2,128.7 Reads/Wh (1.42x)** y neta de **3,495.4 Reads/Wh (2.13x)**.
4. **Demostración Empírica de Escalabilidad Mononodo vs. Multinodo:**
   * La comparación directa en el hardware ARM64 demostró speedups de **5.00x en QIIME 2** (escalabilidad lineal perfecta al 100%) y **4.36x en LotuS3 PacBio** (eficiencia del 87.2%), confirmando que el cómputo distribuido en clúster elimina horas de consumo basal inútil y ahorra un **-15.9% de energía bruta** en lotes largos frente a la ejecución secuencial en un solo nodo.
5. **Sobrecarga de la Virtualización Ligera (WSL2 vs. Nativo):**
   * Al operar sobre procesadores físicos equivalentes (Intel Core i5-10300H), la capa de virtualización de WSL2 sobre Windows 11 introdujo un sobrecosto medible en tiempo (+12.7% en el lote global y hasta +83.5% en flujos intensivos en disco como LotuS3) y en energía consumida (+35.7% en energía bruta total debido a la línea base más elevada de Windows de ~13.8 W vs. ~10.6 W en Ubuntu nativo), demostrando las ventajas energéticas de los entornos Linux dedicados.
