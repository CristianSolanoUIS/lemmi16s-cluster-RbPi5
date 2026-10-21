"""Procesa una corrida medida de LotuS3 PacBio en mi PC (WSL2), con el mismo criterio del libro:
- divide el CSV crudo (timestamp, muestra, fase, power_w) en la corrida y el reposo (pre/),
  con el mismo formato y nombres que la corrida de 3 muestras, y los copia a
  datos_energia/x86_pc_zamir/lotus3/pacbio_5muestras/ junto con las marcas por muestra
- reposo = promedio del reposo de 5 min de la misma sesion
- tiempo = ventana medida (primera a ultima lectura de la corrida)
- energia total y neta por regla del trapecio con los tiempos reales, en Wh
- eficiencia = lecturas / Wh (bruta con total, neta con neta)

Uso (desde WSL): python3 procesar_corrida_pacbio.py <fecha>   p. ej. 20261002_143731
"""
import csv, os, sys
from datetime import datetime

FECHA = sys.argv[1]
AQUI = os.path.dirname(os.path.abspath(__file__))
DEST = '/mnt/c/Users/zamir/Downloads/Libro_Proyecto_Grado/datos_energia/x86_pc_zamir/lotus3/pacbio_5muestras'
# lecturas HiFi reales de cada muestra (queryReads.fq del paquete de Cristian)
LECTURAS = {'c001': 5179, 'c002': 5045, 'c003': 5194, 'e001': 5133, 'e002': 5060}

crudo = os.path.join(AQUI, f'energia_lotus3_pacbio_x86_LOTE_{FECHA}.csv')
marcas = os.path.join(AQUI, f'marcas_lotus3_pacbio_x86_LOTE_{FECHA}.csv')

fases = {'baseline_pre': [], 'run': []}
with open(crudo, encoding='utf-8-sig') as fh:
    for r in csv.DictReader(fh):
        fases[r['fase']].append((r['timestamp'], float(r['power_w'])))

os.makedirs(os.path.join(DEST, 'pre'), exist_ok=True)
salidas = {'run': os.path.join(DEST, f'energia_lotus3_pacbio_x86_lote_run_{FECHA}.csv'),
           'baseline_pre': os.path.join(DEST, 'pre', f'energia_lotus3_pacbio_x86_lote_pre_{FECHA}.csv')}
for fase, ruta in salidas.items():
    with open(ruta, 'w', newline='', encoding='utf-8') as fh:
        w = csv.writer(fh)
        w.writerow(['timestamp', 'power_w'])
        w.writerows(fases[fase])
with open(marcas, encoding='utf-8-sig') as fi, \
        open(os.path.join(DEST, f'marcas_por_muestra_{FECHA}.csv'), 'w', newline='', encoding='utf-8') as fo:
    fo.write(fi.read())


def seg(ts):
    return datetime.fromisoformat(ts).timestamp()


pre = [(seg(t), p) for t, p in fases['baseline_pre']]
run = sorted((seg(t), p) for t, p in fases['run'])
idle = sum(p for _, p in pre) / len(pre)
et = en = 0.0
gap = 0.0
for (t0, p0), (t1, p1) in zip(run, run[1:]):
    dt = t1 - t0
    gap = max(gap, dt)
    et += (p0 + p1) / 2 * dt
    en += ((p0 + p1) / 2 - idle) * dt
et, en = et / 3600, en / 3600
T = run[-1][0] - run[0][0]
carga = sum(p for _, p in run) / len(run)
N = sum(LECTURAS.values())

print(f'LotuS3 PacBio, 5 muestras, WSL2 (corrida {FECHA})')
print(f'  lecturas medidor: reposo={len(pre)}  corrida={len(run)}  intervalo max={gap:.1f} s')
print(f'  Reposo (baseline)  {idle:8.2f} W')
print(f'  Carga media        {carga:8.2f} W')
print(f'  Tiempo (ventana)   {T:10.2f} s  ({T/3600:.2f} h)')
print(f'  Energia total      {et:10.4f} Wh')
print(f'  Energia neta       {en:10.4f} Wh')
print(f'  Lecturas           {N}')
print(f'  Eficiencia bruta   {N/et:10.1f} lecturas/Wh')
print(f'  Eficiencia neta    {N/en:10.1f} lecturas/Wh')
print('  Tiempo por muestra:')
with open(marcas, encoding='utf-8-sig') as fh:
    for r in csv.DictReader(fh):
        d = seg(r['fin']) - seg(r['inicio'])
        print(f"    {r['muestra']}  {d:8.1f} s  ({d/60:.1f} min)")
print(f'\nArchivos copiados a: {DEST}')
