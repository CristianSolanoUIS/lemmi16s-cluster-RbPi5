# Kraken 2 + Bracken

- Dataset: `HOMD_v4_GTDB`, microbioma oral humano, 2,453,431 lecturas Illumina MiSeq pareadas de 200 pb en 5 muestras.
- Versiones: Kraken 2 2.1.3 y Bracken 3.0.1, base GTDB.

| | x86 nativo | Clúster 5 nodos |
| :--- | ---: | ---: |
| Tiempo | 22.01 s | 51.04 s |
| Energía neta | 0.1518 Wh | 0.0398 Wh (3.81× menos) |
| Energía total | 0.2183 Wh | 0.2023 Wh (1.08× menos) |
| Lecturas/Wh (total) | 11.2 M | 12.1 M |

- El análisis dura unos 20 s por muestra; en el clúster domina la carga simultánea de la base desde NFS, por eso x86 nativo es 2.32× más rápido.
- Con 1 nodo el clúster tarda 98.35 s (4.47× más que x86) y gasta 4.7× menos energía neta.
- Predicciones idénticas bit a bit en las tres plataformas. F1: 0.5223 en familia y 0.3545 en género.

`predicciones/`: salidas del clúster en formato LEMMI16s (5 nodos y, en `mononodo/`, 1 nodo).
