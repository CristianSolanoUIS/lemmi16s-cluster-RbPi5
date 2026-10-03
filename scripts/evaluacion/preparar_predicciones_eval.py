#!/usr/bin/env python3
import os
import shutil
import glob

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BACKUP_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
ANALYSIS_OUT = os.path.join(BACKUP_DIR, "benchmark", "analysis_outputs")
EVAL_READY_DIR = os.path.join(BACKUP_DIR, "eval_ready_predictions")
os.makedirs(EVAL_READY_DIR, exist_ok=True)

print("=== ORGANIZANDO PREDICCIONES DEL CLUSTER PARA LEMMI16s eval.smk ===")

# 1. Kraken 2 (HOMD_v4_GTDB)
for sample in ["c001", "c002", "c003", "e001", "e002"]:
    # Multi
    src = os.path.join(ANALYSIS_OUT, "kraken2", f"kraken2_multinodo.HOMD_v4_GTDB-{sample}.predictions.tsv")
    dst = os.path.join(EVAL_READY_DIR, f"kraken2_multi_cluster.HOMD_v4_GTDB-{sample}.predictions.tsv")
    if os.path.exists(src):
        shutil.copy2(src, dst)
        print(f"[OK] {os.path.basename(dst)}")

    # Mono
    src = os.path.join(ANALYSIS_OUT, "kraken2", "mononodo", f"kraken2_mononodo.HOMD_v4_GTDB-{sample}.predictions.tsv")
    dst = os.path.join(EVAL_READY_DIR, f"kraken2_mono_cluster.HOMD_v4_GTDB-{sample}.predictions.tsv")
    if os.path.exists(src):
        shutil.copy2(src, dst)
        print(f"[OK] {os.path.basename(dst)}")

# 2. QIIME 2 (alfa_v1v2_SILVA)
for sample in ["c001", "c002", "c003", "e001", "e002"]:
    # Multi
    src = os.path.join(ANALYSIS_OUT, "qiime2", f"qiime2_multinodo.alfa_v1v2_SILVA-{sample}.predictions.tsv")
    dst = os.path.join(EVAL_READY_DIR, f"qiime2_multi_cluster.alfa_v1v2_SILVA-{sample}.predictions.tsv")
    if os.path.exists(src):
        shutil.copy2(src, dst)
        print(f"[OK] {os.path.basename(dst)}")

    # Mono
    src = os.path.join(ANALYSIS_OUT, "qiime2", "mononodo", f"qiime2_mononodo.alfa_v1v2_SILVA-{sample}.predictions.tsv")
    dst = os.path.join(EVAL_READY_DIR, f"qiime2_mono_cluster.alfa_v1v2_SILVA-{sample}.predictions.tsv")
    if os.path.exists(src):
        shutil.copy2(src, dst)
        print(f"[OK] {os.path.basename(dst)}")

# 3. LotuS3 PacBio (HM_Contaminated_Soil)
for sample in ["c001", "c002", "c003", "e001", "e002"]:
    # Multi
    pattern_multi = os.path.join(ANALYSIS_OUT, "lotus3_pacbio", f"lotus3_pacbio_multinodo.HM_Contaminated_Soil_PacBio-{sample}.job*.predictions.tsv")
    matches_m = glob.glob(pattern_multi)
    if matches_m:
        dst = os.path.join(EVAL_READY_DIR, f"lotus3_pacbio_multi_cluster.HM_Contaminated_Soil-{sample}.predictions.tsv")
        shutil.copy2(matches_m[0], dst)
        print(f"[OK] {os.path.basename(dst)}")

    # Mono
    pattern_mono = os.path.join(ANALYSIS_OUT, "lotus3_pacbio", "mononodo", f"lotus3_pacbio_mononodo.HM_Contaminated_Soil_PacBio-{sample}.job*.predictions.tsv")
    matches_o = glob.glob(pattern_mono)
    if matches_o:
        dst = os.path.join(EVAL_READY_DIR, f"lotus3_pacbio_mono_cluster.HM_Contaminated_Soil-{sample}.predictions.tsv")
        shutil.copy2(matches_o[0], dst)
        print(f"[OK] {os.path.basename(dst)}")

print(f"\nTotal de archivos listos para LEMMI eval.smk: {len(os.listdir(EVAL_READY_DIR))}")
