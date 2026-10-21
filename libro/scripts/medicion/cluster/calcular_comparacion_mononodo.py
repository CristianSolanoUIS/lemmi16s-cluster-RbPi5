#!/usr/bin/env python3
"""
calcular_comparacion_mononodo.py
================================
Calcula y compara métricas energéticas, temporales y taxonómicas entre
las corridas MONONODO (secuenciales en 1 nodo) y MULTINODO (paralelas en N nodos).

Criterios de cálculo del Libro de Tesis:
- Tiempo de ejecución = ventana medida (primera a última lectura de potencia).
- Energía total = integral trapezoidal usando marcas de tiempo reales (Wh).
- Energía neta = integral trapezoidal restando potencia promedio de reposo (Wh).
- Eficiencia = lecturas / energía (bruta y neta, en lecturas/Wh).
- Speedup = T_mononodo / T_multinodo.
- Verificación taxonómica = diff -u entre predicciones mononodo y multinodo.
"""

import sys
import csv
import argparse
import subprocess
from pathlib import Path
from datetime import datetime

# Metricas de referencia Multinodo del libro de grado
REF_MULTINODO = {
    "kraken2": {
        "nombre": "Kraken 2 + Bracken",
        "nodos": 5,
        "tiempo_s": 51.04,
        "p_reposo_w": 2.35,
        "p_carga_w": 2.93,
        "e_total_wh": 0.2023,
        "e_neta_wh": 0.0398,
        "reads": 2453431,
        "instance": "HOMD_v4_GTDB",
        "samples": ["c001", "c002", "c003", "e001", "e002"],
        "out_dir_multi": "/shared/users/grupo1/lemmi16s/benchmark/analysis_outputs/kraken2",
        "out_dir_mono": "/shared/users/grupo1/lemmi16s/benchmark/analysis_outputs/kraken2/mononodo"
    },
    "lotus3": {
        "nombre": "LotuS3",
        "nodos": 3,
        "tiempo_s": 32.55,
        "p_reposo_w": 2.41,
        "p_carga_w": 3.22,
        "e_total_wh": 0.0782,
        "e_neta_wh": 0.0195,
        "reads": 29783,
        "instance": "HM_Contaminated_Soil",
        "samples": ["c001", "c002", "e001"],
        "out_dir_multi": "/shared/users/grupo1/lemmi16s/benchmark/analysis_outputs/lotus3",
        "out_dir_mono": "/shared/users/grupo1/lemmi16s/benchmark/analysis_outputs/lotus3/mononodo"
    },
    "qiime2": {
        "nombre": "QIIME 2",
        "nodos": 5,
        "tiempo_s": 1678.94,
        "p_reposo_w": 2.42,
        "p_carga_w": 3.64,
        "e_total_wh": 8.2884,
        "e_neta_wh": 2.7779,
        "reads": 2690077,
        "instance": "alfa_v1v2_SILVA",
        "samples": ["c001", "c002", "c003", "e001", "e002"],
        "out_dir_multi": "/shared/users/grupo1/lemmi16s/benchmark/analysis_outputs/qiime2",
        "out_dir_mono": "/shared/users/grupo1/lemmi16s/benchmark/analysis_outputs/qiime2/mononodo"
    }
}

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

def procesar_pipeline(pipe_key, base_medir_dir):
    pipe_dir = base_medir_dir / pipe_key
    if not pipe_dir.exists():
        return None

    # Buscar archivos mas recientes de baseline y corrida mononodo
    baseline_files = sorted(list(pipe_dir.glob("*baseline_pre*mononodo*.csv")))
    run_files = sorted(list(pipe_dir.glob("*_mononodo*.csv")))
    run_files = [f for f in run_files if "baseline" not in f.name]

    if not baseline_files or not run_files:
        return None

    baseline_csv = baseline_files[-1]
    run_csv = run_files[-1]

    # Parsear baseline
    base_ts, base_p = parse_csv(baseline_csv)
    avg_reposo = sum(base_p) / len(base_p) if base_p else 0.0

    # Parsear corrida activa
    run_ts, run_p = parse_csv(run_csv)
    if not run_ts or len(run_ts) < 2:
        return None

    dur_s = (run_ts[-1] - run_ts[0]).total_seconds()
    avg_carga = sum(run_p) / len(run_p)

    # Integral trapezoidal
    gross_wh = 0.0
    for k in range(1, len(run_p)):
        dt = (run_ts[k] - run_ts[k-1]).total_seconds()
        gross_wh += ((run_p[k] + run_p[k-1]) / 2.0) * (dt / 3600.0)

    net_wh = max(0.0, gross_wh - (avg_reposo * (dur_s / 3600.0)))

    ref = REF_MULTINODO[pipe_key]
    reads = ref["reads"]
    speedup = dur_s / ref["tiempo_s"] if ref["tiempo_s"] > 0 else 0.0

    eff_bruta_mono = reads / gross_wh if gross_wh > 0 else 0.0
    eff_neta_mono = reads / net_wh if net_wh > 0 else 0.0

    eff_bruta_multi = reads / ref["e_total_wh"] if ref["e_total_wh"] > 0 else 0.0
    eff_neta_multi = reads / ref["e_neta_wh"] if ref["e_neta_wh"] > 0 else 0.0

    # Leer marcas de tiempo por muestra si existen
    marks_files = sorted(list(pipe_dir.glob(f"marcas_tiempo_{pipe_key}_mononodo_*.tsv")))
    marks = []
    if marks_files:
        with open(marks_files[-1], "r", encoding="utf-8") as mf:
            reader = csv.DictReader(mf, delimiter="\t")
            marks = list(reader)

    return {
        "pipeline": pipe_key,
        "nombre": ref["nombre"],
        "baseline_csv": baseline_csv.name,
        "run_csv": run_csv.name,
        "dur_s": dur_s,
        "p_reposo": avg_reposo,
        "p_carga": avg_carga,
        "gross_wh": gross_wh,
        "net_wh": net_wh,
        "speedup": speedup,
        "eff_bruta_mono": eff_bruta_mono,
        "eff_neta_mono": eff_neta_mono,
        "eff_bruta_multi": eff_bruta_multi,
        "eff_neta_multi": eff_neta_multi,
        "ref": ref,
        "marks": marks
    }

def verificar_taxonomia(pipe_key):
    ref = REF_MULTINODO[pipe_key]
    instance = ref["instance"]
    samples = ref["samples"]
    dir_multi = Path(ref["out_dir_multi"])
    dir_mono = Path(ref["out_dir_mono"])

    print("\n" + "=" * 90)
    print(f"=== VERIFICACION TAXONOMICA (diff -u): {ref['nombre']} ===")
    print("=" * 90)

    total_diffs = 0
    for s in samples:
        f_multi = dir_multi / f"{pipe_key}_multinodo.{instance}-{s}.predictions.tsv"
        f_mono = dir_mono / f"{pipe_key}_mononodo.{instance}-{s}.predictions.tsv"

        if not f_mono.exists():
            print(f"[!] Muestra {s}: Archivo mononodo no encontrado ({f_mono.name})")
            continue
        if not f_multi.exists():
            print(f"[!] Muestra {s}: Archivo multinodo no encontrado ({f_multi.name})")
            continue

        cmd = ["diff", "-u", str(f_multi), str(f_mono)]
        proc = subprocess.run(cmd, capture_output=True, text=True)

        if proc.returncode == 0:
            print(f"  [OK] Muestra {s}: 100% IDENTICA (0 diferencias)")
        else:
            total_diffs += 1
            print(f"  [DIFERENCIA DETECTADA] Muestra {s}:")
            diff_lines = proc.stdout.strip().splitlines()
            for l in diff_lines[:25]:
                print(f"    {l}")
            if len(diff_lines) > 25:
                print(f"    ... (+{len(diff_lines) - 25} lineas de diferencias adicionales)")

            # Analisis especifico si es LotuS3
            if pipe_key == "lotus3":
                print("    -> Nota: En LotuS3 las diferencias son esperadas debido al clustering heuristico multihilo de UPARSE.")

    if total_diffs == 0:
        print("\nResultado global: Todas las muestras analizadas son estrictamente identicas.")
    else:
        print(f"\nResultado global: {total_diffs} muestra(s) presentaron diferencias.")

def main():
    parser = argparse.ArgumentParser(description="Calculo de metricas comparativas Mononodo vs Multinodo")
    parser.add_argument("--pipeline", choices=["kraken2", "lotus3", "qiime2", "all"], default="all")
    parser.add_argument("--medir-dir", default="/shared/users/grupo1/lemmi16s/medicion_energia/mononodo")
    parser.add_argument("--skip-taxo", action="store_true", help="Omitir verificacion taxonomica diff -u")
    args = parser.parse_args()

    medir_dir = Path(args.medir_dir)
    pipelines = ["qiime2", "lotus3", "kraken2"] if args.pipeline == "all" else [args.pipeline]

    resultados = {}
    for p in pipelines:
        res = procesar_pipeline(p, medir_dir)
        if res:
            resultados[p] = res

    if not resultados:
        print("No se encontraron resultados completos en", medir_dir)
        return

    for p, r in resultados.items():
        ref = r["ref"]
        print("\n" + "=" * 90)
        print(f"=== RESULTADOS DETALLADOS: {r['nombre']} (MONONODO vs MULTINODO) ===")
        print("=" * 90)
        print(f"Archivo reposo:  {r['baseline_csv']}")
        print(f"Archivo corrida: {r['run_csv']}")
        if r["marks"]:
            print("\nDesglose temporal por muestra:")
            print("{:<10} | {:<25} | {:<25} | {:<12} | {:<8}".format("Muestra", "Inicio", "Fin", "Duracion(s)", "Exit"))
            print("-" * 88)
            for m in r["marks"]:
                print("{:<10} | {:<25} | {:<25} | {:<12} | {:<8}".format(
                    m.get("sample", ""), m.get("start_iso", ""), m.get("end_iso", ""),
                    m.get("duration_s", ""), m.get("exit_status", "")
                ))

        print("\nComparativa Directa:")
        print(f"  Tiempo Mononodo:            {r['dur_s']:.2f} s ({r['dur_s']/60:.2f} min)")
        print(f"  Tiempo Multinodo:           {ref['tiempo_s']:.2f} s ({ref['nodos']} nodos concurrentes)")
        print(f"  Speedup (T_mono / T_multi): {r['speedup']:.2f}x")
        print(f"  Potencia Reposo (Mono):     {r['p_reposo']:.3f} W (vs {ref['p_reposo_w']:.3f} W promedio multi)")
        print(f"  Potencia en Carga (Mono):   {r['p_carga']:.3f} W (vs {ref['p_carga_w']:.3f} W promedio multi)")
        print(f"  Energia Bruta:              {r['gross_wh']:.4f} Wh (1 nodo) vs {ref['e_total_wh']:.4f} Wh ({ref['nodos']} nodos suma)")
        print(f"  Energia Neta:               {r['net_wh']:.4f} Wh (1 nodo) vs {ref['e_neta_wh']:.4f} Wh ({ref['nodos']} nodos suma)")
        print(f"  Eficiencia Bruta:           {r['eff_bruta_mono']:,.1f} reads/Wh (Mono) vs {r['eff_bruta_multi']:,.1f} reads/Wh (Multi)")
        print(f"  Eficiencia Neta:            {r['eff_neta_mono']:,.1f} reads/Wh (Mono) vs {r['eff_neta_multi']:,.1f} reads/Wh (Multi)")

        if not args.skip_taxo:
            verificar_taxonomia(p)

    print("\n" + "=" * 130)
    print("=== TABLA COMPARATIVA CONSOLIDADA (MONONODO vs MULTINODO - LIBRO DE TESIS) ===")
    print("=" * 130)
    header = "{:<10} | {:<10} | {:<10} | {:<8} | {:<9} | {:<10} | {:<11} | {:<11} | {:<10} | {:<10} | {:<11} | {:<11}".format(
        "Pipeline", "T_mono(s)", "T_multi(s)", "Speedup", "P_rep(W)", "P_carg(W)", "E_tot_mono", "E_tot_multi*", "E_net_mono", "E_net_multi*", "Eff_b_mono", "Eff_b_multi"
    )
    print(header)
    print("-" * 130)
    for p, r in resultados.items():
        ref = r["ref"]
        print("{:<10} | {:<10.2f} | {:<10.2f} | {:<8.2f}x | {:<9.3f} | {:<10.3f} | {:<11.4f} | {:<11.4f} | {:<10.4f} | {:<10.4f} | {:<11.0f} | {:<11.0f}".format(
            p, r["dur_s"], ref["tiempo_s"], r["speedup"], r["p_reposo"], r["p_carga"],
            r["gross_wh"], ref["e_total_wh"], r["net_wh"], ref["e_neta_wh"],
            r["eff_bruta_mono"], r["eff_bruta_multi"]
        ))
    print("=" * 130)
    print("* NOTA: E_tot_multi y E_net_multi corresponden a la SUMA energetica de todos los nodos concurrentes del cluster.")
    print("        E_tot_mono y E_net_mono corresponden al consumo de UN SOLO nodo durante todo el lote secuencial.")

if __name__ == "__main__":
    main()
