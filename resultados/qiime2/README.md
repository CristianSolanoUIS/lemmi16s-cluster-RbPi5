# QIIME 2

- Dataset: `alfa_v1v2_SILVA`, regiones V1–V2 del gen 16S, 2,690,077 lecturas Illumina pareadas en 5 muestras.
- Método: ASVs con Deblur y clasificador Naive Bayes sobre SILVA recortada a V1–V2 (unas 62,000 secuencias), porque la base completa no cabe en 16 GB de RAM.

| | x86 nativo | Clúster 5 nodos |
| :--- | ---: | ---: |
| Tiempo | 72.06 min | 27.98 min (2.58× más rápido) |
| Energía neta | 12.70 Wh | 2.78 Wh (4.57× menos) |
| Energía total | 25.49 Wh | 8.29 Wh (3.08× menos) |
| Lecturas/Wh (total) | 105,518 | 324,561 |

- Cada nodo procesa su muestra sin depender de los demás, por eso escala 5.00× de 1 a 5 nodos (139.9 → 27.98 min).
- Predicciones idénticas bit a bit en las tres plataformas. F1: 0.8286 en familia, 0.7083 en género y 0.4500 en especie.

`predicciones/`: salidas del clúster en formato LEMMI16s (5 nodos y, en `mononodo/`, 1 nodo).
