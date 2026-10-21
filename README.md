# Pipelines de amplicones 16S en un clúster Raspberry Pi 5

Trabajo de grado de Ingeniería de Sistemas e Informática, Universidad Industrial de Santander (2026).

- **Título:** Implementación y análisis del desempeño de un pipeline para el estudio de amplicones 16S en un clúster energéticamente eficiente basado en Raspberry Pi 5.
- **Autores:** Cristian Alberto Solano Torres y Zamir Francisco Granados Peñaloza
- **Director:** Bernardo Andrés Benavides Arévalo, PhD

El libro aprobado está en [`docs/LibroAmpliconesRBPI5.pdf`](docs/LibroAmpliconesRBPI5.pdf) y las diapositivas de la sustentación en [`docs/Sustentacion_RBPi5.pdf`](docs/Sustentacion_RBPi5.pdf).

En este repositorio están los scripts, los datos de energía y los resultados con los que se comparó el desempeño y el consumo de tres pipelines 16S (Kraken 2 + Bracken, LotuS3 y QIIME 2) en un clúster de cinco Raspberry Pi 5 frente a dos computadores x86.

---

## Estructura

```text
├── resultados/        Resultados finales por pipeline (los del libro)
│   ├── kraken2/
│   ├── lotus3_pacbio/
│   ├── qiime2/
│   ├── hpl/
│   └── comparaciones/  F1 corregido, concordancia entre plataformas y 1 nodo vs 5 nodos
├── datos_energia/     Telemetría cruda a 1 Hz de las tres plataformas
├── scripts/
│   ├── cluster/       Ejecución en el clúster con Slurm (5 nodos y 1 nodo)
│   ├── medicion/      Medición de energía (PMIC, RAPL, LibreHardwareMonitor) y HPL
│   └── evaluacion/    Evaluación con LEMMI16s
├── analisis/          Cálculo de energía, F1 y HPL; gráficas y Excel del libro
├── docs/              Libro (PDF y LaTeX), diapositivas y guías de instalación
├── environments/      Entornos Conda para ARM64
├── build/             usearch12 y LCA compilados para ARM64
└── soporte/           Logs de Slurm y salidas completas de LEMMI16s (respaldo)
```

Cada carpeta tiene su propio README.

---

## Plataformas

| Plataforma | Hardware | Medición de energía |
| :--- | :--- | :--- |
| Clúster RBPi5 | 5 Raspberry Pi 5 (Cortex-A76 a 2.4 GHz, 16 GB cada una; 20 núcleos y 80 GB en total) de los 10 nodos del clúster. Nodo maestro Raspberry Pi 4B de 8 GB con Slurm 23.11 y NFSv4 en `/shared`. Switch Gigabit en estrella, microSD de 64 GB por nodo y fuente oficial de 27 W por nodo | PMIC Renesas DA9091, placa completa, 1 Hz |
| x86 nativo | Intel Core i5-10300H, 16 GB DDR4, SSD NVMe, Ubuntu 24.04 | Intel RAPL `package-0` vía sysfs, 1 Hz |
| x86 WSL2 | Mismo modelo de i5, Windows 11 + WSL2 | Intel RAPL vía LibreHardwareMonitor, 1 Hz |

En reposo, cada Raspberry Pi 5 consume 2.38 W (11.90 W los cinco nodos).

## Datos

Muestras sintéticas generadas con LEMMI16s, cinco por pipeline (tres de calibración y dos de evaluación), con composición conocida (Ground Truth) e idénticas en las tres plataformas (verificado con MD5).

| Pipeline | Dataset | Tecnología | Lecturas |
| :--- | :--- | :--- | :--- |
| Kraken 2 + Bracken | `HOMD_v4_GTDB` (microbioma oral) | Illumina MiSeq, pareadas de 200 pb | 2,453,431 |
| LotuS3 | `HM_Contaminated_Soil_PacBio` (suelo con metales pesados) | PacBio HiFi, gen 16S completo | 25,611 |
| QIIME 2 | `alfa_v1v2_SILVA` (regiones V1–V2) | Illumina, pareadas | 2,690,077 |

## Portabilidad a ARM64

Los contenedores de LEMMI16s no eran portables al clúster, así que los tres pipelines se instalaron de forma nativa con entornos Conda para aarch64 (`environments/`). LAMBDA3 no existe para ARM64, por lo que LotuS3 asigna la taxonomía con VSEARCH y se compiló usearch12 (`build/`). En QIIME 2, la base SILVA completa no cabe en 16 GB, así que se recortó a las regiones V1–V2 (unas 62,000 secuencias). Las versiones de los paquetes son las mismas en las tres plataformas.

## Protocolo de medición

1. 60 s de estabilización.
2. 5 min de reposo para obtener la potencia basal (`P_idle`).
3. Ejecución del pipeline con registro de potencia a 1 Hz.

- Energía total: `E_total = Σ ½ (P_i + P_{i+1}) · Δt` (regla del trapecio).
- Energía neta: `E_neta = E_total − P_idle · t`.
- Eficiencia: lecturas / Wh, con energía total.

El PMIC mide la placa completa y RAPL solo el procesador, así que la comparación favorece al x86.

---

## Resultados (clúster de 5 nodos frente a x86 nativo)

| Pipeline | Tiempo x86 · clúster | Energía neta x86 · clúster | Menos energía neta | Lecturas/Wh x86 · clúster |
| :--- | :--- | :--- | :--- | :--- |
| Kraken 2 + Bracken | 22.01 s · 51.04 s | 0.1518 · 0.0398 Wh | 3.81× | 11.2 M · 12.1 M |
| LotuS3 (PacBio) | 31.65 · 32.87 min | 15.65 · 7.33 Wh | 2.14× | 1,494 · 2,129 |
| QIIME 2 | 72.06 · 27.98 min | 12.70 · 2.78 Wh | 4.57× | 105,518 · 324,561 |

- QIIME 2 es 2.58× más rápido en el clúster y escala 5.00× de 1 a 5 nodos.
- En Kraken 2 y LotuS3 el tiempo del clúster quedó limitado por la lectura simultánea de la base de referencia desde NFS por la red Gigabit.
- Las taxonomías son las mismas en las tres plataformas: Kraken 2 y QIIME 2 idénticas bit a bit; LotuS3 con las mismas familias, géneros y F1.
- HPL (N = 30,000): clúster 134.86 GFLOPS (suma de los 5 nodos), x86 nativo 177.36 y WSL2 129.07; 3.25, 4.08 y 3.23 GFLOPS/W.

El detalle de cada pipeline está en [`resultados/`](resultados/README.md).

---

## Documentación

- [Resultados por pipeline](resultados/README.md)
- [Datos de energía](datos_energia/README.md)
- [Scripts de ejecución y medición](scripts/README.md)
- [Análisis: cálculos, gráficas y Excel](analisis/README.md)
- [Guías de instalación y ejecución](docs/guias/README.md)
- [Entornos Conda ARM64](environments/README.md)
- [Evaluación con LEMMI16s](scripts/evaluacion/README.md)
- [Material de soporte](soporte/README.md)

Para compilar el libro, ejecutar pdfLaTeX + BibTeX sobre `docs/latex/main.tex`.
