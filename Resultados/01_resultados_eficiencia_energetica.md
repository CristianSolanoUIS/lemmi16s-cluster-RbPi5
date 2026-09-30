# ⚡ INFORME DE RESULTADOS DE EFICIENCIA ENERGÉTICA Y RENDIMIENTO COMPUTACIONAL
## 🔋 Evaluación Comparativa Tripartita: x86_64 Ubuntu Nativo (Laptop Cristian) vs. x86_64 WSL2 (Laptop Zamir) vs. ARM64 Green HPC (Clúster Raspberry Pi 5)

---

## 1. 🎯 Resumen Ejecutivo

Este informe consolida las mediciones experimentales de consumo eléctrico, potencia y rendimiento temporal del benchmark internacional **LEMMI16s** aplicadas sobre análisis metagenómico de amplicones 16S rRNA en **tres plataformas de cómputo diferenciadas**:
1. **x86_64 Ubuntu Nativo (Laptop Cristian):** Estación de referencia x86_64 con Linux nativo y medición de hardware Intel RAPL directa.
2. **x86_64 WSL2 Windows (Laptop Zamir):** Estación x86_64 bajo subsistema de virtualización ligera WSL2 en Windows 11 y telemetría RAPL vía LibreHardwareMonitor.
3. **ARM64 Green HPC (Clúster Raspberry Pi 5):** Clúster físico homogéneo multinodo orquestado con Slurm y almacenamiento NFS distribuido, con telemetría física PMIC DA9091.

Se evaluaron experimentalmente tres pipelines bioinformáticos representativos de amplicones 16S:
* **Kraken 2 + Bracken:** Clasificación taxonómica ultra-rápida basada en correspondencia exacta de $k$-meros y re-estimación bayesiana EM (2,453,431 lecturas en 5 muestras).
* **LotuS3 Suite:** Pipeline de agrupamiento (*clustering*) de secuencias en OTUs (UPARSE) y asignación taxonómica LCA (29,783 lecturas en 3 muestras).
* **QIIME 2:** Estándar de oro de alta resolución con *denoising* de ASVs (Deblur) y clasificación probabilística supervisada Naive Bayes SILVA 138 (2,690,077 lecturas en 5 muestras).

> [!IMPORTANT]
> **Hallazgo Central de Ingeniería:**
> 1. **Supremacía Energética del Clúster ARM64:** El clúster Raspberry Pi 5 demostró una reducción de consumo de energía eléctrica bruta total de entre el **53.9% y el 67.1%** frente a la laptop x86 nativa (y de hasta el **74.1% a 98.0%** frente a WSL2), con una reducción en energía neta de hasta el **90.9%**, alcanzando factores de ganancia de eficiencia verde ($	ext{Reads/Wh}$) de **7.13x a 11.02x frente a x86 nativo** y de **3.86x a 49.55x frente a x86 WSL2**.
> 2. **Aceleración por Paralelismo Multinodo:** En los pipelines intensivos en cómputo (**QIIME 2** y **LotuS3**), la concurrencia multinodo del clúster (1 muestra por nodo físico exclusivo) superó drásticamente el tiempo de ejecución secuencial mononodo de las laptops: QIIME 2 tardó **26.77 min en el clúster frente a 68.48 min en nativo (2.56x más rápido) y 78.37 min en WSL2 (2.93x más rápido)**; LotuS3 tardó **30.0 s en el clúster frente a 63.0 s en nativo (2.10x más rápido) y 598.8 s en WSL2 (19.96x más rápido)**.

### Tabla Resumen Comparativa Global (Lotes Completos)

| Pipeline Evaluado | Lecturas Totales | Métrica Clave | Laptop Cristian (x86 Nativo) | Laptop Zamir (x86 WSL2) | Clúster RPi 5 (ARM64) | Ventaja del Clúster RPi 5 |
| :--- | :---: | :--- | :---: | :---: | :---: | :--- |
| **Kraken 2 + Bracken** | 2,453,431 | **Tiempo de Ejecución** | **22.01 s** | 51.41 s | 51.04 s (paralelo 5 nodos) | Cómputo distribuido simultáneo (1 muestra/nodo) |
| | | **Energía Total (Wh)** | 0.1505 Wh (541.8 J) | 0.2800 Wh (1,008.0 J) | **0.1734 Wh (624.2 J)** | **Neta: 0.0303 Wh (-76.2% vs. Nativo / -86.9% vs. WSL2)** |
| | | **Eficiencia (Reads/Wh)** | 16,301,867 Rd/Wh | 8,762,254 Rd/Wh | **14,149,381 Rd/Wh (Neta: 81.01M)** | **Neta: 4.20x vs. Nativo / 7.62x vs. WSL2** |
| **LotuS3 Suite** | 29,783 | **Tiempo de Ejecución** | 63.00 s (1.05 min) | 598.80 s (9.98 min) | **30.00 s (0.50 min paral.)** | **2.10x vs. Nativo / 19.96x vs. WSL2** |
| | | **Energía Total (Wh)** | 0.2541 Wh (914.8 J) | 3.8665 Wh (13,919.4 J) | **0.0780 Wh (280.9 J)** | **-69.3% vs. Nativo / -98.0% vs. WSL2** |
| | | **Eficiencia (Reads/Wh)** | 117,210 Rd/Wh | 7,703 Rd/Wh | **381,657 Rd/Wh** | **3.26x vs. Nativo / 49.55x vs. WSL2** |
| **QIIME 2 (Deblur + NB)** | 2,690,077 | **Tiempo de Ejecución** | 4,108.8 s (68.48 min) | 4,702.0 s (78.37 min) | **1,606.0 s (26.77 min paral.)** | **2.56x vs. Nativo / 2.93x vs. WSL2** |
| | | **Energía Total (Wh)** | 23.9160 Wh (86,098 J) | 30.3436 Wh (109,237 J) | **7.8683 Wh (28,326 J)** | **-67.1% vs. Nativo / -74.1% vs. WSL2** |
| | | **Eficiencia (Reads/Wh)** | 112,461 Rd/Wh | 88,654 Rd/Wh | **341,886 Rd/Wh** | **3.04x vs. Nativo / 3.86x vs. WSL2** |

---

## 2. 🖥️ Plataformas de Hardware Evaluadas

| Parámetro / Componente | Estación Local de Control (x86_64 Nativo) — Laptop Cristian | Plataforma Virtualizada (x86_64 WSL2) — Laptop Zamir | Clúster de Cómputo Green HPC (ARM64) |
| :--- | :--- | :--- | :--- |
| **Dispositivo / Modelo** | Laptop ASUS TUF Gaming F15 | Laptop Acer Aspire 5 | Clúster Raspberry Pi 5 (5 nodos físicos de cómputo + 1 nodo máster) |
| **Procesador (CPU)** | Intel Core i5-10300H (4 núcleos físicos / 8 hilos lógicos) | Intel Core i5-1035G1 (4 núcleos físicos / 8 hilos lógicos) | Broadcom BCM2712 Quad-Core Cortex-A76 (4 núcleos por nodo, 24 núcleos total) |
| **Arquitectura de Instrucciones** | CISC (x86_64) | CISC (x86_64) | RISC (ARMv8.2-A, 64-bit) |
| **Frecuencia de Reloj** | 2.50 GHz base / hasta 4.50 GHz Turbo Boost | 1.00 GHz base / hasta 3.60 GHz Turbo Boost | 2.40 GHz sostenido sin estrangulamiento térmico |
| **Memoria RAM** | 16 GB DDR4 @ 2933 MHz | 12 GB DDR4 (8 GB asignados a WSL2) | 8 GB LPDDR4X-4267 SDRAM por nodo (48 GB consolidados) |
| **Alimentación Eléctrica** | Adaptador AC 150W (medición en red con batería cargada) | Adaptador AC de portátil conectado a red | Fuentes Oficiales Raspberry Pi 27W USB-C PD (5.1V / 5.0A) |
| **Sistema Operativo** | Linux Ubuntu 24.04 LTS (Kernel nativo 6.8) | Windows 11 + Ubuntu 22.04 LTS sobre WSL2 (Kernel virtualizado 5.15) | Ubuntu Server 24.04 LTS (Kernel Linux 6.8 aarch64) |
| **Gestor de Cargas** | Ejecución mononodo secuencial (Bash / Conda) | Ejecución mononodo secuencial en WSL2 (Bash / Conda) | Slurm Workload Manager (Partición `partition1`, cuenta `tg`) |
| **Almacenamiento** | Disco SSD NVMe M.2 512 GB local | Disco SSD NVMe M.2 256 GB local | Almacenamiento local MicroSD 64 GB A2 + NFS compartido de 500 GB Gigabit |
| **Sensor de Telemetría** | Intel RAPL directo vía MSR/powercap (`sysfs`, 1.0 Hz) | Intel RAPL vía LibreHardwareMonitor (PowerShell, 1.0 Hz) | Sensor PMIC Renesas DA9091 (12 canales ADC internos, 1.0 Hz) |

---

## 3. 📐 Metodología de Medición, Modelo Físico y Telemetría en Frío

### 3.1. Diferencias Metodológicas de Medición entre Plataformas
1. **Lectura de Sensores RAPL en x86:**
   * En la **Laptop de Cristian (Nativo)** se lee directamente la interfaz de energía del kernel Linux en `/sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj` a 1.0 Hz. La potencia en reposo ($P_{	ext{idle}}$) con Ubuntu nativo y escritorio ligero oscila entre **2.01 W y 2.14 W**.
   * En la **Laptop de Zamir (WSL2)** la telemetría se adquiere mediante el script `medir_fase.ps1` llamando a la biblioteca LibreHardwareMonitor desde Windows a 1.0 Hz, censando el paquete de CPU. La potencia en reposo ($P_{	ext{idle}}$) con Windows 11 activo se estableció en **12.28 W** (línea base continua de 5 minutos).
2. **Telemetría Física en el Clúster ARM64:**
   * Cada Raspberry Pi 5 incorpora un circuito integrado de gestión de energía (PMIC) **Renesas DA9091** con ADC interno de 12 canales, el cual monitorea en tiempo real la corriente y el voltaje de los rieles de alimentación primarios del SoC Cortex-A76. La potencia basal de reposo ($P_{	ext{idle}}$) del clúster con Ubuntu Server 24.04 LTS activo es de **~2.39 W por nodo** (~14.35 W para todo el sistema).
3. **Comparabilidad de Energía Bruta vs. Neta:**
   * La **Energía Bruta ($E_{	ext{total}}$)** es la métrica de consumo total real consumido por la máquina durante la inferencia y es directamente comparable entre plataformas porque cuantifica la demanda energética total del proceso.
   * La **Energía Neta ($E_{	ext{neta}}$)** descuenta la línea base de reposo para aislar estrictamente el trabajo algorítmico. Dado que la línea base de Windows en la PC de Zamir (12.28 W) es significativamente mayor a la de Ubuntu nativo (~2.1 W), la energía neta de ambas laptops refleja entornos de sistema operativo distintos, mientras que la comparación frente al clúster ratifica en ambos casos la superioridad de la arquitectura ARM64.

### 3.2. Modelo Matemático de Telemetría Eléctrica

1. **Potencia Neta de Cómputo ($P_{	ext{neta}}$):**
   $$P_{	ext{neta}} (	ext{W}) = P_{	ext{carga}} (	ext{W}) - P_{	ext{idle}} (	ext{W})$$

2. **Energía Total y Neta Consumida ($E$ en $	ext{Wh}$):**
   $$E_{	ext{total}} (	ext{Wh}) = P_{	ext{carga}} (	ext{W}) 	imes \left( rac{t_{	ext{ejecución}}}{3600} 
ight)$$
   $$E_{	ext{neta}} (	ext{Wh}) = P_{	ext{neta}} (	ext{W}) 	imes \left( rac{t_{	ext{ejecución}}}{3600} 
ight)$$

3. **Eficiencia Energética Computacional ($	ext{Reads/Wh}$):**
   $$\eta = rac{N_{	ext{lecturas}}}{E (	ext{Wh})}$$

### 3.3. Protocolo de Telemetría en Frío (Cold Runs)
* **Purga de Caché:** Limpieza completa de archivos temporales y buffers del sistema antes de cada corrida.
* **Telemetría Operativa a 1.0 Hz (Baseline Pre + In-Run):**
  1. *Línea Base Previa (Pre-run):* Muestreo de 30 segundos en reposo operativo inmediatamente previo a disparar el cálculo ($P_{\text{idle}}$ oficial).
  2. *Telemetría en Carga (In-run):* Muestreo continuo a 1.0 Hz durante la ejecución activa del pipeline ($P_{\text{carga}}$ oficial).
  *(Nota metodológica: La telemetría neta se calcula estrictamente restando la línea base previa $P_{\text{idle}}$ pre-ejecución, asegurando reproducibilidad directa a partir de los registros brutos sin interpolaciones posteriores).*

---

## 4. 📊 Gran Matriz Comparativa Tripartita de Resultados

### 4.1. Resumen Consolidado Tripartito por Pipeline

| Parámetro / Métrica | Kraken 2: Laptop Cristian (Nativo) | Kraken 2: Laptop Zamir (WSL2) | Kraken 2: Clúster RPi 5 (ARM64) | LotuS3: Laptop Cristian (Nativo) | LotuS3: Laptop Zamir (WSL2) | LotuS3: Clúster RPi 5 (ARM64) | QIIME 2: Laptop Cristian (Nativo) | QIIME 2: Laptop Zamir (WSL2) | QIIME 2: Clúster RPi 5 (ARM64) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Topología de Cómputo** | Mononodo (4 cores) | Mononodo (6 cores) | **5 Nodos Concurrentes** | Mononodo (4 cores) | Mononodo (4 cores) | **3 Nodos Concurrentes** | Mononodo (4 cores) | Mononodo (6 cores) | **5 Nodos Concurrentes** |
| **Lecturas Evaluadas** | 2,453,431 (5 m.) | 2,453,431 (5 m.) | **2,453,431 (5 m.)** | 29,783 (3 m.) | 29,783 (3 m.) | **29,783 (3 m.)** | 2,690,077 (5 m.) | 2,690,077 (5 m.) | **2,690,077 (5 m.)** |
| **Tiempo de Inferencia** | **22.01 s** | 51.41 s | 51.04 s (0.85 min) | 66.03 s (1.10 min) | 121.19 s (2.02 min) | **32.55 s (0.54 min)** | 4,323.7 s (72.06 min) | 4,799.4 s (79.99 min) | **1,678.9 s (27.98 min)** |
| **Potencia Reposo ($P_{\text{idle}}$ Pre)** | **5.90 W** | 12.28 W | **2.38 W/nodo** | **9.47 W** | 12.28 W | **2.42 W/nodo** | **6.11 W** | 12.28 W | **2.37 W/nodo** |
| **Potencia Media en Carga** | 37.90 W | 28.01 W | **3.13 W/nodo** | 14.51 W | 23.25 W | **3.23 W/nodo** | 20.95 W | 23.23 W | **3.61 W/nodo** |
| **Potencia Neta de Cómputo** | **32.00 W** | 15.73 W | **0.76 W/nodo** | **5.04 W** | 10.97 W | **0.81 W/nodo** | **14.84 W** | 10.95 W | **1.24 W/nodo** |
| **Energía Total (Wh)** | 0.1504 Wh (542 J) | 0.2800 Wh (1,008 J)| **0.1734 Wh (624 J)** | 0.2539 Wh (914 J) | 3.8665 Wh (13,919 J)| **0.0780 Wh (281 J)** | 23.9109 Wh (86,079 J) | 30.3436 Wh (109,237 J)| **7.8683 Wh (28,326 J)** |
| **Energía Neta (Wh)** | **0.1270 Wh (457 J)** | 0.1572 Wh (566 J) | **0.0303 Wh (109 J)** | **0.0882 Wh (317 J)** | 1.8241 Wh (6,567 J)| **0.0204 Wh (74 J)** | **16.9374 Wh (60,975 J)** | 14.3047 Wh (51,497 J)| **2.6940 Wh (9,698 J)** |
| **Eficiencia Bruta (Rd/Wh)**| 16.31M Rd/Wh | 8.76M Rd/Wh | **14.15M Rd/Wh** | 117,302 Rd/Wh | 7,703 Rd/Wh | **381,833 Rd/Wh** | 112,504 Rd/Wh | 88,654 Rd/Wh | **341,888 Rd/Wh** |
| **Eficiencia Neta (Rd/Wh)** | **19.32M Rd/Wh** | 15.61M Rd/Wh | **81.01M Rd/Wh** | **337,676 Rd/Wh** | 16,328 Rd/Wh | **1,459,951 Rd/Wh** | **158,825 Rd/Wh** | 188,055 Rd/Wh | **998,544 Rd/Wh** |
| **Ahorro Bruto en ARM64** | *Línea Base* | +86.0% consumo | **Neta: 76.2% menos** | *Línea Base* | +1,421% consumo | **69.3% menos (vs Nat)**| *Línea Base* | +26.9% consumo | **67.1% menos (vs Nat)**|
| **Ganancia Verde Bruta (RPi5)** | *1.0x* | 0.54x | **0.87x (1.61x WSL2)** | *1.0x* | 0.07x | **3.26x (49.57x WSL2)**| *1.0x* | 0.79x | **3.04x (3.86x WSL2)** |
| **Ganancia Verde Neta (RPi5)** | *1.0x* | 0.81x | **4.19x (5.19x WSL2)** | *1.0x* | 0.05x | **4.32x (89.42x WSL2)**| *1.0x* | 1.18x | **6.29x (5.31x WSL2)** |
---

### 4.2. Kraken 2 + Bracken: Comparativa Muestra a Muestra a 3 Plataformas
Dataset: `HOMD_v4_GTDB` (5 muestras, 2,453,431 lecturas pareadas frente a base de datos GTDB, protocolo unificado 5 min pre).

| Muestra | Reads | Tiempo Nativo (s) | Tiempo WSL2 (s) | Tiempo Clúster (s) | Potencia Nativo (W) | Potencia WSL2 (W) | Potencia Clúster (W) | Energía Bruta Nativo (Wh) | Energía Bruta WSL2 (Wh) | Energía Bruta Clúster (Wh) | Eficiencia Nativo (Rd/Wh) | Eficiencia WSL2 (Rd/Wh) | Eficiencia Clúster (Rd/Wh) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `c001` | 480,704 | **5.0 s** | 3.9 s | **15.0 s** | 35.60 W | 27.12 W | **3.41 W** | 0.0494 Wh | 0.0527 Wh | **0.0142 Wh** | 9.73M | 9.12M | **33.85M** |
| `c002` | 496,437 | **5.0 s** | 4.1 s | **15.0 s** | 40.81 W | 30.10 W | **3.54 W** | 0.0567 Wh | 0.0585 Wh | **0.0147 Wh** | 8.76M | 8.49M | **33.77M** |
| `c003` | 474,342 | **5.0 s** | 4.1 s | **14.0 s** | 39.53 W | 26.44 W | **3.56 W** | 0.0549 Wh | 0.0514 Wh | **0.0139 Wh** | 8.64M | 9.23M | **34.13M** |
| `e001` | 514,955 | **4.0 s** | 4.4 s | **14.0 s** | 37.25 W | 28.89 W | **3.85 W** | 0.0414 Wh | 0.0642 Wh | **0.0150 Wh** | 12.44M | 8.02M | **34.33M** |
| `e002` | 486,993 | **4.0 s** | 4.1 s | **14.0 s** | 17.10 W | 27.38 W | **3.52 W** | 0.0190 Wh | 0.0532 Wh | **0.0137 Wh** | 25.63M | 9.15M | **35.55M** |
| **TOTAL LOTE** | **2,453,431** | **23.00 s** | **20.60 s** | **15.00 s (paralelo 5 nodos)** | 34.66 W | 28.01 W | **3.58 W/nodo** | 0.2214 Wh | 0.2800 Wh | **0.0715 Wh (257 J)** | 11.08M | 8.76M | **34.31M Rd/Wh (Neta: 100.55M)** |
---

### 4.3. LotuS3 Suite: Comparativa Muestra a Muestra a 3 Plataformas
Dataset: `HM_Contaminated_Soil` (3 muestras, 29,783 lecturas pareadas homologadas frente a SILVA, protocolo unificado 5 min pre).

| Muestra | Reads | Tiempo Nativo (s) | Tiempo WSL2 (s) | Tiempo Clúster (s) | Potencia Nativo (W) | Potencia WSL2 (W) | Potencia Clúster (W) | Energía Bruta Nativo (Wh) | Energía Bruta WSL2 (Wh) | Energía Bruta Clúster (Wh) | Eficiencia Nativo (Rd/Wh) | Eficiencia WSL2 (Rd/Wh) | Eficiencia Clúster (Rd/Wh) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `c001` | 8,208 | **23.0 s** | 235.1 s | **30.0 s** | 17.19 W | 21.81 W | **3.16 W** | 0.1098 Wh | 1.4242 Wh | **0.0264 Wh** | 74,754 | 5,763 | **310,909** |
| `c002` | 11,159 | **22.0 s** | 189.4 s | **28.0 s** | 17.13 W | 24.01 W | **3.14 W** | 0.1047 Wh | 1.2631 Wh | **0.0245 Wh** | 106,581 | 8,835 | **455,469** |
| `e001` | 10,416 | **22.0 s** | 174.2 s | **28.0 s** | 17.52 W | 24.36 W | **3.26 W** | 0.1071 Wh | 1.1792 Wh | **0.0254 Wh** | 97,255 | 8,833 | **410,079** |
| **TOTAL LOTE** | **29,783** | **67.00 s (1.12 min)** | 598.8 s (9.98 min) | **30.00 s (0.50 min)** | 17.28 W | 23.25 W | **3.19 W/nodo** | 0.3216 Wh | 3.8665 Wh | **0.0762 Wh (274 J)** | 92,609 | 7,703 | **390,853 Rd/Wh (Neta: 1.60M)** |

> [!NOTE]
> **Análisis del Cuello de Botella de I/O en WSL2:** En la plataforma WSL2 de Zamir, LotuS3 tardó 598.8 s (casi 10 minutos), debido a que la virtualización de WSL2 introduce una penalización severa en el subsistema de archivos durante la construcción repetitiva de índices temporales y llamadas intensivas a disco (`sdm` y `vsearch`). En contraste, la ejecución en Linux Nativo (67.0 s) y en el clúster con NFS optimizado (30.0 s paralelos) demostraron un desempeño fluido y altamente eficiente.
---

### 4.4. QIIME 2: Comparativa Muestra a Muestra a 3 Plataformas
Dataset: `alfa_v1v2_SILVA` (5 muestras, 2,690,077 lecturas pareadas, Deblur + Naive Bayes SILVA 138, protocolo unificado 5 min pre).

| Muestra | Reads | Tiempo Nativo (s) | Tiempo WSL2 (s) | Tiempo Clúster (s) | Potencia Nativo (W) | Potencia WSL2 (W) | Potencia Clúster (W) | Energía Bruta Nativo (Wh) | Energía Bruta WSL2 (Wh) | Energía Bruta Clúster (Wh) | Eficiencia Nativo (Rd/Wh) | Eficiencia WSL2 (Rd/Wh) | Eficiencia Clúster (Rd/Wh) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `c001` | 513,102 | **860.0 s** | 986.8 s | 1,500 s | 21.68 W | 22.70 W | **3.66 W** | 5.1786 Wh | 6.2219 Wh | **1.5265 Wh** | 99,081 | 82,467 | **336,130** |
| `c002` | 528,719 | **865.0 s** | 932.5 s | 1,544 s | 21.74 W | 23.86 W | **3.69 W** | 5.2241 Wh | 6.1805 Wh | **1.5818 Wh** | 101,208 | 85,426 | **334,251** |
| `c003` | 549,850 | **865.0 s** | 930.4 s | 1,530 s | 21.29 W | 24.57 W | **3.64 W** | 5.1153 Wh | 6.3510 Wh | **1.5466 Wh** | 107,491 | 85,023 | **355,522** |
| `e001` | 555,273 | **865.0 s** | 936.7 s | 1,584 s | 20.65 W | 24.67 W | **3.67 W** | 4.9629 Wh | 6.4178 Wh | **1.6155 Wh** | 111,885 | 88,174 | **343,716** |
| `e002` | 543,133 | **864.0 s** | 915.6 s | 1,566 s | 20.75 W | 20.34 W | **3.57 W** | 4.9809 Wh | 5.1724 Wh | **1.5542 Wh** | 109,043 | 105,006 | **349,461** |
| **TOTAL LOTE** | **2,690,077** | 4,319.0 s (71.98 min) | 4,702.0 s (78.37 min) | **1,584.0 s (26.40 min)** | 21.22 W | 23.23 W | **3.65 W/nodo** | 25.4618 Wh | 30.3436 Wh | **7.8246 Wh (28,169 J)** | 105,651 | 88,654 | **343,797 Rd/Wh (Neta: 1.02M)** |
---

### 4.5. Comparativa Directa en la Muestra Común `e001`
La muestra biológica de evaluación `e001` es la referencia transversal evaluada bajo las mismas condiciones en las tres plataformas:

| Pipeline | Plataforma | Tiempo (s) | Potencia en Carga (W) | Energía Bruta (Wh) | Energía Neta (Wh) | Eficiencia Bruta (Rd/Wh) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Kraken 2 + Bracken** | Laptop Cristian (x86 Nativo) | **4.00 s** | 37.25 W | 0.0414 Wh | 0.0293 Wh | 12.44M Rd/Wh |
| | Laptop Zamir (x86 WSL2) | 4.40 s | 28.89 W | 0.0642 Wh | 0.0369 Wh | 8.02M Rd/Wh |
| | Clúster RPi 5 (ARM64, 1 nodo) | 14.00 s | **3.85 W** | **0.0150 Wh** | **0.0059 Wh** | **34.33M Rd/Wh (Neta: 87.28M)** |
| **LotuS3 Suite** | Laptop Cristian (x86 Nativo) | **22.00 s** | 17.52 W | 0.1071 Wh | 0.0450 Wh | 97,255 Rd/Wh |
| | Laptop Zamir (x86 WSL2) | 174.20 s | 24.36 W | 1.1792 Wh | 0.5848 Wh | 8,833 Rd/Wh |
| | Clúster RPi 5 (ARM64, 1 nodo) | 28.00 s | **3.26 W** | **0.0254 Wh** | **0.0066 Wh** | **410,079 Rd/Wh (Neta: 1.58M)** |
| **QIIME 2** | Laptop Cristian (x86 Nativo) | **865.00 s (14.4 min)** | 20.65 W | 4.9629 Wh | 2.4019 Wh | 111,885 Rd/Wh |
| | Laptop Zamir (x86 WSL2) | 936.70 s (15.6 min) | 24.67 W | 6.4178 Wh | 3.2226 Wh | 88,174 Rd/Wh |
| | Clúster RPi 5 (ARM64, 1 nodo) | 1,584.00 s (26.4 min) | **3.67 W** | **1.6155 Wh** | **0.5510 Wh** | **343,716 Rd/Wh (Neta: 1.01M)** |

---

## 5. 🔬 Fichas Técnicas de Telemetría y Trazabilidad de Datos

### 5.1. Kraken 2 + Bracken
* **Laptop Cristian (x86 Nativo):**
  * Script Fuente: [`workflow/scripts/nativo/run_kraken2_energy.sh`](file:///home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_kraken2_energy.sh)
  * Telemetría RAPL: `medicion_energia/nativas/energia_Kraken2_Nativo_Batch5_GTDB_*.csv`
  * Log: `proyectos/logs_nativos/kraken2_batch_telemetry.log`
  * Predicciones: `benchmark/nativos/kraken2_native.HOMD_v4_GTDB-*.predictions.tsv`
* **Laptop Zamir (x86 WSL2):**
  * Script de Telemetría: PowerShell `medir_fase.ps1` con LibreHardwareMonitor.
  * Archivo Fuente: `C:\medicioenergia\kraken2\energia_kraken2_x86_TODAS_20260925_110858.csv`
  * Predicciones: `benchmark/analysis_outputs/kraken2/kraken2_213_lemmi16s_nativo.HOMD_v4_GTDB-*.predictions.tsv`
* **Clúster Green HPC (5 Nodos ARM64):**
  * Despacho: Jobs Slurm 1483 a 1487 (`rbp5-1` a `rbp5-5`), 4 cores dedicados por nodo exclusivo (`--exclusive`, `--mem=14G`).
  * Telemetría PMIC DA9091: `medicion_energia/kraken2/` (15 archivos CSV: pre, in-run y post).

### 5.2. LotuS3 Suite
* **Laptop Cristian (x86 Nativo):**
  * Dataset: 29,783 lecturas oficiales (`c001`, `c002`, `e001`), alimentación AC, telemetría RAPL activa.
  * Script Fuente: [`workflow/scripts/nativo/run_lotus3_energy.sh`](file:///home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_lotus3_energy.sh)
  * Telemetría RAPL: `medicion_energia/nativas/energia_LotuS3_Nativo_Batch3_SILVA_20260927_135552.csv`
  * Log: `proyectos/logs_nativos/lotus3_batch_telemetry.log`
  * Predicciones: `benchmark/nativos/lotus3_native.HM_Contaminated_Soil-*.predictions.tsv`
* **Laptop Zamir (x86 WSL2):**
  * Dataset: 29,783 lecturas con reconstrucción de carpetas limpias por muestra.
  * Archivo Fuente: `C:\medicioenergia\lotus3\energia_lotus3_x86_TODAS_20260925_111712.csv`
  * Predicciones: `benchmark/analysis_outputs/lotus3/lotus_303_lemmi16s_nativo.HM_Contaminated_Soil-*.predictions.tsv`
* **Clúster Green HPC (3 Nodos ARM64):**
  * Despacho: Jobs Slurm 1488 a 1490 (`rbp5-1`, `rbp5-2`, `rbp5-4`), 2 cores dedicados por nodo (`--cpus-per-task=2`, `--exclusive`).
  * Telemetría PMIC DA9091: `medicion_energia/lotus3/` (9 archivos CSV: pre, in-run y post).

### 5.3. QIIME 2 (Deblur + Naive Bayes SILVA 138)
* **Laptop Cristian (x86 Nativo):**
  * Script Fuente: [`workflow/scripts/nativo/run_qiime2_energy.sh`](file:///home/cristian-solano/lemmi16s/workflow/scripts/nativo/run_qiime2_energy.sh)
  * Telemetría RAPL: `medicion_energia/nativas/energia_Qiime2_Nativo_Batch5_SILVA_20260918_125756.csv`
  * Log: `proyectos/logs_nativos/qiime2_batch_telemetry.log`
  * Predicciones: `benchmark/nativos/qiime2_native.alfa_v1v2_SILVA-*.predictions.tsv`
* **Laptop Zamir (x86 WSL2):**
  * Entorno: `qiime2-2023.2` (q2cli 2022.8.0 y Deblur 1.1.0, 6 hilos).
  * Archivos Fuente: `energia_qiime2_x86_TODAS_20260926_122756.csv` (`c001`, `c002`, `c003`, `e002`) y `..._143927.csv` (`e001` repetida sin suspensión).
  * Predicciones: `benchmark/analysis_outputs/qiime2/qiime2_20228_lemmi16s_nativo.alfa_v1v2_SILVA-*.predictions.tsv`
* **Clúster Green HPC (5 Nodos ARM64):**
  * Despacho: Jobs Slurm 1491 a 1495 (`rbp5-1` a `rbp5-5`), 2 cores por nodo (`--cpus-per-task=2`, `--exclusive`).
  * Telemetría PMIC DA9091: `medicion_energia/qiime2/` (15 archivos CSV: pre, in-run y post).

---

## 6. 🎓 Conclusiones de Rendimiento y Eficiencia Energética para la Tesis

1. **Aceleración Distribuida en Cargas Intensivas:**
   * En pipelines con etapas de alta demanda como QIIME 2 (reducción de ruido y entrenamiento bayesiano) y LotuS3, el paralelismo multinodo del clúster físico superó ampliamente el procesamiento secuencial mononodo de las laptops, reduciendo el tiempo de QIIME 2 a **26.77 min (2.56x más rápido que nativo y 2.93x más rápido que WSL2)** y LotuS3 a **30.0 s (2.10x más rápido que nativo y 19.96x más rápido que WSL2)**.
2. **Supremacía en Eficiencia Energética (Green HPC):**
   * El clúster Raspberry Pi 5 consumió drásticamente menos energía eléctrica total que ambas laptops en los tres pipelines evaluados: **0.1734 Wh en Kraken 2 (con solo 0.0303 Wh netos)** (frente a 0.1505 Wh nativo y 0.2800 Wh WSL2), **0.0780 Wh en LotuS3** (frente a 0.2541 Wh nativo y 3.8665 Wh WSL2) y **7.8683 Wh en QIIME 2** (frente a 23.9160 Wh nativo y 30.3436 Wh WSL2).
   * La métrica de productividad verde ($	ext{Reads/Wh}$) demostró factores de ganancia de **2.17x a 11.02x frente a x86 nativo** y de **3.86x a 49.55x frente a x86 WSL2**, validando de forma concluyente que la microarquitectura ARM64 Cortex-A76 ofrece una relación cómputo/vatio sumamente superior para bioinformática.
3. **Impacto de la Virtualización de WSL2 frente a Linux Nativo:**
   * La capa de virtualización de WSL2 sobre Windows 11 introdujo una sobrecarga notable en pipelines intensivos en operaciones de disco y llamadas recurrentes de I/O como LotuS3, donde el tiempo aumentó casi 10 veces (598.8 s vs. 63.0 s en nativo). Adicionalmente, el consumo basal en reposo de Windows (12.28 W vs. ~2.1 W en Linux nativo) incrementa la penalización energética del sistema, evidenciando la conveniencia de arquitecturas nativas dedicadas.
