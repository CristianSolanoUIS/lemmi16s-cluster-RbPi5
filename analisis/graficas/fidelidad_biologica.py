"""Figura de F1 frente al Ground Truth (actualizada 2026-10-03).
F1 con la lógica de LEMMI usando la verdad de cada muestra (el eval.smk de LEMMI v1 usa la de e001 para todas).
Kraken 2 y QIIME 2: predicciones idénticas bit a bit en las tres plataformas.
LotuS3: PacBio, 5 muestras, VSEARCH; mismo F1 en las tres plataformas."""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
plt.rcParams.update({'font.family': 'Arial', 'font.size': 11})
AZUL, NARANJA, VERDE = '#1f4e79', '#c55a11', '#2e7d32'
grupos = ['Kraken 2\n(Familia)', 'Kraken 2\n(Género)', 'LotuS3\n(Familia)', 'LotuS3\n(Género)',
          'QIIME 2\n(Familia)', 'QIIME 2\n(Género)', 'QIIME 2\n(Especie)']
nat = [0.5223, 0.3545, 0.8667, 0.8762, 0.8286, 0.7083, 0.4500]
wsl = [0.5223, 0.3545, 0.8667, 0.8762, 0.8286, 0.7083, 0.4500]
clu = [0.5223, 0.3545, 0.8667, 0.8762, 0.8286, 0.7083, 0.4500]
x = np.arange(len(grupos)); w = 0.26
fig, ax = plt.subplots(figsize=(10.5, 5.2), dpi=300)
for off, vals, c, lab in [(-w, nat, AZUL, 'x86_64 Ubuntu nativo (Laptop Cristian)'),
                          (0, wsl, NARANJA, 'x86_64 WSL2 (Laptop Zamir)'),
                          (w, clu, VERDE, 'ARM64 Green HPC (Clúster RBPi5)')]:
    ax.bar(x + off, vals, w, color=c, edgecolor='black', linewidth=0.8, label=lab)
for i in range(len(grupos)):
    if nat[i] == wsl[i] == clu[i]:
        ax.text(x[i], nat[i] + 0.02, f'{nat[i]:.3f}\n(idénticos)', ha='center', va='bottom', fontsize=8.5,
                fontweight='bold', color='#1b5e20')
    else:
        for off, v, c in [(-w, nat[i], AZUL), (0, wsl[i], NARANJA), (w, clu[i], VERDE)]:
            ax.text(x[i] + off, v + 0.02, f'{v:.3f}', ha='center', va='bottom', fontsize=8.5, color=c,
                    fontweight='bold' if c == VERDE else 'normal')
ax.set_ylim(0, 1.15)
ax.set_ylabel('F1-Score frente a Ground Truth Oficial', fontweight='bold')
ax.set_title('Evaluación de Fidelidad Biológica y Taxonómica (F1-Score)', fontweight='bold', pad=12)
ax.set_xticks(x, grupos)
ax.grid(axis='y', linestyle='--', color='#dddddd'); ax.set_axisbelow(True)
for s in ax.spines.values(): s.set_color('#cccccc')
ax.legend(loc='upper left', frameon=True, fontsize=9.5)
fig.tight_layout(); import os; fig.savefig(os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'docs', 'latex', 'figuras', 'fig_fidelidad_biologica.png'))); print('ok')
