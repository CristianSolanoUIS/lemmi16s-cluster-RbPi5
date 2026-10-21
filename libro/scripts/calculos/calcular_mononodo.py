"""Mononodo vs multinodo (clúster RBPi5), mismo criterio del libro:
- reposo = promedio del archivo pre/ (5 min) del nodo
- tiempo = ventana medida (primera a última lectura de la corrida)
- energía total y neta por regla del trapecio con los tiempos reales, en Wh
Los valores multinodo son los de las tablas del libro (datos_energia/cluster_rpi5).
"""
import csv, glob, os
from datetime import datetime

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))  # Libro_Proyecto_Grado
BASE = os.path.join(RAIZ, 'datos_energia', 'cluster_rpi5_mononodo')
SALIDA = os.path.join(RAIZ, 'resultados')
# LotuS3: corrida PacBio de 5 muestras (VSEARCH) en su propia subcarpeta
SUB = {'lotus3': 'pacbio_5muestras'}
LECTURAS = {'kraken2': 2453431, 'lotus3': 25611, 'qiime2': 2690077}
# multinodo (libro): nodos, tiempo s, reposo W/nodo, carga W/nodo, E total Wh, E neta Wh
MULTI = {
    'kraken2': (5, 51.04, 2.35, 2.93, 0.2023, 0.0398),
    'lotus3': (5, 1972.46, 2.361, 6.216, 12.0311, 7.3270),
    'qiime2': (5, 1678.94, 2.42, 3.64, 8.2884, 2.7779),
}
NOMBRE = {'kraken2': 'Kraken 2 + Bracken', 'lotus3': 'LotuS3', 'qiime2': 'QIIME 2'}


def leer(f):
    out = []
    with open(f, encoding='utf-8-sig') as fh:
        for r in csv.DictReader(fh):
            out.append((datetime.fromisoformat(r['timestamp']).timestamp(), float(r['power_w'])))
    return sorted(out)


filas = []
for p in ['kraken2', 'lotus3', 'qiime2']:
    pre = leer(glob.glob(os.path.join(BASE, p, SUB.get(p, ''), 'pre', '*.csv'))[0])
    run = leer([f for f in glob.glob(os.path.join(BASE, p, SUB.get(p, ''), 'energia_*.csv'))][0])
    idle = sum(w for _, w in pre) / len(pre)
    et = en = 0.0
    gaps = 0
    for (t0, p0), (t1, p1) in zip(run, run[1:]):
        dt = t1 - t0
        gaps = max(gaps, dt)
        et += (p0 + p1) / 2 * dt
        en += ((p0 + p1) / 2 - idle) * dt
    T = run[-1][0] - run[0][0]
    carga = sum(w for _, w in run) / len(run)
    et, en = et / 3600, en / 3600
    n, Tm, idm, cgm, etm, enm = MULTI[p]
    N = LECTURAS[p]
    filas.append(dict(p=p, T=T, Tm=Tm, S=T / Tm, n=n, idle=idle, carga=carga, idm=idm, cgm=cgm,
                      et=et, en=en, etm=etm, enm=enm,
                      eb=N / et, ebm=N / etm, en_=N / en, enm_=N / enm, lect=len(run), gap=gaps))

print('MONONODO vs MULTINODO (clúster RBPi5)\n')
for f in filas:
    print(f"== {NOMBRE[f['p']]}  (multinodo: {f['n']} nodos)")
    print(f"  lecturas PMIC corrida={f['lect']}  intervalo máx entre lecturas={f['gap']:.1f} s")
    print(f"  Tiempo           mono {f['T']:10.2f} s   multi {f['Tm']:10.2f} s   speedup T_mono/T_multi = {f['S']:.2f}x")
    print(f"  Reposo (nodo)    mono {f['idle']:10.3f} W   multi {f['idm']:10.2f} W/nodo")
    print(f"  Carga (nodo)     mono {f['carga']:10.3f} W   multi {f['cgm']:10.2f} W/nodo  (x{f['n']} nodos = {f['cgm']*f['n']:.2f} W)")
    print(f"  Energía total    mono {f['et']:10.4f} Wh  multi {f['etm']:10.4f} Wh   mono/multi = {f['et']/f['etm']:.2f}")
    print(f"  Energía neta     mono {f['en']:10.4f} Wh  multi {f['enm']:10.4f} Wh   mono/multi = {f['en']/f['enm']:.2f}")
    print(f"  Eficiencia bruta mono {f['eb']:12,.0f}   multi {f['ebm']:12,.0f} reads/Wh")
    print(f"  Eficiencia neta  mono {f['en_']:12,.0f}   multi {f['enm_']:12,.0f} reads/Wh\n")

with open(os.path.join(SALIDA, 'resumen_mononodo_vs_multinodo.csv'), 'w', newline='', encoding='utf-8') as fh:
    w = csv.writer(fh)
    w.writerow(['pipeline', 'nodos_multi', 'T_mono_s', 'T_multi_s', 'speedup', 'reposo_mono_W', 'carga_mono_W',
                'reposo_multi_W_nodo', 'carga_multi_W_nodo', 'Etotal_mono_Wh', 'Etotal_multi_Wh',
                'Eneta_mono_Wh', 'Eneta_multi_Wh', 'eta_bruta_mono', 'eta_bruta_multi', 'eta_neta_mono', 'eta_neta_multi'])
    for f in filas:
        w.writerow([f['p'], f['n'], round(f['T'], 2), f['Tm'], round(f['S'], 2), round(f['idle'], 3), round(f['carga'], 3),
                    f['idm'], f['cgm'], round(f['et'], 4), f['etm'], round(f['en'], 4), f['enm'],
                    round(f['eb']), round(f['ebm']), round(f['en_']), round(f['enm_'])])
print('Guardado: resumen_mononodo_vs_multinodo.csv')
