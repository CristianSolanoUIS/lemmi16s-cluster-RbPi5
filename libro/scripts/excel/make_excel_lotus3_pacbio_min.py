import csv, glob, math, os, re, shutil
from datetime import datetime
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.chart import ScatterChart, Reference, Series
from openpyxl.chart.legend import LegendEntry
from openpyxl.chart.shapes import GraphicalProperties
from openpyxl.workbook.properties import CalcProperties
from openpyxl.utils import get_column_letter as LL

BASE = r"C:\Users\zamir\Downloads\Libro_Proyecto_Grado"
E = BASE + r"\datos_energia"
OUTDIR = BASE + r"\excel graficas"
OUT = OUTDIR + r"\graficas_lotus3_por_minuto.xlsx"

CL_DIR = E + r"\cluster_rpi5\lotus3\pacbio_5muestras"
ZA_RUN = E + r"\x86_pc_zamir\lotus3\pacbio_5muestras\energia_lotus3_pacbio_x86_lote_run_20261003_001356.csv"
ZA_PRE = E + r"\x86_pc_zamir\lotus3\pacbio_5muestras\pre\energia_lotus3_pacbio_x86_lote_pre_20261003_001356.csv"
ZA_MARCAS = E + r"\x86_pc_zamir\lotus3\pacbio_5muestras\marcas_por_muestra_20261003_001356.csv"
CR_RUN = E + r"\x86_pc_cristian\lotus3\pacbio_5muestras\energia_lotus3_pacbio_Nativo_all_20261003_123350_20261003_123953.csv"
CR_PRE = E + r"\x86_pc_cristian\lotus3\pacbio_5muestras\pre\energia_baseline_pre_lotus3_pacbio_20261003_123450.csv"
SAMPLES = ["c001", "c002", "c003", "e001", "e002"]
CL, ZA, CR = "Clúster", "Laptop Zamir", "Laptop Cristian"

# viejo -> excel graficas\viejos
# versión adicional por minuto: no reemplaza graficas_lotus3.xlsx

F = "Calibri"
f_n = Font(name=F, size=11)
f_b = Font(name=F, size=11, bold=True)
f_t = Font(name=F, size=13, bold=True)
f_in = Font(name=F, size=11, color="0000FF")
f_g = Font(name=F, size=10, color="666666")
head = PatternFill("solid", fgColor="E7E6E6")
thin = Side(style="thin", color="BFBFBF")
box = Border(top=thin, bottom=thin, left=thin, right=thin)
TS = "yyyy-mm-dd hh:mm:ss.000"
C_CR, C_ZA, C_CL = "2A78D6", "EB6834", "1BAF7A"
C_NODE = {"c001": "2A78D6", "c002": "EB6834", "c003": "1BAF7A", "e001": "EDA100", "e002": "8E5CC4"}


def read(path):
    with open(path, encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))


def ts(s):
    return datetime.strptime(s, "%Y-%m-%d %H:%M:%S.%f")


def header(ws, names, widths, row=1, col=1):
    for i, (n, w) in enumerate(zip(names, widths), col):
        c = ws.cell(row=row, column=i, value=n)
        c.font, c.fill, c.border = f_b, head, box
        c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        ws.column_dimensions[c.column_letter].width = w
    ws.row_dimensions[row].height = 32


# ---------------- leer datos ----------------
cl_run, cl_pre, cl_node = {}, {}, {}
for s in SAMPLES:
    fr = glob.glob(os.path.join(CL_DIR, f"energia_LotuS3_pacbio_multinodo_{s}_*.csv"))[0]
    fp = glob.glob(os.path.join(CL_DIR, "pre", f"energia_baseline_pre_lotus3_pacbio_{s}_*.csv"))[0]
    cl_node[s] = re.search(r"node_(rbp5-\d)", fr).group(1)
    cl_run[s] = [(ts(r["timestamp"]), float(r["power_w"])) for r in read(fr)]
    cl_pre[s] = [(ts(r["timestamp"]), float(r["power_w"])) for r in read(fp)]
za_run = [(ts(r["timestamp"]), float(r["power_w"])) for r in read(ZA_RUN)]
za_pre = [(ts(r["timestamp"]), float(r["power_w"])) for r in read(ZA_PRE)]
za_marcas = [(r["muestra"], ts(r["inicio"]), ts(r["fin"])) for r in read(ZA_MARCAS)]
cr_run = [(ts(r["timestamp"]), float(r["power_w"])) for r in read(CR_RUN)]
cr_pre = [(ts(r["timestamp"]), float(r["power_w"])) for r in read(CR_PRE)]

wb = Workbook()

# ---------------- LEEME ----------------
ws = wb.active
ws.title = "LEEME"
ws.column_dimensions["A"].width = 110
lines = [
    ("LotuS3 (PacBio, 5 muestras, VSEARCH) - potencia durante la corrida (gráficas con el promedio de cada minuto)", f_t),
    ("", f_n),
    ("Datos", f_b),
    ("Clúster (5 Raspberry Pi 5): las 5 muestras corren en paralelo, una por nodo. Carpeta cluster_rpi5\\lotus3\\pacbio_5muestras.", f_n),
    ("Laptop Zamir (x86, WSL2): lote de 5 muestras seguidas. Las marcas de inicio y fin de cada muestra están en Datos_Zamir.", f_n),
    ("Laptop Cristian (x86, Ubuntu nativo): lote de 5 muestras seguidas, sin separar por muestra.", f_n),
    ("", f_n),
    ("Baseline y normalización", f_b),
    ("Antes de cada corrida hay 60 s de estabilización sin medir y 5 min de reposo medido (pre).", f_n),
    ("El baseline es el promedio de ese pre, uno por nodo en el clúster.", f_n),
    ("Potencia normalizada = potencia medida - baseline, cada plataforma con el suyo.", f_n),
    ("Energía = integral trapezoidal con los tiempos reales de cada lectura, en Wh (hoja Baselines).", f_n),
    ("", f_n),
    ("Hojas", f_b),
    ("Datos_Cluster, Datos_Zamir, Datos_Cristian: lecturas de la corrida. Datos_Pre: lecturas del reposo.", f_n),
    ("Azul = dato del CSV, negro = fórmula. t (min) = tiempo desde el inicio de la corrida; el pre queda en tiempo negativo.", f_n),
    ("G1 a G3: la corrida y, encima, la curva real del reposo (pre), las dos desde 0 min para compararlas.", f_n),
    ("El tiempo va en minutos porque las corridas duran entre 14 y 33 min; el reposo (5 min) se ve completo al inicio.", f_n),
    ("t reposo (min) en Datos_Pre = tiempo desde la primera lectura del reposo.", f_n), ("Cada punto de las gráficas es el promedio de las lecturas de ese minuto (tablas a la derecha de cada gráfica).", f_n), ("Las hojas de datos tienen todas las lecturas por segundo y la energía se calcula con ellas; los picos de pocos segundos se ven suavizados.", f_n),
    ("G1: cada nodo del clúster con sus lecturas reales; los reposos de los 5 nodos van en gris.", f_n),
    ("G4: potencia normalizada de las tres plataformas. Clúster = suma de los 5 nodos interpolada cada 1 s,", f_n),
    ("porque cada nodo lee en momentos distintos (tabla a la derecha de la gráfica).", f_n),
    ("", f_n),
    ("Nota: en LotuS3 el medidor del clúster tuvo huecos de hasta 7.6 s entre lecturas;", f_n),
    ("las lecturas reales de cada nodo están en Datos_Cluster. En G4, un nodo que ya terminó suma 0.", f_n),
]
for i, (t, fnt) in enumerate(lines, 1):
    ws.cell(row=i, column=1, value=t).font = fnt

# ---------------- Baselines (se crea antes para fijar filas) ----------------
wp = wb.create_sheet("Datos_Pre")
wbl = wb.create_sheet("Baselines")
wcl = wb.create_sheet("Datos_Cluster")
wza = wb.create_sheet("Datos_Zamir")
wcr = wb.create_sheet("Datos_Cristian")

header(wbl, ["Plataforma", "Muestra", "Nodo", "Lecturas pre", "Baseline (W)", "Inicio corrida"],
       [16, 10, 10, 11, 13, 23])
base_rows = [(CL, s, cl_node[s]) for s in SAMPLES] + [(ZA, "lote", ""), (CR, "lote", "")]
BL = {}
for i, (eq, s, nodo) in enumerate(base_rows, 2):
    wbl.cell(row=i, column=1, value=eq)
    wbl.cell(row=i, column=2, value=s)
    wbl.cell(row=i, column=3, value=nodo)
    wbl.cell(row=i, column=4, value=f"=COUNTIFS(Datos_Pre!$A:$A,A{i},Datos_Pre!$B:$B,B{i})")
    wbl.cell(row=i, column=5, value=f"=AVERAGEIFS(Datos_Pre!$E:$E,Datos_Pre!$A:$A,A{i},Datos_Pre!$B:$B,B{i})")
    if eq == CL:
        start = f"=_xlfn.MINIFS(Datos_Cluster!$C:$C,Datos_Cluster!$A:$A,B{i})"
    else:
        start = "=MIN(Datos_Zamir!$B:$B)" if eq == ZA else "=MIN(Datos_Cristian!$B:$B)"
    wbl.cell(row=i, column=6, value=start)
    wbl.cell(row=i, column=5).number_format = "0.000"
    wbl.cell(row=i, column=6).number_format = TS
    for c in range(1, 7):
        wbl.cell(row=i, column=c).font = f_n
        wbl.cell(row=i, column=c).border = box
    BL[(eq, s)] = f"Baselines!$E${i}"

# ---------------- Datos_Pre ----------------
header(wp, ["Plataforma", "Muestra", "Hora", "t (min)", "Potencia (W)", "Baseline (W)", "Potencia normalizada (W)",
             "t reposo (min)"],
       [16, 10, 23, 9, 13, 13, 15, 10])
wp.freeze_panes = "A2"
pre_rows = [(CL, s, t, p) for s in SAMPLES for t, p in cl_pre[s]]
pre_rows += [(ZA, "lote", t, p) for t, p in za_pre]
pre_rows += [(CR, "lote", t, p) for t, p in cr_pre]
rpre = {}
for i, (eq, s, t, p) in enumerate(pre_rows, 2):
    for c, v in ((1, eq), (2, s), (3, t), (5, p)):
        wp.cell(row=i, column=c, value=v).font = f_in
    wp.cell(row=i, column=4, value=f"=ROUND((C{i}-SUMIFS(Baselines!$F:$F,Baselines!$A:$A,A{i},Baselines!$B:$B,B{i}))*1440,3)")
    wp.cell(row=i, column=6, value=f"=SUMIFS(Baselines!$E:$E,Baselines!$A:$A,A{i},Baselines!$B:$B,B{i})")
    wp.cell(row=i, column=7, value=f"=E{i}-F{i}")
    wp.cell(row=i, column=8, value=f"=ROUND((C{i}-_xlfn.MINIFS($C:$C,$A:$A,A{i},$B:$B,B{i}))*1440,3)")
    for c in (4, 6, 7, 8):
        wp.cell(row=i, column=c).font = f_n
    wp.cell(row=i, column=3).number_format = TS
    for c in (5, 6, 7):
        wp.cell(row=i, column=c).number_format = "0.000"
    lo, hi = rpre.get((eq, s), (i, i))
    rpre[(eq, s)] = (min(lo, i), max(hi, i))

# ---------------- Datos_Cluster ----------------
header(wcl, ["Muestra", "Nodo", "Hora", "t (min)", "t lote (min)", "Potencia (W)", "Baseline (W)",
             "Potencia normalizada (W)", "Energía tramo (Wh)", "Energía neta tramo (Wh)"],
       [10, 10, 23, 9, 11, 13, 13, 15, 13, 14])
wcl.freeze_panes = "A2"
rcl = {}
i = 2
for s in SAMPLES:
    first = i
    for t, p in cl_run[s]:
        wcl.cell(row=i, column=1, value=s).font = f_in
        wcl.cell(row=i, column=2, value=cl_node[s]).font = f_in
        wcl.cell(row=i, column=3, value=t).font = f_in
        wcl.cell(row=i, column=6, value=p).font = f_in
        wcl.cell(row=i, column=4, value=f"=ROUND((C{i}-_xlfn.MINIFS($C:$C,$A:$A,A{i}))*1440,3)")
        wcl.cell(row=i, column=5, value=f"=ROUND((C{i}-MIN($C:$C))*1440,3)")
        wcl.cell(row=i, column=7, value=f"={BL[(CL, s)]}")
        wcl.cell(row=i, column=8, value=f"=F{i}-G{i}")
        if i > first:
            wcl.cell(row=i, column=9, value=f"=(F{i}+F{i-1})/2*(C{i}-C{i-1})*24")
            wcl.cell(row=i, column=10, value=f"=(H{i}+H{i-1})/2*(C{i}-C{i-1})*24")
        for c in (4, 5, 7, 8, 9, 10):
            wcl.cell(row=i, column=c).font = f_n
        wcl.cell(row=i, column=3).number_format = TS
        for c in (6, 7, 8):
            wcl.cell(row=i, column=c).number_format = "0.000"
        for c in (9, 10):
            wcl.cell(row=i, column=c).number_format = "0.00000"
        i += 1
    rcl[s] = (first, i - 1)


# ---------------- Datos_Zamir / Datos_Cristian ----------------
def lote_sheet(w, rows, eq, muestra_formula):
    header(w, ["Muestra", "Hora", "t (min)", "Potencia (W)", "Baseline (W)", "Potencia normalizada (W)",
               "Energía tramo (Wh)", "Energía neta tramo (Wh)"], [16, 23, 9, 13, 13, 15, 13, 14])
    w.freeze_panes = "A2"
    for i, (t, p) in enumerate(rows, 2):
        if muestra_formula:
            w.cell(row=i, column=1, value=muestra_formula(i)).font = f_n
        else:
            w.cell(row=i, column=1, value="lote").font = f_in
        w.cell(row=i, column=2, value=t).font = f_in
        w.cell(row=i, column=4, value=p).font = f_in
        w.cell(row=i, column=3, value=f"=ROUND((B{i}-MIN($B:$B))*1440,3)")
        w.cell(row=i, column=5, value=f"={BL[(eq, 'lote')]}")
        w.cell(row=i, column=6, value=f"=D{i}-E{i}")
        if i > 2:
            w.cell(row=i, column=7, value=f"=(D{i}+D{i-1})/2*(B{i}-B{i-1})*24")
            w.cell(row=i, column=8, value=f"=(F{i}+F{i-1})/2*(B{i}-B{i-1})*24")
        for c in (3, 5, 6, 7, 8):
            w.cell(row=i, column=c).font = f_n
        w.cell(row=i, column=2).number_format = TS
        for c in (4, 5, 6):
            w.cell(row=i, column=c).number_format = "0.000"
        for c in (7, 8):
            w.cell(row=i, column=c).number_format = "0.00000"
    return 2, len(rows) + 1


# marcas de Zamir en J:L
header(wza, ["Muestra", "Inicio", "Fin"], [10, 23, 23], row=1, col=10)
for k, (s, a, b) in enumerate(za_marcas, 2):
    wza.cell(row=k, column=10, value=s).font = f_in
    wza.cell(row=k, column=11, value=a).font = f_in
    wza.cell(row=k, column=12, value=b).font = f_in
    wza.cell(row=k, column=11).number_format = TS
    wza.cell(row=k, column=12).number_format = TS
mk = f"$K$2:$K${len(za_marcas) + 1}"
ml = f"$L$2:$L${len(za_marcas) + 1}"
mj = f"$J$2:$J${len(za_marcas) + 1}"


def za_muestra(i):
    return (f'=IF(B{i}<MIN({mk}),"fuera de muestra",IF(B{i}>INDEX({ml},MATCH(B{i},{mk},1)),'
            f'"fuera de muestra",INDEX({mj},MATCH(B{i},{mk},1))))')


rza = lote_sheet(wza, za_run, ZA, za_muestra)
rcr = lote_sheet(wcr, cr_run, CR, None)

# ---------------- energía (bajo Baselines) ----------------
r0 = len(base_rows) + 3
wbl.cell(row=r0, column=1, value="Energía de la corrida").font = f_b
header(wbl, ["Plataforma", "Lecturas", "Duración (min)", "Energía bruta (Wh)", "Energía neta (Wh)"],
       [16, 10, 10, 11, 13], row=r0 + 1)
wbl.column_dimensions["A"].width = 16
en = [
    (CL, "=COUNT(Datos_Cluster!F:F)", "=MAX(Datos_Cluster!E:E)", "=SUM(Datos_Cluster!I:I)", "=SUM(Datos_Cluster!J:J)"),
    (ZA, "=COUNT(Datos_Zamir!D:D)", "=MAX(Datos_Zamir!C:C)", "=SUM(Datos_Zamir!G:G)", "=SUM(Datos_Zamir!H:H)"),
    (CR, "=COUNT(Datos_Cristian!D:D)", "=MAX(Datos_Cristian!C:C)", "=SUM(Datos_Cristian!G:G)", "=SUM(Datos_Cristian!H:H)"),
]
for k, row in enumerate(en, r0 + 2):
    for c, v in enumerate(row, 1):
        cell = wbl.cell(row=k, column=c, value=v)
        cell.font, cell.border = f_n, box
    wbl.cell(row=k, column=3).number_format = "0.00"
    wbl.cell(row=k, column=4).number_format = "0.0000"
    wbl.cell(row=k, column=5).number_format = "0.0000"
wbl.cell(row=r0 + 5, column=1, value="Clúster = suma de los 5 nodos; duración = nodo más largo.").font = f_g


# ---------------- gráficas ----------------
def series(ws, lo, hi, xcol, ycol, title, color, dash=False, marker=True, width=19050, msize=5):
    s = Series(Reference(ws, min_col=ycol, min_row=lo, max_row=hi),
               Reference(ws, min_col=xcol, min_row=lo, max_row=hi), title=title)
    s.graphicalProperties.line.solidFill = color
    s.graphicalProperties.line.width = width
    if dash:
        s.graphicalProperties.line.dashStyle = "sysDash"
    if marker:
        s.marker.symbol = "circle"
        s.marker.size = msize
        s.marker.graphicalProperties = GraphicalProperties(solidFill=color)
        s.marker.graphicalProperties.line.solidFill = color
    else:
        s.marker.symbol = "none"
    s.smooth = False
    return s


def chart(title, xt, yt, xmin, xmax, xunit, ymin, ymax, yunit):
    c = ScatterChart()
    c.title, c.style = title, 13
    c.x_axis.title, c.y_axis.title = xt, yt
    c.x_axis.delete = c.y_axis.delete = False
    c.x_axis.majorGridlines = None
    c.title.overlay = False
    c.legend.position = "r"
    c.legend.overlay = False
    for ax, lo, hi, u in ((c.x_axis, xmin, xmax, xunit), (c.y_axis, ymin, ymax, yunit)):
        ax.number_format = "0"
        ax.numFmt.sourceLinked = False
        ax.scaling.min, ax.scaling.max, ax.majorUnit = lo, hi, u
        ax.crosses = "min"
    c.width, c.height = 26, 13
    return c


def hide(c, idxs):
    c.legend.legendEntry = [LegendEntry(idx=k, delete=True) for k in idxs]


def note(ws, text):
    ws["A1"] = text
    ws["A1"].font = f_g


XMIN = -10
XMAX4 = 35

C_REP = "8C8C8C"  # reposo en gris para distinguirlo de la corrida
TC = 18  # columna R: tablas auxiliares a la derecha de las gráficas
L = lambda c: chr(64 + c)


def interp_formula(sheet, tcol, ncol, lo, hi, xcell):
    """interpolación lineal de la columna ncol en el tiempo xcell, sobre las filas lo..hi."""
    T = f"{sheet}!${tcol}${lo}:${tcol}${hi}"
    N = f"{sheet}!${ncol}${lo}:${ncol}${hi}"
    k = f"MATCH({xcell},{T},1)"
    return (f"=IFERROR(INDEX({N},{k})+(INDEX({N},{k}+1)-INDEX({N},{k}))*({xcell}-INDEX({T},{k}))"
            f"/(INDEX({T},{k}+1)-INDEX({T},{k})),INDEX({N},{k}))")


def bins_min(tiempos, minimo=5):
    """minutos (enteros) que tienen al menos `minimo` lecturas."""
    cuenta = {}
    for t in tiempos:
        m = math.floor(round(t, 3))
        cuenta[m] = cuenta.get(m, 0) + 1
    return sorted(m for m, n in cuenta.items() if n >= minimo)


def minutos(lst, t0):
    return [(t - t0).total_seconds() / 60 for t, _ in lst]


def tabla_min(ws, col, fila, titulo, bins, formula):
    """tabla Minuto | t centro | promedio; formula(celda_m) devuelve el AVERAGEIFS. Devuelve (lo, hi, xcol, ycol)."""
    header(ws, ["Minuto", "t (min)", titulo], [8, 8, 13], row=fila, col=col)
    r = fila + 1
    for m in bins:
        mc = f"${LL(col)}{r}"
        ws.cell(row=r, column=col, value=m).font = f_n
        ws.cell(row=r, column=col + 1, value=f"={mc}+0.5").font = f_n
        ws.cell(row=r, column=col + 2, value=formula(mc)).font = f_n
        ws.cell(row=r, column=col + 2).number_format = "0.000"
        r += 1
    return fila + 1, r - 1, col + 1, col + 2


def prom(hoja, ycol, tcol, crit, mc):
    """AVERAGEIFS de hoja!ycol en el minuto [m, m+1) de hoja!tcol, con criterios extra [(col, valor)]."""
    extra = "".join(f',{hoja}!${c}:${c},"{v}"' for c, v in crit)
    return (f'=AVERAGEIFS({hoja}!${ycol}:${ycol}{extra},{hoja}!${tcol}:${tcol},">="&{mc},'
            f'{hoja}!${tcol}:${tcol},"<"&({mc}+1))')


# G1 clúster: promedio por minuto de cada nodo y, en gris, el reposo de cada nodo; todo desde 0 min
g1 = wb.create_sheet("G1_Cluster_vs_baseline")
note(g1, "Promedio por minuto de la corrida de LotuS3 PacBio en cada nodo y, en gris, del reposo previo de cada nodo, desde 0 min.")
c = chart("LotuS3 en el clúster: potencia por nodo vs. reposo (promedio por minuto)", "Tiempo (min)", "Potencia (W)",
          0, 35, 5, 0, 10, 1)
fila = 3
for s_ in SAMPLES:
    b = bins_min(minutos(cl_run[s_], cl_run[s_][0][0]))
    lo, hi, xc, yc = tabla_min(g1, TC, fila, f"{s_} (W)", b, lambda mc, s_=s_: prom("Datos_Cluster", "F", "D", [("A", s_)], mc))
    c.series.append(series(g1, lo, hi, xc, yc, f"{s_} ({cl_node[s_]})", C_NODE[s_]))
    fila = hi + 3
G1_HIDE = []
for k, s_ in enumerate(SAMPLES):
    b = bins_min(minutos(cl_pre[s_], cl_pre[s_][0][0]))
    lo, hi, xc, yc = tabla_min(g1, TC, fila, f"Reposo {s_} (W)", b,
                               lambda mc, s_=s_: prom("Datos_Pre", "E", "H", [("A", CL), ("B", s_)], mc))
    if k:
        G1_HIDE.append(len(c.series) + 1)  # 1-based, para ocultarlos en la leyenda desde Excel
    c.series.append(series(g1, lo, hi, xc, yc, "Reposo (cada nodo)" if k == 0 else f"Reposo {s_}", C_REP,
                           width=12700, msize=4))
    fila = hi + 3
g1.add_chart(c, "A3")
print("G1_HIDE=" + ",".join(map(str, G1_HIDE)))


def lote_chart(ws_g, hoja, run, pre, eq, color, title, label, xmax, ymax, yunit, xunit=10):
    c = chart(title, "Tiempo (min)", "Potencia (W)", 0, xmax, xunit, 0, ymax, yunit)
    lo, hi, xc, yc = tabla_min(ws_g, TC, 3, "Corrida (W)", bins_min(minutos(run, run[0][0])),
                               lambda mc: prom(hoja, "D", "C", [], mc))
    c.series.append(series(ws_g, lo, hi, xc, yc, label, color))
    lo, hi, xc, yc = tabla_min(ws_g, TC, hi + 3, "Reposo (W)", bins_min(minutos(pre, pre[0][0])),
                               lambda mc: prom("Datos_Pre", "E", "H", [("A", eq), ("B", "lote")], mc))
    c.series.append(series(ws_g, lo, hi, xc, yc, "Reposo (pre)", C_REP, width=12700, msize=4))
    ws_g.add_chart(c, "A3")


g2 = wb.create_sheet("G2_Zamir_vs_baseline")
note(g2, "Promedio por minuto del lote de 5 muestras de LotuS3 PacBio en la laptop de Zamir (WSL2) y de su reposo previo, desde 0 min.")
lote_chart(g2, "Datos_Zamir", za_run, za_pre, ZA, C_ZA, "LotuS3 en laptop Zamir (WSL2): potencia vs. reposo (promedio por minuto)",
           "Corrida (lote 5 muestras)", 30, 50, 10, xunit=5)

g3 = wb.create_sheet("G3_Cristian_vs_baseline")
note(g3, "Promedio por minuto del lote de 5 muestras de LotuS3 PacBio en la laptop de Cristian (nativo) y de su reposo previo, desde 0 min.")
lote_chart(g3, "Datos_Cristian", cr_run, cr_pre, CR, C_CR, "LotuS3 en laptop Cristian (nativo): potencia vs. reposo (promedio por minuto)",
           "Corrida (lote 5 muestras)", 35, 50, 10, xunit=5)

# G4: clúster = suma de los 5 nodos normalizados, interpolada a una rejilla de 1 s (fórmulas)
g4 = wb.create_sheet("G4_Comparacion")
note(g4, "Promedio por minuto de la potencia normalizada (medida - baseline). Clúster = suma de los 5 nodos interpolada cada 1 s, luego promediada por minuto. "
         "Tiempo negativo = reposo.")
t0 = {s: cl_run[s][0][0] for s in SAMPLES}
pre_t = {s: [round((t - t0[s]).total_seconds(), 1) for t, _ in cl_pre[s]] for s in SAMPLES}
run_t = {s: [round((t - t0[s]).total_seconds(), 1) for t, _ in cl_run[s]] for s in SAMPLES}
pre_grid = list(range(math.ceil(max(v[0] for v in pre_t.values())), math.floor(min(v[-1] for v in pre_t.values())) + 1))
run_grid = list(range(0, math.floor(max(v[-1] for v in run_t.values())) + 1))
header(g4, ["t (min)"] + [f"{s} norm. (W)" for s in SAMPLES] + ["Clúster suma (W)"], [7] + [10] * 5 + [11], row=3, col=TC)


r = 4
g4_pre = (r, r + len(pre_grid) - 1)
g4_run = (r + len(pre_grid), r + len(pre_grid) + len(run_grid) - 1)
for x in pre_grid + run_grid:
    xc = f"${chr(64 + TC)}{r}"
    g4.cell(row=r, column=TC, value=round(x / 60, 4)).font = f_n
    for k, s in enumerate(SAMPLES):
        if x < 0:
            lo, hi = rpre[(CL, s)]
            f = interp_formula("Datos_Pre", "D", "G", lo, hi, xc)
        else:
            lo, hi = rcl[s]
            f = interp_formula("Datos_Cluster", "D", "H", lo, hi, xc)
            f = f"=IF({xc}>MAX(Datos_Cluster!$D${lo}:$D${hi}),0,{f[1:]})"  # nodo que ya terminó suma 0
        g4.cell(row=r, column=TC + 1 + k, value=f).font = f_n
        g4.cell(row=r, column=TC + 1 + k).number_format = "0.000"
    g4.cell(row=r, column=TC + 6, value=f"=SUM({chr(65 + TC)}{r}:{chr(69 + TC)}{r})").font = f_n
    g4.cell(row=r, column=TC + 6).number_format = "0.000"
    r += 1
zr = r + 1
lo0, hi0, xc0, yc0 = zr + 1, zr + 2, TC, TC + 1
g4.cell(row=zr, column=TC, value="Línea 0 W").font = f_b
for k, xv in enumerate((XMIN, XMAX4)):
    g4.cell(row=zr + 1 + k, column=TC, value=xv).font = f_n
    g4.cell(row=zr + 1 + k, column=TC + 1, value=0).font = f_in

c = chart("LotuS3: potencia normalizada por plataforma (promedio por minuto)", "Tiempo desde el inicio de la corrida (min)",
          "Potencia normalizada (W)", XMIN, XMAX4, 5, -10, 50, 10)
TM = TC + 8  # tablas por minuto a la derecha de la rejilla de 1 s
G = f"G4_Comparacion"
tR, tS = LL(TC), LL(TC + 6)


def prom_rejilla(r0, r1, mc):
    return (f'=AVERAGEIFS(${tS}${r0}:${tS}${r1},${tR}${r0}:${tR}${r1},">="&{mc},'
            f'${tR}${r0}:${tR}${r1},"<"&({mc}+1))')


za0, cr0 = za_run[0][0], cr_run[0][0]
fila = 3
tablas = []
for titulo, bins, f in (
    ("Zamir norm. (W)", bins_min(minutos(za_run, za0)), lambda mc: prom("Datos_Zamir", "F", "C", [], mc)),
    ("Cristian norm. (W)", bins_min(minutos(cr_run, cr0)), lambda mc: prom("Datos_Cristian", "F", "C", [], mc)),
    ("Clúster norm. (W)", bins_min([x / 60 for x in run_grid]), lambda mc: prom_rejilla(*g4_run, mc)),
    ("Clúster pre norm. (W)", bins_min([x / 60 for x in pre_grid]), lambda mc: prom_rejilla(*g4_pre, mc)),
    ("Zamir pre norm. (W)", bins_min(minutos(za_pre, za0)),
     lambda mc: prom("Datos_Pre", "G", "D", [("A", ZA), ("B", "lote")], mc)),
    ("Cristian pre norm. (W)", bins_min(minutos(cr_pre, cr0)),
     lambda mc: prom("Datos_Pre", "G", "D", [("A", CR), ("B", "lote")], mc)),
):
    lo, hi, xc, yc = tabla_min(g4, TM, fila, titulo, bins, f)
    tablas.append((lo, hi, xc, yc))
    fila = hi + 3
c.series.append(series(g4, *tablas[0], "Laptop Zamir (WSL2)", C_ZA))
c.series.append(series(g4, *tablas[1], "Laptop Cristian (nativo)", C_CR))
c.series.append(series(g4, *tablas[2], "Clúster (suma 5 nodos)", C_CL))
c.series.append(series(g4, *tablas[3], "Clúster pre", C_CL))
c.series.append(series(g4, *tablas[4], "Zamir pre", C_ZA))
c.series.append(series(g4, *tablas[5], "Cristian pre", C_CR))
c.series.append(series(g4, lo0, hi0, xc0, yc0, "Baseline (0 W)", "404040", dash=True, marker=False, width=9525))
hide(c, [3, 4, 5])
g4.add_chart(c, "A3")

for w in wb.worksheets:
    for row in w.iter_rows():
        for cell in row:
            if cell.value is not None and cell.font.name != F:
                cell.font = Font(name=F, size=cell.font.size, bold=cell.font.bold, color=cell.font.color)

wb.calculation = CalcProperties(fullCalcOnLoad=True)
wb.save(OUT)
print("OK", OUT)
