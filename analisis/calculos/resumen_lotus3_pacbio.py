"""LotuS3 PacBio (5 muestras, VSEARCH) en todas las plataformas, con el criterio del libro:
- reposo = promedio del archivo pre/ (5 min) de la misma sesion (en el cluster, por nodo)
- tiempo = ventana medida: primera a ultima lectura de la corrida
  (multinodo: del primer nodo que arranca al ultimo que termina)
- energia total y neta por regla del trapecio con los tiempos reales, en Wh
  (cluster: neta por nodo con su propio reposo y luego se suman los nodos)
- eficiencia = lecturas / Wh (bruta con total, neta con neta)
- speedup = T_mono / T_multi
Lee las carpetas <plataforma>/lotus3/pacbio_5muestras/. Si una plataforma aun no tiene datos, la salta.
Escribe resumen_lotus3_pacbio.csv junto a este script.
"""
import csv, glob, os
from datetime import datetime

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))  # Libro_Proyecto_Grado
BASE = os.path.join(RAIZ, 'datos_energia')
SALIDA = os.path.join(RAIZ, 'resultados', 'lotus3_pacbio')
LECTURAS = 25611  # 5 muestras HiFi del paquete de Cristian (5,179 + 5,045 + 5,194 + 5,133 + 5,060)
# F1 con benchmark/tmp/compute_f1_pacbio.py (logica LEMMI, verdad de cada muestra)
F1 = {'x86_pc_zamir': (0.8667, 0.8762), 'cluster_rpi5': (0.8667, 0.8762),
      'cluster_rpi5_mononodo': (0.8667, 0.8762), 'x86_pc_cristian': (0.8667, 0.8762)}
NOMBRE = {'x86_pc_cristian': 'x86 Ubuntu nativo (Cristian)', 'x86_pc_zamir': 'x86 WSL2 (Zamir)',
          'cluster_rpi5': 'Cluster RBPi5 multinodo (5 nodos)', 'cluster_rpi5_mononodo': 'Cluster RBPi5 mononodo (1 nodo)'}


def leer(f):
    out = []
    with open(f, encoding='utf-8-sig') as fh:
        for r in csv.DictReader(fh):
            t = r.get('timestamp') or r.get('time') or list(r.values())[0]
            p = r.get('power_w') or r.get('power') or list(r.values())[-1]
            out.append((datetime.fromisoformat(t).timestamp(), float(p)))
    return sorted(out)


def integrar(run, idle):
    et = en = 0.0
    for (t0, p0), (t1, p1) in zip(run, run[1:]):
        dt = t1 - t0
        et += (p0 + p1) / 2 * dt
        en += ((p0 + p1) / 2 - idle) * dt
    return et / 3600, en / 3600


def sesiones(plat):
    """Lista de (corrida, reposo) por nodo o por sesion."""
    d = os.path.join(BASE, plat, 'lotus3', 'pacbio_5muestras')
    runs = sorted(glob.glob(os.path.join(d, 'energia_*.csv')))
    pres = sorted(glob.glob(os.path.join(d, 'pre', '*.csv')))
    if not runs or not pres:
        return []
    if len(runs) == 1:
        return [(leer(runs[0]), leer(pres[0]))]
    # multinodo: emparejar por muestra (c001, c002, ...)
    out = []
    for r in runs:
        m = next(s for s in ['c001', 'c002', 'c003', 'e001', 'e002'] if f'_{s}_' in os.path.basename(r))
        p = next(x for x in pres if f'_{m}_' in os.path.basename(x))
        out.append((leer(r), leer(p)))
    return out


filas = []
for plat in ['x86_pc_cristian', 'x86_pc_zamir', 'cluster_rpi5', 'cluster_rpi5_mononodo']:
    ses = sesiones(plat)
    if not ses:
        print(f'[sin datos] {plat}')
        continue
    et = en = 0.0
    idles, cargas = [], []
    for run, pre in ses:
        idle = sum(p for _, p in pre) / len(pre)
        a, b = integrar(run, idle)
        et += a; en += b
        idles.append(idle); cargas.append(sum(p for _, p in run) / len(run))
    T = max(r[-1][0] for r, _ in ses) - min(r[0][0] for r, _ in ses)
    filas.append(dict(plataforma=plat, nombre=NOMBRE[plat], nodos=len(ses), tiempo_s=round(T, 2),
                      reposo_w=round(sum(idles) / len(idles), 3), carga_w=round(sum(cargas) / len(cargas), 3),
                      energia_total_wh=round(et, 4), energia_neta_wh=round(en, 4),
                      eficiencia_bruta=round(LECTURAS / et, 1), eficiencia_neta=round(LECTURAS / en, 1),
                      f1_familia=F1[plat][0], f1_genero=F1[plat][1]))

t = {f['plataforma']: f['tiempo_s'] for f in filas}
for f in filas:
    f['speedup_vs_mono'] = round(t['cluster_rpi5_mononodo'] / f['tiempo_s'], 2) if 'cluster_rpi5_mononodo' in t else ''

with open(os.path.join(SALIDA, 'resumen_lotus3_pacbio.csv'), 'w', newline='', encoding='utf-8') as fh:
    w = csv.DictWriter(fh, fieldnames=list(filas[0].keys()))
    w.writeheader(); w.writerows(filas)

print(f'LotuS3 PacBio, 5 muestras, {LECTURAS:,} lecturas, VSEARCH\n')
for f in filas:
    print(f"== {f['nombre']}  ({f['nodos']} sesion/nodo)")
    print(f"  Tiempo        {f['tiempo_s']:10.2f} s   speedup T_mono/T = {f['speedup_vs_mono']}")
    print(f"  Reposo        {f['reposo_w']:10.3f} W {'(por nodo)' if f['nodos'] > 1 else ''}")
    print(f"  Carga media   {f['carga_w']:10.3f} W {'(por nodo)' if f['nodos'] > 1 else ''}")
    print(f"  Energia total {f['energia_total_wh']:10.4f} Wh   neta {f['energia_neta_wh']:.4f} Wh")
    print(f"  Eficiencia    {f['eficiencia_bruta']:10.1f} / {f['eficiencia_neta']:.1f} lecturas/Wh (bruta / neta)")
    print(f"  F1            familia {f['f1_familia']}  genero {f['f1_genero']}")
