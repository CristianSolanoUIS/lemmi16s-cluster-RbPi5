"""Graficas de resumen del libro (tiempo, energia total y eficiencia) para las tres plataformas.
  fig_tiempo_ejecucion.png     tiempo total por pipeline; en verde, speedup del cluster frente al nativo
  fig_energia_consumida.png    energia total (Wh); en verde, % de cambio del cluster frente al nativo
  fig_eficiencia_reads_wh.png  lecturas / Wh (energia total); en verde, factores brutos y netos del cluster
Valores (criterio del libro: ventana medida, trapecio en Wh, cluster multinodo):
  Kraken 2 y QIIME 2: corridas del 2026-09-29.
  LotuS3: PacBio, 5 muestras, VSEARCH (datos_energia/resumen_lotus3_pacbio.csv, 2026-10-03).
"""
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

FIG = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'docs', 'latex', 'figuras'))
plt.rcParams.update({'font.family': 'Arial', 'font.size': 11})
AZUL, NARANJA, VERDE = '#1f4e79', '#c55a11', '#2e7d32'
PIPES = ['Kraken 2\n(5 muestras)', 'LotuS3\n(5 muestras)', 'QIIME 2\n(5 muestras)']
SERIES = [('x86_64 Ubuntu nativo (Cristian)', AZUL), ('x86_64 WSL2 (Zamir)', NARANJA),
          ('Clúster RBPi5 (ARM64)', VERDE)]

LECTURAS = [2453431, 25611, 2690077]
TIEMPO = [[22.01, 51.41, 51.04], [1899.24, 1775.85, 1972.46], [4323.72, 4799.44, 1678.94]]   # nativo, wsl2, cluster
E_TOTAL = [[0.2183, 0.3744, 0.2023], [17.1442, 17.6435, 12.0311], [25.4939, 34.2407, 8.2884]]
E_NETA = [[0.1518, 0.1775, 0.0398], [15.6519, 10.1478, 7.3270], [12.6965, 16.9772, 2.7779]]


def ejes(ax, ylabel):
    ax.set_yscale('log')
    ax.set_ylabel(ylabel, fontweight='bold')
    ax.grid(axis='y', which='major', linestyle='--', color='#dddddd', linewidth=0.8)
    ax.set_axisbelow(True)
    for s in ax.spines.values():
        s.set_color('#cccccc')


def barras(ax, datos, etiqueta, etiqueta_verde, w=0.26):
    x = np.arange(len(PIPES))
    for j, (lab, col) in enumerate(SERIES):
        xs = x + (j - 1) * w
        vals = [d[j] for d in datos]
        ax.bar(xs, vals, w, color=col, edgecolor='black', linewidth=0.8, label=lab)
        for i, (xx, v) in enumerate(zip(xs, vals)):
            if j == 2:
                ax.text(xx, v * 1.15, etiqueta_verde(i), ha='center', va='bottom', fontsize=9.5,
                        fontweight='bold', color=VERDE)
            else:
                ax.text(xx, v * 1.15, etiqueta(v), ha='center', va='bottom', fontsize=9, color='#222222')
    ax.set_xticks(x, PIPES)


# ---------- Tiempo ----------
def t_txt(v):
    return f'{v:,.0f} s\n({v/60:.1f}m)' if v >= 600 else f'{v:.1f} s'


def t_verde(i):
    nat, _, clu = TIEMPO[i]
    return f'{t_txt(clu).split(chr(10))[0]}\n({nat/clu:.2f}x)'


fig, ax = plt.subplots(figsize=(7.5, 5.2), dpi=300)
barras(ax, TIEMPO, t_txt, t_verde)
ejes(ax, 'Tiempo total (segundos, escala log)')
ax.set_ylim(5, 2e5)
ax.set_title('Tiempo Total de Cómputo por Pipeline', fontweight='bold', fontsize=14, pad=12)
ax.legend(loc='upper left', frameon=True)
fig.tight_layout(); fig.savefig(os.path.join(FIG, 'fig_tiempo_ejecucion.png')); plt.close(fig)


# ---------- Energia total ----------
def e_txt(v):
    return f'{v:.1f} Wh' if v >= 10 else f'{v:.2f} Wh'


def e_verde(i):
    nat, _, clu = E_TOTAL[i]
    return f'{e_txt(clu)}\n({(clu/nat - 1)*100:+.0f}%)'


fig, ax = plt.subplots(figsize=(7.5, 5.2), dpi=300)
barras(ax, E_TOTAL, e_txt, e_verde)
ejes(ax, 'Energía Total (Wh, escala log)')
ax.set_ylim(0.04, 2000)
ax.set_title('Consumo Eléctrico Total Invertido (Wh)', fontweight='bold', fontsize=14, pad=12)
ax.legend(loc='upper left', frameon=True)
fig.tight_layout(); fig.savefig(os.path.join(FIG, 'fig_energia_consumida.png')); plt.close(fig)


# ---------- Eficiencia ----------
def ef_txt(v):
    return f'{v/1e6:.1f} M' if v >= 1e6 else f'{v/1e3:.3g} k'


EF = [[n / e for e in fila] for n, fila in zip(LECTURAS, E_TOTAL)]
EFN = [[n / e for e in fila] for n, fila in zip(LECTURAS, E_NETA)]


def ef_verde(i):
    nat, wsl, clu = EF[i]
    nn, nw, nc = EFN[i]
    return (f'{ef_txt(clu)} Rd/Wh\n({clu/nat:.2f}x vs Nat / {clu/wsl:.2f}x vs WSL)\n'
            f'[Neta: {nc/nn:.2f}x Nat / {nc/nw:.2f}x WSL]')


fig, ax = plt.subplots(figsize=(10.5, 5.2), dpi=300)
barras(ax, EF, ef_txt, ef_verde)
ejes(ax, 'Eficiencia Energética (Reads / Wh, escala log)')
ax.set_ylim(300, 6e8)
ax.set_title('Eficiencia Energética Final (Reads / Wh)', fontweight='bold', fontsize=14, pad=12)
ax.legend(loc='upper right', frameon=True)
fig.tight_layout(); fig.savefig(os.path.join(FIG, 'fig_eficiencia_reads_wh.png')); plt.close(fig)
print('ok')
