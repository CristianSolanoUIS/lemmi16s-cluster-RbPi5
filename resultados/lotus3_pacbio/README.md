# LotuS3 (PacBio HiFi)

- Dataset: `HM_Contaminated_Soil_PacBio`, suelo contaminado con metales pesados, 25,611 lecturas PacBio HiFi de unos 1,500 pb (gen 16S completo) en 5 muestras.
- Versión: LotuS3 3.03, agrupamiento en OTUs y asignación con VSEARCH contra SILVA 138.1 (LAMBDA3 no existe para ARM64).

| | x86 nativo | x86 WSL2 | Clúster 5 nodos |
| :--- | ---: | ---: | ---: |
| Tiempo | 31.65 min | 29.60 min | 32.87 min |
| Energía neta | 15.65 Wh | 10.15 Wh | 7.33 Wh (2.14× menos que x86 nativo) |
| Lecturas/Wh (total) | 1,494 | 1,452 | 2,129 |

- Los nodos terminaron entre los 14 y los 33 min porque leen la base desde el mismo almacenamiento NFS; el tiempo del lote lo marca el último.
- Con 1 nodo el clúster tarda 143.0 min (4.52× más que x86) y gasta 1.8× menos energía neta.
- Mismas familias, géneros y F1 en las tres plataformas: 0.8667 en familia y 0.8762 en género, con pequeñas diferencias en las abundancias.

Archivos:
- `predicciones/`: salidas del clúster (5 nodos y, en `mononodo/`, 1 nodo).
- `resumen_lotus3_pacbio.csv`: tiempo, energía y F1 por plataforma.
- `reporte_*.txt`, `resumen_*_wsl2_*.txt` y `notas_analisis_lotus3_pacbio.md`: reportes de las corridas y de la comparación entre plataformas.
