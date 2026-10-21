# Resultados

Valores finales del libro (Tablas 3.3 y 3.4). Cada pipeline tiene su carpeta con las predicciones del clúster y un resumen.

| Carpeta | Contenido |
| :--- | :--- |
| [`kraken2/`](kraken2/README.md) | Kraken 2 + Bracken, dataset `HOMD_v4_GTDB` |
| [`lotus3_pacbio/`](lotus3_pacbio/README.md) | LotuS3 con lecturas PacBio HiFi, dataset `HM_Contaminated_Soil_PacBio` |
| [`qiime2/`](qiime2/README.md) | QIIME 2, dataset `alfa_v1v2_SILVA` |
| [`hpl/`](hpl/README.md) | Prueba de potencia de cálculo HPL |
| `comparaciones/` | F1 corregido, concordancia entre plataformas y comparación de 1 nodo frente a 5 nodos |

## Tiempo y energía

| Pipeline | Métrica | x86 nativo | x86 WSL2 | Clúster 1 nodo | Clúster 5 nodos |
| :--- | :--- | ---: | ---: | ---: | ---: |
| Kraken 2 | Tiempo | 22.01 s | 51.41 s | 98.35 s | 51.04 s |
| | Energía total | 0.2183 Wh | 0.3744 Wh | 0.0976 Wh | 0.2023 Wh |
| | Energía neta | 0.1518 Wh | 0.1775 Wh | 0.0321 Wh | 0.0398 Wh |
| LotuS3 | Tiempo | 31.65 min | 29.60 min | 143.0 min | 32.87 min |
| | Energía total | 17.14 Wh | 17.64 Wh | 14.30 Wh | 12.03 Wh |
| | Energía neta | 15.65 Wh | 10.15 Wh | 8.65 Wh | 7.33 Wh |
| QIIME 2 | Tiempo | 72.06 min | 79.99 min | 139.9 min | 27.98 min |
| | Energía total | 25.49 Wh | 34.24 Wh | 8.42 Wh | 8.29 Wh |
| | Energía neta | 12.70 Wh | 16.98 Wh | 2.91 Wh | 2.78 Wh |

## Eficiencia (lecturas por Wh, energía total)

| Pipeline | x86 nativo | Clúster 5 nodos | Factor total | Factor neto |
| :--- | ---: | ---: | ---: | ---: |
| Kraken 2 | 11.2 M | 12.1 M | 1.08× | 3.81× |
| LotuS3 | 1,494 | 2,129 | 1.42× | 2.14× |
| QIIME 2 | 105,518 | 324,561 | 3.08× | 4.57× |

## Fidelidad biológica

| Pipeline | F1 familia | F1 género | Entre plataformas |
| :--- | ---: | ---: | :--- |
| Kraken 2 | 0.5223 | 0.3545 | Idéntico bit a bit |
| LotuS3 | 0.8667 | 0.8762 | Mismas familias, géneros y F1 |
| QIIME 2 | 0.8286 | 0.7083 | Idéntico bit a bit |

El F1 se recalculó con la lógica de LEMMI16s usando el `queryTaxo.tsv` de cada muestra, porque el evaluador original usa el de la primera muestra para todas (ver `comparaciones/f1_corregido_kraken2_qiime2.txt`).
