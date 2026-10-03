# Entornos Conda para Arquitectura ARM64 (Raspberry Pi 5)

Este directorio contiene las definiciones YAML de los entornos Conda utilizados en el clúster:

* **`lemmi16s_env_environment.yml`**: Entorno principal para la orquestación de LEMMI16s en ARM64 (Python 3.10, Snakemake, biom-format, pandas, scipy, numpy).
* **`qiime2_arm64_environment.yml`**: Entorno bioinformático para la ejecución de QIIME 2 Amplicon en arquitectura AArch64.

---

## 🛠️ Recreación de los Entornos

```bash
# 1. Crear entorno principal LEMMI16s
conda env create -f lemmi16s_env_environment.yml

# 2. Crear entorno QIIME 2 ARM64
conda env create -f qiime2_arm64_environment.yml
```
