# Datos de energía

Telemetría cruda a 1 Hz de las corridas que aparecen en el libro.

| Carpeta | Plataforma | Medición |
| :--- | :--- | :--- |
| `cluster_rpi5/` | Clúster, 5 nodos (una muestra por nodo) | PMIC DA9091 |
| `cluster_rpi5_mononodo/` | Clúster, 1 nodo (muestras una tras otra) | PMIC DA9091 |
| `x86_pc_cristian/` | x86 nativo, Ubuntu 24.04 | RAPL (sysfs) |
| `x86_pc_zamir/` | x86 WSL2 | RAPL (LibreHardwareMonitor) |

Dentro de cada plataforma hay una carpeta por prueba (`kraken2/`, `lotus3/pacbio_5muestras/`, `qiime2/`, `hpl/`, `reposo_5min/`).

- `energia_*.csv`: potencia por segundo durante la ejecución.
- `pre/`: los 5 min de reposo antes de cada corrida, usados para la energía neta.
- `marcas_*`: inicio y fin de cada muestra.
- `predicciones/`: salidas del pipeline de esa corrida.

Los nombres de las carpetas son los que usan los scripts de `analisis/`, por eso no se cambiaron.
