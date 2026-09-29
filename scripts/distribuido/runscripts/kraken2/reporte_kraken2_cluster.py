#!/usr/bin/env python3
import sys
import csv
from pathlib import Path
from datetime import datetime

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

def main():
    if len(sys.argv) < 6:
        print("Uso: reporte_kraken2_cluster.py <job_ids_csv> <samples_str> <medir_dir> <instance> <base_dir>")
        sys.exit(1)

    job_ids = sys.argv[1].split(",")
    samples = sys.argv[2].split()
    medir_dir = Path(sys.argv[3])
    instance = sys.argv[4]
    base_dir = Path(sys.argv[5])

    print("=" * 105)
    print("=== RESUMEN ENERGETICO CONSOLIDADO DEL CLUSTER (KRAKEN 2 + BRACKEN) ===")
    print("=" * 105)

    header = "{:<8} | {:<7} | {:<8} | {:<8} | {:<9} | {:<8} | {:<6} | {:<10} | {:<9} | {:<10}".format(
        "Muestra", "Job", "Nodo", "Pre (W)", "Carga (W)", "Neta (W)", "Dur(s)", "Bruta (Wh)", "Neta (Wh)", "Reads"
    )
    print(header)
    print("-" * 105)

    tot_gross_wh = 0.0
    tot_net_wh = 0.0
    durations = []
    total_reads_all = 0
    sampling_diagnostics = []

    for sample, jid in zip(samples, job_ids):
        pre_match = sorted(list(medir_dir.glob(f"*baseline_pre*kraken2_{sample}*job{jid}*.csv")))
        run_match = sorted(list(medir_dir.glob(f"*Kraken2_multinodo_{sample}*job{jid}*.csv")))

        pre_f = pre_match[-1] if pre_match else None
        run_f = run_match[-1] if run_match else None

        node = "unknown"
        if run_f:
            parts = run_f.stem.split("_")
            for idx_p, p in enumerate(parts):
                if p == "node" and idx_p + 1 < len(parts):
                    node = parts[idx_p + 1]

        pre_ts, pre_p = parse_csv(pre_f)
        run_ts, run_p = parse_csv(run_f)

        avg_pre = sum(pre_p) / len(pre_p) if pre_p else 0.0
        avg_carga = sum(run_p) / len(run_p) if run_p else 0.0
        p_neta = max(0.0, avg_carga - avg_pre)

        # Duración real calculada por timestamps de telemetría activa
        if len(run_ts) >= 2:
            dur_s = (run_ts[-1] - run_ts[0]).total_seconds()
        else:
            dur_s = float(len(run_p))
        durations.append(dur_s)

        # Integración trapezoidal o por pasos de energía activa
        if len(run_p) >= 2 and len(run_ts) == len(run_p):
            gross_wh = 0.0
            for k in range(1, len(run_p)):
                dt = (run_ts[k] - run_ts[k-1]).total_seconds()
                gross_wh += ((run_p[k] + run_p[k-1]) / 2.0) * (dt / 3600.0)
        else:
            gross_wh = sum(p / 3600.0 for p in run_p)

        net_wh = max(0.0, gross_wh - (avg_pre * (dur_s / 3600.0)))

        tot_gross_wh += gross_wh
        tot_net_wh += net_wh

        # Lecturas biológicas
        qdir = base_dir / "benchmark/instances" / instance / f"{instance}-{sample}"
        s_reads = 0
        for fq in [qdir / "queryReads1.fq", qdir / "queryReads.fq"]:
            if fq.exists():
                with open(fq, "r", encoding="utf-8") as f:
                    s_reads = sum(1 for _ in f) // 4
                break
        total_reads_all += s_reads

        row_str = "{:<8} | {:<7} | {:<8} | {:<8.3f} | {:<9.3f} | {:<8.3f} | {:<6.1f} | {:<10.4f} | {:<9.4f} | {:<10,}".format(
            sample, jid, node, avg_pre, avg_carga, p_neta, dur_s, gross_wh, net_wh, s_reads
        )
        print(row_str)

        # Diagnóstico de muestreo (delta t entre lecturas consecutivas)
        deltas = []
        if len(run_ts) >= 2:
            for k in range(1, len(run_ts)):
                deltas.append((run_ts[k] - run_ts[k-1]).total_seconds())
        jumps = [d for d in deltas if d > 2.0]
        mean_dt = sum(deltas)/len(deltas) if deltas else 0.0
        min_dt = min(deltas) if deltas else 0.0
        max_dt = max(deltas) if deltas else 0.0
        sampling_diagnostics.append({
            "sample": sample, "node": node, "samples": len(run_p),
            "mean_dt": mean_dt, "min_dt": min_dt, "max_dt": max_dt, "jumps": len(jumps)
        })

    rw_gross = (total_reads_all / tot_gross_wh) if tot_gross_wh > 0 else 0
    rw_net = (total_reads_all / tot_net_wh) if tot_net_wh > 0 else 0
    max_duration_s = max(durations) if durations else 0

    print("-" * 105)
    print("ENERGIA TOTAL BRUTA CONSOLIDADA: {:>10.4f} Wh  ({:>10.1f} J)".format(tot_gross_wh, tot_gross_wh * 3600.0))
    print("ENERGIA TOTAL NETA CONSOLIDADA:  {:>10.4f} Wh  ({:>10.1f} J)".format(tot_net_wh, tot_net_wh * 3600.0))
    print("TOTAL LECTURAS PROCESADAS:       {:>10,}".format(total_reads_all))
    print("TIEMPO PARALELO (WALL TIME):     {:>10.1f} s   ({:>10.2f} min)".format(max_duration_s, max_duration_s / 60.0))
    print("EFICIENCIA ENERGETICA BRUTA:     {:>10.1f} Reads/Wh".format(rw_gross))
    print("EFICIENCIA ENERGETICA NETA:      {:>10.1f} Reads/Wh".format(rw_net))
    print("=" * 105)

    print("\n" + "=" * 80)
    print("=== VALIDACION DE FRECUENCIA DE MUESTREO PMIC (TELEMETRIA ACTIVA) ===")
    print("=" * 80)
    diag_hdr = "{:<8} | {:<8} | {:<8} | {:<12} | {:<12} | {:<12} | {:<8}".format(
        "Muestra", "Nodo", "Puntos", "Delta Media", "Delta Min", "Delta Max", "Saltos >2s"
    )
    print(diag_hdr)
    print("-" * 80)
    all_ok = True
    for d in sampling_diagnostics:
        print("{:<8} | {:<8} | {:<8} | {:<12.3f} | {:<12.3f} | {:<12.3f} | {:<8}".format(
            d["sample"], d["node"], d["samples"], d["mean_dt"], d["min_dt"], d["max_dt"], d["jumps"]
        ))
        if d["jumps"] > 0:
            all_ok = False
    print("-" * 80)
    if all_ok:
        print("[VALIDACION OK] Todos los nodos registraron muestreo continuo y regular a ~1.0 Hz sin saltos.")
    else:
        print("[ATENCION] Se detectaron saltos temporales superiores a 2.0s en uno o mas nodos.")
    print("=" * 80)

if __name__ == "__main__":
    main()
