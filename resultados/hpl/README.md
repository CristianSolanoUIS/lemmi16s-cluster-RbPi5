# HPL (High-Performance Linpack)

Prueba inicial de potencia de cálculo. Cada plataforma resolvió A·x = b con una matriz densa de 30,000 × 30,000 en doble precisión (unos 7.2 GB).

- Configuración igual en todas: HPL 2.3, N = 30,000, NB = 192, P × Q = 2 × 2 (un proceso MPI por núcleo).
- El clúster corrió un HPL independiente en cada nodo; su resultado es la suma de los cinco.
- La energía se midió solo durante la resolución, con el mismo protocolo de los pipelines.
- Todas las corridas pasaron la verificación del residuo.

| Plataforma | GFLOPS | % del pico | Carga (W) | GFLOPS/W bruto | GFLOPS/W neto |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Clúster RBPi5 (5 nodos) | 134.86 | 35.1 | 40.90 | 3.25 | 4.58 |
| x86 nativo | 177.36 | 61.6 | 43.21 | 4.08 | 4.40 |
| x86 WSL2 | 129.07 | 44.8 | 39.47 | 3.23 | 4.82 |

Los nodos rbp5-2 y rbp5-3 rindieron menos (23.23 y 21.03 GFLOPS); se repitió la prueba (21.88 y 20.89) sin throttling.

- `flops_energia.csv`: resultado por nodo y por plataforma.
- `flops_energia_repeticion.csv`: repetición de rbp5-2 y rbp5-3.
- Datos crudos en `datos_energia/<plataforma>/hpl/`.
