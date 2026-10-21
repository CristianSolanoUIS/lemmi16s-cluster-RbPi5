"""FLOPs/energia con HPL (LINPACK) en cada nodo RBPi5, el x86 nativo y el x86 WSL2.
Mismo criterio que el resto del libro:
  - reposo = promedio del reposo de 5 min de la misma sesion
  - energia por regla del trapecio con los tiempos reales, solo dentro de la ventana de HPL (marcas)
  - GFLOPS = valor que reporta HPL (linea WR); GFLOP totales = GFLOPS x tiempo de HPL
  - GFLOPS/W bruto = GFLOP / energia total (J);  GFLOPS/W neto = GFLOP / energia neta (J)
  - % del pico = GFLOPS / pico teorico FP64 del procesador
Lee datos_energia/<plataforma>/hpl/ y escribe resultados/flops_energia.csv y figuras/fig_flops_energia.png.
"""
import csv, glob, os, re
from datetime import datetime

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
D = os.path.join(RAIZ, 'datos_energia')
# Pico teorico FP64: nucleos x frecuencia x FLOP por ciclo
#   Cortex-A76: 2 unidades NEON de 128 bits con FMA = 8 FLOP/ciclo; 4 nucleos a 2.4 GHz = 76.8 GFLOPS
#   i5-10300H: 2 unidades AVX2 de 256 bits con FMA = 16 FLOP/ciclo; 4 nucleos a 4.5 GHz (turbo maximo) = 288 GFLOPS
#   (con HPL el i5 trabaja en turbo; a 2.5 GHz base el pico seria 160 GFLOPS y la laptop nativa lo supera)
PICO = {'arm': 76.8, 'x86': 288.0}


def ts(s):
    return datetime.fromisoformat(s.strip()).timestamp()


def leer(f, fase=None):
    out = []
    with open(f, encoding='utf-8-sig') as fh:
        for r in csv.DictReader(fh):
            if fase and r.get('fase') != fase:
                continue
            out.append((ts(r['timestamp']), float(r['power_w'])))
    return sorted(out)


def hpl(f):
    for line in open(f, encoding='utf-8', errors='ignore'):
        if line.startswith('WR'):
            p = line.split()
            return int(p[1]), float(p[5]), float(p[6])   # N, tiempo (s), GFLOPS
    raise ValueError(f'sin linea WR en {f}')


def ventana(f_hpl, f_marcas):
    """Fase de resolucion de HPL (HPL_pdgesv start/end), que es la que corresponde a los GFLOPS,
    como en el Green500. Si no aparece, se usa la ventana completa de las marcas."""
    txt = open(f_hpl, encoding='utf-8', errors='ignore').read()
    m = re.findall(r'HPL_pdgesv\(\) (?:start|end) time\s+(.+)', txt)
    if len(m) == 2:
        return tuple(datetime.strptime(x.strip(), '%a %b %d %H:%M:%S %Y').timestamp() for x in m)
    r = list(csv.DictReader(open(f_marcas, encoding='utf-8-sig')))[0]
    return ts(r['inicio']), ts(r['fin'])


def calcular(nombre, arq, run, pre, f_hpl, f_marcas):
    N, t, gflops = hpl(f_hpl)
    a, b = ventana(f_hpl, f_marcas)
    sel = [(x, p) for x, p in run if a - 1 <= x <= b + 1]
    idle = sum(p for _, p in pre) / len(pre)
    et = en = 0.0
    for (t0, p0), (t1, p1) in zip(sel, sel[1:]):
        et += (p0 + p1) / 2 * (t1 - t0)
        en += ((p0 + p1) / 2 - idle) * (t1 - t0)
    carga = sum(p for _, p in sel) / len(sel)
    gflop = gflops * t
    return dict(plataforma=nombre, N=N, tiempo_s=round(t, 2), gflops=round(gflops, 2),
                pct_pico=round(100 * gflops / PICO[arq], 1), reposo_w=round(idle, 3), carga_w=round(carga, 3),
                energia_total_wh=round(et / 3600, 4), energia_neta_wh=round(en / 3600, 4),
                gflops_w_bruto=round(gflop / et, 3), gflops_w_neto=round(gflop / en, 3))


filas = []
# cluster: un archivo de corrida, uno de reposo, la salida de HPL y las marcas por nodo
C = os.path.join(D, 'cluster_rpi5', 'hpl')
for n in range(1, 6):
    nodo = f'rbp5-{n}'
    run = glob.glob(os.path.join(C, f'energia_HPL_node_{nodo}_*.csv'))
    if not run:
        continue
    pre = glob.glob(os.path.join(C, 'pre', f'*hpl_node_{nodo}_*.csv'))[0]
    filas.append(calcular(f'Clúster {nodo}', 'arm', leer(run[0]), leer(pre),
                          glob.glob(os.path.join(C, f'hpl_{nodo}_job*.txt'))[0],
                          glob.glob(os.path.join(C, f'marcas_hpl_{nodo}_job*.csv'))[0]))
# x86 nativo (Cristian): corrida y reposo en archivos separados (RAPL)
X = os.path.join(D, 'x86_pc_cristian', 'hpl')
if glob.glob(os.path.join(X, 'energia_*HPL_nativo*.csv')):
    filas.append(calcular('x86 nativo (Cristian)', 'x86',
                          leer(glob.glob(os.path.join(X, 'energia_*HPL_nativo*.csv'))[0]),
                          leer(glob.glob(os.path.join(X, 'pre', '*.csv'))[0]),
                          glob.glob(os.path.join(X, 'hpl_nativo_*.txt'))[0],
                          glob.glob(os.path.join(X, 'marcas_hpl_nativo_*.csv'))[0]))
# x86 WSL2 (Zamir): un solo CSV con las fases baseline_pre y run (LibreHardwareMonitor)
Z = os.path.join(D, 'x86_pc_zamir', 'hpl')
if glob.glob(os.path.join(Z, 'energia_hpl_x86_wsl2_*.csv')):
    f = glob.glob(os.path.join(Z, 'energia_hpl_x86_wsl2_*.csv'))[0]
    filas.append(calcular('x86 WSL2 (Zamir)', 'x86', leer(f, 'run'), leer(f, 'baseline_pre'),
                          glob.glob(os.path.join(Z, 'hpl_wsl2_*.txt'))[0],
                          glob.glob(os.path.join(Z, 'marcas_hpl_wsl2_*.csv'))[0]))

nodos = [f for f in filas if f['plataforma'].startswith('Clúster')]
if nodos:   # el cluster completo: suma de los nodos medidos
    g = sum(f['gflops'] for f in nodos); et = sum(f['energia_total_wh'] for f in nodos); en = sum(f['energia_neta_wh'] for f in nodos)
    gflop = sum(f['gflops'] * f['tiempo_s'] for f in nodos)
    filas.append(dict(plataforma=f'Clúster RBPi5 ({len(nodos)} nodos, suma)', N=nodos[0]['N'],
                      tiempo_s=max(f['tiempo_s'] for f in nodos), gflops=round(g, 2),
                      pct_pico=round(100 * g / (PICO['arm'] * len(nodos)), 1),
                      reposo_w=round(sum(f['reposo_w'] for f in nodos), 3), carga_w=round(sum(f['carga_w'] for f in nodos), 3),
                      energia_total_wh=round(et, 4), energia_neta_wh=round(en, 4),
                      gflops_w_bruto=round(gflop / (et * 3600), 3), gflops_w_neto=round(gflop / (en * 3600), 3)))

if not filas:
    raise SystemExit('No hay datos de HPL todavia en datos_energia/<plataforma>/hpl/')

# repeticion de los nodos que rindieron menos (cluster_rpi5/hpl/repeticion): se compara aparte con la primera corrida
RP = os.path.join(C, 'repeticion')
rep = []
for n in range(1, 6):
    nodo = f'rbp5-{n}'
    run = glob.glob(os.path.join(RP, f'energia_HPL_node_{nodo}_*.csv'))
    if run:
        r = calcular(f'Clúster {nodo} (repetición)', 'arm', leer(run[0]),
                     leer(glob.glob(os.path.join(RP, 'pre', f'*hpl_node_{nodo}_*.csv'))[0]),
                     glob.glob(os.path.join(RP, f'hpl_{nodo}_job*.txt'))[0],
                     glob.glob(os.path.join(RP, f'marcas_hpl_{nodo}_job*.csv'))[0])
        primera = next(f for f in filas if f['plataforma'] == f'Clúster {nodo}')
        rep += [dict(primera, corrida='primera'), dict(r, corrida='repetición')]
if rep:
    with open(os.path.join(RAIZ, 'resultados', 'hpl', 'flops_energia_repeticion.csv'), 'w', newline='', encoding='utf-8') as fh:
        w = csv.DictWriter(fh, fieldnames=['corrida'] + list(filas[0].keys())); w.writeheader(); w.writerows(rep)
    print('Repetición (comparar con la primera corrida):')
    for f in rep:
        print(f"  {f['plataforma']:34s} {f['gflops']:8.2f} GFLOPS  {f['carga_w']:6.2f} W  {f['gflops_w_bruto']:6.3f} GFLOPS/W  neto {f['gflops_w_neto']:6.3f}")
salida = os.path.join(RAIZ, 'resultados', 'hpl', 'flops_energia.csv')
with open(salida, 'w', newline='', encoding='utf-8') as fh:
    w = csv.DictWriter(fh, fieldnames=list(filas[0].keys())); w.writeheader(); w.writerows(filas)

print(f"{'Plataforma':34s} {'GFLOPS':>8s} {'%pico':>6s} {'Reposo W':>9s} {'Carga W':>8s} {'GFLOPS/W':>9s} {'neto':>7s}")
for f in filas:
    print(f"{f['plataforma']:34s} {f['gflops']:8.2f} {f['pct_pico']:6.1f} {f['reposo_w']:9.2f} {f['carga_w']:8.2f} "
          f"{f['gflops_w_bruto']:9.3f} {f['gflops_w_neto']:7.3f}")
print('->', salida)

# grafica: GFLOPS/W bruto y neto por plataforma (mismos colores del libro)
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
plt.rcParams.update({'font.family': 'Arial', 'font.size': 11})
col = lambda p: '#2e7d32' if p.startswith('Clúster') else ('#1f4e79' if 'nativo' in p else '#c55a11')
etq = [f['plataforma'].replace('Clúster ', '').replace(' (', '\n(') for f in filas]
x = np.arange(len(filas)); w = 0.38
fig, ax = plt.subplots(figsize=(10.5, 5.2), dpi=300)
for off, k, alpha, lab in [(-w / 2, 'gflops_w_bruto', 1.0, 'GFLOPS/W bruto (energía total)'),
                           (w / 2, 'gflops_w_neto', 0.55, 'GFLOPS/W neto (energía neta)')]:
    vals = [f[k] for f in filas]
    ax.bar(x + off, vals, w, color=[col(f['plataforma']) for f in filas], alpha=alpha, edgecolor='black', linewidth=0.7, label=lab)
    for xx, v in zip(x + off, vals):
        ax.text(xx, v * 1.02, f'{v:.2f}', ha='center', va='bottom', fontsize=8.5)
ax.set_xticks(x, etq, fontsize=9)
ax.set_ylabel('Rendimiento por energía (GFLOPS/W)', fontweight='bold')
ax.set_xlabel('Plataforma (HPL, N = 30,000, 4 núcleos por equipo)', fontweight='bold')
ax.set_title('Rendimiento por energía con HPL (LINPACK, FP64)', fontweight='bold', pad=12)
ax.grid(axis='y', linestyle='--', color='#dddddd'); ax.set_axisbelow(True)
for s in ax.spines.values(): s.set_color('#cccccc')
ax.set_ylim(0, max(f['gflops_w_neto'] for f in filas) * 1.25)
ax.legend(loc='upper center', ncol=2, frameon=True, fontsize=9)
fig.tight_layout(); fig.savefig(os.path.join(RAIZ, 'docs', 'latex', 'figuras', 'fig_flops_energia.png'))
print('->', os.path.join(RAIZ, 'docs', 'latex', 'figuras', 'fig_flops_energia.png'))
