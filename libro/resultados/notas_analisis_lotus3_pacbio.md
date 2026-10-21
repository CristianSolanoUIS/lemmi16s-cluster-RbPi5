# Notas para el análisis del libro: LotuS3 PacBio (5 muestras, VSEARCH)

Datos: datos_energia/resumen_lotus3_pacbio.csv (criterio del libro: ventana medida, trapecio en Wh, clúster por nodo y suma).
Lecturas: 25,611 HiFi (~1,505 pb) en 5 muestras (c001-c003 calibración, e001-e002 evaluación).

| | Nativo (Cristian) | WSL2 (Zamir) | Clúster multinodo | Clúster mononodo |
|---|---|---|---|---|
| Tiempo | 1,899.24 s | 1,775.85 s | 1,972.46 s | 8,582.68 s |
| Reposo | 2.83 W | 15.20 W | 2.36 W/nodo | 2.37 W |
| Carga media | 32.48 W | 35.76 W | 6.22 W/nodo | 6.01 W |
| Energía total | 17.1442 Wh | 17.6435 Wh | 12.0311 Wh | 14.2991 Wh |
| Energía neta | 15.6519 Wh | 10.1478 Wh | 7.3270 Wh | 8.6506 Wh |
| Eficiencia bruta / neta | 1,494 / 1,636 | 1,452 / 2,524 | 2,129 / 3,495 | 1,791 / 2,961 |
| F1 familia / género | 0.8667 / 0.8762 | igual | igual | igual |

## Lo que cambia frente a la versión de 3 muestras
1. El clúster ya no es más rápido en LotuS3: speedup frente al nativo 0.96x (antes 2.03x). Frente a WSL2, 0.90x.
   El tiempo del multinodo está inflado por pruebas fio de grupo2 sobre /shared (NFS en la microSD del maestro):
   la etapa VSEARCH varió de 12 a 30 min entre nodos idénticos sin throttling (vcgencmd get_throttled = 0x0);
   el nodo más rápido consumió más (7.55 W) y el más lento menos (5.84 W) = CPU esperando datos.
2. El clúster sigue ganando en energía: total -30 % frente al nativo (antes -75 %); -32 % frente a WSL2.
   Eficiencia bruta 1.42x nativo / 1.47x WSL2; neta 2.14x nativo / 1.38x WSL2.
3. Energía neta de Cristian (15.65 Wh) > la de WSL2 (10.15 Wh) aunque la total es casi igual:
   su reposo medido con RAPL (sysfs, solo paquete) es 2.83 W y el de WSL2 con LibreHardwareMonitor es 15.20 W.
   Mismo efecto que en Kraken 2 y QIIME 2; explicarlo como diferencia de instrumentación.
4. Mononodo vs multinodo: speedup 4.35x; el multinodo gasta menos energía (total 12.03 vs 14.30 Wh, neta 7.33 vs 8.65).
   Predicciones: mismas familias y géneros en las 5 muestras (máx. dif. de abundancia 0.49 pp en c001); F1 idéntico.
5. F1 de LotuS3 sube mucho con lecturas largas: 0.8667 / 0.8762 (antes 0.3963 / 0.4141 con Illumina 3 muestras),
   y es idéntico en las cuatro corridas (antes el clúster daba 0.4352 en género).
6. Por qué VSEARCH: en ARM no existe lambda3 (bioconda), LotuS3 cae a VSEARCH en el clúster; se usó -taxAligner vsearch
   en todas las plataformas para correr el mismo pipeline (VSEARCH v2.31.0). Con LAMBDA3 en x86 cada muestra tardaba ~100 min.
7. Parámetros: -derepMin 1:1,1:2,1:3 -p PacBio -s sdm_PacBio_LSSU.txt -buildPhylo 0 -lulu 0 -t 4 -taxAligner vsearch (4 hilos en todas).

## F1 corregido de Kraken 2 y QIIME 2 (afecta tab:validacion y fig_fidelidad_biologica)
El evaluador oficial de LEMMI v1 (eval.smk, input.truth[0]) evalúa todas las muestras con la verdad de e001.
Recalculado con la verdad de cada muestra (datos_energia/f1_corregido_kraken2_qiime2.txt):
- Kraken 2: familia 0.5223, género 0.3545, especie 0 (antes 0.3397 / 0.2088)
- QIIME 2: familia 0.8286, género 0.7083, especie 0.4500 (antes 0.9094 / 0.7941 / 0.4895)
Idéntico en las tres plataformas (predicciones bit a bit iguales).

## Gráficas de potencia (Excel, graficas_lotus3.xlsx -> fig_lotus3_potencia_*.png)
- Clúster (G1): cada nodo pasa de ~2.4 W en reposo a 5-9 W durante la corrida. Los nodos terminan en tiempos muy distintos
  (c002 a ~867 s, c003 ~1,182 s, e001 ~1,386 s, c001 ~1,776 s, e002 ~1,970 s) aunque las muestras son del mismo tamaño
  (efecto de la carga de grupo2 sobre /shared). Picos de 8-9 W al inicio (filtrado/clustering) y meseta de 5-7 W en VSEARCH.
- WSL2 (G2): reposo ~15 W; corrida estable en ~36-38 W con un pico de ~47 W al arrancar. Se ven 5 caídas cortas a ~15 W
  (cambio de muestra) cada ~355 s: las 5 muestras tardan casi lo mismo (346-362 s).
- Cristian (G3): reposo ~2.8 W (RAPL, solo paquete). Cada muestra tiene un patrón de dos niveles muy marcado:
  pico de ~47-49 W, meseta en ~40 W (VSEARCH con 4 hilos) y luego ~21 W hasta terminar, con caídas a ~3 W entre muestras.
- Normalizada (G4): x86 aporta ~20 W (WSL2) y ~19-37 W (Cristian) sobre su reposo; el clúster (suma de 5 nodos) sube a ~20 W
  y baja en escalones (≈16, 12, 8, 4 W) a medida que cada nodo termina, hasta 0 W en ~1,970 s.
- Las 4 figuras del libro (fig_lotus3_potencia_*.png) salen ahora de graficas_lotus3_por_minuto.xlsx (promedio de cada minuto),
  igual que QIIME 2. Con el promedio por minuto: en el clúster todos los nodos bajan a ~3-4 W en el minuto 2-3
  (etapa de pocos hilos antes de VSEARCH) y luego quedan en ~6-7.6 W; c002 (rbp5-2, el más rápido) es el que más consume (~7.6 W).
  WSL2 ~36 W con bajadas a ~32 W entre muestras; Cristian alterna ~40 W (VSEARCH) y ~21 W en cada muestra.
