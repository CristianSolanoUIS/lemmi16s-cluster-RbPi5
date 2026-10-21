# Libro del proyecto, datos de energía y análisis

Esta carpeta contiene el libro aprobado del trabajo de grado y todo lo necesario para reproducir sus tablas y figuras: los datos crudos de energía de las tres plataformas, la prueba HPL y los scripts de cálculo y graficación.

**Trabajo de grado:** *Implementación y análisis del desempeño de un pipeline para el estudio de amplicones 16S en un clúster energéticamente eficiente basado en Raspberry Pi 5*
**Autores:** Cristian Alberto Solano Torres y Zamir Francisco Granados Peñaloza
**Director:** Bernardo Andrés Benavides Arévalo, PhD
**Escuela de Ingeniería de Sistemas e Informática · Universidad Industrial de Santander · 2026**

---

## Contenido

```text
libro/
├── LibroAmpliconesRBPI5.pdf      # Libro aprobado (versión final)
├── Sustentacion_RBPi5.pdf        # Diapositivas de la sustentación
├── main.tex                      # Código LaTeX del libro
├── references.bib                # Bibliografía
├── figuras/                      # Figuras del libro (las usa main.tex)
├── datos_energia/                # Telemetría cruda a 1 Hz
│   ├── cluster_rpi5/             # Clúster, 5 nodos (PMIC): kraken2, lotus3, qiime2, hpl, reposo_5min
│   ├── cluster_rpi5_mononodo/    # Clúster, ejecución secuencial en 1 nodo
│   ├── x86_pc_cristian/          # x86 nativo, Ubuntu 24.04 (RAPL vía sysfs)
│   └── x86_pc_zamir/             # x86 con WSL2 (RAPL vía LibreHardwareMonitor)
├── resultados/                   # Tablas finales usadas en el libro
│   ├── flops_energia.csv         # HPL: GFLOPS, potencia y GFLOPS/W por equipo
│   ├── flops_energia_repeticion.csv
│   ├── resumen_mononodo_vs_multinodo.csv / .txt
│   ├── f1_corregido_kraken2_qiime2.txt
│   ├── resumen_lotus3_pacbio.csv
│   └── ...
└── scripts/
    ├── medicion/                 # Scripts de medición por plataforma (cluster, x86, HPL)
    ├── calculos/                 # Energía por la regla del trapecio, F1, HPL, mononodo
    ├── graficas/                 # Figuras del libro (matplotlib)
    └── excel/                    # Generación de los libros Excel con las gráficas
```

## Plataformas comparadas

| Plataforma | Hardware | Medición de energía |
| :--- | :--- | :--- |
| Clúster RBPi5 | 5 × Raspberry Pi 5 (Cortex-A76 a 2.4 GHz, 16 GB), maestro Raspberry Pi 4B (8 GB), Slurm 23.11, NFSv4 | PMIC Renesas DA9091 (placa completa), 1 Hz |
| x86 nativo | Intel Core i5-10300H, 16 GB, Ubuntu 24.04 | Intel RAPL `package-0` (sysfs), 1 Hz |
| x86 WSL2 | Mismo modelo de i5, Windows 11 + WSL2 | Intel RAPL vía LibreHardwareMonitor, 1 Hz |

## Protocolo de medición

1. 60 s de estabilización.
2. 5 min de reposo para obtener la potencia basal (`P_idle`).
3. Ejecución del pipeline con registro de potencia a 1 Hz.

- **Energía total:** integral de la potencia por la regla del trapecio, `E_total = Σ ½ (P_i + P_{i+1}) · Δt`.
- **Energía neta:** `E_neta = E_total − P_idle · t`.
- **Eficiencia:** `η = lecturas / Wh` (calculada con energía total).

El PMIC mide la placa completa y RAPL solo el procesador, por lo que la comparación favorece al x86.

## Resultados principales (5 nodos frente a x86 nativo)

| Pipeline | Tiempo x86 · clúster | Energía neta x86 · clúster | Factor neto | Lecturas/Wh clúster (total) |
| :--- | :--- | :--- | :--- | :--- |
| Kraken 2 + Bracken | 22.01 s · 51.04 s | 0.1518 · 0.0398 Wh | 3.81× | 12.1 M |
| LotuS3 (PacBio HiFi) | 31.65 · 32.87 min | 15.65 · 7.33 Wh | 2.14× | 2,129 |
| QIIME 2 | 72.06 · 27.98 min | 12.70 · 2.78 Wh | 4.57× | 324,561 |

**HPL (N = 30,000, NB = 192, P × Q = 2 × 2, HPL 2.3):** clúster 134.86 GFLOPS (suma de 5 corridas independientes, una por nodo), x86 nativo 177.36 y WSL2 129.07. Eficiencia bruta: 3.25, 4.08 y 3.23 GFLOPS/W. Todas las corridas pasaron la verificación del residuo.

## Cómo reproducir

- **Libro:** compilar `main.tex` con pdfLaTeX + BibTeX desde esta carpeta (las figuras se leen de `figuras/`).
- **Cálculos y gráficas:** los scripts de `scripts/calculos/` y `scripts/graficas/` usan rutas relativas a esta carpeta.
- **Excel:** los scripts de `scripts/excel/` tienen la ruta base en la variable `BASE` (o `$X` / `$F` en `exportar_figuras.ps1`); ajústela a la ubicación de esta carpeta antes de ejecutarlos.
