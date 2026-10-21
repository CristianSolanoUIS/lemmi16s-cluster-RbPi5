# Análisis

Scripts que generan las tablas y figuras del libro a partir de `datos_energia/`.

- `calculos/`
  - `calcular_flops_energia.py`: resultados de HPL → `resultados/hpl/`.
  - `calcular_mononodo.py`, `comparar_taxonomia.py`: 1 nodo frente a 5 nodos → `resultados/comparaciones/`.
  - `compute_f1_kraken2_qiime2.py`, `compute_f1_pacbio.py`: F1 con el `queryTaxo.tsv` de cada muestra.
  - `resumen_lotus3_pacbio.py`: resumen de LotuS3 → `resultados/lotus3_pacbio/`.
- `graficas/`: figuras del libro → `docs/latex/figuras/`.
- `excel/`: libros de Excel con las gráficas de potencia por pipeline.

Los scripts de `calculos/` y `graficas/` usan rutas relativas a la raíz del repositorio. Los de `excel/` tienen la ruta base en la variable `BASE` (o `$X` y `$F` en `exportar_figuras.ps1`); hay que ajustarla antes de usarlos.
