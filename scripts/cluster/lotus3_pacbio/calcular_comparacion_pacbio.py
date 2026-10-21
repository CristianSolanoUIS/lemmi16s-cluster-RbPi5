#!/usr/bin/env python3
"""
calcular_comparacion_pacbio.py
==============================
Calcula y compara métricas energéticas, temporales y taxonómicas entre
las corridas MULTINODO (5 nodos) y MONONODO (1 nodo) de LotuS3 PacBio.

Lecturas totales PacBio: 25,611
(c001: 5179, c002: 5045, c003: 5194, e001: 5133, e002: 5060)
"""

import sys
import csv
import argparse
import subprocess
from pathlib import Path
from datetime import datetime

TOTAL_READS_PACBIO = 25611
SAMPLES = ["c001", "c002", "c003", "e001", "e002"]

def parse_csv(path):
    timestamps = []
    powers = []
    if not path or not Path(path).exists():
        return timestamps, powers
    with open(path, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader, None)
        for row in reader:
            if len(row) >= 2:
                try:
                    ts = datetime.strptime(row[0], "%Y-%m-%d %H:%M:%S.%f")
                    p = float(row[1])
                    timestamps.append(ts)
                    powers.append(p)
                except Exception:
                    try:
                        ts = datetime.strptime(row[0], "%Y-%m-%d %H:%M:%S")
                        p = float(row[1])
                        timestamps.append(ts)
                        powers.append(p)
                    except Exception:
                        pass
    return timestamps, powers

def procesar_multinodo(medir_dir):
    medir_dir = Path(medir_dir)
    pre_dir = medir_dir / "pre"
    
    tot_gross_wh = 0.0
    tot_net_wh = 0.0
    max_duration_s = 0.0
    powers_carga = []
    powers_reposo = []

    print("\n" + "=" * 90)
    print("=== DESGLOSE MULTINODO LOTUS3 PACBIO (5 NODOS) ===")
    print("=" * 90)
    print("{:<8} | {:<20} | {:<8} | {:<8} | {:<8} | {:<10} | {:<10}".format(
        "Muestra", "Nodo", "P_rep(W)", "P_carg(W)", "Dur(s)", "Bruta(Wh)", "Neta(Wh)"
    ))
    print("-" * 88)

    for s in SAMPLES:
        run_files = sorted(list(medir_dir.glob(f"*LotuS3_pacbio_multinodo_{s}_*.csv")))
        pre_files = sorted(list(pre_dir.glob(f"*baseline_pre_lotus3_pacbio_{s}_*.csv")))

        if not run_files:
            continue
        run_f = run_files[-1]
        pre_f = pre_files[-1] if pre_files else None

        # Nodo
        node = "desconocido"
        parts = run_f.stem.split("_")
        for idx, p in enumerate(parts):
            if p == "node" and idx + 1 < len(parts):
                node = parts[idx + 1]

        # Parsear
        base_ts, base_p = parse_csv(pre_f)
        avg_base = sum(base_p) / len(base_p) if base_p else 2.37
        powers_reposo.extend(base_p)

        run_ts, run_p = parse_csv(run_f)
        if len(run_p) < 2:
            continue
        powers_carga.extend(run_p)
        avg_carga = sum(run_p) / len(run_p)
        dur_s = (run_ts[-1] - run_ts[0]).total_seconds()

        gross_wh = 0.0
        for k in range(1, len(run_p)):
            dt = (run_ts[k] - run_ts[k-1]).total_seconds()
            gross_wh += ((run_p[k] + run_p[k-1]) / 2.0) * (dt / 3600.0)

        net_wh = max(0.0, gross_wh - (avg_base * (dur_s / 3600.0)))

        tot_gross_wh += gross_wh
        tot_net_wh += net_wh
        if dur_s > max_duration_s:
            max_duration_s = dur_s

        print("{:<8} | {:<20} | {:<8.3f} | {:<8.3f} | {:<8.1f} | {:<10.4f} | {:<10.4f}".format(
            s, node, avg_base, avg_carga, dur_s, gross_wh, net_wh
        ))

    avg_p_rep = sum(powers_reposo)/len(powers_reposo) if powers_reposo else 0.0
    avg_p_carg = sum(powers_carga)/len(powers_carga) if powers_carga else 0.0

    return {
        "tiempo_paralelo_s": max_duration_s,
        "tot_gross_wh": tot_gross_wh,
        "tot_net_wh": tot_net_wh,
        "p_reposo": avg_p_rep,
        "p_carga": avg_p_carg
    }

def procesar_mononodo(medir_dir):
    mono_dir = Path(medir_dir) / "mononodo"
    pre_dir = mono_dir / "pre"

    run_files = sorted(list(mono_dir.glob("*LotuS3_pacbio_mononodo_*.csv")))
    pre_files = sorted(list(pre_dir.glob("*baseline_pre_lotus3_pacbio_mononodo_*.csv")))

    if not run_files or not pre_files:
        return None

    run_f = run_files[-1]
    pre_f = pre_files[-1]

    base_ts, base_p = parse_csv(pre_f)
    avg_base = sum(base_p)/len(base_p) if base_p else 0.0

    run_ts, run_p = parse_csv(run_f)
    if len(run_p) < 2:
        return None

    dur_s = (run_ts[-1] - run_ts[0]).total_seconds()
    avg_carga = sum(run_p)/len(run_p)

    gross_wh = 0.0
    for k in range(1, len(run_p)):
        dt = (run_ts[k] - run_ts[k-1]).total_seconds()
        gross_wh += ((run_p[k] + run_p[k-1]) / 2.0) * (dt / 3600.0)

    net_wh = max(0.0, gross_wh - (avg_base * (dur_s / 3600.0)))

    # Marcas
    marks_files = sorted(list(mono_dir.glob("marcas_tiempo_lotus3_pacbio_mononodo_*.tsv")))
    marks = []
    if marks_files:
        with open(marks_files[-1], "r", encoding="utf-8") as mf:
            reader = csv.DictReader(mf, delimiter="\t")
            marks = list(reader)

    return {
        "dur_s": dur_s,
        "gross_wh": gross_wh,
        "net_wh": net_wh,
        "p_reposo": avg_base,
        "p_carga": avg_carga,
        "marks": marks
    }

def verificar_taxonomia(out_dir):
    out_dir = Path(out_dir)
    mono_dir = out_dir / "mononodo"
    if not mono_dir.exists():
        return

    print("\n" + "=" * 90)
    print("=== VERIFICACION TAXONOMICA (diff -u): PACBIO MULTINODO vs MONONODO ===")
    print("=" * 90)

    for s in SAMPLES:
        f_multi = list(out_dir.glob(f"lotus3_pacbio_multinodo.HM_Contaminated_Soil_PacBio-{s}.job*.predictions.tsv"))
        f_mono = list(mono_dir.glob(f"lotus3_pacbio_mononodo.HM_Contaminated_Soil_PacBio-{s}.job*.predictions.tsv"))

        if f_multi and f_mono:
            cmd = ["diff", "-u", str(f_multi[-1]), str(f_mono[-1])]
            proc = subprocess.run(cmd, capture_output=True, text=True)
            if proc.returncode == 0:
                print(f"  [OK] Muestra {s}: 100% IDENTICA")
            else:
                lines = proc.stdout.strip().splitlines()
                print(f"  [DIFERENCIA UPARSE] Muestra {s}: {len(lines)} lineas diff (esperado por heuristica)")

def main():
    parser = argparse.ArgumentParser(description="Calculo comparativo LotuS3 PacBio Multinodo vs Mononodo")
    parser.add_argument("--base-dir", default="/shared/users/grupo1/lemmi16s")
    args = parser.parse_args()

    b = Path(args.base_dir)
    medir_dir = b / "medicion_energia/lotus3_pacbio"
    out_dir = b / "benchmark/analysis_outputs/lotus3_pacbio"

    multi = procesar_multinodo(medir_dir)
    mono = procesar_mononodo(medir_dir)

    print("\n" + "=" * 115)
    print("=== RESULTADOS LOTUS3 PACBIO: MULTINODO (5 NODOS) ===")
    print("=" * 115)
    t_multi = multi["tiempo_paralelo_s"]
    e_multi_b = multi["tot_gross_wh"]
    e_multi_n = multi["tot_net_wh"]
    eff_m_b = TOTAL_READS_PACBIO / e_multi_b if e_multi_b > 0 else 0
    eff_m_n = TOTAL_READS_PACBIO / e_multi_n if e_multi_n > 0 else 0

    print(f"Tiempo paralelo (cuello de botella): {t_multi:.2f} s ({t_multi/60:.2f} min)")
    print(f"Potencia promedio reposo:           {multi['p_reposo']:.3f} W")
    print(f"Potencia promedio en carga:         {multi['p_carga']:.3f} W")
    print(f"Energia total bruta (5 nodos):      {e_multi_b:.4f} Wh ({e_multi_b*3600:.1f} J)")
    print(f"Energia neta (5 nodos):             {e_multi_n:.4f} Wh ({e_multi_n*3600:.1f} J)")
    print(f"Eficiencia bruta:                   {eff_m_b:,.1f} reads/Wh")
    print(f"Eficiencia neta:                    {eff_m_n:,.1f} reads/Wh")

    if mono:
        t_mono = mono["dur_s"]
        e_mono_b = mono["gross_wh"]
        e_mono_n = mono["net_wh"]
        speedup = t_mono / t_multi if t_multi > 0 else 0
        eff_o_b = TOTAL_READS_PACBIO / e_mono_b if e_mono_b > 0 else 0
        eff_o_n = TOTAL_READS_PACBIO / e_mono_n if e_mono_n > 0 else 0

        print("\n" + "=" * 115)
        print("=== RESULTADOS LOTUS3 PACBIO: MONONODO (1 NODO SECUENCIAL) ===")
        print("=" * 115)
        print(f"Tiempo secuencial total:            {t_mono:.2f} s ({t_mono/60:.2f} min)")
        print(f"Speedup multinodo (T_mono/T_multi): {speedup:.2f}x")
        print(f"Potencia reposo (1 nodo):           {mono['p_reposo']:.3f} W")
        print(f"Potencia en carga (1 nodo):         {mono['p_carga']:.3f} W")
        print(f"Energia total bruta (1 nodo):       {e_mono_b:.4f} Wh ({e_mono_b*3600:.1f} J)")
        print(f"Energia neta (1 nodo):              {e_mono_n:.4f} Wh ({e_mono_n*3600:.1f} J)")
        print(f"Eficiencia bruta:                   {eff_o_b:,.1f} reads/Wh")
        print(f"Eficiencia neta:                    {eff_o_n:,.1f} reads/Wh")

        print("\n" + "=" * 125)
        print("=== TABLA COMPARATIVA CONSOLIDADA (LOTUS3 PACBIO) ===")
        print("=" * 125)
        header = "{:<12} | {:<10} | {:<10} | {:<8} | {:<9} | {:<10} | {:<11} | {:<11} | {:<11} | {:<11}".format(
            "Config", "T(s)", "Speedup", "P_rep(W)", "P_carg(W)", "E_tot(Wh)", "E_net(Wh)", "Eff_bruta", "Eff_neta", "Lecturas"
        )
        print(header)
        print("-" * 125)
        print("{:<12} | {:<10.2f} | {:<10} | {:<8.3f} | {:<9.3f} | {:<10.4f} | {:<11.4f} | {:<11.0f} | {:<11.0f} | {:<11}".format(
            "Multinodo(5)", t_multi, f"{speedup:.2f}x", multi["p_reposo"], multi["p_carga"], e_multi_b, e_multi_n, eff_m_b, eff_m_n, TOTAL_READS_PACBIO
        ))
        print("{:<12} | {:<10.2f} | {:<10} | {:<8.3f} | {:<9.3f} | {:<10.4f} | {:<11.4f} | {:<11.0f} | {:<11.0f} | {:<11}".format(
            "Mononodo(1)", t_mono, "1.00x", mono["p_reposo"], mono["p_carga"], e_mono_b, e_mono_n, eff_o_b, eff_o_n, TOTAL_READS_PACBIO
        ))
        print("=" * 125)

        verificar_taxonomia(out_dir)

if __name__ == "__main__":
    main()
