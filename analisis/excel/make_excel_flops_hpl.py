"""Excel de FLOPs/energia (HPL) -> excel graficas/flops_energia_hpl.xlsx
  Resumen: tabla de resultados/flops_energia.csv (GFLOPS, potencia, energia, GFLOPS/W) y grafica de barras.
  Una hoja por plataforma con todas las lecturas de potencia (reposo y corrida) y la ventana de HPL marcada.
Correr despues de scripts/calculos/calcular_flops_energia.py.
"""
import csv, glob, os, re
from datetime import datetime
from openpyxl import Workbook
from openpyxl.chart import BarChart, Reference
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
D = os.path.join(RAIZ, 'datos_energia')
OUT = os.path.join(RAIZ, 'excel graficas', 'flops_energia_hpl.xlsx')
f_b = Font(name='Calibri', size=11, bold=True); f_t = Font(name='Calibri', size=13, bold=True)
f_g = Font(name='Calibri', size=10, color='666666')
head = PatternFill('solid', fgColor='E7E6E6'); verde = PatternFill('solid', fgColor='DCEFC4')
thin = Side(style='thin', color='BFBFBF'); box = Border(top=thin, bottom=thin, left=thin, right=thin)
TS = 'yyyy-mm-dd hh:mm:ss.000'


def ts(s):
    return datetime.fromisoformat(s.strip())


def encabezado(ws, nombres, anchos, fila=1):
    for i, (n, w) in enumerate(zip(nombres, anchos), 1):
        c = ws.cell(row=fila, column=i, value=n)
        c.font, c.fill, c.border = f_b, head, box
        c.alignment = Alignment(horizontal='center', vertical='center', wrap_text=True)
        ws.column_dimensions[c.column_letter].width = w
    ws.row_dimensions[fila].height = 32


def ventana_hpl(f_hpl):
    txt = open(f_hpl, encoding='utf-8', errors='ignore').read()
    m = re.findall(r'HPL_pdgesv\(\) (?:start|end) time\s+(.+)', txt)
    return [datetime.strptime(x.strip(), '%a %b %d %H:%M:%S %Y') for x in m]


wb = Workbook()
ws = wb.active; ws.title = 'Resumen'
ws['A1'] = 'FLOPs/energía con HPL (LINPACK, FP64): N = 30,000, NB = 192, 4 procesos MPI (uno por núcleo), OpenBLAS'
ws['A1'].font = f_t
ws['A2'] = ('GFLOPS = valor reportado por HPL. Energía integrada por trapecio solo durante la fase de resolución de HPL. '
            'GFLOPS/W bruto = GFLOP / energía total; neto = GFLOP / energía neta (descontando el reposo de la misma sesión).')
ws['A2'].font = f_g
filas = list(csv.DictReader(open(os.path.join(RAIZ, 'resultados', 'hpl', 'flops_energia.csv'), encoding='utf-8')))
cols = [('plataforma', 'Plataforma', 32), ('N', 'N', 8), ('tiempo_s', 'Tiempo HPL (s)', 11), ('gflops', 'GFLOPS', 10),
        ('pct_pico', '% del pico teórico', 11), ('reposo_w', 'Reposo (W)', 10), ('carga_w', 'Carga media (W)', 11),
        ('energia_total_wh', 'Energía total (Wh)', 11), ('energia_neta_wh', 'Energía neta (Wh)', 11),
        ('gflops_w_bruto', 'GFLOPS/W bruto', 11), ('gflops_w_neto', 'GFLOPS/W neto', 11)]
encabezado(ws, [c[1] for c in cols], [c[2] for c in cols], fila=4)
for i, f in enumerate(filas, 5):
    for j, (k, _, _) in enumerate(cols, 1):
        v = f[k]
        c = ws.cell(row=i, column=j, value=v if k == 'plataforma' else float(v))
        c.border = box
        if 'suma' in f['plataforma']:
            c.fill = verde; c.font = f_b
n = len(filas)
ws.cell(row=n + 6, column=1, value='Pico teórico FP64: Raspberry Pi 5 (4 x Cortex-A76 a 2.4 GHz, 8 FLOP/ciclo) = 76.8 GFLOPS; '
        'i5-10300H (4 núcleos a 4.5 GHz turbo máximo, AVX2 con FMA, 16 FLOP/ciclo) = 288 GFLOPS.').font = f_g

ch = BarChart(); ch.type = 'col'; ch.title = 'Rendimiento por energía (GFLOPS/W)'
ch.y_axis.title = 'GFLOPS/W'; ch.x_axis.title = 'Plataforma'
ch.add_data(Reference(ws, min_col=10, max_col=11, min_row=4, max_row=4 + n), titles_from_data=True)
ch.set_categories(Reference(ws, min_col=1, min_row=5, max_row=4 + n))
ch.x_axis.delete = ch.y_axis.delete = False
ch.width, ch.height = 26, 12
ws.add_chart(ch, f'A{n + 9}')


def hoja(nombre, run, pre, f_hpl):
    w = wb.create_sheet(nombre)
    encabezado(w, ['Fase', 'Hora', 't (s)', 'Potencia (W)', 'En fase de resolución HPL'], [12, 24, 10, 13, 16])
    a, b = ventana_hpl(f_hpl)
    t0 = run[0][0]
    r = 2
    for fase, datos in (('reposo', pre), ('corrida', run)):
        for t, p in datos:
            w.cell(row=r, column=1, value=fase)
            w.cell(row=r, column=2, value=t).number_format = TS
            w.cell(row=r, column=3, value=round((t - t0).total_seconds(), 1))
            w.cell(row=r, column=4, value=p)
            w.cell(row=r, column=5, value='sí' if fase == 'corrida' and a <= t.replace(microsecond=0) <= b else '')
            r += 1
    w.freeze_panes = 'A2'


def leer(f, fase=None):
    out = []
    for r in csv.DictReader(open(f, encoding='utf-8-sig')):
        if fase and r.get('fase') != fase:
            continue
        out.append((ts(r['timestamp']), float(r['power_w'])))
    return sorted(out)


C = os.path.join(D, 'cluster_rpi5', 'hpl')
for k in range(1, 6):
    nodo = f'rbp5-{k}'
    run = glob.glob(os.path.join(C, f'energia_HPL_node_{nodo}_*.csv'))
    if run:
        hoja(f'Datos_{nodo}', leer(run[0]), leer(glob.glob(os.path.join(C, 'pre', f'*hpl_node_{nodo}_*.csv'))[0]),
             glob.glob(os.path.join(C, f'hpl_{nodo}_job*.txt'))[0])
Z = os.path.join(D, 'x86_pc_zamir', 'hpl')
for f in glob.glob(os.path.join(Z, 'energia_hpl_x86_wsl2_*.csv'))[:1]:
    hoja('Datos_x86_WSL2', leer(f, 'run'), leer(f, 'baseline_pre'), glob.glob(os.path.join(Z, 'hpl_wsl2_*.txt'))[0])
X = os.path.join(D, 'x86_pc_cristian', 'hpl')
for f in glob.glob(os.path.join(X, 'energia_*HPL_nativo*.csv'))[:1]:
    hoja('Datos_x86_nativo', leer(f), leer(glob.glob(os.path.join(X, 'pre', '*.csv'))[0]),
         glob.glob(os.path.join(X, 'hpl_nativo_*.txt'))[0])

wb.save(OUT)
print('->', OUT, '| hojas:', wb.sheetnames)
