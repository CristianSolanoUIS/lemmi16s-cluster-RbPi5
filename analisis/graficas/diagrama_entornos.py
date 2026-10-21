"""Diagrama de los tres entornos de experimentación -> fig_entornos_experimentales.png
Colores iguales a las gráficas de resumen del libro: clúster verde, x86 nativo azul, x86 WSL2 naranja.
"""
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

plt.rcParams.update({'font.family': 'Arial'})
VERDE, AZUL, NARANJA = '#2e7d32', '#1f4e79', '#c55a11'
TINTA, GRIS = '#222222', '#555555'

fig, ax = plt.subplots(figsize=(12, 7.2), dpi=300)
ax.set_xlim(0, 120); ax.set_ylim(0, 72); ax.axis('off')


def caja(x, y, w, h, borde, fondo='white', lw=1.2, r=1.2, ls='-'):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle=f'round,pad=0,rounding_size={r}',
                                linewidth=lw, edgecolor=borde, facecolor=fondo, linestyle=ls))


def texto(x, y, s, size=9, bold=False, color=TINTA, ha='center', va='center'):
    ax.text(x, y, s, fontsize=size, fontweight='bold' if bold else 'normal', color=color, ha=ha, va=va, linespacing=1.3)


def linea(x0, y0, x1, y1, color=GRIS, lw=1.3):
    ax.plot([x0, x1], [y0, y1], color=color, linewidth=lw, solid_capstyle='round')


# ---------- Entorno 1: clúster ----------
caja(1, 1, 70, 66, VERDE, fondo='#f3f8f3', lw=2)
texto(36, 63.5, 'Entorno 1: Clúster RBPi5 (ARM64), plataforma evaluada', 12, True, VERDE)
texto(36, 60, 'Ubuntu Server 24.04 LTS · Slurm 23.11 · telemetría PMIC DA9091 a 1 Hz en cada nodo de cómputo', 8.5, color=GRIS)

# maestro
caja(21, 45.5, 30, 11, VERDE)
texto(36, 53.6, 'Nodo maestro (rbpi4-master)', 9.5, True)
texto(36, 49.3, 'Raspberry Pi 4B · 4× Cortex-A72 · 8 GB\nSlurm (slurmctld) · servidor NFS /shared\nno ejecuta los pipelines', 7.8, color=GRIS)
# switch
caja(22, 36, 28, 5, GRIS, fondo='#eeeeee')
texto(36, 38.5, 'Switch Gigabit Ethernet (topología en estrella)', 8.5, True)
linea(36, 45.5, 36, 41)
# nodos
xs = [3.0, 16.5, 30.0, 43.5, 57.0]
for i, x in enumerate(xs):
    caja(x, 13, 12, 17, VERDE)
    texto(x + 6, 27, f'rbp5-{i+1}', 9.5, True)
    texto(x + 6, 19.5, 'Raspberry Pi 5\n4× Cortex-A76\n2.4 GHz\n16 GB LPDDR4X\nMicroSD 64 GB', 7.4, color=GRIS)
    linea(36, 36, x + 6, 30)
texto(36, 9.5, 'Nodos de cómputo usados: 5 de 10 (20 núcleos, 80 GB de RAM en total) · una muestra por nodo', 8.5, True, VERDE)
texto(36, 5.5, 'Entradas, bases de datos y entornos leídos desde /shared (NFS)', 8.2, color=GRIS)

# ---------- Entornos 2 y 3: laptops ----------
def laptop(y, color, titulo, so, ram, disco, tele, rol):
    caja(74, y, 45, 31, color, fondo='white', lw=2)
    texto(96.5, y + 27.5, titulo, 11, True, color)
    texto(96.5, y + 24.3, rol, 8.5, True, color)
    filas = [('Procesador', 'Intel Core i5-10300H (x86-64)\n4 núcleos / 8 hilos, 2.5–4.5 GHz'),
             ('Sistema', so), ('Memoria', ram), ('Disco', disco), ('Telemetría', tele)]
    yy = y + 19.8
    for k, v in filas:
        texto(76, yy, k, 8, True, ha='left')
        texto(88, yy, v, 7.8, color=GRIS, ha='left')
        yy -= 3.6 if '\n' not in v else 4.8


laptop(36, AZUL, 'Entorno 2: Laptop x86 con Ubuntu nativo', 'Ubuntu 24.04 LTS (nativo)', '16 GB DDR4',
       'SSD NVMe 512 GB', 'Intel RAPL (sysfs), 1 Hz', 'Referencia x86 principal')
laptop(1, NARANJA, 'Entorno 3: Laptop x86 con WSL2', 'Windows 11 + WSL2 (Ubuntu 22.04 LTS)',
       '32 GB DDR4 (28 GB asignados a WSL2)', 'SSD NVMe 500 GB', 'Intel RAPL (LibreHardwareMonitor), 1 Hz',
       'Referencia complementaria')

fig.savefig(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'docs', 'latex', 'figuras', 'fig_entornos_experimentales.png'),
            bbox_inches='tight', facecolor='white')
print('ok')
