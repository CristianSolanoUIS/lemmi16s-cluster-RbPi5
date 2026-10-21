"""Gráficas de la sección "un solo nodo y cinco nodos" (versión 2, pedida por el profesor):
mismas plataformas y colores que las gráficas de resumen del libro, más el clúster en un solo nodo.
  fig_mononodo_tiempo.png   tiempo de ejecución por pipeline (escala log)
  fig_mononodo_energia.png  energía total y energía neta por pipeline (escala log)
Valores: tablas del libro (nativo, WSL2, clúster multinodo) y resumen_mononodo_vs_multinodo.csv (mononodo).
"""
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

BASE = os.path.dirname(os.path.abspath(__file__))
FIG = os.path.normpath(os.path.join(BASE, '..', '..', 'docs', 'latex', 'figuras'))
plt.rcParams.update({'font.family': 'Arial', 'font.size': 11})

PIPES = ['Kraken 2\n(5 muestras)', 'LotuS3\n(5 muestras)', 'QIIME 2\n(5 muestras)']
SERIES = [  # etiqueta, color, rayado
    ('x86_64 Ubuntu nativo (Laptop Cristian)', '#1f4e79', ''),
    ('x86_64 WSL2 (Laptop Zamir)', '#c55a11', ''),
    ('Clúster RBPi5, 1 nodo', '#6aa864', '//'),
    ('Clúster RBPi5, 5 nodos', '#24692a', ''),
]
# LotuS3: PacBio, 5 muestras, VSEARCH (../resumen_lotus3_pacbio.csv)
TIEMPO = [  # s: nativo, wsl2, mono, multi
    [22.01, 51.41, 98.35, 51.04],
    [1899.24, 1775.85, 8582.68, 1972.46],
    [4323.72, 4799.44, 8394.91, 1678.94],
]
E_TOTAL = [[0.2183, 0.3744, 0.0976, 0.2023], [17.1442, 17.6435, 14.2991, 12.0311], [25.4939, 34.2407, 8.4246, 8.2884]]
E_NETA = [[0.1518, 0.1775, 0.0321, 0.0398], [15.6519, 10.1478, 8.6506, 7.3270], [12.6965, 16.9772, 2.9144, 2.7779]]


def ejes(ax, ylabel):
    ax.set_yscale('log')
    if ylabel:
        ax.set_ylabel(ylabel, fontweight='bold')
    ax.grid(axis='y', which='major', linestyle='--', color='#dddddd', linewidth=0.8)
    ax.set_axisbelow(True)
    for s in ax.spines.values():
        s.set_color('#cccccc')


def barras(ax, datos, fmt):
    x = np.arange(len(PIPES)); w = 0.2
    for j, (lab, col, hatch) in enumerate(SERIES):
        vals = [d[j] for d in datos]
        xs = x + (j - 1.5) * w
        ax.bar(xs, vals, w, color=col, edgecolor='black', linewidth=0.7, hatch=hatch, label=lab)
        for xx, v in zip(xs, vals):
            ax.text(xx, v * 1.12, fmt(v), ha='center', va='bottom', fontsize=7.3, rotation=90, color='#222222')
    ax.set_xticks(x, PIPES)


def fmt_t(v):
    return f'{v/60:.1f} min' if v >= 600 else f'{v:.1f} s'


def fmt_e(v):
    return f'{v:.2f}' if v >= 1 else f'{v:.4f}'


# Tiempo
fig, ax = plt.subplots(figsize=(9.5, 5.6), dpi=300)
barras(ax, TIEMPO, fmt_t)
ejes(ax, 'Tiempo total (segundos, escala log)')
ax.set_ylim(10, 200000)
ax.set_title('Tiempo de ejecución por plataforma', fontweight='bold', pad=12)
ax.legend(loc='upper left', frameon=True, fontsize=9)
fig.tight_layout(); fig.savefig(os.path.join(FIG, 'fig_mononodo_tiempo.png')); plt.close(fig)

# Energía
fig, axs = plt.subplots(1, 2, figsize=(12, 5.6), dpi=300, sharey=True)
for ax, datos, tit in [(axs[0], E_TOTAL, 'Energía total'), (axs[1], E_NETA, 'Energía neta')]:
    barras(ax, datos, fmt_e)
    ejes(ax, 'Energía (Wh, escala log)' if ax is axs[0] else '')
    ax.set_ylim(0.01, 400)
    ax.set_title(tit, fontweight='bold')
axs[0].legend(loc='upper left', frameon=True, fontsize=8.5)
fig.suptitle('Energía consumida por plataforma', fontweight='bold', fontsize=13)
fig.tight_layout(); fig.savefig(os.path.join(FIG, 'fig_mononodo_energia.png')); plt.close(fig)
print('ok')
